#!/bin/bash

# One command to get working: npm start
#
# Starts WordPress if it is not already up, then runs the Vite dev server.
# Everything here is a check that turns a confusing failure into a sentence that
# says what to do — wp-env's own errors for a stopped Docker daemon or a taken
# port are accurate but not actionable.

set -uo pipefail

WP_PORT=$(node -p "require('./.wp-env.json').port || 8000" 2>/dev/null || echo 8000)
VITE_PORT=3030

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
    echo "  Usually another copy of \`npm run dev\` is still running. Stop it, or change"
    echo "  server.port in vite.config.mjs."
    exit 1
fi

# ---------------------------------------------------------------- wordpress
if port_in_use "$WP_PORT"; then
    echo "▸ WordPress already up on http://localhost:$WP_PORT"
else
    echo "▸ Starting WordPress (first run pulls images — a few minutes)..."
    if ! npx --no-install wp-env start; then
        echo ""
        echo "✖ wp-env could not start."
        echo "  If it reports a port conflict, another project is on $WP_PORT — change"
        echo "  \"port\" in .wp-env.json. If it reports a missing image, check your"
        echo "  network and re-run."
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
