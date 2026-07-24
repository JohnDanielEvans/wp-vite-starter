#!/bin/bash

# Build and zip theme for deployment
# Usage: npm run deploy   (or THEME_SLUG=my-theme npm run deploy)

set -e

source "$(dirname "$0")/theme-slug.sh"

echo "🔨 Building $THEME_SLUG for production..."

# Clean previous deploy folder
rm -rf deploy "$THEME_SLUG.zip"

# Run production build with all steps
npm run build

# Assemble the theme folder.
# copy-theme.sh handles placing public/static/ into assets/images/, so there is
# no separate static copy step here.
echo "📦 Packaging theme..."
bash "$(dirname "$0")/copy-theme.sh"

# Create zip file for upload
echo "🗜️ Creating zip file..."
(cd deploy && zip -rq "../$THEME_SLUG.zip" "$THEME_SLUG")

echo "✅ Build complete!"
echo "📁 Theme folder: deploy/$THEME_SLUG/"
echo "📦 Zip file: $THEME_SLUG.zip"
echo ""
echo "Upload $THEME_SLUG.zip to WordPress, or copy deploy/$THEME_SLUG/ to wp-content/themes/"
