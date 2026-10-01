#!/bin/bash

# Import an existing WordPress site's database into the local wp-env.
#
# Usage: npm run site:import -- path/to/dump.sql[.gz] [--uploads path/to/uploads]
#
# A raw `wp db import` is not enough for a real production dump. Three things
# have to happen or the local site comes up broken in ways that are tedious to
# diagnose:
#
#   1. Table prefix. wp-env's generated wp-config.php hardcodes $table_prefix =
#      'wp_'. Hosts and security plugins frequently use something else, and a
#      dump with a different prefix imports "successfully" into a site that then
#      shows a fresh install screen, because WordPress is reading tables that do
#      not exist. We rename the tables instead of text-replacing the prefix in
#      the dump: option names and meta keys embed the prefix inside serialized
#      values, where changing the string length without fixing the s:N: counts
#      corrupts the data.
#
#   2. Site URLs. Every absolute URL in the dump points at the live domain, so
#      the local site redirects straight back to production the moment you load
#      it. search-replace walks serialized structures and fixes the lengths.
#
#   3. Users, theme and plugins. The live admin passwords are unknown, the live
#      theme is not in this repo, and the plugin files are not in the dump at
#      all — only the record that they were active.

set -euo pipefail

LOCAL_URL="http://localhost:8000"
DUMP=""
UPLOADS_SRC=""

while [ $# -gt 0 ]; do
    case "$1" in
        --uploads)
            UPLOADS_SRC="${2:-}"
            shift 2
            ;;
        --url)
            LOCAL_URL="${2:-}"
            shift 2
            ;;
        -h|--help)
            sed -n '3,8p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            DUMP="$1"
            shift
            ;;
    esac
done

if [ -z "$DUMP" ]; then
    echo "✖ No dump given."
    echo "  Usage: npm run site:import -- path/to/dump.sql[.gz] [--uploads path/to/uploads]"
    exit 1
fi

if [ ! -f "$DUMP" ]; then
    echo "✖ No such file: $DUMP"
    exit 1
fi

# wp-cli runs inside the wp-env container. Everything it touches has to be a
# path inside that container, which is why the dump is staged into ./sql — the
# one directory .wp-env.json maps in for exactly this purpose.
wp() { npx --no-install wp-env run cli wp "$@" 2>&1 | sed '/^ℹ Starting/d; /^✔ Ran/d; /^$/d'; }
wp_quiet() { npx --no-install wp-env run cli wp "$@" > /dev/null 2>&1; }

echo "▸ Checking the local environment is up..."
if ! wp_quiet core is-installed --skip-plugins --skip-themes; then
    echo "✖ Cannot reach WordPress. Run 'npm run wp:start' first."
    exit 1
fi

# ---------------------------------------------------------------- stage dump
mkdir -p sql
STAGED="sql/.import.sql"
echo "▸ Staging $DUMP..."
case "$DUMP" in
    *.gz) gzip -dc "$DUMP" > "$STAGED" ;;
    *)    cp "$DUMP" "$STAGED" ;;
esac

if grep -qm1 "CREATE TABLE" "$STAGED"; then
    :
else
    echo "✖ $DUMP does not look like a SQL dump (no CREATE TABLE found)."
    rm -f "$STAGED"
    exit 1
fi

# Multisite needs per-site URL rewriting and a wp-config that wp-env does not
# generate. Better to say so than to half-import it.
if grep -qm1 -E "CREATE TABLE \`?[a-zA-Z0-9_]+_blogs\`?" "$STAGED"; then
    echo "⚠ This dump contains a *_blogs table, so it looks like a multisite network."
    echo "  This importer handles single sites only; the import would come up misconfigured."
    rm -f "$STAGED"
    exit 1
fi

# ------------------------------------------------------------ detect prefix
# The options table is the reliable marker: exactly one table ends in "options"
# in a single-site dump, and whatever precedes it is the prefix.
SRC_PREFIX=$(grep -oE "CREATE TABLE \`?[a-zA-Z0-9_]+options\`?" "$STAGED" \
    | head -1 | sed -E 's/CREATE TABLE `?//; s/options`?$//')

if [ -z "$SRC_PREFIX" ]; then
    echo "✖ Could not find an options table in the dump — cannot determine its table prefix."
    rm -f "$STAGED"
    exit 1
fi
echo "  Dump table prefix: ${SRC_PREFIX}"

echo "▸ Importing (this drops the current local database contents)..."
wp db reset --yes
wp db import "$STAGED"
rm -f "$STAGED"

# ------------------------------------------------------------ rename prefix
if [ "$SRC_PREFIX" != "wp_" ]; then
    echo "▸ Renaming tables ${SRC_PREFIX}* → wp_* (wp-env's wp-config expects wp_)..."
    TABLES=$(wp db query "SHOW TABLES LIKE '${SRC_PREFIX}%';" --skip-column-names --silent | tr -d '\r')
    for t in $TABLES; do
        [ -z "$t" ] && continue
        new="wp_${t#"$SRC_PREFIX"}"
        wp_quiet db query "RENAME TABLE \`$t\` TO \`$new\`;"
    done

    # These two keys embed the prefix as a plain column value, not inside a
    # serialized blob, so a straight UPDATE is safe. Miss them and every user
    # loses their roles: WordPress looks up wp_capabilities and finds nothing,
    # leaving even the owner with no permissions.
    echo "  Fixing prefixed option and meta keys..."
    wp_quiet db query "UPDATE wp_options SET option_name = 'wp_user_roles' WHERE option_name = '${SRC_PREFIX}user_roles';"
    wp_quiet db query "UPDATE wp_usermeta SET meta_key = CONCAT('wp_', SUBSTRING(meta_key, ${#SRC_PREFIX} + 1)) WHERE meta_key LIKE '${SRC_PREFIX}%';"
