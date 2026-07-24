<?php
/**
 * Custom Post Types
 *
 * Registers the "works" post type and its "works-category" taxonomy, which the
 * bundled archive-works.php, single-works.php and taxonomy-works-category.php
 * templates render. Treat this as the worked example: copy the shape, rename
 * the slugs, and add matching templates.
 *
 * Rewrite rules are cached, so flush after changing anything here:
 *   npm run wp:env run cli 'wp rewrite flush --hard'
 */

function wpvs_register_post_types()
{
    register_post_type("works", [
        "label" => "Works",
        "labels" => [
            "name" => "Works",
            "singular_name" => "Work",
            "add_new" => "Add New",
            "add_new_item" => "Add New Work",
            "edit_item" => "Edit Work",
            "new_item" => "New Work",
            "view_item" => "View Work",
            "search_items" => "Search Works",
            "not_found" => "No works found",
            "not_found_in_trash" => "No works found in Trash",
        ],
        "public" => true,
        "has_archive" => true,
        "show_in_rest" => true,
        "supports" => ["title", "editor", "thumbnail", "excerpt", "page-attributes"],
        "menu_icon" => "dashicons-portfolio",
        "rewrite" => ["slug" => "works"],
        "show_in_nav_menus" => true,
    ]);
}

add_action("init", "wpvs_register_post_types");

function wpvs_register_taxonomies()
{
    register_taxonomy("works-category", "works", [
        "label" => "Work Categories",
        "labels" => [
            "name" => "Work Categories",
            "singular_name" => "Work Category",
            "search_items" => "Search Categories",
            "all_items" => "All Categories",
            "edit_item" => "Edit Category",
            "update_item" => "Update Category",
            "add_new_item" => "Add New Category",
            "new_item_name" => "New Category Name",
            "menu_name" => "Categories",
        ],
        "hierarchical" => true,
        "public" => true,
        "show_in_rest" => true,
        "show_admin_column" => true,
        "rewrite" => ["slug" => "works-category"],
    ]);
}

add_action("init", "wpvs_register_taxonomies");
