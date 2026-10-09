#!/bin/bash

# Runs automatically after `wp-env start`, via lifecycleScripts.afterStart in
# .wp-env.json. Not usually run by hand.
#
# Without this, a fresh environment comes up with WordPress's default theme
# active and this one merely installed, so the first thing anyone sees is the
# wrong site until they find Appearance → Themes. The theme directory is always
# "src" inside the container, because .wp-env.json maps ./src/ and wp-env names
# the mount after it — that stays true after `npm run init` or `theme:adopt`,
# both of which keep the theme in src/.

set -uo pipefail

wp() { npx --no-install wp-env run cli wp "$@" > /dev/null 2>&1; }

# wp-env has just reported success, but the CLI container can still be a moment
# behind. A few quick retries is cheaper than failing the whole start.
for attempt in 1 2 3 4 5; do
    if wp core is-installed --skip-plugins --skip-themes; then
        break
    fi
    [ "$attempt" = "5" ] && {
        echo "⚠ WordPress is not responding yet — activate the theme manually if needed."
        exit 0
    }
    sleep 2
done

if wp theme is-active src; then
    exit 0
fi

if wp theme activate src; then
    # Permalinks are a WordPress setting, not a theme one, so a fresh database
    # starts on plain ?p=123 URLs and any custom post type 404s.
    wp rewrite flush --hard
    echo "✓ Activated the theme in ./src and flushed permalinks"
else
    echo "⚠ Could not activate the theme — do it under Appearance → Themes."
fi

# Never fail the start: a hook that aborts `wp-env start` over a cosmetic step
# would be worse than the problem it solves.
exit 0
