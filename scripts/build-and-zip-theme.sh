#!/bin/bash

# Build and zip theme for deployment
# Usage: npm run deploy   (or THEME_SLUG=my-theme npm run deploy)

set -e

source "$(dirname "$0")/theme-slug.sh"

echo "🔨 Building $THEME_SLUG for production..."

# Clean previous deploy folder
rm -rf deploy "$THEME_SLUG.zip"

# build:prod, not build. `build` stops after vite + press:images, skipping
# generate-version, so the packaged theme shipped without a version.json at all:
# wpvs_get_theme_version() then fell back to "1.0.0" forever and the ?ver= query
# never changed, so browsers kept serving stale CSS and JS after every release.
# build:prod also runs copy-theme, which assembles deploy/$THEME_SLUG and folds
# public/static into assets/images.
npm run build:prod

# Create zip file for upload
echo "🗜️ Creating zip file..."
(cd deploy && zip -rq "../$THEME_SLUG.zip" "$THEME_SLUG")

echo "✅ Build complete!"
echo "📁 Theme folder: deploy/$THEME_SLUG/"
echo "📦 Zip file: $THEME_SLUG.zip"
echo ""
echo "Upload $THEME_SLUG.zip to WordPress, or copy deploy/$THEME_SLUG/ to wp-content/themes/"
