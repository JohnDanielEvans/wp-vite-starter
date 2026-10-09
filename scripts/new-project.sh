#!/bin/bash

# Rename this starter for a new project, and optionally strip the demo content.
#
# Usage: npm run init
#        npm run init -- --name "Acme Corp" --slug acme-corp --author "You" --strip-demo --yes
#
# The rename touches four places that all have to agree, because everything that
# packages or deploys the theme reads THEME_SLUG: src/style.css, theme-slug.sh,
# both workflows, and package.json. Doing it by hand is where the mismatches
# come from.

set -euo pipefail

NAME=""
SLUG=""
AUTHOR=""
DESCRIPTION=""
STRIP="ask"
ASSUME_YES=0

while [ $# -gt 0 ]; do
    case "$1" in
        --name)        NAME="${2:-}"; shift 2 ;;
        --slug)        SLUG="${2:-}"; shift 2 ;;
        --author)      AUTHOR="${2:-}"; shift 2 ;;
        --description) DESCRIPTION="${2:-}"; shift 2 ;;
        --strip-demo)  STRIP="yes"; shift ;;
        --keep-demo)   STRIP="no"; shift ;;
        -y|--yes)      ASSUME_YES=1; shift ;;
        -h|--help)     sed -n '3,7p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "✖ Unknown option: $1"; exit 1 ;;
    esac
done

slugify() {
    printf '%s' "$1" \
        | tr '[:upper:]' '[:lower:]' \
        | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'
}

ask() {
    # $1 prompt, $2 default
    local reply
    if [ "$ASSUME_YES" -eq 1 ]; then
        printf '%s' "$2"
        return
    fi
    read -r -p "$1 [$2]: " reply < /dev/tty || reply=""
    printf '%s' "${reply:-$2}"
}

confirm() {
    # $1 prompt, $2 default (y/n)
    local reply
    if [ "$ASSUME_YES" -eq 1 ]; then
        [ "$2" = "y" ]
        return
    fi
    read -r -p "$1 [$( [ "$2" = y ] && echo 'Y/n' || echo 'y/N' )]: " reply < /dev/tty || reply=""
    reply="${reply:-$2}"
    case "$reply" in [Yy]*) return 0 ;; *) return 1 ;; esac
}

if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    if [ "$ASSUME_YES" -eq 1 ]; then
        # Non-interactive runs get a hard stop rather than a prompt that would
        # silently answer itself: this rewrites tracked files and deletes others,
        # and git is the only way back.
        echo "✖ Working tree has uncommitted changes, and --yes cannot confirm this."
        echo "  Commit or stash first, then re-run."
        exit 1
    fi
    echo "⚠ Working tree has uncommitted changes. This rewrites tracked files and"
    echo "  deletes others; committing first means git can undo it."
    confirm "Continue anyway?" "n" || exit 1
fi

echo ""
echo "Setting up a new project from wp-vite-starter."
echo ""

[ -z "$NAME" ] && NAME=$(ask "Theme name" "My Theme")
[ -z "$SLUG" ] && SLUG=$(ask "Theme slug (directory name on the server)" "$(slugify "$NAME")")
SLUG=$(slugify "$SLUG")
[ -z "$AUTHOR" ] && AUTHOR=$(ask "Author" "$(git config user.name 2>/dev/null || echo 'Your Name')")
[ -z "$DESCRIPTION" ] && DESCRIPTION=$(ask "Description" "A WordPress theme built with wp-env and Vite.")

if [ -z "$SLUG" ]; then
    echo "✖ Slug came out empty — give one with --slug."
    exit 1
fi

echo ""
echo "  Name:        $NAME"
echo "  Slug:        $SLUG"
echo "  Author:      $AUTHOR"
echo ""

if [ "$STRIP" = "ask" ]; then
    echo "The starter ships a 'works' portfolio demo: its post type, archive and"
    echo "single templates, the privacy page, and the AJAX load-more example."
    if confirm "Remove the demo content?" "y"; then STRIP="yes"; else STRIP="no"; fi
fi

# ----------------------------------------------------------------- style.css
echo "▸ Rewriting src/style.css..."
cat > src/style.css <<EOF
/*
Theme Name: $NAME
Author: $AUTHOR
Description: $DESCRIPTION
Version: 1.0.0
Requires at least: 6.0
Tested up to: 6.8
Requires PHP: 8.1
License: MIT
License URI: https://opensource.org/licenses/MIT
Text Domain: $SLUG
*/
EOF

# ---------------------------------------------------------------- theme slug
echo "▸ Setting THEME_SLUG to \"$SLUG\"..."
SLUG="$SLUG" perl -pi -e 's|^: "\$\{THEME_SLUG:=.*\}"|: "\$\{THEME_SLUG:=$ENV{SLUG}\}"|' scripts/theme-slug.sh

echo "▸ Updating the deploy workflows..."
for wf in .github/workflows/deploy-production.yml .github/workflows/deploy-staging.yml; do
    [ -f "$wf" ] || continue
    SLUG="$SLUG" perl -pi -e 's|^(\s*THEME_SLUG:\s*).*$|$1$ENV{SLUG}|' "$wf"
done

