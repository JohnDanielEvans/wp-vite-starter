# Contributing

Thanks for taking a look. This is a starter theme, so the most useful
contributions are usually the boring ones: a fix for something that breaks on a
fresh clone, a host quirk the deploy scripts don't handle, or documentation for
a step that isn't obvious.

## Getting it running

Requires Node 20.11+ (`sharp` sets a 20.9 floor, `import.meta.dirname` in the
Vite config raises it to 20.11) and Docker (for `@wordpress/env`).

```bash
npm install
npm run wp:start
npm run dev
```

WordPress lands on http://localhost:8000 (`admin` / `password`), Vite on
http://localhost:3030, BrowserSync on http://localhost:3031. The theme is
mounted from `./src/`, so edits are live. Activate **WP Vite Starter** under
Appearance → Themes.

Tear down with `npm run wp:destroy`.

## Before you open a PR

Both of these must pass:

```bash
npm run lint:check
```

```bash
npm run build:prod
```

A Husky pre-commit hook runs `lint-staged` (markuplint, eslint, stylelint,
prettier) over staged files, so most style issues are fixed for you on commit.
Don't hand-format around the tools — if a rule is wrong, change the rule and say
why in the PR.

There is no test suite. Verification is: does it build, does it lint, and does
the affected page still render correctly in the local wp-env. Say in the PR
which pages you actually loaded.

## Scope

Things that fit well:

- Bug fixes in the Vite↔PHP bridge, packaging scripts, or deploy workflows
- Host-compatibility fixes (the managed-host permission dance in
  `deploy-production.yml` is the kind of thing that varies by host)
- Documentation, especially anything you had to work out by reading the source
- Attribution — see the Provenance section of the README; the upstream project
  this descends from is not identified, and identifying it would be a real
  contribution

Things that probably don't:

- Swapping out a core tool (Vite, wp-env, Sass) — that's a different starter,
  not a change to this one
- New runtime dependencies. The dependency list is already heavier than it
  needs to be; adding to it needs a strong reason
- Design opinions about the default markup. It's placeholder scaffolding and
  every user deletes it

If you're planning something substantial, open an issue first so you don't spend
a weekend on something that gets declined.

## Conventions

- **Edit `src/` only.** `dist/` and `deploy/` are build output and gitignored.
- **Never commit database dumps.** `sql/` is gitignored for a reason: WordPress
  dumps carry `wp_users` rows (emails, password hashes) and plugin API keys in
  `wp_options`. Same goes for anything under `uploads/`.
- **Never commit secrets, SSH keys, or real hostnames.** The deploy workflows
  read everything host-specific from repository secrets.
- PHP functions in the theme are prefixed `wpvs_`. Keep new ones consistent.
- Adding a page-level JS entry point means registering it in `vite.config.mjs`
  under `build.rollupOptions.input` *and* emitting the tag in
  `parts/global-footer.php`.

## License

By contributing, you agree your contributions are licensed under the MIT
License, the same as the rest of the project.
