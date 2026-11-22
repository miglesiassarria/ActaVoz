#!/usr/bin/env python3
"""Create a numbered SDD unit from the repository templates."""

from __future__ import annotations

import argparse
import re
import shutil
import unicodedata
from datetime import date
from pathlib import Path


INDEX_MARKER = "<!-- spec-driven-development:index-end -->"


def slugify(value: str) -> str:
    normalized = unicodedata.normalize("NFKD", value)
    ascii_value = normalized.encode("ascii", "ignore").decode("ascii").lower()
    return re.sub(r"(^-|-$)", "", re.sub(r"[^a-z0-9]+", "-", ascii_value)) or "spec"


def next_number(specs: Path) -> int:
    values = []
    for path in specs.iterdir():
        match = re.match(r"^(\d{4})-", path.name)
        if path.is_dir() and match:
            values.append(int(match.group(1)))
    return max(values, default=0) + 1


def main() -> int:
    parser = argparse.ArgumentParser(description="Crea una unidad SDD numerada")
    parser.add_argument("title", help="Título del cambio o descubrimiento")
    parser.add_argument(
        "--state", choices=("discovery", "spec"), default="spec", help="Estado inicial"
    )
    args = parser.parse_args()

    root = Path(__file__).resolve().parent.parent
    specs = root / "specs"
    template = specs / "TEMPLATE"
    index = specs / "README.md"
    if not template.is_dir() or not index.is_file():
        parser.error("faltan specs/TEMPLATE o specs/README.md")

    index_text = index.read_text(encoding="utf-8")
    if INDEX_MARKER not in index_text:
        parser.error(f"falta el marcador {INDEX_MARKER}")

    identifier = f"{next_number(specs):04d}"
    destination = specs / f"{identifier}-{slugify(args.title)}"
    if destination.exists():
        parser.error(f"ya existe {destination}")
    shutil.copytree(template, destination)

    replacements = {"NNNN": identifier, "TÍTULO": args.title, "AAAA-MM-DD": date.today().isoformat()}
    for path in destination.glob("*.md"):
        text = path.read_text(encoding="utf-8")
        for needle, value in replacements.items():
            text = text.replace(needle, value)
        path.write_text(text, encoding="utf-8")

    spec = destination / "spec.md"
    if args.state == "discovery":
        text = spec.read_text(encoding="utf-8")
        text = text.replace("**Estado:** spec", "**Estado:** discovery")
        text = text.replace("**Aprobación:** pendiente", "**Aprobación:** no aplica")
        spec.write_text(text, encoding="utf-8")
        next_step = "Cerrar decisión o crear una spec aprobable"
    else:
        next_step = "Completar la spec y obtener aprobación explícita"

    safe_title = args.title.replace("|", "\\|")
    row = f"| [{identifier}]({destination.name}/spec.md) | {safe_title} | `{args.state}` | {next_step} | |\n"
    index.write_text(index_text.replace(INDEX_MARKER, row + INDEX_MARKER), encoding="utf-8")
    print(destination.relative_to(root))
    print(f"Siguiente paso: {next_step}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
