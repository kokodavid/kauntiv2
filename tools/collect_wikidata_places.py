#!/usr/bin/env python3
"""Collect a small, review-only set of Kenyan place records from Wikidata."""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from collections.abc import Iterable
from dataclasses import dataclass
from datetime import date
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import Request, urlopen

from wikimedia_commons import CommonsImage, resolve as resolve_commons_image

WIKIDATA_ENDPOINT = 'https://query.wikidata.org/sparql'
MAX_BATCH_SIZE = 100
MAX_LIMIT = 100
COORDINATE = re.compile(r'^Point\(([-+]?\d+(?:\.\d+)?)\s+([-+]?\d+(?:\.\d+)?)\)$')
QID = re.compile(r'/([^/]+)$')

# Keep this initial collector narrow. The database performs the final Kenyan
# county check, duplicate detection, and all candidate writes.
PLACE_CLASSES = (
    ('Q570116', 'Tourist attraction'),
    ('Q355304', 'Waterfall'),
    ('Q8502', 'Mountain'),
    ('Q22698', 'Park'),
    ('Q46169', 'National park'),
    ('Q23413', 'Castle'),
)


@dataclass(frozen=True)
class Place:
    key: str
    name: str
    kind: str
    lat: float
    lng: float
    summary: str | None
    image_file_url: str | None

    def payload(self, image: CommonsImage | None = None) -> dict[str, Any]:
        return {
            'key': self.key,
            'name': self.name,
            'type': self.kind,
            'lat': self.lat,
            'lng': self.lng,
            'summary': self.summary,
            'source': 'Wikidata',
            'source_url': f'https://www.wikidata.org/wiki/{self.key}',
            'licence': 'CC0',
            'external_id': self.key,
            'last_verified_at': date.today().isoformat(),
            'images': [] if image is None else [{
                'key': image.key,
                'remote_url': image.remote_url,
                'thumbnail_url': image.remote_url,
                'width': image.width,
                'height': image.height,
                'source': 'Wikimedia Commons',
                'source_url': image.source_url,
                'licence': image.licence,
                'licence_url': image.licence_url,
                'attribution': image.attribution,
                'last_verified_at': date.today().isoformat(),
            }],
        }


def endpoint_query(limit: int) -> str:
    values = '\n'.join(f'  (wd:{qid} "{kind}")' for qid, kind in PLACE_CLASSES)
    return f'''SELECT ?item ?itemLabel ?coord ?description ?image ?kind WHERE {{
  VALUES (?class ?kind) {{
{values}
  }}
  ?item wdt:P31 ?class;
        wdt:P625 ?coord;
        wdt:P17 wd:Q114.
  OPTIONAL {{ ?item schema:description ?description FILTER (lang(?description) = "en") }}
  OPTIONAL {{ ?item wdt:P18 ?image }}
  SERVICE wikibase:label {{ bd:serviceParam wikibase:language "en". }}
}}
LIMIT {limit}'''


def parse_point(value: str) -> tuple[float, float] | None:
    match = COORDINATE.match(value.strip())
    if not match:
        return None
    lng, lat = map(float, match.groups())
    if -90 <= lat <= 90 and -180 <= lng <= 180:
        return lat, lng
    return None


def binding_value(binding: dict[str, Any], key: str) -> str | None:
    value = binding.get(key, {}).get('value')
    return value.strip() if isinstance(value, str) and value.strip() else None


def places_from_bindings(bindings: Iterable[dict[str, Any]]) -> list[Place]:
    places: dict[str, Place] = {}
    for binding in bindings:
        item_url = binding_value(binding, 'item')
        name = binding_value(binding, 'itemLabel')
        point = binding_value(binding, 'coord')
        kind = binding_value(binding, 'kind')
        if not item_url or not name or not point or not kind:
            continue
        qid_match = QID.search(item_url)
        coordinates = parse_point(point)
        if not qid_match or not coordinates:
            continue
        key = qid_match.group(1)
        lat, lng = coordinates
        candidate = Place(key, name, kind, lat, lng, binding_value(binding, 'description'), binding_value(binding, 'image'))
        # A place may match more than one allowed class; preserve the first
        # deterministic row rather than submitting duplicate source keys.
        places.setdefault(key, candidate)
    return sorted(places.values(), key=lambda place: place.key)


def request_json(url: str, body: dict[str, Any], key: str | None = None) -> dict[str, Any]:
    encoded = json.dumps(body).encode('utf-8')
    headers = {'content-type': 'application/json', 'user-agent': 'Kaunti47WikidataCollector/1.0'}
    if key:
        headers['x-ingest-key'] = key
    request = Request(url, data=encoded, headers=headers, method='POST')
    try:
        with urlopen(request, timeout=60) as response:
            return json.loads(response.read().decode('utf-8'))
    except HTTPError as error:
        detail = error.read().decode('utf-8', errors='replace')[:500]
        raise RuntimeError(f'HTTP {error.code} from {url}: {detail}') from error
    except URLError as error:
        raise RuntimeError(f'Network request to {url} failed: {error.reason}') from error


