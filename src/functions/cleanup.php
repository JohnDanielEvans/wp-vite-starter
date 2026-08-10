<?php

/**
 * WP
 */

add_action("init", "wpvs_cleanup_init");

function wpvs_cleanup_init()
{
    wpvs_disable_wp_head();
    wpvs_disable_emojis();
    wpvs_disable_extra_rss();
    wpvs_disable_recent_comments_css();
    wpvs_disable_gallery_css();
}

function wpvs_disable_wp_head()
{
    add_filter("the_generator", "__return_false");
    remove_action("wp_head", "rsd_link");
    remove_action("wp_head", "wlwmanifest_link");
    remove_action("wp_head", "wp_generator");
    remove_action("wp_head", "wp_shortlink_wp_head", 10);
    remove_action("wp_head", "rest_output_link_wp_head", 10);
    remove_action("wp_head", "wp_oembed_add_discovery_links");
    remove_action("wp_enqueue_scripts", "wp_enqueue_global_styles");
    remove_action("wp_enqueue_scripts", "wp_common_block_scripts_and_styles");

    add_action(
        "wp_enqueue_scripts",
        function () {
            wp_dequeue_style("classic-theme-styles");
        },
        20,
    );
    add_action("wp_footer", function () {
        wp_dequeue_style("core-block-supports");
    });
}

function wpvs_disable_emojis()
{
    remove_action("wp_head", "print_emoji_detection_script", 7);
    remove_action("admin_print_scripts", "print_emoji_detection_script");
    remove_action("wp_print_styles", "print_emoji_styles");
    remove_action("admin_print_styles", "print_emoji_styles");
    remove_filter("the_content_feed", "wp_staticize_emoji");
    remove_filter("comment_text_rss", "wp_staticize_emoji");
    remove_filter("wp_mail", "wp_staticize_emoji_for_email");
    add_filter("emoji_svg_url", "__return_false");
}

function wpvs_disable_extra_rss()
{
    add_filter("feed_links_show_comments_feed", "__return_false");
    remove_action("wp_head", "feed_links_extra", 3);
}

function wpvs_disable_recent_comments_css()
{
    add_filter("show_recent_comments_widget_style", "__return_false");
}

function wpvs_disable_gallery_css()
{
    add_filter("use_default_gallery_style", "__return_false");
}
