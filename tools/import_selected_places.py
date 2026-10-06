#!/usr/bin/env python3
"""Copy explicit Dev place IDs into the Prod public/candidate intake split.

The Dev source remains untouched. The Prod database owns the routing decision:
complete records (summary, coordinates, and an image) become reviewed public
places; anything else is retained only in the protected candidate queue.
"""

from __future__ import annotations

import argparse
import json
import mimetypes
from pathlib import Path
from urllib.parse import quote, unquote

from migrate_user_journeys import Project, get_rows, request, required_environment, required_url


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--place-ids-file', type=Path, required=True)
    parser.add_argument('--apply', action='store_true', help='Perform writes. Default: dry run.')
    parser.add_argument(
        '--copy-dev-storage-images',
        action='store_true',
        help='Required with --apply when selected images are in the Dev place-images bucket.',
    )
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


def dev_place_image_path(project: Project, image_url: object) -> str | None:
    if not isinstance(image_url, str):
        return None
    prefix = f'{project.url}/storage/v1/object/public/place-images/'
    if not image_url.startswith(prefix):
        return None
    path = unquote(image_url.removeprefix(prefix)).strip('/')
    return path or None


def public_place_image_url(project: Project, path: str) -> str:
    return f'{project.url}/storage/v1/object/public/place-images/{quote(path, safe="/")}'


def storage_image_paths(project: Project, images: list[dict]) -> set[str]:
    return {
        path
        for image in images
        for key in ('image_url', 'thumbnail_url')
        if (path := dev_place_image_path(project, image.get(key))) is not None
    }


def copy_place_image(dev: Project, prod: Project, path: str) -> None:
    encoded_path = quote(path, safe='/')
    content = request(dev, 'GET', f'/storage/v1/object/public/place-images/{encoded_path}')
    content_type = mimetypes.guess_type(path)[0] or 'application/octet-stream'
    request(
        prod,
        'POST',
        f'/storage/v1/object/place-images/{encoded_path}',
        body=content,
        headers={'Content-Type': content_type, 'x-upsert': 'true'},
    )


def rewrite_copied_storage_urls(dev: Project, prod: Project, images: list[dict]) -> list[dict]:
    rewritten: list[dict] = []
    for image in images:
        copied = dict(image)
        for key in ('image_url', 'thumbnail_url'):
            path = dev_place_image_path(dev, copied.get(key))
            if path is not None:
                copied[key] = public_place_image_url(prod, path)
                copied['storage_copied'] = True
        rewritten.append(copied)
    return rewritten


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


def verify_import_rpc(prod: Project) -> None:
    """Confirm the target has the RPC before copying any Storage objects.

    An empty payload intentionally fails the function's required-field check
    after PostgREST resolves it. A missing function instead produces a 404.
    """
    try:
        import_place(prod, {}, [])
    except RuntimeError as error:
        message = str(error)
        if 'failed (404)' in message:
            raise RuntimeError(
                'The target database is missing import_selected_dev_place. Apply the place-candidate intake migrations there first.',
            ) from error
        if 'Selected place must include id, county_id, name, and type' in message:
            return
        raise
    raise RuntimeError('Unexpected preflight response from import_selected_dev_place.')


def main() -> int:
    args = parse_args()
    ids = selected_ids(args.place_ids_file)
    dev = Project(required_url('KAUNTI_DEV_SUPABASE_URL'), required_environment('KAUNTI_DEV_SERVICE_ROLE_KEY'))
    prod = Project(required_url('KAUNTI_PROD_SUPABASE_URL'), required_environment('KAUNTI_PROD_SERVICE_ROLE_KEY'))
    if args.apply:
        verify_import_rpc(prod)
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
        dev_storage_paths = storage_image_paths(dev, images_by_place.get(place_id, []))
        unknown_storage_url = any(
            '/storage/v1/object/' in str(image.get(key) or '')
            and dev_place_image_path(dev, image.get(key)) is None
            for image in images_by_place.get(place_id, [])
            for key in ('image_url', 'thumbnail_url')
        )
        complete = has_summary and has_coordinates and image_count > 0 and bool(str(place.get('source') or '').strip())
        if complete and not unknown_storage_url:
            route = 'public place'
            suffix = f'; copy {len(dev_storage_paths)} Dev storage image(s)' if dev_storage_paths else ''
        else:
            route = 'candidate queue'
            suffix = '; unsupported storage URL' if unknown_storage_url else ''
        print(f'- {place["name"]}: {route} ({image_count} image(s)){suffix}')

    if not args.apply:
        print('Dry run only. Re-run with --apply after reviewing the routes above.')
        return 0

    for place_id in ids:
        images = images_by_place.get(place_id, [])
        paths = storage_image_paths(dev, images)
        if paths and not args.copy_dev_storage_images:
            raise RuntimeError(
                'Selected images are in Dev Storage. Re-run with --copy-dev-storage-images to copy them to Prod.',
            )
        for path in sorted(paths):
            print(f'Copying place image: {path}')
            copy_place_image(dev, prod, path)
        result = import_place(prod, places_by_id[place_id], rewrite_copied_storage_urls(dev, prod, images))
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
