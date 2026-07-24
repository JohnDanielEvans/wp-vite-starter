#!/bin/bash
#
# Server-side deploy: build on the server from a git checkout.
#
# This is the alternative to the rsync-from-CI model in .github/workflows/.
# Use it when the server has Node and wp-cli and you would rather it pull and
# build itself — e.g. SpinupWP boxes where the whole site root is a git repo.
#
# Pair it with .github/workflows/deploy-production-ssh.yml.example, which SSHes
# in and runs this script.
#
# Usage on the server:
#   SITE_PATH=/home/spinupwp/sites/example.com/public \
#   THEME_SLUG=my-theme \
#   DEPLOY_BRANCH=prod-live \
#   bash scripts/server-deploy.sh

set -euo pipefail

: "${SITE_PATH:?SITE_PATH must be set (the WordPress document root)}"
: "${THEME_SLUG:=wp-vite-starter}"
: "${DEPLOY_BRANCH:=prod-live}"

echo "🚀 Deploying $THEME_SLUG to $SITE_PATH ($DEPLOY_BRANCH)..."

cd "$SITE_PATH"

# 1. Reset to the deploy branch.
#    `git reset --hard` discards any drift from plugins or editors writing into
#    the checkout. It is destructive by design — never point SITE_PATH at a
#    directory holding uncommitted work.
git fetch origin "$DEPLOY_BRANCH"
git reset --hard "origin/$DEPLOY_BRANCH"

# 2. Install dependencies from the lockfile
npm ci

# 3. Build and package the theme into deploy/$THEME_SLUG
THEME_SLUG="$THEME_SLUG" npm run build:prod

# 4. Publish into wp-content/themes
THEME_DIR="$SITE_PATH/wp-content/themes/$THEME_SLUG"
mkdir -p "$THEME_DIR"
rsync -rl --delete "deploy/$THEME_SLUG/" "$THEME_DIR/"

# 5. Activate and flush
wp theme activate "$THEME_SLUG"
wp rewrite flush --hard

echo "✅ Deployment complete."
