#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:?version required}"
BUNDLE="${2:-build/linux/x64/release/bundle}"
OUT="${3:-OmniConvert-${VERSION}-linux-x64.AppImage}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

[[ -d "$BUNDLE" ]] || { echo "Linux bundle not found: $BUNDLE" >&2; exit 1; }
BIN="$BUNDLE/omniconvert"
[[ -x "$BIN" ]] || { echo "Linux executable not found: $BIN" >&2; exit 1; }

APPDIR="$(mktemp -d)"
trap 'rm -rf "$APPDIR"' EXIT
mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/share/applications" "$APPDIR/usr/share/icons/hicolor/256x256/apps"
cp -a "$BUNDLE/." "$APPDIR/usr/bin/"
cat > "$APPDIR/omniconvert.desktop" <<'DESKTOP'
[Desktop Entry]
Name=OmniConvert
Comment=Local-first file and formula tools
Exec=omniconvert
Icon=omniconvert
Type=Application
Categories=Utility;Office;
DESKTOP
cp "$APPDIR/omniconvert.desktop" "$APPDIR/usr/share/applications/omniconvert.desktop"
if [[ -f "$ROOT/assets/omniconvert.png" ]]; then
  cp "$ROOT/assets/omniconvert.png" "$APPDIR/omniconvert.png"
  cp "$ROOT/assets/omniconvert.png" "$APPDIR/usr/share/icons/hicolor/256x256/apps/omniconvert.png"
else
  sed -i '/^Icon=/d' "$APPDIR/omniconvert.desktop"
fi
cat > "$APPDIR/AppRun" <<'RUNNER'
#!/usr/bin/env sh
HERE="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
exec "$HERE/usr/bin/omniconvert" "$@"
RUNNER
chmod +x "$APPDIR/AppRun"

APPIMAGE_TOOL="${APPIMAGETOOL:-$(command -v appimagetool || true)}"
if [[ -z "$APPIMAGE_TOOL" || ! -x "$APPIMAGE_TOOL" ]]; then
  echo "appimagetool is required (install it on the runner)" >&2
  exit 1
fi
"$APPIMAGE_TOOL" "$APPDIR" "$OUT"
chmod +x "$OUT"
[[ -s "$OUT" ]] || { echo "AppImage was not created: $OUT" >&2; exit 1; }
echo "$OUT"
