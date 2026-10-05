#!/usr/bin/env python3
"""Migrate selected Kaunti47 users from Dev to Prod by email.

The user must already have an auth account in both projects. The tool copies
portable profile settings, county progress, reviewed-place-safe wishlists, and
private Journeys. It never migrates auth identities, manual Dev Pro grants,
free-tier counters, public-trip publications, or unreviewed place references.

County-event history defaults to a single canonical event per current county
visit. This preserves badge/visit state without importing unverified Dev test
history into Prod leaderboards. Use --event-history all only after auditing a
specific cohort's Dev event history.
"""

from __future__ import annotations

import argparse
import csv
import subprocess
import sys
from collections.abc import Iterable
from pathlib import Path
from typing import Any
from urllib.parse import urlencode

from migrate_user_journeys import (
    Project,
    get_rows,
    required_environment,
    required_url,
    upsert_rows,
)


PROFILE_COLUMNS = (
    'home_county_id',
    'home_county_slug',
    'location_mode',
    'map_visibility',
    'show_on_leaderboards',
    'notify_badge_unlocks',
    'notify_county_nudges',
    'home_county_changed_at',
    'side_quest_radius_km',
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        '--emails-file',
        type=Path,
        required=True,
        help='Text file containing one selected email address per line.',
    )
    parser.add_argument(
        '--event-history',
        choices=('canonical', 'all'),
        default='canonical',
        help='Use canonical current-visit events by default; all requires review.',
    )
    parser.add_argument(
        '--apply',
        action='store_true',
        help='Perform writes. The default is a read-only inventory.',
    )
    return parser.parse_args()


def selected_emails(path: Path) -> list[str]:
    if not path.is_file():
        raise RuntimeError(f'Email list does not exist: {path}')
    emails = []
    for raw in path.read_text(encoding='utf-8').splitlines():
        email = raw.strip().lower()
        if email and not email.startswith('#'):
            emails.append(email)
    if not emails:
        raise RuntimeError('Email list is empty.')
    duplicates = {email for email in emails if emails.count(email) > 1}
    if duplicates:
        raise RuntimeError(f'Duplicate email(s) in list: {", ".join(sorted(duplicates))}')
    return emails


def auth_users_by_email(project: Project, wanted: set[str]) -> dict[str, str]:
    users: dict[str, str] = {}
    page = 1
    while wanted - users.keys():
        query = urlencode({'page': page, 'per_page': 1000})
        from migrate_user_journeys import request

        response = request(project, 'GET', f'/auth/v1/admin/users?{query}')
        batch = __import__('json').loads(response).get('users', [])
        for user in batch:
            email = str(user.get('email') or '').lower()
            if email in wanted:
                users[email] = user['id']
        if len(batch) < 1000:
            return users
        page += 1
    return users


def copy_user_id(row: dict[str, Any], prod_user_id: str) -> dict[str, Any]:
    copied = dict(row)
    copied['user_id'] = prod_user_id
    return copied


