<?php
require_once get_theme_file_path("./functions/cleanup.php");
require_once get_theme_file_path("./functions/editor-extra.php");
require_once get_theme_file_path("./functions/variables.php");
require_once get_theme_file_path("./functions/vite-config.php");
require_once get_theme_file_path("./functions/utility.php");
require_once get_theme_file_path("./functions/pagination.php");
require_once get_theme_file_path("./functions/ajax.php");
require_once get_theme_file_path("./functions/post-types.php");

function vite_image($filename)
{
    if (IS_TYPE === "local") {
        return "http://localhost:3030/static/" . ltrim($filename, "/");
    }

    return get_template_directory_uri() . "/assets/images/" . ltrim($filename, "/");
}

function enqueue_custom_scripts()
{
    // Skip all enqueues during local dev (Vite handles it)
    if (defined("IS_TYPE") && IS_TYPE === "local") {
        return;
    }

    // Use theme version for cache busting
    $version = function_exists("get_theme_version") ? get_theme_version() : "1.0.0";
    wp_enqueue_style("theme-style", get_template_directory_uri() . "/assets/css/app.css", [], $version);

    // Optionally: enqueue legacy plugin or extra scripts here
    // Vite-built scripts are injected in global-footer.php with type="module"
}

add_action("wp_enqueue_scripts", "enqueue_custom_scripts");

// Menu locations used by parts/global-header.php and parts/global-footer.php
add_action("after_setup_theme", function () {
    add_theme_support("title-tag");
    add_theme_support("post-thumbnails");
    add_theme_support("html5", ["search-form", "gallery", "caption", "style", "script"]);

    register_nav_menus([
        "primary" => "Primary Menu",
        "mobile" => "Mobile Menu",
        "footer" => "Footer Menu",
        "legal" => "Legal Menu",
    ]);
});

// Disable jQuery Migrate console warnings (they're from WP plugins, not our code)
add_action("wp_default_scripts", function ($scripts) {
    if (!empty($scripts->registered["jquery-migrate"])) {
        $scripts->registered["jquery-migrate"]->extra["after"] = ["if (window.jQuery && window.jQuery.migrateWarnings) { jQuery.migrateMute = true; jQuery.migrateTrace = false; }"];
    }
});
