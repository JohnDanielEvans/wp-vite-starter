#!/bin/bash

# Move an existing WordPress theme into this harness.
#
# Usage: npm run theme:adopt -- path/to/existing-theme [--force]
#
# What this does deterministically:
#   - replaces src/ with the theme
#   - puts the Vite bridge back (functions/vite-config.php, functions/variables.php)
#   - wires those into the theme's functions.php
#   - creates the Vite entry points if the theme has none
#   - points THEME_SLUG at the theme's own directory name
#
# What it deliberately leaves to you is printed at the end. Emitting the script
# tags means finding the right place in an unknown footer template, and removing
# the theme's existing wp_enqueue_* calls means deciding which of them the build
# now replaces. Both are judgement calls, and a script that guesses produces a
# theme that loads its assets twice or not at all.

set -euo pipefail

SRC=""
FORCE=0

while [ $# -gt 0 ]; do
    case "$1" in
        --force) FORCE=1; shift ;;
        -h|--help) sed -n '3,6p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) SRC="$1"; shift ;;
    esac
done

if [ -z "$SRC" ]; then
    echo "✖ No theme path given."
    echo "  Usage: npm run theme:adopt -- path/to/existing-theme"
    exit 1
fi

SRC="${SRC%/}"

if [ ! -d "$SRC" ]; then
    echo "✖ No such directory: $SRC"
    exit 1
fi

if [ ! -f "$SRC/style.css" ]; then
    echo "✖ $SRC has no style.css, so it is not a WordPress theme."
    exit 1
fi

if ! grep -qi "Theme Name:" "$SRC/style.css"; then
    echo "✖ $SRC/style.css has no 'Theme Name:' header."
    exit 1
fi

# This replaces src/ wholesale. Git is the undo button, so insist on a clean
# tree rather than inventing a backup directory nobody will remember to delete.
if [ "$FORCE" -eq 0 ] && [ -n "$(git status --porcelain src 2>/dev/null)" ]; then
    echo "✖ src/ has uncommitted changes. Commit or stash them first, or pass --force."
    exit 1
fi

THEME_NAME=$(grep -i "Theme Name:" "$SRC/style.css" | head -1 | sed -E 's/.*[Tt]heme [Nn]ame:[[:space:]]*//' | tr -d '\r')
NEW_SLUG=$(basename "$SRC")

echo "▸ Adopting \"$THEME_NAME\" from $SRC"

# Keep the bridge: read it out of git rather than copying from the working tree,
# so this still works if a previous run already replaced src/.
STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT
for f in functions/vite-config.php functions/variables.php; do
    if [ -f "src/$f" ]; then
        mkdir -p "$STAGE/$(dirname "$f")"
        cp "src/$f" "$STAGE/$f"
    elif git cat-file -e "HEAD:src/$f" 2>/dev/null; then
        mkdir -p "$STAGE/$(dirname "$f")"
        git show "HEAD:src/$f" > "$STAGE/$f"
    else
        echo "✖ Cannot find src/$f in the working tree or in git — nothing to adopt into."
        exit 1
    fi
done

echo "▸ Replacing src/ with the theme..."
# Empty the directory instead of removing it. wp-env bind-mounts ./src into the
# container, and a bind mount follows the inode: `rm -rf src` leaves the
# container pointing at the deleted directory, so the theme shows up empty and
# unactivatable until wp-env is restarted. Clearing the contents keeps the
# existing mount valid.
mkdir -p src
find src -mindepth 1 -delete
cp -R "$SRC/." src/
# A theme copied from a live server often carries its own VCS metadata and OS junk.
rm -rf src/.git src/.github src/node_modules
find src -name '.DS_Store' -delete 2>/dev/null || true

echo "▸ Restoring the Vite bridge..."
mkdir -p src/functions
cp "$STAGE/functions/vite-config.php" src/functions/vite-config.php
cp "$STAGE/functions/variables.php" src/functions/variables.php

# -------------------------------------------------------------- functions.php
if [ ! -f src/functions.php ]; then
    printf '<?php\n' > src/functions.php
fi

if grep -q "wp-vite-starter:bridge" src/functions.php; then
    echo "  functions.php already wired — leaving it alone."
