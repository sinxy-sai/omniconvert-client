#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

host="$(uname -s)"
case "$host" in
  Linux) default_target=linux ;;
  Darwin) default_target=macos ;;
  *) echo "Use verify_platforms.ps1 on Windows." >&2; exit 2 ;;
esac

target="${1:-$default_target}"
skip_checks="${2:-}"

case "$target" in
  linux|android|web)
    [[ "$host" == Linux ]] || { echo "$target builds run on Linux CI." >&2; exit 2; }
    ;;
  macos|ios-check)
    [[ "$host" == Darwin ]] || { echo "$target builds run on macOS CI." >&2; exit 2; }
    ;;
  *) echo "Unknown target: $target" >&2; exit 2 ;;
esac

if [[ "$skip_checks" != --skip-checks ]]; then
  cargo build --manifest-path rust/Cargo.toml
  flutter analyze
  flutter test
  cargo test --manifest-path rust/Cargo.toml
fi

case "$target" in
  linux) flutter build linux --debug ;;
  android) flutter build apk --debug ;;
  web) flutter build web --release --base-href /app/ ;;
  macos) flutter build macos --debug ;;
  ios-check) flutter build ios --debug --no-codesign ;;
esac

echo "OmniConvert $target verification passed."