# --------------------------------------------------------------- package.json
echo "▸ Updating package.json..."
NAME="$NAME" SLUG="$SLUG" AUTHOR="$AUTHOR" DESCRIPTION="$DESCRIPTION" node <<'NODE'
const fs = require("fs");
const p = JSON.parse(fs.readFileSync("package.json", "utf8"));
p.name = process.env.SLUG;
p.description = process.env.DESCRIPTION;
p.author = process.env.AUTHOR;
p.version = "1.0.0";
// These point at the starter's own repository. Leaving them in means a new
// project files its issues against the starter.
delete p.repository;
delete p.bugs;
delete p.homepage;
p.keywords = ["wordpress", "wordpress-theme", "vite"];
fs.writeFileSync("package.json", JSON.stringify(p, null, 2) + "\n");
NODE

# ------------------------------------------------------------ demo stripping
if [ "$STRIP" = "yes" ]; then
    echo "▸ Removing the demo content..."

    rm -f \
        src/archive-works.php \
        src/single-works.php \
        src/taxonomy-works-category.php \
        src/page-privacy.php \
        src/parts/card-archive.php \
        src/parts/contents-archive.php \
        src/parts/label-category.php \
        src/functions/post-types.php \
        src/functions/ajax.php \
        src/assets/js/modules/load-more.js \
        src/assets/css/parts/_card-archive.scss \
        src/assets/css/parts/_label-category.scss
    rm -rf \
        src/assets/css/pages/archive-works \
        src/assets/css/pages/page-privacy

    # Each removal above leaves a reference behind. Miss one and the theme
    # fatals on a missing require, or the build fails on a missing @forward.
    echo "  Rewiring functions.php, app.js and the SCSS indexes..."

    perl -ni -e 'print unless m{functions/(post-types|ajax)\.php}' src/functions.php
    perl -ni -e 'print unless m{modules/load-more|^\s*loadMore\(\);}' src/assets/js/app.js
    perl -ni -e 'print unless m{^\@forward "(card-archive|label-archive|label-category)"}' src/assets/css/parts/_index.scss
    perl -ni -e 'print unless m{^\@forward "(archive-works|page-privacy)/index"}' src/assets/css/pages/_index.scss

    # pages/_index.scss is now empty, and an empty partial that app.scss still
    # @use-s is fine, but leaving it blank invites someone to delete it and
    # break the import. Say what it is for.
    if [ ! -s src/assets/css/pages/_index.scss ]; then
        cat > src/assets/css/pages/_index.scss <<'SCSS'
// Page-level styles. Add one directory per template and @forward it here:
//   @forward "about/index";
SCSS
    fi
fi

# ------------------------------------------------------------------- README
if confirm "Replace README.md with a short project README?" "y"; then
    echo "▸ Writing a project README..."
    cat > README.md <<EOF
# $NAME

$DESCRIPTION

## Getting started

Requires Node 20.11+ and Docker.

\`\`\`bash
npm install
npm run wp:start
npm run dev
\`\`\`

- Site: http://localhost:3030
- WordPress admin: http://localhost:8000/wp-admin (\`admin\` / \`password\`)

The theme runs from \`src/\`, so edits are live. Stop with \`npm run wp:destroy\`.

## Commands

| Command | What it does |
| --- | --- |
| \`npm run dev\` | Vite dev server with hot reload |
| \`npm run build:prod\` | Production build into \`deploy/\` |
| \`npm run deploy\` | Production build plus an installable zip |
| \`npm run lint:check\` | Lint markup, styles and scripts |
| \`npm run db:export\` / \`db:import\` | Save and restore the local database |

## Deploying

Pushing to \`staging\` or \`prod-live\` builds and rsyncs the theme over SSH.
Set the repository secrets listed in \`.github/workflows/\` first.

Built on [wp-vite-starter](https://github.com/JohnDanielEvans/wp-vite-starter).
EOF
fi

# ---------------------------------------------------------------- git history
if confirm "Reset git history and start a fresh initial commit?" "n"; then
    echo "▸ Resetting git history..."
    rm -rf .git
    git init -q
    git add -A
    git commit -qm "Initial commit: $NAME"
    echo "  New repository with one commit. Add your remote with:"
    echo "    git remote add origin <url>"
fi

echo ""
echo "✓ \"$NAME\" is set up."

if [ "$STRIP" = "yes" ]; then
    echo ""
    echo "Demo content removed. What is left: the header/footer/hamburger partials,"
    echo "the picture and heading partials, the pagination helper, and index.php."
fi

# ------------------------------------------------------------------- launch
# Finishing on "now run these two commands" is a seam: the scaffold already
# knows everything needed to start, so offer to do it. Declining prints the
# command, so nobody is left guessing either way.
#
# Never under --yes, and never when output is not a terminal. Both mean nobody
# is watching, and handing control to a dev server that blocks until
# interrupted would hang a script or a CI job. The other prompts read from
# /dev/tty so they still work when stdin is piped, which also means they fall
# back to their defaults rather than failing — fine for a yes/no about files,
# not for something that never returns.
echo ""
if [ "$ASSUME_YES" -eq 0 ] && [ -t 1 ] && confirm "Start WordPress and the dev server now?" "y"; then
    echo ""
    exec bash "$(dirname "$0")/start.sh"
fi

cat <<EOF

When you're ready:
  npm start

That brings up WordPress, activates the theme and starts the dev server.
EOF
