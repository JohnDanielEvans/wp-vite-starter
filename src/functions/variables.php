<?php

/**
 * Theme-wide constants.
 *
 * Deliberately minimal. These are global names with no prefix, so every one
 * added here is a collision risk with WordPress core or a plugin — keep it to
 * things genuinely needed in more than one template, and prefer a wpvs_
 * function for anything else.
 */

// "local", "development", "staging" or "production". Drives the dev/built asset
// switch in vite-config.php and the script tags in parts/global-footer.php.
define("IS_TYPE", wp_get_environment_type());

// Static site chrome. In local dev this resolves to the Vite dev server; in a
// built theme, copy-theme.sh has flattened public/static into assets/images.
define("URL_STATIC", IS_TYPE === "local" ? "http://localhost:3030/static/" : get_theme_file_uri("/assets/images/"));
define("URL_FAVICON", URL_STATIC . "favicon.ico");
