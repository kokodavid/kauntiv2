#!/usr/bin/env python3
"""Copy one exact-name Dev place, including its place-images, into Prod.

Dev stays unchanged. The restricted Prod RPC decides whether the selected
record is publicly ready or must remain in the candidate review queue.
"""

from __future__ import annotations

import argparse

from import_selected_places import (
    copy_place_image,
    import_place,
    rewrite_copied_storage_urls,
    source_images,
    storage_image_paths,
    verify_import_rpc,
)
from migrate_user_journeys import Project, get_rows, required_environment, required_url


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--name', required=True, help='Exact Dev place name.')
    parser.add_argument(
        '--place-id',
        help='Optional Dev UUID. Required only when multiple records share the name.',
    )
    parser.add_argument('--apply', action='store_true', help='Copy the place and images. Default: dry run.')
    return parser.parse_args()


def matching_places(rows: list[dict], name: str, place_id: str | None) -> list[dict]:
    normalized_name = name.strip().casefold()
    matches = [
        row
        for row in rows
        if str(row.get('name') or '').strip().casefold() == normalized_name
    ]
    if place_id is not None:
        matches = [row for row in matches if row.get('id') == place_id]
    return matches


def resolve_place(project: Project, name: str, place_id: str | None) -> dict:
    name = name.strip()
    if not name:
        raise RuntimeError('Place name cannot be empty.')

    rows = get_rows(project, 'places', {'name': f'ilike.{name}'})
    matches = matching_places(rows, name, place_id)
    if not matches:
        suffix = f' with ID {place_id}' if place_id else ''
        raise RuntimeError(f'No exact Dev place found for {name!r}{suffix}.')
    if len(matches) > 1:
        ids = ', '.join(str(row['id']) for row in matches)
        raise RuntimeError(
            f'More than one Dev place is named {name!r}. Re-run with --place-id. Matches: {ids}',
        )
    return matches[0]


def readiness(place: dict, images: list[dict], dev: Project) -> tuple[str, str]:
    has_summary = bool(str(place.get('summary') or '').strip())
    has_coordinates = place.get('lat') is not None and place.get('lng') is not None
    has_source = bool(str(place.get('source') or '').strip())
    has_unknown_storage_url = any(
        '/storage/v1/object/' in str(image.get(key) or '')
        and not str(image.get(key) or '').startswith(
          f'{dev.url}/storage/v1/object/public/place-images/',
        )
        for image in images
        for key in ('image_url', 'thumbnail_url')
    )
    paths = storage_image_paths(dev, images)
    if has_summary and has_coordinates and has_source and images and not has_unknown_storage_url:
        return 'public place', f'copy {len(paths)} Dev storage image(s)'
    return 'candidate queue', 'Prod will retain incomplete or non-portable data for review'


def main() -> int:
    args = parse_args()
    dev = Project(required_url('KAUNTI_DEV_SUPABASE_URL'), required_environment('KAUNTI_DEV_SERVICE_ROLE_KEY'))
    prod = Project(required_url('KAUNTI_PROD_SUPABASE_URL'), required_environment('KAUNTI_PROD_SERVICE_ROLE_KEY'))
    place = resolve_place(dev, args.name, args.place_id)
    images = source_images(dev, [place['id']]).get(place['id'], [])
    route, detail = readiness(place, images, dev)

    print(f'Dev match: {place["name"]} ({place["id"]})')
    print(f'Route: {route}; {len(images)} image row(s); {detail}.')
    if not args.apply:
        print('Dry run only. Re-run with --apply to copy the record and supported Dev Storage images.')
        return 0

    verify_import_rpc(prod)
    for path in sorted(storage_image_paths(dev, images)):
        print(f'Copying place image: {path}')
        copy_place_image(dev, prod, path)
    result = import_place(prod, place, rewrite_copied_storage_urls(dev, prod, images))
    reference = result['place_id'] or result['candidate_id']
    missing = ', '.join(result['missing_fields']) or 'none'
    blockers = ', '.join(result['publish_blockers']) or 'none'
    print(f'Imported: {result["destination"]} ({reference}); missing: {missing}; blockers: {blockers}')
    return 0


if __name__ == '__main__':
    try:
        raise SystemExit(main())
    except RuntimeError as error:
        print(f'Error: {error}')
        raise SystemExit(1)
