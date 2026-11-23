#!/usr/bin/env bash
# Crea ZIP ad hoc sin certificados; no publica ni modifica un artefacto previo.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
label="${1:-$(date +%Y%m%d-%H%M%S)}"
[[ "$label" =~ ^[a-zA-Z0-9._-]+$ ]] || { echo "Etiqueta no válida" >&2; exit 64; }
destination="$root/build/releases/$label"
[[ ! -e "$destination" ]] || { echo "Ya existe el artefacto; no se reemplaza: $destination" >&2; exit 73; }
xcodebuild -project "$root/ActaVoz/ActaVoz.xcodeproj" -scheme ActaVoz -configuration Release -derivedDataPath "$root/build/ReleaseDerivedData" -destination "platform=macOS,arch=arm64" build
mkdir -p "$destination"
ditto "$root/build/ReleaseDerivedData/Build/Products/Release/ActaVoz.app" "$destination/ActaVoz.app"
codesign --verify --strict "$destination/ActaVoz.app"
ditto -c -k --sequesterRsrc --keepParent "$destination/ActaVoz.app" "$destination/ActaVoz-$label-macos-arm64.zip"
shasum -a 256 "$destination/ActaVoz-$label-macos-arm64.zip" > "$destination/SHA256SUMS"
printf "Artefacto fijo (sin notarizar): %s\n" "$destination"
