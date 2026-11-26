#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../.."
echo "ActaVoz · informe de calidad"
sw_vers
system_profiler SPHardwareDataType | grep -E "Chip|Memory" || true
echo "Pruebas:"
(cd ActaVoz/ActaVozCore && DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test 2>&1 | grep -E "Executed [0-9]+ tests" | tail -1)
echo "Identidades:"
security find-identity -v -p codesigning || true
echo "DMG:"
ls -lh build/ActaVoz-0.1.0-dev.dmg 2>/dev/null || echo "no generado"
echo "Gatekeeper:"
spctl -a -vv build/ReleaseDerived/Build/Products/Release/ActaVoz.app 2>&1 || true
echo "Límites: sin Developer ID/notarización; umbrales pendientes de aprobación."
