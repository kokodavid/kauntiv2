#!/usr/bin/env python3
"""Copy explicit Dev place IDs into the Prod public/candidate intake split.

The Dev source remains untouched. The Prod database owns the routing decision:
complete records (summary, coordinates, and an image) become reviewed public
places; anything else is retained only in the protected candidate queue.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from urllib.parse import urlencode

from migrate_user_journeys import Project, get_rows, request, required_environment, required_url


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--place-ids-file', type=Path, required=True)
    parser.add_argument('--apply', action='store_true', help='Perform writes. Default: dry run.')
    return parser.parse_args()


def selected_ids(path: Path) -> list[str]:
    if not path.is_file():
        raise RuntimeError(f'Place-ID list does not exist: {path}')
    ids = [line.strip() for line in path.read_text(encoding='utf-8').splitlines() if line.strip() and not line.startswith('#')]
    if not ids:
        raise RuntimeError('Place-ID list is empty.')
    if len(ids) != len(set(ids)):
        raise RuntimeError('Place-ID list contains duplicate IDs.')
    return ids


def source_images(project: Project, place_ids: list[str]) -> dict[str, list[dict]]:
    rows = get_rows(project, 'place_images', {'place_id': f"in.({','.join(place_ids)})"})
    grouped: dict[str, list[dict]] = {place_id: [] for place_id in place_ids}
    for row in rows:
        grouped.setdefault(row['place_id'], []).append(row)
    return grouped


def import_place(prod: Project, place: dict, images: list[dict]) -> dict:
    response = request(
        prod,
        'POST',
        '/rest/v1/rpc/import_selected_dev_place',
        body=json.dumps({'p_place': place, 'p_images': images}).encode(),
    )
    rows = json.loads(response)
    if len(rows) != 1:
        raise RuntimeError(f'Unexpected import response for {place["id"]}.')
    return rows[0]


def main() -> int:
    args = parse_args()
    ids = selected_ids(args.place_ids_file)
    dev = Project(required_url('KAUNTI_DEV_SUPABASE_URL'), required_environment('KAUNTI_DEV_SERVICE_ROLE_KEY'))
    prod = Project(required_url('KAUNTI_PROD_SUPABASE_URL'), required_environment('KAUNTI_PROD_SERVICE_ROLE_KEY'))
    places = get_rows(dev, 'places', {'id': f"in.({','.join(ids)})"})
    found = {place['id'] for place in places}
    missing = [place_id for place_id in ids if place_id not in found]
    if missing:
        raise RuntimeError(f'Dev places not found: {", ".join(missing)}')

    images_by_place = source_images(dev, ids)
    places_by_id = {place['id']: place for place in places}
    print(f'Selected Dev places: {len(ids)}')
    for place_id in ids:
        place = places_by_id[place_id]
        has_summary = bool(str(place.get('summary') or '').strip())
        has_coordinates = place.get('lat') is not None and place.get('lng') is not None
        image_count = len(images_by_place.get(place_id, []))
        uses_supabase_storage = any(
            '/storage/v1/object/' in str(image.get(key) or '')
            for image in images_by_place.get(place_id, [])
            for key in ('image_url', 'thumbnail_url')
        )
        complete = has_summary and has_coordinates and image_count > 0 and bool(str(place.get('source') or '').strip())
        route = 'public place' if complete and not uses_supabase_storage else 'candidate queue'
        print(f'- {place["name"]}: {route} ({image_count} image(s))')

    if not args.apply:
        print('Dry run only. Re-run with --apply after reviewing the routes above.')
        return 0

    for place_id in ids:
        result = import_place(prod, places_by_id[place_id], images_by_place.get(place_id, []))
        destination = result['destination']
        reference = result['place_id'] or result['candidate_id']
        missing_fields = ', '.join(result['missing_fields']) or 'none'
        blockers = ', '.join(result['publish_blockers']) or 'none'
        print(f'- {places_by_id[place_id]["name"]}: {destination} ({reference}); missing: {missing_fields}; blockers: {blockers}')

    return 0


if __name__ == '__main__':
    try:
        raise SystemExit(main())
    except RuntimeError as error:
        print(f'Error: {error}')
        raise SystemExit(1)
