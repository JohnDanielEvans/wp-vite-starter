# WP Vite Starter

A WordPress starter theme wired to a modern local-development harness: [`@wordpress/env`](https://developer.wordpress.org/block-editor/reference-guides/packages/packages-env/) for a Dockerized WordPress, Vite for HMR and bundling, Sharp for image optimization, and GitHub Actions for rsync deployment.

## What you get

| Piece | File(s) |
| --- | --- |
| Dockerized local WordPress on `:8000` | `.wp-env.json` |
| Vite dev server + BrowserSync proxy on `:3030` | `vite.config.js` |
| PHP↔Vite asset bridge (dev URLs vs. versioned build URLs) | `src/functions/vite-config.php` |
| Cache-busting build hash | `scripts/generate-version.mjs` |
| JPEG/PNG → WebP + AVIF conversion | `convert.images.mjs` |
| Theme packaging + zip | `scripts/copy-theme.sh`, `scripts/build-and-zip-theme.sh` |
| Staging/production deploy over rsync+SSH | `.github/workflows/` |
| Server-side build deploy (alternative model) | `scripts/server-deploy.sh`, `.github/workflows/*.yml.example` |
| Theme-level asset serving rules | `src/.htaccess` |
| Lint + format on commit | `.husky/`, `eslint.config.mjs`, `.stylelintrc.json`, `.markuplintrc.json`, `.prettierrc.json` |
| Claude Code permission allowlist | `.claude/settings.json` |

## Quick start

```bash
npm install
npm run wp:start
npm run dev
```

- WordPress admin: http://localhost:8000/wp-admin (`admin` / `password`)
- Vite dev server: http://localhost:3030
- BrowserSync proxy: http://localhost:3031

Activate **WP Vite Starter** under Appearance → Themes. The theme is mounted from `./src/`, so edits are live.

Stop with `npm run wp:destroy`.

## How the Vite bridge works

`wp_get_environment_type()` drives the `IS_TYPE` constant (`src/functions/variables.php`). Everything downstream branches on it:

- **Local** — `parts/global-footer.php` emits `<script type="module">` tags pointing at `http://localhost:3030`, so you get HMR against real WordPress output. No PHP enqueues run.
- **Built** — `vite_src_js()` / `vite_src_css()` return `/assets/…?ver=<hash>`, where the hash comes from `version.json` written at build time.

`WP_ENVIRONMENT_TYPE` is set to `local` by `.wp-env.json`. On your servers, set it in `wp-config.php`.

## Renaming the theme for a new project

1. `src/style.css` — update the `Theme Name:` / `Author:` / `Text Domain:` header.
2. `scripts/theme-slug.sh` — change the `THEME_SLUG` default.
3. `.github/workflows/*.yml` — change the `THEME_SLUG` env value in both files.
4. `package.json` — change `name`.

Everything that writes to `deploy/` or rsyncs to a server reads `THEME_SLUG`, so those four edits cover it. For a one-off build without editing anything: `THEME_SLUG=my-theme npm run deploy`.

## Build & deploy

```bash
npm run build:prod
```

Compiles SCSS, bundles JS, generates WebP/AVIF variants, writes `version.json`, and assembles `deploy/$THEME_SLUG/`. Use `npm run deploy` to also produce an installable zip.

CI deploys on push:

| Branch | Workflow | Target |
| --- | --- | --- |
| `staging` | `deploy-staging.yml` | staging host |
| `prod-live` | `deploy-production.yml` | production host |

### Required repository secrets

Production: `PRIVATE_KEY`, `SSH_USER`, `SSH_HOST`, `SSH_PATH`, `SSH_KNOWN_HOSTS`
Staging: `STAGING_PRIVATE_KEY`, `STAGING_SSH_USER`, `STAGING_SSH_HOST`, `STAGING_SSH_PATH`, `STAGING_SSH_KNOWN_HOSTS`

`PRIVATE_KEY` is a base64-encoded SSH private key:

```bash
base64 -i ~/.ssh/deploy_key | pbcopy
```

`SSH_KNOWN_HOSTS` is the server's public host key — the workflows pin it rather than using `StrictHostKeyChecking=no`:

```bash
ssh-keyscan -H your-server.example.com
```

Only the theme directory is synced by default. Uploads are never deployed from CI — they are site content and belong to the server. Plugin sync is opt-in: set the repository variable `SYNC_PLUGINS=true` and vendor the plugins into `./plugins` (also removing it from `.gitignore`). There is deliberately no `--delete` on that sync, so it cannot wipe plugins installed through wp-admin.

### Deploy models

Two are included; pick one.

**rsync from CI** (`deploy-production.yml`, `deploy-staging.yml`, active by default) — CI builds the theme and rsyncs the finished artifact. The server needs nothing but SSH.

**Server-side build** (`deploy-production-ssh.yml.example` + `scripts/server-deploy.sh`) — CI SSHes in and the server pulls, builds, and activates the theme with wp-cli. Requires Node and a full git checkout on the server, and build failures land on production mid-deploy. Rename the `.example` file to enable it.

### Managed-host permission recovery

`deploy-production.yml` contains a step that moves the theme directory aside if the deploy user cannot write to it. This is not defensive boilerplate — on managed hosts (SpinupWP and similar), a plugin or theme update performed through wp-admin leaves `wp-content/themes/<slug>` owned by the web user. The deploy user then has no write access and no sudo, and every subsequent rsync fails. Moving the directory to `<slug>.old-<timestamp>` and recreating it is the only recovery available without root. Those `.old-*` directories accumulate; prune them periodically.

## Conventions

- **Edit `src/` only.** `dist/` and `deploy/` are build output and are gitignored.
- **All images go in `src/assets/images/`.** The build emits `.webp` and `.avif` alongside the original. Render them through `parts/picture.php`, which wraps them in a `<picture>` with both variants and an original-format fallback.
- **Site chrome — favicon, touch icon — goes in `public/static/`.** `copy-theme.sh` flattens that into `assets/images/` at build time, which is where `vite_src_static()` resolves to in a built theme.
- **Never commit database dumps.** `sql/` is gitignored: WordPress dumps carry `wp_users` rows (emails, password hashes) and plugin API keys in `wp_options`.
- Adding a page-level JS entry point means registering it in `vite.config.js` under `build.rollupOptions.input` *and* emitting the tag in `parts/global-footer.php`.

## Local database

`.wp-env.json` maps `./sql` into the container, so you can round-trip a database:

```bash
npm run db:export   # writes sql/wpenv.sql.gz
npm run db:import   # restores it
```

Keep those dumps out of version control.

## Provenance

The initial scaffolding — the `destyle.scss` reset, the Sharp conversion script, the base template partials — derives from a third-party open-source wp-env + Vite starter theme. The Vite↔PHP asset bridge, versioning, packaging scripts, and deployment workflows are original work.

## License

MIT — see [LICENSE](LICENSE).
