<?php

add_action("init", "wpvs_editor_extra_init");
add_action("admin_menu", "wpvs_remove_menus", 999);

function wpvs_editor_extra_init()
{
    wpvs_disable_post_support();
    wpvs_enable_post_support();
}

function wpvs_disable_post_support()
{
    remove_post_type_support("post", "excerpt"); // Excerpt
    remove_post_type_support("post", "trackbacks"); // Trackbacks
    remove_post_type_support("post", "comments"); // Discussion
}

function wpvs_enable_post_support()
{
    add_theme_support("post-thumbnails"); // Enable featured images
}

function wpvs_remove_menus()
{
    remove_menu_page("edit.php"); // Posts
    remove_menu_page("edit-comments.php"); // Comments
}
