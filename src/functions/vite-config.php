<?php

// Ensure IS_TYPE is defined
if (!defined("IS_TYPE")) {
  define("IS_TYPE", "production"); // fallback to production
}

/**
 * Get the theme build version from version.json
 * Used for cache busting CSS/JS assets
 */
function wpvs_get_theme_version()
{
  static $version = null;

  if ($version !== null) {
    return $version;
  }

  // In local dev, use a timestamp to bust cache on every request
  if (IS_TYPE === "local") {
    $version = time();
    return $version;
  }

  // Read version from version.json generated during build
  $version_file = get_template_directory() . "/version.json";
  if (file_exists($version_file)) {
    $version_data = json_decode(file_get_contents($version_file), true);
    $version = $version_data["version"] ?? "1.0.0";
  } else {
    // Fallback to theme version from style.css
    $theme = wp_get_theme();
    $version = $theme->get("Version") ?: "1.0.0";
  }

  return $version;
}

/**
 * Base URL of the Vite dev server.
 *
 * Reads the VITE_SERVER constant, which .wp-env.json defines and
 * scripts/sync-wp-env.mjs keeps in step with the VITE_PORT in .env. The
 * fallback keeps the theme working outside wp-env, where nothing defines it.
 *
 * This exists so the dev URL lives in one place. It used to be written out at
 * six separate call sites, which meant changing the port required finding all
 * of them.
 */
function wpvs_vite_dev_url($path = "")
{
  $base = defined("VITE_DEV_URL") ? VITE_DEV_URL : "http://localhost:3030";

  return $base . "/" . ltrim($path, "/");
}

/**
 * Return the JS file path with version query string.
 */
function wpvs_vite_src_js($name)
{
  if (IS_TYPE === "local") {
    return wpvs_vite_dev_url("src/assets/" . ltrim($name, "/"));
  }

  return get_template_directory_uri() . "/assets/js/" . ltrim($name, "/") . "?ver=" . wpvs_get_theme_version();
}

/**
 * Return the CSS file path with version query string.
 */
function wpvs_vite_src_css($name)
{
  if (IS_TYPE === "local") {
    return wpvs_vite_dev_url("src/assets/css/" . ltrim($name, "/"));
  }

  $name = str_replace(".scss", ".css", $name);
  return get_template_directory_uri() . "/assets/css/" . ltrim($name, "/") . "?ver=" . wpvs_get_theme_version();
}

/**
 * Return static assets path (like favicon, svg, etc).
 */
function wpvs_vite_src_static($name)
{
  if (IS_TYPE === "local") {
    return wpvs_vite_dev_url("static/" . ltrim($name, "/"));
  }

  return get_template_directory_uri() . "/assets/images/" . ltrim($name, "/") . "?ver=" . wpvs_get_theme_version();
}

/**
 * Return an image path from src/assets/images/.
 *
 * With no $extension this returns the ORIGINAL file. That matters: it is the
 * value used for the <img> fallback inside <picture>, which has to be a format
 * every browser can decode. Pass "webp" or "avif" explicitly to get a converted
 * variant for a <source> tag.
 */
function wpvs_vite_src_images($name, $extension = null)
{
  if (IS_TYPE === "local") {
    return wpvs_vite_dev_url("src/assets/images/" . ltrim($name, "/"));
  }

  if ($extension === "webp" || $extension === "avif") {
    $name = preg_replace('/\.(jpe?g|png)$/i', "." . $extension, $name);
  }

  return get_template_directory_uri() . "/assets/images/" . ltrim($name, "/") . "?ver=" . wpvs_get_theme_version();
}

/**
 * In local mode, CSS is loaded via Vite's HMR through the app.js entry point
 * which imports app.scss. No need for wp_enqueue_style in local mode.
 */
