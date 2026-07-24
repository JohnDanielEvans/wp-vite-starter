#!/usr/bin/env node
/**
 * Generate a version file with build timestamp and hash for cache busting
 */
import { writeFileSync, existsSync, mkdirSync } from 'fs';
import { createHash } from 'crypto';
import { execSync } from 'child_process';

// Generate a short hash based on current timestamp + random
const timestamp = Date.now();
const hash = createHash('md5')
  .update(timestamp.toString() + Math.random().toString())
  .digest('hex')
  .substring(0, 8);

// Try to get git commit hash if available
let gitHash = '';
try {
  gitHash = execSync('git rev-parse --short HEAD', { encoding: 'utf8' }).trim();
} catch {
  gitHash = hash;
}

const version = {
  version: gitHash,
  timestamp: timestamp,
  buildDate: new Date().toISOString()
};

// Ensure dist directory exists
if (!existsSync('dist')) {
  mkdirSync('dist', { recursive: true });
}

// Write version file
writeFileSync('dist/version.json', JSON.stringify(version, null, 2));

console.log(`✓ Generated version: ${version.version} (${version.buildDate})`);

