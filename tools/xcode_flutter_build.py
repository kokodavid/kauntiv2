"""Supply flavor entry point and Dart defines to Flutter's Xcode build phase."""

import base64
import json
import os
from pathlib import Path
import sys


REQUIRED_DEFINES = (
    "SUPABASE_URL",
    "SUPABASE_PUBLISHABLE_KEY",
    "GOOGLE_WEB_CLIENT_ID",
    "GOOGLE_IOS_CLIENT_ID",
)


def build_environment(environment: dict[str, str]) -> dict[str, str]:
    configuration = environment.get("CONFIGURATION", "")
    if configuration.endswith("-dev"):
        flavor = "dev"
    elif configuration.endswith("-prod"):
        flavor = "prod"
    elif configuration == "Release":
        raise ValueError("Archive with the dev or prod scheme, not Runner.")
    else:
        return environment.copy()

    source_root = environment.get("SRCROOT")
    if not source_root:
        raise ValueError("Xcode did not provide SRCROOT.")
    defines_path = Path(source_root).resolve().parent / "dart_defines" / f"{flavor}.json"
    if not defines_path.is_file():
        raise ValueError(f"Missing {defines_path}; create the local flavor defines file.")

    try:
        defines = json.loads(defines_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ValueError(f"Cannot read {defines_path}: {error}") from error
    if not isinstance(defines, dict):
        raise ValueError(f"{defines_path} must contain a JSON object.")

    for key in REQUIRED_DEFINES:
        if not isinstance(defines.get(key), str) or not defines[key].strip():
            raise ValueError(f"{defines_path} is missing {key}.")

    encoded = []
    for key, value in defines.items():
        if not isinstance(key, str) or not isinstance(value, (str, int, float, bool)):
            raise ValueError(f"{defines_path} contains a non-scalar Dart define.")
        text = value if isinstance(value, str) else json.dumps(value)
        encoded.append(base64.b64encode(f"{key}={text}".encode("utf-8")).decode("ascii"))

    result = environment.copy()
    result["FLUTTER_TARGET"] = f"lib/main_{flavor}.dart"
    result["DART_DEFINES"] = ",".join(encoded)
    return result


def main() -> int:
    try:
        environment = build_environment(dict(os.environ))
        flutter_root = environment.get("FLUTTER_ROOT")
        if not flutter_root:
            raise ValueError("Xcode did not provide FLUTTER_ROOT.")
    except ValueError as error:
        print(f"error: {error}", file=sys.stderr)
        return 1

    backend = Path(flutter_root) / "packages/flutter_tools/bin/xcode_backend.sh"
    os.execve("/bin/sh", ["/bin/sh", str(backend), "build"], environment)
    return 0


if __name__ == "__main__":
    sys.exit(main())
