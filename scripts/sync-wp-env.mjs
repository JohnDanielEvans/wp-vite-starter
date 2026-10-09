// Writes .wp-env.override.json so wp-env uses the ports from .env.
//
// .wp-env.json is static JSON and cannot read environment variables, but wp-env
// merges a sibling .wp-env.override.json over it — the mechanism it provides for
// exactly this. The override is gitignored, so each checkout can sit on its own
// ports without anyone committing a local preference.
//
// Overriding does NOT create a second environment: wp-env keys its working
// directory to md5 of the .wp-env.json path, and the override file does not
// change that path. Ports can move without stranding a database volume.
//
// Run automatically by `npm start`; safe to run by hand.

import { writeFileSync, existsSync, readFileSync, rmSync } from "node:fs";
import path from "node:path";
import { WP_PORT, VITE_PORT, VITE_URL } from "./ports.mjs";

const root = path.resolve(import.meta.dirname, "..");
const basePath = path.join(root, ".wp-env.json");
const overridePath = path.join(root, ".wp-env.override.json");

const base = JSON.parse(readFileSync(basePath, "utf8"));
const baseViteServer = base?.config?.VITE_SERVER;

const needsPort = base.port !== WP_PORT;
const needsViteServer = baseViteServer !== VITE_URL;

// Nothing to override when the defaults already match: leaving a redundant file
// behind just invites confusion about which file is in charge.
if (!needsPort && !needsViteServer) {
  if (existsSync(overridePath)) {
    rmSync(overridePath);
    console.log("Removed .wp-env.override.json — ports match .wp-env.json");
  }
  process.exit(0);
}

const override = {};
if (needsPort) override.port = WP_PORT;
if (needsViteServer) override.config = { VITE_SERVER: VITE_URL };

writeFileSync(overridePath, JSON.stringify(override, null, 2) + "\n");

console.log(
  `Wrote .wp-env.override.json (WordPress :${WP_PORT}, Vite :${VITE_PORT})`,
);
