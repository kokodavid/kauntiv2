#!/usr/bin/env python3
"""Copy one user's private Journeys between two Supabase projects.

The tool is intentionally narrow: it migrates rows reachable from the source
user's private journeys and their matching `journey-media` Storage objects.
It never reads or migrates public-trip publication records, and ignores orphan
Storage objects because they have no journey_media row to authorise them.

The operation is resumable. Every database write is an upsert and media
objects are uploaded with upsert enabled. Run without --apply to inspect the
source and validate its relationships first.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from collections.abc import Iterable
from dataclasses import dataclass
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.parse import quote, urlencode
from urllib.request import Request, urlopen


@dataclass(frozen=True)
class Project:
    url: str
    service_key: str

    @property
    def headers(self) -> dict[str, str]:
        return {
            'apikey': self.service_key,
            'Authorization': f'Bearer {self.service_key}',
        }


def required_environment(name: str) -> str:
    value = os.environ.get(name, '').strip()
    if not value:
        raise RuntimeError(f'Missing required environment variable: {name}')
    return value


def required_url(name: str) -> str:
    value = required_environment(name).rstrip('/')
    if not value.startswith(('https://', 'http://')):
        raise RuntimeError(
            f'{name} must be a plain http(s) URL, not a Markdown link or other value.',
        )
    return value


def request(
    project: Project,
    method: str,
    path: str,
    *,
    body: bytes | None = None,
    headers: dict[str, str] | None = None,
) -> bytes:
    combined = project.headers | (headers or {})
    if body is not None:
        combined.setdefault('Content-Type', 'application/json')
    raw = Request(
        f'{project.url}{path}',
        data=body,
        headers=combined,
        method=method,
    )
    try:
        with urlopen(raw, timeout=120) as response:
            return response.read()
    except HTTPError as error:
        detail = error.read().decode('utf-8', errors='replace')
        raise RuntimeError(f'{method} {path} failed ({error.code}): {detail}') from error
    except URLError as error:
        raise RuntimeError(f'{method} {path} could not reach Supabase: {error.reason}') from error


def get_rows(project: Project, table: str, filters: dict[str, str]) -> list[dict[str, Any]]:
    query = urlencode({'select': '*'} | filters, safe='(),.*')
    rows: list[dict[str, Any]] = []
    page_size = 1000
    offset = 0
    while True:
        response = request(
            project,
            'GET',
            f'/rest/v1/{table}?{query}',
            headers={
                'Range-Unit': 'items',
                'Range': f'{offset}-{offset + page_size - 1}',
            },
        )
        page = json.loads(response)
        rows.extend(page)
        if len(page) < page_size:
            return rows
        offset += len(page)


def upsert_rows(
    project: Project,
    table: str,
    rows: Iterable[dict[str, Any]],
    conflict_columns: str,
) -> None:
    payload = list(rows)
    if not payload:
        return
    query = urlencode({'on_conflict': conflict_columns})
    request(
        project,
        'POST',
        f'/rest/v1/{table}?{query}',
        body=json.dumps(payload).encode(),
        headers={'Prefer': 'resolution=merge-duplicates,return=minimal'},
    )


def replace_user_id(row: dict[str, Any], prod_user_id: str) -> dict[str, Any]:
    copied = dict(row)
    copied['user_id'] = prod_user_id
    return copied


def copy_media_object(
    dev: Project,
    prod: Project,
    old_path: str,
    new_path: str,
) -> None:
    source_path = quote(old_path, safe='/')
    target_path = quote(new_path, safe='/')
    content = request(dev, 'GET', f'/storage/v1/object/authenticated/journey-media/{source_path}')
    content_type = 'image/jpeg' if new_path.lower().endswith('.jpg') else 'application/octet-stream'
    request(
        prod,
        'POST',
        f'/storage/v1/object/journey-media/{target_path}',
        body=content,
        headers={
            'Content-Type': content_type,
            'x-upsert': 'true',
        },
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--dev-user-id', required=True)
    parser.add_argument('--prod-user-id', required=True)
    parser.add_argument(
        '--apply',
        action='store_true',
        help='Perform writes. Without this flag the tool only validates and reports.',
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    dev = Project(
        required_url('KAUNTI_DEV_SUPABASE_URL'),
        required_environment('KAUNTI_DEV_SERVICE_ROLE_KEY'),
    )
    prod = Project(
        required_url('KAUNTI_PROD_SUPABASE_URL'),
        required_environment('KAUNTI_PROD_SERVICE_ROLE_KEY'),
    )

    journeys = get_rows(dev, 'journeys', {'user_id': f'eq.{args.dev_user_id}'})
    journey_ids = [journey['id'] for journey in journeys]
    if not journey_ids:
        print('No source journeys found; nothing to migrate.')
        return 0

    in_filter = f"in.({','.join(journey_ids)})"
    points = get_rows(dev, 'journey_points', {'journey_id': in_filter})
    counties = get_rows(dev, 'journey_counties', {'journey_id': in_filter})
    media = get_rows(dev, 'journey_media', {'journey_id': in_filter})

    journey_id_set = set(journey_ids)
    invalid_media = [
        row for row in media
        if row['user_id'] != args.dev_user_id
        or row['journey_id'] not in journey_id_set
        or not row['storage_path'].startswith(f'{args.dev_user_id}/{row["journey_id"]}/')
    ]
    if invalid_media:
        raise RuntimeError('Source journey_media rows do not have expected ownership paths.')

    print(
        'Source inventory: '
        f'{len(journeys)} journeys, {len(points)} points, '
        f'{len(counties)} county splits, {len(media)} media rows.'
    )
    if not args.apply:
        print('Dry run only. Re-run with --apply after reviewing this inventory.')
        return 0

    # cover_media_id references journey_media, so insert parents without the
    # cover selection, then restore it after media rows exist.
    covers = {
        row['id']: row.get('cover_media_id')
        for row in journeys
        if row.get('cover_media_id') is not None
    }
    prod_journeys = []
    for row in journeys:
        copied = replace_user_id(row, args.prod_user_id)
        copied['cover_media_id'] = None
        prod_journeys.append(copied)

    upsert_rows(prod, 'journeys', prod_journeys, 'id')
    upsert_rows(prod, 'journey_points', points, 'journey_id,sequence_number')
    upsert_rows(
        prod,
        'journey_counties',
        (replace_user_id(row, args.prod_user_id) for row in counties),
        'journey_id,county_id',
    )

    prod_media = []
    for index, row in enumerate(media, start=1):
        old_path = row['storage_path']
        new_path = old_path.replace(args.dev_user_id, args.prod_user_id, 1)
        print(f'Copying media {index}/{len(media)}: {row["journey_id"]}')
        copy_media_object(dev, prod, old_path, new_path)
        copied = replace_user_id(row, args.prod_user_id)
        copied['storage_path'] = new_path
        prod_media.append(copied)
    upsert_rows(prod, 'journey_media', prod_media, 'id')

    for journey_id, media_id in covers.items():
        query = urlencode({'id': f'eq.{journey_id}', 'user_id': f'eq.{args.prod_user_id}'})
        request(
            prod,
            'PATCH',
            f'/rest/v1/journeys?{query}',
            body=json.dumps({'cover_media_id': media_id}).encode(),
            headers={'Prefer': 'return=minimal'},
        )

    migrated = get_rows(prod, 'journeys', {'id': in_filter, 'user_id': f'eq.{args.prod_user_id}'})
    if len(migrated) != len(journeys):
        raise RuntimeError('Post-copy validation failed: journey count does not match.')
    migrated_points = get_rows(prod, 'journey_points', {'journey_id': in_filter})
    migrated_counties = get_rows(prod, 'journey_counties', {'journey_id': in_filter})
    migrated_media = get_rows(
        prod,
        'journey_media',
        {'journey_id': in_filter, 'user_id': f'eq.{args.prod_user_id}'},
    )
    expected = (len(journeys), len(points), len(counties), len(media))
    actual = (
        len(migrated),
        len(migrated_points),
        len(migrated_counties),
        len(migrated_media),
    )
    if actual != expected:
        raise RuntimeError(
            'Post-copy validation failed: expected '
            f'journeys/points/counties/media {expected}, got {actual}.',
        )
    print(
        'Completed: '
        f'{actual[0]} journeys, {actual[1]} points, {actual[2]} county splits, '
        f'and {actual[3]} media rows migrated to the Prod account.',
    )
    return 0


if __name__ == '__main__':
    try:
        raise SystemExit(main())
    except RuntimeError as error:
        print(f'Error: {error}', file=sys.stderr)
        raise SystemExit(1)
