// Single source of truth for the ports this project listens on.
//
// Read by vite.config.mjs, scripts/sync-wp-env.mjs and scripts/start.sh, so a
// port is configured in one place rather than in .wp-env.json, vite.config.mjs
// and the theme's PHP separately.
//
// Resolution order: real environment variables win, then .env, then defaults.
// That lets CI or a one-off shell override without touching a file:
//
//   WP_PORT=8100 VITE_PORT=3130 npm start

import { existsSync, readFileSync } from "node:fs";
import path from "node:path";

const root = path.resolve(import.meta.dirname, "..");

function readDotEnv() {
  const file = path.join(root, ".env");
  if (!existsSync(file)) return {};

  const out = {};
  for (const rawLine of readFileSync(file, "utf8").split("\n")) {
    const line = rawLine.trim();
    if (!line || line.startsWith("#")) continue;

    const eq = line.indexOf("=");
    if (eq === -1) continue;

    const key = line.slice(0, eq).trim();
    // Strip one layer of matching quotes; anything fancier belongs in a real
    // dotenv parser, and this file only ever holds a couple of port numbers.
    const value = line
      .slice(eq + 1)
      .trim()
      .replace(/^(['"])(.*)\1$/, "$2");

    if (key) out[key] = value;
  }
  return out;
}

const fileEnv = readDotEnv();

function port(name, fallback) {
  const raw = process.env[name] ?? fileEnv[name];
  if (raw === undefined || raw === "") return fallback;

  const n = Number(raw);
  if (!Number.isInteger(n) || n < 1 || n > 65535) {
    throw new Error(
      `${name} must be a port number between 1 and 65535, got "${raw}".`,
    );
  }
  return n;
}

export const WP_PORT = port("WP_PORT", 8000);
export const VITE_PORT = port("VITE_PORT", 3030);

// BrowserSync sits next to Vite by default, so moving VITE_PORT moves both and
// two copies of this project do not collide on a port nobody thought about.
export const BROWSERSYNC_PORT = port("BROWSERSYNC_PORT", VITE_PORT + 1);

export const WP_URL = `http://localhost:${WP_PORT}`;
export const VITE_URL = `http://localhost:${VITE_PORT}`;

export default { WP_PORT, VITE_PORT, BROWSERSYNC_PORT, WP_URL, VITE_URL };
