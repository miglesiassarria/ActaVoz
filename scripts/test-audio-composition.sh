#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
mkdir -p "$root/build/modulecache" "$root/build/audio-composition-test"
xcrun swiftc -parse-as-library -module-cache-path "$root/build/modulecache"   "$root"/ActaVoz/ActaVozCore/Sources/ActaVozCore/*.swift   "$root/ActaVoz/ActaVoz/CoreAudioSystemTap.swift"   "$root/ActaVoz/ActaVoz/SystemCaptureDriver.swift"   "$root/scripts/test-audio-composition.swift" -o "$root/build/audio-composition-test/runner"
"$root/build/audio-composition-test/runner" "$root/build/audio-composition-test/output"
