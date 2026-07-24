<?php

// Ensure IS_TYPE is defined
if (!defined("IS_TYPE")) {
    define("IS_TYPE", "production"); // fallback to production
}

/**
 * Get the theme build version from version.json
 * Used for cache busting CSS/JS assets
 */
function get_theme_version()
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
 * Return the JS file path with version query string.
 */
function vite_src_js($name)
{
    if (IS_TYPE === "local") {
        return "http://localhost:3030/src/assets/" . ltrim($name, "/");
    }

    return get_template_directory_uri() . "/assets/js/" . ltrim($name, "/") . "?ver=" . get_theme_version();
}

/**
 * Return the CSS file path with version query string.
 */
function vite_src_css($name)
{
    if (IS_TYPE === "local") {
        return "http://localhost:3030/src/assets/css/" . ltrim($name, "/");
    }

    $name = str_replace(".scss", ".css", $name);
    return get_template_directory_uri() . "/assets/css/" . ltrim($name, "/") . "?ver=" . get_theme_version();
}

/**
 * Return static assets path (like favicon, svg, etc).
 */
function vite_src_static($name)
{
    if (IS_TYPE === "local") {
        return "http://localhost:3030/static/" . ltrim($name, "/");
    }

    return get_template_directory_uri() . "/assets/images/" . ltrim($name, "/") . "?ver=" . get_theme_version();
}

/**
 * Return an image path from src/assets/images/.
 *
 * With no $extension this returns the ORIGINAL file. That matters: it is the
 * value used for the <img> fallback inside <picture>, which has to be a format
 * every browser can decode. Pass "webp" or "avif" explicitly to get a converted
 * variant for a <source> tag.
 */
function vite_src_images($name, $extension = null)
{
    if (IS_TYPE === "local") {
        return "http://localhost:3030/src/assets/images/" . ltrim($name, "/");
    }

    if ($extension === "webp" || $extension === "avif") {
        $name = preg_replace('/\.(jpe?g|png)$/i', "." . $extension, $name);
    }

    return get_template_directory_uri() . "/assets/images/" . ltrim($name, "/") . "?ver=" . get_theme_version();
}

/**
 * In local mode, CSS is loaded via Vite's HMR through the app.js entry point
 * which imports app.scss. No need for wp_enqueue_style in local mode.
 */
