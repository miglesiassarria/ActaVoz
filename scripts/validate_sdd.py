#!/usr/bin/env python3
"""Validate SDD structure, phase gates, evidence, and index consistency."""

from __future__ import annotations

import argparse
import re
from pathlib import Path


VALID_STATES = {"discovery", "spec", "design", "tasks", "build", "done", "blocked", "discarded", "superseded"}
REQUIRED_ROOT_FILES = (
    "AGENTS.md",
    ".agents/skills/spec-driven-development/SKILL.md",
    "docs/sdd.md",
    "docs/agent-harness.md",
    "docs/product.md",
    "docs/architecture.md",
    "docs/verification.md",
    "docs/adr/README.md",
    "docs/adr/TEMPLATE.md",
    "specs/README.md",
    "specs/TEMPLATE/spec.md",
    "specs/TEMPLATE/design.md",
    "specs/TEMPLATE/tasks.md",
    "scripts/new-spec.py",
    "scripts/suggest_verification.py",
    "scripts/validate_sdd.py",
    "scripts/audit_sdd.py",
)
INDEX_MARKER = "<!-- spec-driven-development:index-end -->"


def metadata(text: str, field: str) -> str | None:
    match = re.search(rf"(?mi)^-\s+\*\*{re.escape(field)}:\*\*\s*(.+?)\s*$", text)
    return match.group(1).strip().lower() if match else None


def collect_specs(root: Path) -> list[Path]:
    specs_dir = root / "specs"
    if not specs_dir.is_dir():
        return []
    return sorted(path for path in specs_dir.iterdir() if path.is_dir() and re.match(r"^\d{4}-", path.name))


def index_states(index_text: str) -> dict[str, str]:
    rows = re.findall(r"^\|\s*\[(\d{4})\]\([^)]*/spec\.md\)\s*\|.*?\|\s*`([^`]+)`\s*\|", index_text, re.MULTILINE)
    return {identifier: state.strip().lower() for identifier, state in rows}


def validate(root: Path, strict: bool) -> tuple[list[str], list[str], list[tuple[str, str]]]:
    errors: list[str] = []
    warnings: list[str] = []
    summaries: list[tuple[str, str]] = []
    for relative in REQUIRED_ROOT_FILES:
        if not (root / relative).is_file():
            errors.append(f"falta {relative}")

    agents = root / "AGENTS.md"
    if agents.is_file():
        content = agents.read_text(encoding="utf-8")
        if content.count("<!-- spec-driven-development:start -->") != 1 or content.count("<!-- spec-driven-development:end -->") != 1:
            errors.append("AGENTS.md no contiene un único bloque SDD delimitado")

    index = root / "specs/README.md"
    index_text = index.read_text(encoding="utf-8") if index.is_file() else ""
    if index.is_file() and INDEX_MARKER not in index_text:
        errors.append("specs/README.md no contiene el marcador de índice")
    indexed = index_states(index_text)

    for path in collect_specs(root):
        identifier = path.name[:4]
        spec = path / "spec.md"
        design = path / "design.md"
        tasks = path / "tasks.md"
        for required in (spec, design, tasks):
            if not required.is_file():
                errors.append(f"{path.relative_to(root)}: falta {required.name}")
        if not spec.is_file():
            continue
        spec_text = spec.read_text(encoding="utf-8")
        state = metadata(spec_text, "Estado")
        approval = metadata(spec_text, "Aprobación")
        summaries.append((identifier, state or "sin estado"))
        if state not in VALID_STATES:
            errors.append(f"{path.relative_to(root)}: estado inválido {state!r}")
            continue
        if identifier not in indexed:
            errors.append(f"{path.relative_to(root)}: falta en specs/README.md")
        elif indexed[identifier] != state:
            errors.append(f"{path.relative_to(root)}: índice={indexed[identifier]!r}, spec={state!r}")
        if approval not in {"no aplica", "pendiente", "aprobada", "rechazada"}:
            errors.append(f"{path.relative_to(root)}: aprobación inválida {approval!r}")
        if state in {"design", "tasks", "build", "done"} and approval != "aprobada":
            errors.append(f"{path.relative_to(root)}: {state} exige Aprobación: aprobada")
        if state == "done" and tasks.is_file():
            tasks_text = tasks.read_text(encoding="utf-8").lower()
            if "- [ ]" in tasks_text:
                errors.append(f"{path.relative_to(root)}: done conserva tareas de cierre pendientes")
            if "pendiente" in tasks_text:
                errors.append(f"{path.relative_to(root)}: done conserva resultados o evidencia pendientes")
            completed = len(re.findall(r"(?m)^\s*- \[x\]\s+\*\*t\d+\.", tasks_text))
            evidence = len(re.findall(r"(?m)^\s*- método:", tasks_text))
            if completed and evidence < completed:
                errors.append(f"{path.relative_to(root)}: faltan bloques de evidencia para tareas cerradas")

    for identifier in indexed:
        if not any(path.name.startswith(identifier + "-") for path in collect_specs(root)):
            errors.append(f"specs/README.md: la entrada {identifier} no tiene directorio")

    for relative in ("docs/product.md", "docs/architecture.md", "docs/verification.md"):
        path = root / relative
        if path.is_file() and "TODO" in path.read_text(encoding="utf-8"):
            message = f"{relative} conserva TODO de adaptación"
            (errors if strict else warnings).append(message)
    return errors, warnings, summaries


def main() -> int:
    parser = argparse.ArgumentParser(description="Valida el sistema SDD del repositorio")
    parser.add_argument("--target", default=".", help="Raíz del proyecto")
    parser.add_argument("--strict", action="store_true", help="Convierte avisos de documentación en errores")
    args = parser.parse_args()
    root = Path(args.target).resolve()
    errors, warnings, _ = validate(root, args.strict)
    for message in errors:
        print(f"ERROR: {message}")
    for message in warnings:
        print(f"WARN: {message}")
    if errors:
        print(f"FAIL: {len(errors)} error(es), {len(warnings)} aviso(s)")
        return 1
    print(f"OK: instalación SDD válida; {len(warnings)} aviso(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