else
    echo "▸ Wiring the bridge into functions.php..."
    # variables.php must load first: it defines IS_TYPE, which vite-config.php
    # and the footer tags both branch on.
    BRIDGE=$(cat <<'PHP'

// wp-vite-starter:bridge — defines IS_TYPE and the wpvs_vite_src_* helpers.
// variables.php must come first; vite-config.php reads IS_TYPE.
require_once get_theme_file_path("./functions/variables.php");
require_once get_theme_file_path("./functions/vite-config.php");
PHP
)
    # Insert immediately after the opening tag so the constants exist before
    # anything else in the file can reference them. Done with head/tail rather
    # than awk -v, which cannot carry a multi-line value.
    if [ "$(head -1 src/functions.php | tr -d '\r')" = "<?php" ]; then
        TMP=$(mktemp)
        {
            head -1 src/functions.php
            printf '%s\n' "$BRIDGE"
            tail -n +2 src/functions.php
        } > "$TMP"
        mv "$TMP" src/functions.php
        # mktemp creates 0600 and mv preserves it, which leaves functions.php
        # unreadable by the web server: WordPress then reports the whole theme
        # directory as "not readable" and serves a blank page with no fatal.
        chmod 644 src/functions.php
    else
        echo "  ⚠ functions.php does not open with a bare <?php on line 1."
        echo "    Add these lines near the top yourself:"
        printf '%s\n' "$BRIDGE"
    fi
fi

# ------------------------------------------------------------- entry points
if [ ! -f src/assets/app.js ]; then
    echo "▸ Creating the Vite entry point (src/assets/app.js)..."
    mkdir -p src/assets/css
    cat > src/assets/app.js <<'JS'
// Vite entry point. Registered in vite.config.mjs as `app` and emitted by
// parts/global-footer.php (or wherever your theme prints its footer scripts).
import "./css/app.scss";
JS
    if [ ! -f src/assets/css/app.scss ]; then
        cat > src/assets/css/app.scss <<'SCSS'
// Imported by src/assets/app.js and built to assets/css/app.css.
// Point this at your theme's existing stylesheets, or paste them in.
SCSS
    fi
else
    echo "  src/assets/app.js already exists — leaving it alone."
fi

# ---------------------------------------------------------------- theme slug
if [ -f scripts/theme-slug.sh ]; then
    echo "▸ Setting THEME_SLUG to \"$NEW_SLUG\"..."
    # perl -pi rather than sed -i: GNU sed wants `-i`, BSD sed wants `-i ''`,
    # and this repo is developed on macOS but also runs on Linux CI.
    NEW_SLUG="$NEW_SLUG" perl -pi -e 's|^: "\$\{THEME_SLUG:=.*\}"|: "\$\{THEME_SLUG:=$ENV{NEW_SLUG}\}"|' scripts/theme-slug.sh
fi

# ------------------------------------------------------------ permissions
# A theme pulled off a server or out of a zip often arrives with modes the local
# web server cannot read. One unreadable file is enough for WordPress to skip the
# whole theme directory, and it does so with a notice rather than an error, so
# the symptom is a blank page with nothing in the log to explain it.
chmod -R a+rX src

# ------------------------------------------------------------------- report
# Exclude the bridge files we just installed; vite-config.php mentions enqueues
# in passing and reporting it back as "the theme's own" is just noise.
EXISTING_ENQUEUE=$(grep -rln "wp_enqueue_style\|wp_enqueue_script" src --include='*.php' 2>/dev/null \
    | grep -vE '^src/functions/(vite-config|variables)\.php$' | head -5 || true)
FOOTER=$(ls src/footer.php src/parts/global-footer.php 2>/dev/null | head -1 || true)

cat <<EOF

✓ "$THEME_NAME" adopted into src/

Still to do by hand — these need a judgement call about your templates:

  1. Emit the built assets. In ${FOOTER:-your footer template}, replace the
     theme's own script/style tags with:

       <?php if (defined("IS_TYPE") && IS_TYPE === "local"): ?>
         <script type="module" src="http://localhost:3030/@vite/client"></script>
         <script type="module" src="http://localhost:3030/src/assets/app.js"></script>
       <?php else: ?>
         <script type="module" src="<?= wpvs_vite_src_js("app.js") ?>" defer></script>
       <?php endif; ?>

     and for the stylesheet, <?= wpvs_vite_src_css("app.css") ?>.
EOF

if [ -n "$EXISTING_ENQUEUE" ]; then
    cat <<EOF

  2. Remove the enqueues the build now replaces. These files still call
     wp_enqueue_style/script — keep the ones for fonts or third-party CDNs,
     drop the ones pointing at this theme's own CSS and JS:
EOF
    for f in $EXISTING_ENQUEUE; do echo "       - $f"; done
fi

cat <<EOF

  3. Move the theme's CSS and JS under src/assets/ and import them from
     src/assets/app.js, so Vite compiles and fingerprints them.

  4. On your servers, set WP_ENVIRONMENT_TYPE in wp-config.php ("production"
     or "staging"). Locally .wp-env.json already sets it to "local".

Then: npm run wp:start && npm run dev
EOF
