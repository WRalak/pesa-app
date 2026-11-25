#!/usr/bin/env bash
# Downloads Satoshi (Indian Type Foundry, ITF Free Font License) from Fontshare
# for self-hosting in the mobile app and admin console. Review the licence at
# https://www.fontshare.com/fonts/satoshi before distribution.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
curl -fsSL "https://api.fontshare.com/v2/fonts/download/satoshi" -o "$TMP/satoshi.zip"
unzip -q "$TMP/satoshi.zip" -d "$TMP"
mkdir -p "$ROOT/mobile/assets/fonts" "$ROOT/admin/public/fonts"
for w in Regular Medium Bold Black; do
  find "$TMP" -name "Satoshi-$w.otf" -exec cp {} "$ROOT/mobile/assets/fonts/" \;
done
find "$TMP" -name "Satoshi-Variable.woff2" -exec cp {} "$ROOT/admin/public/fonts/" \;
rm -rf "$TMP"
echo "Fonts installed. Uncomment the 'fonts:' block in mobile/pubspec.yaml."
