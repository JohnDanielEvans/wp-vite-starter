#!/bin/bash
# Single source of truth for the theme directory name.
# Override per-project with:  THEME_SLUG=my-theme npm run deploy
: "${THEME_SLUG:=wp-vite-starter}"
export THEME_SLUG
