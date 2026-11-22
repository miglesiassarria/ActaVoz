#!/usr/bin/env python3
"""Report the durable SDD state and run its consistency checks."""

from __future__ import annotations

import argparse
from pathlib import Path

from validate_sdd import validate


def main() -> int:
    parser = argparse.ArgumentParser(description="Audita las unidades SDD activas")
    parser.add_argument("--target", default=".", help="Raíz del proyecto")
    args = parser.parse_args()
    root = Path(args.target).resolve()
    errors, warnings, summaries = validate(root, strict=False)
    if summaries:
        print("Estado de especificaciones:")
        for identifier, state in summaries:
            print(f"- {identifier}: {state}")
    else:
        print("No hay especificaciones creadas.")
    for message in warnings:
        print(f"WARN: {message}")
    for message in errors:
        print(f"ERROR: {message}")
    active = [identifier for identifier, state in summaries if state in {"discovery", "spec", "design", "tasks", "build", "blocked"}]
    print("Activas: " + (", ".join(active) if active else "ninguna"))
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
