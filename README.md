# WP Vite Starter

A WordPress starter theme with a modern front-end workflow: Docker-backed
WordPress, Vite with hot reload, automatic WebP/AVIF images, and one-push
deploys.

Build a classic PHP theme, but with the tooling you'd expect from any other
2020s front-end project.

---

## Requirements

- **Node 20.19+** (or 22+) — `.nvmrc` has the version this is developed against
- **Docker** (for the local WordPress)

## Quick start

```bash
npm install
npm run wp:start
npm run dev
```

Then open **http://localhost:3030** and activate **WP Vite Starter** under
Appearance → Themes.

| | |
| --- | --- |
| Site (with hot reload) | http://localhost:3030 |
| WordPress admin | http://localhost:8000/wp-admin — `admin` / `password` |
| BrowserSync proxy | http://localhost:3031 |

The theme runs straight from `src/`, so your edits appear immediately. Run
`npm run wp:destroy` when you're finished.

> **Run `npm run wp:destroy` before moving, renaming or deleting this checkout.**
> wp-env keys each environment to the *path* of `.wp-env.json`, and `destroy`
> looks it up the same way — so once the path changes, its WordPress install and
> database volume (300MB+) are stranded with no way to reach them. Editing
> `.wp-env.json` is free; only the path matters. `npm run wp:prune` cleans up any
> that were already stranded.

## Everyday commands

| Command | What it does |
| --- | --- |
| `npm run dev` | Start the Vite dev server with hot reload |
| `npm run build:prod` | Full production build into `deploy/` |
| `npm run deploy` | Production build, plus an installable `.zip` |
| `npm run lint:check` | Lint markup, styles, and scripts |
| `npm run lint:fix` | Fix what can be fixed automatically |
| `npm run format` | Run Prettier over `src/` |
| `npm run wp:start` / `wp:destroy` | Start / tear down local WordPress |
| `npm run wp:prune` | Remove wp-env environments whose project is gone |
| `npm run db:export` / `db:import` | Save and restore the local database |
| `npm run init` | Rename the theme for a new project |
| `npm run site:import` | Import an existing site's database |
| `npm run theme:adopt` | Move an existing theme into this harness |

## Project layout

```
src/                  The theme itself — this is what gets deployed
  assets/             SCSS, JS, images, SVG sprites
  functions/          PHP: post types, AJAX, the Vite bridge
  parts/              Template partials
  *.php               Page templates
public/static/        Favicon and touch icons
scripts/              Build and packaging
dist/  deploy/        Build output (gitignored)
```

Edit `src/` only — everything else is generated.

---

## How it works

**In development**, `parts/global-footer.php` points `<script type="module">`
tags at the Vite dev server, so you get hot reload against real WordPress
output.

**In a build**, `wpvs_vite_src_js()` and `wpvs_vite_src_css()` return
`/assets/…?ver=<hash>`, where the hash comes from a `version.json` written at
build time — so browsers pick up new assets immediately.

The switch between the two is WordPress's own `wp_get_environment_type()`.
`.wp-env.json` sets it to `local` for you; on a real server, set
`WP_ENVIRONMENT_TYPE` in `wp-config.php`.

### Images

Drop images in `src/assets/images/`. The build generates `.webp` and `.avif`
alongside the original, and `parts/picture.php` renders a `<picture>` with all
three so browsers take the best one they support.

### Plugins

None are installed by default — the theme doesn't need any, since the `works`
post type and its taxonomy are registered in `src/functions/post-types.php`. Add
what a project needs to `.wp-env.json`:

```json
"plugins": ["https://downloads.wordpress.org/plugin/advanced-custom-fields.zip"]
```

---

## Using it for your own project

### Starting something new

```bash
npm run init
```

Asks for a theme name, slug and author, then renames the theme everywhere it
needs to agree — `src/style.css`, `scripts/theme-slug.sh`, both deploy
workflows and `package.json` — and offers to remove the `works` portfolio demo
and start a fresh git history.

<details>
<summary>Doing it by hand, or non-interactively</summary>

Four edits rename the theme everywhere:

1. `src/style.css` — the `Theme Name:` / `Author:` / `Text Domain:` header
2. `scripts/theme-slug.sh` — the `THEME_SLUG` default
3. `.github/workflows/*.yml` — the `THEME_SLUG` value in both files
4. `package.json` — the `name` field

Everything that packages or deploys reads `THEME_SLUG`. For a one-off build
without editing anything: `THEME_SLUG=my-theme npm run deploy`.

`init` also takes flags, so it can run unattended:

```bash
npm run init -- --name "Acme Corp" --slug acme-corp --author "You" --strip-demo --yes
```

</details>

### Bringing in an existing site

Two independent steps — run either, or both.

```bash
npm run site:import -- path/to/dump.sql.gz --uploads path/to/uploads
```

Imports a production database into the local environment: rewrites the live
URLs to `localhost:8000` (walking serialized data so widgets and options
survive), renames the tables if the dump uses a prefix other than `wp_`,
reinstalls the plugins the database says were active, and gives you a working
`admin` / `password` login, since nobody knows the live passwords.

```bash
npm run theme:adopt -- path/to/existing-theme
```

Moves an existing theme into `src/`, installs the Vite bridge, wires it into the
theme's `functions.php`, creates the entry points, and points `THEME_SLUG` at
it. It then prints the handful of template edits it will not guess at.

