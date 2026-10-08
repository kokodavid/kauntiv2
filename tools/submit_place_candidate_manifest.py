#!/usr/bin/env python3
"""Submit a reviewed, local candidate manifest through the scraper ingest API.

The manifest remains review-only: this tool can create or update
``place_candidates`` but cannot write to ``public.places``.
"""

from __future__ import annotations

import argparse
import json
import math
import os
import sys
from collections import Counter
from pathlib import Path
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


def request_json(url: str, body: dict[str, Any], key: str) -> dict[str, Any]:
    request = Request(
        url,
        data=json.dumps(body).encode("utf-8"),
        headers={
            "content-type": "application/json",
            "x-ingest-key": key,
            "user-agent": "Kaunti47CandidateManifest/1.0",
        },
        method="POST",
    )
    try:
        with urlopen(request, timeout=60) as response:
            return json.loads(response.read().decode("utf-8"))
    except HTTPError as error:
        detail = error.read().decode("utf-8", errors="replace")[:500]
        raise RuntimeError(f"HTTP {error.code} from ingest API: {detail}") from error
    except URLError as error:
        raise RuntimeError(f"Could not reach ingest API: {error.reason}") from error


def arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("manifest", type=Path)
    parser.add_argument("--ingest-url", default=os.getenv("DEV_SCRAPER_INGEST_URL"))
    parser.add_argument("--ingest-key", default=os.getenv("SCRAPER_INGEST_KEY"))
    parser.add_argument("--apply", action="store_true", help="Create candidates instead of dry-running.")
    parser.add_argument(
        "--probe-coastal-anchors",
        action="store_true",
        help="Dry-run nearby land anchors and print the closest county-valid point for each item.",
    )
    parser.add_argument(
        "--coastal-probe-offset",
        type=float,
        default=0.003,
        help="Decimal-degree probe offset for --probe-coastal-anchors (default: 0.003).",
    )
    args = parser.parse_args()
    if not args.ingest_url or not args.ingest_key:
        parser.error("ingest URL and key are required")
    return args


def load_manifest(path: Path) -> tuple[str, list[dict[str, Any]]]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except OSError as error:
        raise RuntimeError(f"Could not read {path}: {error}") from error
    except json.JSONDecodeError as error:
        raise RuntimeError(f"{path} is not valid JSON: {error}") from error

    source = payload.get("source") if isinstance(payload, dict) else None
    items = payload.get("items") if isinstance(payload, dict) else None
    if not isinstance(source, str) or not source:
        raise RuntimeError("manifest source must be a non-empty string")
    if not isinstance(items, list) or not items or len(items) > 100:
        raise RuntimeError("manifest items must contain between 1 and 100 records")
    if not all(isinstance(item, dict) for item in items):
        raise RuntimeError("every manifest item must be an object")
    return source, items


def distance_meters(a: dict[str, Any], b: dict[str, Any]) -> float:
    lat1, lng1 = math.radians(float(a["lat"])), math.radians(float(a["lng"]))
    lat2, lng2 = math.radians(float(b["lat"])), math.radians(float(b["lng"]))
    return 6_371_000 * 2 * math.asin(
        math.sqrt(
            math.sin((lat2 - lat1) / 2) ** 2
            + math.cos(lat1) * math.cos(lat2) * math.sin((lng2 - lng1) / 2) ** 2
        )
    )


def coastal_anchor_probes(
    items: list[dict[str, Any]], offset: float
) -> tuple[list[dict[str, Any]], dict[str, dict[str, Any]]]:
    # The original point plus eight points approximately 330 m away. This
    # finds a drivable/access-side anchor when a beach or marine point is just
    # outside a land county polygon, without silently changing the manifest.
    offsets = ((0, 0), (-offset, 0), (offset, 0), (0, -offset), (0, offset),
               (-offset, -offset), (-offset, offset), (offset, -offset), (offset, offset))
    probes: list[dict[str, Any]] = []
    originals: dict[str, dict[str, Any]] = {}
    for item in items:
        key = str(item["key"])
        originals[key] = item
        for index, (lat_offset, lng_offset) in enumerate(offsets):
            probe = dict(item)
            probe["key"] = f"{key}:coastal-probe:{index}"
            probe["lat"] = float(item["lat"]) + lat_offset
            probe["lng"] = float(item["lng"]) + lng_offset
            probes.append(probe)
    return probes, originals


def print_results(results: list[Any]) -> Counter[str]:
    outcomes = Counter(row.get("outcome", "error") for row in results if isinstance(row, dict))
    for row in results:
        if not isinstance(row, dict) or row.get("outcome") in ("created", "updated", "unchanged"):
            continue
        key = row.get("key", "unknown")
        reason = row.get("reason") or row.get("detail") or row.get("outcome", "error")
        if ":coastal-probe:" in str(key) and reason == "outside_kenya":
            continue
        print(f"{key}: {reason}", file=sys.stderr)
    return outcomes


def main() -> int:
    args = arguments()
    source, items = load_manifest(args.manifest)
    if args.probe_coastal_anchors and args.apply:
        raise RuntimeError("--probe-coastal-anchors cannot be used with --apply")
    if args.coastal_probe_offset <= 0 or args.coastal_probe_offset > 0.02:
        raise RuntimeError("--coastal-probe-offset must be greater than 0 and no more than 0.02")
    submitted_items = items
    originals: dict[str, dict[str, Any]] = {}
    if args.probe_coastal_anchors:
        submitted_items, originals = coastal_anchor_probes(items, args.coastal_probe_offset)
    start = request_json(
        args.ingest_url,
        {
            "action": "start",
            "source": source,
            "triggered_by": "manual",
            "dry_run": True if args.probe_coastal_anchors else not args.apply,
        },
        args.ingest_key,
    )
    run_id = start.get("run_id")
    if not isinstance(run_id, str):
        raise RuntimeError(f"Ingest start returned no run_id: {start}")

    try:
        result = request_json(
            args.ingest_url,
            {"action": "items", "run_id": run_id, "items": submitted_items},
            args.ingest_key,
        )
        results = result.get("results", [])
        outcomes = print_results(results)
        if args.probe_coastal_anchors:
            accepted: dict[str, list[dict[str, Any]]] = {}
            for row, probe in zip(results, submitted_items):
                if isinstance(row, dict) and row.get("outcome") == "created":
                    original_key = str(probe["key"]).split(":coastal-probe:", 1)[0]
                    accepted.setdefault(original_key, []).append(probe)
            suggestions = {
                key: min(points, key=lambda point: distance_meters(originals[key], point))
                for key, points in accepted.items()
            }
            print(json.dumps({
                "coastal_anchor_suggestions": {
                    key: {"lat": point["lat"], "lng": point["lng"], "distance_m": round(distance_meters(originals[key], point))}
                    for key, point in suggestions.items()
                },
            }, sort_keys=True))
        status = "succeeded" if not outcomes.get("error") else "partial"
        request_json(
            args.ingest_url,
            {"action": "finish", "run_id": run_id, "status": status, "checkpoint": {}},
            args.ingest_key,
        )
        print(json.dumps({"run_id": run_id, "dry_run": not args.apply, "outcomes": outcomes}, default=dict))
        return 0 if status == "succeeded" else 1
    except Exception as error:
        try:
            request_json(
                args.ingest_url,
                {"action": "finish", "run_id": run_id, "status": "failed", "error_summary": str(error)[:500]},
                args.ingest_key,
            )
        except Exception as finish_error:
            print(f"Could not mark run as failed: {finish_error}", file=sys.stderr)
        raise


if __name__ == "__main__":
    raise SystemExit(main())
