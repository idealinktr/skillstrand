#!/usr/bin/env python3
"""Choose an installed iPhone simulator without hardcoding a device or runtime.

Writes destination=... to GITHUB_OUTPUT when that file is set, and always
prints the destination. Falls back to generic/platform=iOS Simulator.
"""

from __future__ import annotations

import json
import os
import subprocess


def emit(destination: str) -> None:
    print(destination)
    path = os.environ.get("GITHUB_OUTPUT")
    if not path:
        return
    with open(path, "a", encoding="utf-8") as handle:
        handle.write(f"destination={destination}\n")


def main() -> None:
    try:
        raw = subprocess.check_output(
            ["xcrun", "simctl", "list", "devices", "available", "-j"],
            text=True,
        )
        payload = json.loads(raw)
    except (OSError, subprocess.CalledProcessError, json.JSONDecodeError):
        emit("generic/platform=iOS Simulator")
        return

    candidates: list[tuple[bool, str]] = []
    for runtime, devices in payload.get("devices", {}).items():
        if "iOS" not in runtime:
            continue
        for device in devices:
            if device.get("isAvailable") is False:
                continue
            name = device.get("name") or ""
            udid = device.get("udid")
            if udid and "iPhone" in name:
                candidates.append((device.get("state") == "Booted", udid))

    if not candidates:
        emit("generic/platform=iOS Simulator")
        return

    candidates.sort(reverse=True)
    emit(f"platform=iOS Simulator,id={candidates[0][1]}")


if __name__ == "__main__":
    main()
