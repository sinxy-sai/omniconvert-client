#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:?version required}"
BUNDLE="${2:-build/macos/Build/Products/Release/OmniConvert.app}"
OUT="${3:-}"

[[ -d "$BUNDLE" ]] || { echo "macOS app bundle not found: $BUNDLE" >&2; exit 1; }
EXEC="$BUNDLE/Contents/MacOS/OmniConvert"
[[ -x "$EXEC" ]] || { echo "app executable not found: $EXEC" >&2; exit 1; }

ARCHS="$(lipo -archs "$EXEC" 2>/dev/null || true)"
if [[ "$ARCHS" == *"arm64"* && "$ARCHS" == *"x86_64"* ]]; then
  ARCH_LABEL="universal"
elif [[ "$ARCHS" == *"arm64"* ]]; then
  ARCH_LABEL="arm64"
elif [[ "$ARCHS" == *"x86_64"* ]]; then
  ARCH_LABEL="x64"
else
  echo "unable to determine macOS architecture: ${ARCHS:-unknown}" >&2
  exit 1
fi
[[ -n "$OUT" ]] || OUT="OmniConvert-${VERSION}-macos-${ARCH_LABEL}.dmg"
if [[ "$ARCH_LABEL" != "universal" && "$OUT" == *"macos-universal"* ]]; then
  echo "refusing universal filename for ${ARCH_LABEL} app" >&2
  exit 1
fi

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
cp -R "$BUNDLE" "$STAGE/OmniConvert.app"
ln -s /Applications "$STAGE/Applications"

RW="$STAGE/OmniConvert-rw.dmg"
hdiutil create -volname "OmniConvert ${VERSION}" -srcfolder "$STAGE" -ov -format UDRW "$RW" >/dev/null
hdiutil convert "$RW" -format UDZO -ov -o "$OUT" >/dev/null
rm -f "$RW"
[[ -f "$OUT" ]] || { echo "DMG was not created: $OUT" >&2; exit 1; }
echo "$OUT"
