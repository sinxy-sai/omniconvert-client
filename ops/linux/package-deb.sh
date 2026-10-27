#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:?version required}"
BUNDLE="${2:-build/linux/x64/release/bundle}"
OUT="${3:-OmniConvert-${VERSION}-linux-x64.deb}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

[[ -d "$BUNDLE" ]] || { echo "Linux bundle not found: $BUNDLE" >&2; exit 1; }
[[ -x "$BUNDLE/omniconvert" ]] || { echo "Linux executable not found" >&2; exit 1; }
PKG="$(mktemp -d)"
trap 'rm -rf "$PKG"' EXIT
mkdir -p "$PKG/opt/omniconvert" "$PKG/usr/bin" "$PKG/usr/share/applications" "$PKG/usr/share/icons/hicolor/256x256/apps" "$PKG/DEBIAN"
cp -a "$BUNDLE/." "$PKG/opt/omniconvert/"
ln -s /opt/omniconvert/omniconvert "$PKG/usr/bin/omniconvert"
cat > "$PKG/usr/share/applications/omniconvert.desktop" <<'DESKTOP'
[Desktop Entry]
Name=OmniConvert
Comment=Local-first file and formula tools
Exec=omniconvert
Icon=omniconvert
Terminal=false
Type=Application
Categories=Utility;Office;
DESKTOP
if [[ -f "$ROOT/assets/omniconvert.png" ]]; then cp "$ROOT/assets/omniconvert.png" "$PKG/usr/share/icons/hicolor/256x256/apps/omniconvert.png"; fi
cat > "$PKG/DEBIAN/control" <<CONTROL
Package: omniconvert
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: amd64
Maintainer: OmniConvert contributors <opensource@sinxysai.site>
Description: Local-first file and formula tools
CONTROL
dpkg-deb --build --root-owner-group "$PKG" "$OUT" >/dev/null
[[ -s "$OUT" ]] || { echo "DEB was not created: $OUT" >&2; exit 1; }
echo "$OUT"
