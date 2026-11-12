#!/usr/bin/env node
// Vercel build script that explicitly creates Build Output API structure.
// This ensures api/stripe-webhook.mjs is always built as a function,
// regardless of zero-config detection quirks.

import { cpSync, mkdirSync, writeFileSync, readFileSync, existsSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = join(__dirname, '..');
const output = join(root, '.vercel/output');

console.log('[vercel-build] Creating Build Output API structure...');

// 1. Copy static site files
console.log('[vercel-build] Copying static files from site/...');
mkdirSync(join(output, 'static/site'), { recursive: true });
cpSync(join(root, 'site'), join(output, 'static/site'), { recursive: true });

// 2. Copy entire repo for reference (docs, tests, Swift sources)
console.log('[vercel-build] Copying additional static assets...');
for (const dir of ['docs', 'Examples', 'Sources', 'Tests', 'scripts', 'tests']) {
  if (existsSync(join(root, dir))) {
    cpSync(join(root, dir), join(output, `static/${dir}`), { recursive: true });
  }
}
for (const file of ['.gitattributes', 'LICENSE', 'Package.swift']) {
  if (existsSync(join(root, file))) {
    cpSync(join(root, file), join(output, `static/${file}`));
  }
}

// 3. Create function for api/stripe-webhook.mjs
console.log('[vercel-build] Creating function: api/stripe-webhook');
const funcDir = join(output, 'functions/api/stripe-webhook.func');
mkdirSync(join(funcDir, 'api/_lib'), { recursive: true });

// Copy function files
cpSync(join(root, 'api/stripe-webhook.mjs'), join(funcDir, 'api/stripe-webhook.mjs'));
cpSync(join(root, 'api/_lib/delivery.mjs'), join(funcDir, 'api/_lib/delivery.mjs'));

// Write function configuration
writeFileSync(join(funcDir, '.vc-config.json'), JSON.stringify({
  runtime: 'nodejs22.x',
  handler: 'api/stripe-webhook.mjs',
  launcherType: 'Nodejs',
  shouldAddHelpers: true
}, null, 2));

// 4. Create config.json with routes
console.log('[vercel-build] Writing config.json with routes...');
writeFileSync(join(output, 'config.json'), JSON.stringify({
  version: 3,
  routes: [
    { handle: 'filesystem' },
    // Rewrite non-api paths to /site/ subdirectory
    { src: '^(?:/((?!api).*))$', dest: '/site/$1', check: true },
    // API function route
    { src: '^/api/stripe-webhook/?$', dest: '/api/stripe-webhook' },
    { handle: 'miss' },
    { handle: 'error', status: 404, src: '^(?!/api).*$', dest: '/404.html' }
  ]
}, null, 2));

console.log('[vercel-build] Build Output API structure created successfully.');
console.log('[vercel-build] Function: .vercel/output/functions/api/stripe-webhook.func/');
console.log('[vercel-build] Static:   .vercel/output/static/');
