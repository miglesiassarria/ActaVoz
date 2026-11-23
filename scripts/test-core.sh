#!/usr/bin/env bash
# Ejecuta las pruebas del núcleo ActaVozCore.
# Usa rutas escribibles dentro del repositorio para que funcione también en
# sesiones enjauladas; en un terminal normal bastaría "swift test".
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
export TMPDIR="$root/build/tmp"
export CLANG_MODULE_CACHE_PATH="$root/build/modulecache"

mkdir -p "$TMPDIR" "$CLANG_MODULE_CACHE_PATH"
cd "$root/ActaVoz/ActaVozCore"
exec swift test --scratch-path "$root/build/spm" --disable-sandbox "$@"
