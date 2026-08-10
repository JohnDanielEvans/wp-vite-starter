<?php
/**
 * AJAX endpoints.
 *
 * Worked example: paginated "load more" for the works archive. Returns JSON so
 * the client knows whether another page exists, rather than guessing from an
 * empty response.
 *
 * Client side: src/assets/js/modules/load-more.js
 */

function wpvs_load_more_works()
{
    check_ajax_referer("wpvs_load_more", "nonce");

    $paged = isset($_POST["page"]) ? max(1, intval($_POST["page"])) : 1;

    // Must match the main archive query, which uses the site's Reading setting.
    // Hardcoding a different number here silently re-serves posts the first page
    // already rendered: with 5 here and 10 on the archive, "page 2" returns
    // posts 6-10, all of which are already on screen.
    $per_page = (int) get_option("posts_per_page");

    $query = new WP_Query([
        "post_type" => "works",
        "post_status" => "publish",
        "posts_per_page" => $per_page,
        "paged" => $paged,
        "ignore_sticky_posts" => true,
    ]);

    ob_start();

    while ($query->have_posts()):

        $query->the_post();

        // get_the_category() only ever returns the built-in "category"
        // taxonomy, so it silently returns nothing for a custom post type.
        // get_the_terms() against the registered taxonomy is what works here.
        $terms = get_the_terms(get_the_ID(), "works-category");

        // Wrapped in <li> because this HTML is appended into the archive's
        // <ul data-load-more-list>. An <article> placed directly in a <ul> is
        // invalid markup and browsers will hoist it out of the list.
        ?>
        <li>
        <article class="card-archive" data-aos="fade-up" data-aos-duration="300">
            <a href="<?php the_permalink(); ?>" class="card-archive__link">
                <?php if (has_post_thumbnail()): ?>
                    <div class="card-archive__thumb"><?php the_post_thumbnail("large"); ?></div>
                <?php endif; ?>
                <div class="card-archive__content">
                    <h2 class="card-archive__title"><?php the_title(); ?></h2>
                    <div class="card-archive__excerpt"><?php the_excerpt(); ?></div>
                    <?php if (!empty($terms) && !is_wp_error($terms)): ?>
                        <p class="card-archive__meta"><?= esc_html($terms[0]->name) ?></p>
                    <?php endif; ?>
                </div>
            </a>
        </article>
        </li>
        <?php
    endwhile;

    wp_reset_postdata();

    wp_send_json_success([
        "html" => ob_get_clean(),
        "page" => $paged,
        "has_more" => $paged < (int) $query->max_num_pages,
    ]);
}

add_action("wp_ajax_wpvs_load_more_works", "wpvs_load_more_works");
add_action("wp_ajax_nopriv_wpvs_load_more_works", "wpvs_load_more_works");
