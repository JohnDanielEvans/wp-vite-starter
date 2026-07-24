<?php
/**
 * Custom Post Types
 */

function wpvs_register_post_types()
{
    register_post_type("products", [
        "label" => "Products",
        "labels" => [
            "name" => "Products",
            "singular_name" => "Product",
            "add_new" => "Add New",
            "add_new_item" => "Add New Product",
            "edit_item" => "Edit Product",
            "new_item" => "New Product",
            "view_item" => "View Product",
            "search_items" => "Search Products",
            "not_found" => "No products found",
            "not_found_in_trash" => "No products found in Trash",
        ],
        "public" => true,
        "has_archive" => false,
        "show_in_rest" => true,
        "supports" => ["title", "editor", "thumbnail", "page-attributes"],
        "menu_icon" => "dashicons-store",
        "rewrite" => ["slug" => "products"],
        "show_in_nav_menus" => true,
    ]);
}

add_action("init", "wpvs_register_post_types");

function wpvs_register_taxonomies()
{
    register_taxonomy("product_category", "products", [
        "label" => "Product Categories",
        "labels" => [
            "name" => "Product Categories",
            "singular_name" => "Product Category",
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
        "rewrite" => ["slug" => "product-category"],
    ]);
}

add_action("init", "wpvs_register_taxonomies");