<details>
<summary>What the importer handles, and what it can't</summary>

A plain `wp db import` leaves you with a site that redirects to production, so
the importer does the three things that actually make a dump usable locally:

| Problem | What happens without it |
| --- | --- |
| Live URLs throughout the database | The local site redirects to the live domain |
| Table prefix other than `wp_` | WordPress shows a fresh install screen; the data is there but unread |
| Prefixed `user_roles` / capability meta keys | Every user loses their role, including the administrator |

It does **not** carry across: plugin *code* (only the record of what was
active — premium plugins are listed at the end for you to drop into
`./plugins/`), `wp-config.php` constants, or anything in `.htaccess`.

Multisite dumps are rejected rather than half-imported.

</details>

<details>
<summary>What theme:adopt leaves to you</summary>

It will not emit the script tags or remove the theme's existing
`wp_enqueue_*` calls. Both need a judgement call about an unfamiliar template,
and a script that guesses produces a theme loading its assets twice or not at
all — so it prints exactly what to add and which files still enqueue their own
assets.

It replaces `src/` entirely, so commit or stash first; git is the undo button,
and the script refuses to run on a dirty `src/` unless you pass `--force`.

</details>

## Deploying

Push to a branch and GitHub Actions builds the theme and rsyncs it over SSH.
The build happens on the runner, so a broken build fails the workflow and never
reaches your server.

| Branch | Deploys to |
| --- | --- |
| `staging` | staging host |
| `prod-live` | production host |

Only the theme directory is synced. Uploads are never deployed — they're site
content and belong to the server.

<details>
<summary><strong>Setting up the deploy secrets</strong></summary>

Add these under Settings → Secrets and variables → Actions:

**Production** — `PRIVATE_KEY`, `SSH_USER`, `SSH_HOST`, `SSH_PATH`, `SSH_KNOWN_HOSTS`
**Staging** — the same five, each prefixed `STAGING_`

`PRIVATE_KEY` is a base64-encoded SSH private key:

```bash
base64 -i ~/.ssh/deploy_key | pbcopy
```

`SSH_KNOWN_HOSTS` is the server's public host key. The workflows pin it rather
than disabling host checking:

```bash
ssh-keyscan -H your-server.example.com
```

Until these exist the deploy job skips itself, so forking this repo won't
produce failing builds.

</details>

<details>
<summary><strong>Deploying plugins too (optional)</strong></summary>

Set the repository variable `SYNC_PLUGINS=true` and commit the plugins into
`./plugins` (removing it from `.gitignore`). That sync deliberately has no
`--delete`, so it can never wipe plugins installed through wp-admin.

</details>

<details>
<summary><strong>If deploys start failing with permission errors</strong></summary>

On managed hosts (SpinupWP and similar), updating a plugin or theme through
wp-admin leaves `wp-content/themes/<slug>` owned by the web user. The deploy
user then can't write to it and has no sudo, so every rsync fails.

`deploy-production.yml` handles this by moving the directory to
`<slug>.old-<timestamp>` and recreating it — the only recovery available without
root. Those `.old-*` directories build up over time, so prune them occasionally.

</details>

---

## Conventions

- **Edit `src/` only.** `dist/` and `deploy/` are build output.
- **Images go in `src/assets/images/`**, rendered via `parts/picture.php`.
- **Favicons and touch icons go in `public/static/`**, resolved by
  `wpvs_vite_src_static()`.
- **Theme functions are prefixed `wpvs_`** — PHP has one global namespace, and
  an unprefixed `remove_menus()` will fatal the site the day a plugin declares
  the same name.
- **Never commit database dumps.** `sql/` is gitignored: WordPress dumps carry
  user emails, password hashes, and plugin API keys.
- **New page-level JS** needs registering in `vite.config.mjs` under
  `build.rollupOptions.input` *and* a tag in `parts/global-footer.php`.

## Contributing

Bug fixes, host-compatibility fixes, and documentation are all welcome — see
[CONTRIBUTING.md](CONTRIBUTING.md). Open an issue first for anything
substantial.

## Credits

This theme isn't scaffolded from scratch. Parts of it descend from an
open-source wp-env + Vite starter theme — Japanese-language, translated during
adaptation — whose name and URL I no longer have. **If you recognise the
lineage, please open an issue so it can be credited properly.**

<details>
<summary>What's inherited, what's original, and third-party licenses</summary>

From that lineage, as best I can reconstruct: the template partial structure,
the SCSS layout (`base/` / `parts/` / `pages/`), and the shape of the Sharp
image-conversion script. The `works` post type and the agency conventions in the
markup come from the same source.

Original work here: the Vite↔PHP asset bridge
(`src/functions/vite-config.php`), the build versioning and cache-busting, the
packaging scripts, and the deployment workflows.

Third-party code shipped in this repo:

| Component | Source | License |
| --- | --- | --- |
| `src/assets/css/base/_destyle.scss` | [destyle.css](https://github.com/nicolas-cusan/destyle.css) v4.0.0 by Nicolas Cusan | MIT |

Runtime dependencies (Bootstrap, GSAP, AOS, Keen-Slider, Rellax) come from npm
under their own licenses — GSAP's in particular is worth reading before
commercial use. Only Bootstrap's grid and spacing utilities are compiled in; see
`src/assets/css/base/_global.scss`.

</details>

## License

MIT — see [LICENSE](LICENSE). Covers the original work here; third-party
components stay under their own licenses.
