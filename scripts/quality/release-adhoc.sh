#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../.."
VERSION="${1:-0.1.0-beta.1}"
ROOT="$(pwd)"
DERIVED="$ROOT/build/ReleaseAdhoc"
STAGE="$ROOT/build/release-stage"
DMG="$ROOT/build/ActaVoz-$VERSION.dmg"

rm -rf "$STAGE"
mkdir -p "$STAGE"

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project ActaVoz/ActaVoz.xcodeproj -scheme ActaVoz \
  -configuration Release -derivedDataPath "$DERIVED" \
  CODE_SIGN_IDENTITY="-" CODE_SIGN_STYLE=Manual \
  CODE_SIGNING_REQUIRED=YES CODE_SIGNING_ALLOWED=YES \
  DEVELOPMENT_TEAM="" build

APP="$DERIVED/Build/Products/Release/ActaVoz.app"
test -d "$APP"
codesign --verify --deep --strict "$APP"
codesign -dv --verbose=4 "$APP" 2>&1 | grep -E "Signature|Identifier|TeamIdentifier" || true

ditto "$APP" "$STAGE/ActaVoz.app"
cp docs/evidencia/0011/INSTALAR.txt "$STAGE/INSTALAR.txt"
hdiutil create -volname "ActaVoz" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null
hdiutil verify "$DMG" >/dev/null
shasum -a 256 "$DMG" | tee "$DMG.sha256"

echo "Gatekeeper (se espera rechazo):"
spctl -a -vv "$APP" 2>&1 || true
echo "Artefacto: $DMG"