fi

# --------------------------------------------------------------- rewrite URLs
# Read the stored row directly rather than through get_option(). wp-env's
# generated wp-config.php defines WP_SITEURL and WP_HOME, and WordPress filters
# those constants over the option, so `wp option get siteurl` answers
# "http://localhost:8000" no matter what the dump contains. Trusting it means
# old URL == new URL, the replace is skipped as a no-op, and every link in the
# imported content still points at production.
OLD_URL=$(wp db query "SELECT option_value FROM wp_options WHERE option_name = 'siteurl';" --skip-column-names --silent | tr -d '\r' | head -1)
echo "▸ Live URL in the dump: ${OLD_URL:-(none found)}"

if [ -n "$OLD_URL" ] && [ "$OLD_URL" != "$LOCAL_URL" ]; then
    echo "  Rewriting to $LOCAL_URL across all tables..."
    # --all-tables so plugin tables are covered too; --recurse-objects and the
    # default serialization handling are what keep widget/option blobs valid.
    wp search-replace "$OLD_URL" "$LOCAL_URL" --all-tables --recurse-objects --skip-columns=guid --report-changed-only

    # Protocol-relative and bare-host references that the full-URL pass misses.
    OLD_HOST=$(printf '%s' "$OLD_URL" | sed -E 's#^https?://##; s#/$##')
    LOCAL_HOST=$(printf '%s' "$LOCAL_URL" | sed -E 's#^https?://##; s#/$##')
    if [ -n "$OLD_HOST" ] && [ "$OLD_HOST" != "$LOCAL_HOST" ]; then
        wp search-replace "//$OLD_HOST" "//$LOCAL_HOST" --all-tables --recurse-objects --skip-columns=guid --report-changed-only
    fi
fi

# siteurl/home can be overridden by constants on the live site and therefore be
# absent or stale in the dump; set them explicitly rather than trusting the replace.
wp_quiet option update siteurl "$LOCAL_URL"
wp_quiet option update home "$LOCAL_URL"

# ------------------------------------------------------------------ theme
echo "▸ Activating the theme in this repo..."
wp_quiet theme activate src || echo "  ⚠ Could not activate ./src — activate it under Appearance → Themes."

# ------------------------------------------------------------------ plugins
# A dump records which plugins were active but contains none of their code.
echo "▸ Restoring plugins recorded in the database..."
ACTIVE=$(wp option get active_plugins --format=json --skip-plugins --skip-themes 2>/dev/null | tr -d '\r' || echo "[]")
MISSING=""
for entry in $(printf '%s' "$ACTIVE" | tr -d '[]"' | tr ',' ' '); do
    slug="${entry%%/*}"
    [ -z "$slug" ] && continue
    if [ -d "plugins/$slug" ]; then
        continue
    fi
    if wp_quiet plugin install "$slug" --activate; then
        echo "  ✓ $slug"
    else
        MISSING="$MISSING $slug"
    fi
done

# ------------------------------------------------------------------- admin
# The dump's users are the live site's, and nobody knows those passwords. Make
# sure the credentials the README documents actually work.
if ! wp_quiet user get admin; then
    echo "▸ Creating a local admin (admin / password)..."
    wp_quiet user create admin admin@example.com --role=administrator --user_pass=password
else
    wp_quiet user update admin --user_pass=password --role=administrator
    echo "▸ Reset the 'admin' password to 'password' for local use."
fi

# ----------------------------------------------------------------- uploads
if [ -n "$UPLOADS_SRC" ]; then
    if [ -d "$UPLOADS_SRC" ]; then
        echo "▸ Copying uploads from $UPLOADS_SRC..."
        mkdir -p uploads
        rsync -a "${UPLOADS_SRC%/}/" uploads/
    else
        echo "⚠ --uploads path not found: $UPLOADS_SRC"
    fi
fi

wp_quiet rewrite flush --hard
wp_quiet cache flush || true

echo ""
echo "✓ Import complete — $LOCAL_URL"
echo "  Admin: $LOCAL_URL/wp-admin  (admin / password)"
if [ -n "$MISSING" ]; then
    echo ""
    echo "⚠ These plugins were active on the live site but are not on wordpress.org"
    echo "  (premium or custom). Drop each into ./plugins/ and activate it:"
    for m in $MISSING; do echo "    - $m"; done
fi
if [ -z "$UPLOADS_SRC" ]; then
    echo ""
    echo "  Media will 404 until you copy the live wp-content/uploads into ./uploads/,"
    echo "  or re-run with --uploads path/to/uploads."
fi
