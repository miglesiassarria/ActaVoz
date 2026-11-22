#!/usr/bin/env python3
"""Suggest candidate checks from project manifests without claiming they passed."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser(description="Sugiere verificaciones según el proyecto detectado")
    parser.add_argument("--target", default=".", help="Raíz del proyecto")
    args = parser.parse_args()
    root = Path(args.target).resolve()
    suggestions: list[str] = []

    if (root / "Package.swift").is_file():
        suggestions.extend(["swift build", "swift test"])
    for project in sorted(root.glob("*.xcodeproj")):
        suggestions.append(f'xcodebuild -list -project "{project.name}"')
    for workspace in sorted(root.glob("*.xcworkspace")):
        suggestions.append(f'xcodebuild -list -workspace "{workspace.name}"')

    package = root / "package.json"
    if package.is_file():
        try:
            scripts = json.loads(package.read_text(encoding="utf-8")).get("scripts", {})
        except (OSError, json.JSONDecodeError):
            scripts = {}
        manager = "pnpm" if (root / "pnpm-lock.yaml").exists() else "yarn" if (root / "yarn.lock").exists() else "npm"
        for name in ("lint", "check", "test", "build"):
            if name in scripts:
                suggestions.append(f"{manager} run {name}")
    if (root / "pyproject.toml").is_file() or (root / "pytest.ini").is_file():
        suggestions.append("python3 -m pytest")
    if (root / "go.mod").is_file():
        suggestions.append("go test ./...")
    if (root / "Cargo.toml").is_file():
        suggestions.extend(["cargo fmt --all -- --check", "cargo test --workspace", "cargo clippy --workspace --all-targets"])

    if not suggestions:
        print("No se detectaron manifiestos con verificaciones conocidas.")
        return 0
    print("Sugerencias: ejecútalas, comprueba que sean válidas y solo entonces añádelas a docs/verification.md.")
    for command in dict.fromkeys(suggestions):
        print(f"- {command}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
