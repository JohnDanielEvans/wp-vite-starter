#!/bin/bash

# One command to get working: npm start
#
# Starts WordPress if it is not already up, then runs the Vite dev server.
# Everything here is a check that turns a confusing failure into a sentence that
# says what to do — wp-env's own errors for a stopped Docker daemon or a taken
# port are accurate but not actionable.

set -uo pipefail

# Both ports come from scripts/ports.mjs (.env, environment, then defaults), so
# this agrees with Vite and wp-env instead of guessing.
eval "$(node -e "
import('./scripts/ports.mjs').then(p => {
  console.log('WP_PORT=' + p.WP_PORT);
  console.log('VITE_PORT=' + p.VITE_PORT);
}).catch(e => { console.error(e.message); process.exit(1); });
")" || { echo "✖ Could not read port configuration (check .env)."; exit 1; }

port_in_use() {
    node -e "
const net=require('net');
const s=net.createConnection({port:$1,host:'127.0.0.1'});
s.on('connect',()=>{s.destroy();process.exit(0);});
s.on('error',()=>process.exit(1));
setTimeout(()=>process.exit(1),1500);
" 2>/dev/null
}

# ------------------------------------------------------------------- docker
if ! docker info > /dev/null 2>&1; then
    echo "✖ Docker is not running — WordPress runs in a container, so it is required."
    case "$(uname -s)" in
        Darwin) echo "  Start Docker Desktop (or: open -a Docker), wait for it to settle, then re-run." ;;
        *)      echo "  Start the Docker daemon, then re-run." ;;
    esac
    exit 1
fi

# -------------------------------------------------------------------- ports
# Vite uses strictPort, so a busy 3030 is a hard failure rather than a fallback.
if port_in_use "$VITE_PORT"; then
    echo "✖ Port $VITE_PORT is already in use, and Vite is configured with strictPort."
    echo "  Usually another copy of \`npm run dev\` is still running. Stop it, or set"
    echo "  VITE_PORT in .env (see .env.example) to run this project alongside it."
    exit 1
fi

# ---------------------------------------------------------------- wordpress
if port_in_use "$WP_PORT"; then
    echo "▸ WordPress already up on http://localhost:$WP_PORT"
else
    # Keep .wp-env.override.json in step with .env before wp-env reads it.
    node scripts/sync-wp-env.mjs || {
        echo "✖ Could not write .wp-env.override.json"
        exit 1
    }

    echo "▸ Starting WordPress (first run pulls images — a few minutes)..."
    if ! npx --no-install wp-env start; then
        echo ""
        echo "✖ wp-env could not start."
        echo "  If it reports a port conflict, another project is on $WP_PORT — set"
        echo "  WP_PORT in .env. If it reports a missing image, check your network"
        echo "  and re-run."
        exit 1
    fi
fi

echo ""
echo "  WordPress   http://localhost:$WP_PORT  (admin / password)"
echo "  Dev server  http://localhost:$VITE_PORT   ← open this one"
echo ""

# Delegate rather than repeat `vite --host` and its env, so there is one
# definition of what "dev" means.
exec npm run dev
