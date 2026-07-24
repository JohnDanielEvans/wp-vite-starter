#!/bin/bash

# Assemble the deployable theme folder from dist/ + src/
# Usage: npm run copy-theme   (called by npm run build:prod)

set -e

source "$(dirname "$0")/theme-slug.sh"
OUT="deploy/$THEME_SLUG"

rm -rf "$OUT"
mkdir -p "$OUT"
cp -r dist/* "$OUT"/
cp -r src/*.php src/parts src/functions "$OUT"/
cp src/style.css "$OUT"/
cp src/screenshot.png "$OUT"/ 2>/dev/null || true
cp src/.htaccess "$OUT"/ 2>/dev/null || true

# Vite's publicDir copies public/static/ to dist/static/, but vite_src_static()
# resolves to assets/images/ in a built theme. Without this the favicon and
# touch icon 404 in production. Flatten into assets/images/ and drop the
# duplicate tree so there is one place these live.
if [ -d "$OUT/static" ]; then
    mkdir -p "$OUT/assets/images"
    cp -R "$OUT/static/." "$OUT/assets/images/"
    rm -rf "$OUT/static"
fi

chmod -R 755 "$OUT"

echo "✓ Theme assembled at $OUT"
