#!/bin/bash

# Assemble the deployable theme folder from dist/ + src/
# Usage: npm run copy-theme   (called by npm run build:prod)

set -e

source "$(dirname "$0")/theme-slug.sh"
OUT="deploy/$THEME_SLUG"

mkdir -p "$OUT"
cp -r dist/* "$OUT"/
cp -r src/*.php src/parts src/functions "$OUT"/
cp src/style.css "$OUT"/
cp src/screenshot.png "$OUT"/ 2>/dev/null || true
cp src/.htaccess "$OUT"/ 2>/dev/null || true
chmod -R 755 "$OUT"

echo "✓ Theme assembled at $OUT"