def canonical_events(
    visits: list[dict[str, Any]],
    events: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    required = {
        (visit['county_id'], 'explored' if visit['state'] == 'explored' else 'passed_through', visit['entered_at'])
        for visit in visits
        if visit['state'] in ('explored', 'passed_through')
    }
    return [
        event
        for event in events
        if (event['county_id'], event['outcome'], event['entered_at']) in required
    ]


def production_place_ids(prod: Project, wishlist: Iterable[dict[str, Any]]) -> set[str]:
    place_ids = sorted({row['place_id'] for row in wishlist if row['place_id'] is not None})
    if not place_ids:
        return set()
    rows = get_rows(prod, 'places', {'id': f"in.({','.join(place_ids)})"})
    return {row['id'] for row in rows}


def user_inventory(
    dev: Project,
    prod: Project,
    dev_user_id: str,
    event_history: str,
) -> dict[str, Any]:
    profiles = get_rows(dev, 'profiles', {'id': f'eq.{dev_user_id}'})
    if len(profiles) != 1:
        raise RuntimeError(f'Dev profile missing or duplicated for {dev_user_id}.')
    visits = get_rows(dev, 'county_visits', {'user_id': f'eq.{dev_user_id}'})
    events = get_rows(dev, 'county_visit_events', {'user_id': f'eq.{dev_user_id}'})
    depth = get_rows(dev, 'county_depth_progress', {'user_id': f'eq.{dev_user_id}'})
    wishlist = get_rows(dev, 'wishlist_items', {'user_id': f'eq.{dev_user_id}'})
    prod_places = production_place_ids(prod, wishlist)
    portable_wishlist = [
        row for row in wishlist
        if row['place_id'] is None or row['place_id'] in prod_places
    ]
    journey_count = len(get_rows(dev, 'journeys', {'user_id': f'eq.{dev_user_id}'}))
    return {
        'profile': profiles[0],
        'visits': visits,
        'events': events if event_history == 'all' else canonical_events(visits, events),
        'depth': depth,
        'wishlist': portable_wishlist,
        'skipped_wishlist': len(wishlist) - len(portable_wishlist),
        'journey_count': journey_count,
    }


def apply_account_data(prod: Project, prod_user_id: str, inventory: dict[str, Any]) -> None:
    source_profile = inventory['profile']
    profile = {
        'id': prod_user_id,
        **{
            column: source_profile[column]
            for column in PROFILE_COLUMNS
            if column in source_profile
        },
    }
    upsert_rows(prod, 'profiles', [profile], 'id')
    upsert_rows(
        prod,
        'county_visits',
        (copy_user_id(row, prod_user_id) for row in inventory['visits']),
        'id',
    )
    upsert_rows(
        prod,
        'county_visit_events',
        (copy_user_id(row, prod_user_id) for row in inventory['events']),
        'id',
    )
    upsert_rows(
        prod,
        'county_depth_progress',
        (copy_user_id(row, prod_user_id) for row in inventory['depth']),
        'user_id,county_id',
    )
    upsert_rows(
        prod,
        'wishlist_items',
        (copy_user_id(row, prod_user_id) for row in inventory['wishlist']),
        'id',
    )


def run_journey_migration(dev_user_id: str, prod_user_id: str, apply: bool) -> None:
    command = [
        sys.executable,
        str(Path(__file__).with_name('migrate_user_journeys.py')),
        '--dev-user-id',
        dev_user_id,
        '--prod-user-id',
        prod_user_id,
    ]
    if apply:
        command.append('--apply')
    subprocess.run(command, check=True)


def main() -> int:
    args = parse_args()
    emails = selected_emails(args.emails_file)
    dev = Project(
        required_url('KAUNTI_DEV_SUPABASE_URL'),
        required_environment('KAUNTI_DEV_SERVICE_ROLE_KEY'),
    )
    prod = Project(
        required_url('KAUNTI_PROD_SUPABASE_URL'),
        required_environment('KAUNTI_PROD_SERVICE_ROLE_KEY'),
    )
    wanted = set(emails)
    dev_users = auth_users_by_email(dev, wanted)
    prod_users = auth_users_by_email(prod, wanted)
    missing_dev = wanted - dev_users.keys()
    missing_prod = wanted - prod_users.keys()
    if missing_dev or missing_prod:
        problems = []
        if missing_dev:
            problems.append(f'missing in Dev: {", ".join(sorted(missing_dev))}')
        if missing_prod:
            problems.append(f'missing in Prod: {", ".join(sorted(missing_prod))}')
        raise RuntimeError('; '.join(problems))

    for email in emails:
        dev_user_id = dev_users[email]
        prod_user_id = prod_users[email]
        inventory = user_inventory(dev, prod, dev_user_id, args.event_history)
        print(
            f'{email}: {len(inventory["visits"])} visits, '
            f'{len(inventory["events"])} events, '
            f'{len(inventory["depth"])} depth rows, '
            f'{len(inventory["wishlist"])} portable wishlist rows '
            f'({inventory["skipped_wishlist"]} deferred), '
            f'{inventory["journey_count"]} journeys.',
        )
        if args.apply:
            apply_account_data(prod, prod_user_id, inventory)
        run_journey_migration(dev_user_id, prod_user_id, apply=args.apply)

    if not args.apply:
        print('Dry run only. Re-run with --apply after reviewing every inventory line.')
    return 0


if __name__ == '__main__':
    try:
        raise SystemExit(main())
    except (RuntimeError, subprocess.CalledProcessError) as error:
        print(f'Error: {error}', file=sys.stderr)
        raise SystemExit(1)
