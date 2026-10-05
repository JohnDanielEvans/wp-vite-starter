#!/bin/bash

# Remove wp-env environments whose project directory no longer exists.
#
# Usage: npm run wp:prune           # show what would be removed
#        npm run wp:prune -- --yes  # actually remove it
#
# wp-env derives its working directory from md5(path/to/.wp-env.json) — the
# config file's PATH, not its contents. Editing .wp-env.json costs nothing, but
# every clone, worktree or moved directory gets its own environment, each with a
# WordPress install and a database volume (typically 300-550MB).
#
# The catch is that `wp-env destroy` resolves that directory from the current
# path too. Once a checkout is moved or deleted, wp-env can no longer find the
# environment it created, so it is stranded rather than cleaned up — invisible
# unless you go looking in ~/.wp-env.
#
# This finds the stranded ones by reading each environment's generated
# docker-compose.yml, recovering the host project path from its bind mounts, and
# checking whether that directory still exists.

set -euo pipefail

ASSUME_YES=0
for arg in "$@"; do
    case "$arg" in
        -y|--yes) ASSUME_YES=1 ;;
        -h|--help) sed -n '3,7p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "✖ Unknown option: $arg"; exit 1 ;;
    esac
done

WP_ENV_HOME="${WP_ENV_HOME:-$HOME/.wp-env}"

if [ ! -d "$WP_ENV_HOME" ]; then
    echo "No wp-env directory at $WP_ENV_HOME — nothing to prune."
    exit 0
fi

STALE=()
KEPT=0
UNKNOWN=0

for dir in "$WP_ENV_HOME"/*/; do
    [ -d "$dir" ] || continue
    name=$(basename "$dir")
    compose="$dir/docker-compose.yml"

    if [ ! -f "$compose" ]; then
        UNKNOWN=$((UNKNOWN + 1))
        continue
    fi

    # Only the host side of a bind mount into the WordPress root identifies the
    # project. Matching bare paths instead is wrong: wp-env also writes
    # `user-home:/home/<you>`, a NAMED volume whose container path looks exactly
    # like a host home directory, and treating that as the project would mark a
    # live environment stale and delete it.
    #
    # Paths under ~/.wp-env are wp-env's own WordPress copies, not the project.
    # `|| true` because an environment with no project mappings filters down to
    # nothing, grep exits 1, and under `set -euo pipefail` that would kill the
    # whole run silently rather than skipping one directory.
    project=$(grep -ohE '(/[A-Za-z0-9._/ -]+):/var/www/html' "$compose" 2>/dev/null \
        | sed -E 's#:/var/www/html$##' \
        | grep -v "^$WP_ENV_HOME" \
        | sed -E 's#/(plugins|themes|uploads|sql|src)$##' \
        | sort -u | head -1 || true)

    if [ -z "$project" ]; then
        UNKNOWN=$((UNKNOWN + 1))
        continue
    fi

    if [ -d "$project" ]; then
        KEPT=$((KEPT + 1))
    else
        STALE+=("$name|$project")
    fi
done

if [ "${#STALE[@]}" -eq 0 ]; then
    echo "✓ Nothing stranded. $KEPT environment(s) still have their project directory."
    [ "$UNKNOWN" -gt 0 ] && echo "  ($UNKNOWN skipped — no recoverable project path.)"
    exit 0
fi

echo "Stranded wp-env environments — their project directory is gone:"
echo ""
TOTAL_K=0
for entry in "${STALE[@]}"; do
    name="${entry%%|*}"
    project="${entry##*|}"
    size=$(du -sh "$WP_ENV_HOME/$name" 2>/dev/null | cut -f1)
    size_k=$(du -sk "$WP_ENV_HOME/$name" 2>/dev/null | cut -f1)
    TOTAL_K=$((TOTAL_K + ${size_k:-0}))
    printf "  %-44s %-6s was: %s\n" "$name" "$size" "$project"
    # Volume names are the compose project name plus the volume, and the compose
    # project name is the directory name.
    docker volume ls --format '{{.Name}}' 2>/dev/null | grep "^${name}_" | sed 's/^/      volume: /' || true
done
echo ""
printf "Reclaimable: ~%s MB across %d environment(s).\n" "$((TOTAL_K / 1024))" "${#STALE[@]}"

if [ "$ASSUME_YES" -eq 0 ]; then
    echo ""
    echo "Nothing removed. Re-run with --yes to delete them:"
    echo "  npm run wp:prune -- --yes"
    exit 0
fi

echo ""
for entry in "${STALE[@]}"; do
    name="${entry%%|*}"
    for vol in $(docker volume ls --format '{{.Name}}' 2>/dev/null | grep "^${name}_" || true); do
        if docker volume rm "$vol" > /dev/null 2>&1; then
            echo "  removed volume $vol"
        else
            echo "  ⚠ could not remove volume $vol (still in use?)"
        fi
    done
    rm -rf "${WP_ENV_HOME:?}/$name"
    echo "  removed $name"
done

echo ""
echo "✓ Pruned ${#STALE[@]} environment(s)."