def fetch_bindings(limit: int) -> list[dict[str, Any]]:
    encoded = urlencode({'query': endpoint_query(limit), 'format': 'json'}).encode('utf-8')
    request = Request(
        WIKIDATA_ENDPOINT,
        data=encoded,
        headers={
            'accept': 'application/sparql-results+json',
            'content-type': 'application/x-www-form-urlencoded',
            'user-agent': 'Kaunti47WikidataCollector/1.0 (contact: support@kaunti47.com)',
        },
        method='POST',
    )
    try:
        with urlopen(request, timeout=90) as response:
            payload = json.loads(response.read().decode('utf-8'))
    except HTTPError as error:
        detail = error.read().decode('utf-8', errors='replace')[:500]
        raise RuntimeError(f'Wikidata returned HTTP {error.code}: {detail}') from error
    except URLError as error:
        raise RuntimeError(f'Wikidata request failed: {error.reason}') from error
    rows = payload.get('results', {}).get('bindings', [])
    if not isinstance(rows, list):
        raise RuntimeError('Wikidata response did not contain result bindings')
    return rows


def chunks(items: list[dict[str, Any]]) -> Iterable[list[dict[str, Any]]]:
    for start in range(0, len(items), MAX_BATCH_SIZE):
        yield items[start:start + MAX_BATCH_SIZE]


def parse_bool(value: str) -> bool:
    if value.lower() in ('true', '1', 'yes'):
        return True
    if value.lower() in ('false', '0', 'no'):
        return False
    raise argparse.ArgumentTypeError('must be true or false')


def arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--ingest-url', default=os.getenv('DEV_SCRAPER_INGEST_URL'))
    parser.add_argument('--ingest-key', default=os.getenv('SCRAPER_INGEST_KEY'))
    parser.add_argument('--source', default='wikidata-ke')
    parser.add_argument('--limit', type=int, default=25)
    parser.add_argument('--dry-run', type=parse_bool, default=True)
    args = parser.parse_args()
    if not args.ingest_url or not args.ingest_key:
        parser.error('ingest URL and key are required')
    if not 1 <= args.limit <= MAX_LIMIT:
        parser.error(f'--limit must be between 1 and {MAX_LIMIT}')
    return args


def main() -> int:
    args = arguments()
    start = request_json(args.ingest_url, {
        'action': 'start', 'source': args.source, 'triggered_by': 'manual', 'dry_run': args.dry_run,
    }, args.ingest_key)
    run_id = start.get('run_id')
    if not isinstance(run_id, str):
        raise RuntimeError(f'Ingest start returned no run_id: {start}')

    try:
        places = places_from_bindings(fetch_bindings(args.limit))
        payloads = []
        for place in places:
            image = None
            if place.image_file_url:
                try:
                    image = resolve_commons_image(place.image_file_url)
                except (OSError, ValueError, json.JSONDecodeError) as error:
                    print(f'Could not resolve image for {place.key}: {error}', file=sys.stderr)
            payloads.append(place.payload(image))
        outcomes: dict[str, int] = {}
        candidate_ids: list[str] = []
        for batch in chunks(payloads):
            response = request_json(args.ingest_url, {'action': 'items', 'run_id': run_id, 'items': batch}, args.ingest_key)
            for result in response.get('results', []):
                outcome = result.get('outcome', 'error')
                outcomes[outcome] = outcomes.get(outcome, 0) + 1
                candidate_id = result.get('candidate_id')
                if not args.dry_run and outcome in ('created', 'updated') and isinstance(candidate_id, str):
                    candidate_ids.append(candidate_id)
        staging = {}
        if candidate_ids:
            staged = request_json(args.ingest_url, {'action': 'stage_images', 'candidate_ids': candidate_ids}, args.ingest_key)
            for result in staged.get('results', []):
                outcome = result.get('outcome', 'error')
                staging[outcome] = staging.get(outcome, 0) + 1
        status = 'partial' if outcomes.get('error') else 'succeeded'
        request_json(args.ingest_url, {'action': 'finish', 'run_id': run_id, 'status': status, 'checkpoint': {}}, args.ingest_key)
        print(json.dumps({'run_id': run_id, 'dry_run': args.dry_run, 'records': len(places), 'outcomes': outcomes, 'staging': staging}, sort_keys=True))
        return 0 if status == 'succeeded' else 1
    except Exception as error:
        try:
            request_json(args.ingest_url, {
                'action': 'finish', 'run_id': run_id, 'status': 'failed', 'error_summary': str(error)[:500],
            }, args.ingest_key)
        except Exception as finish_error:
            print(f'Could not mark scrape run as failed: {finish_error}', file=sys.stderr)
        raise


if __name__ == '__main__':
    raise SystemExit(main())
