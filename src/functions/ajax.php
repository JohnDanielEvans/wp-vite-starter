<?php
function load_more_products()
{
    $paged = isset($_POST["page"]) ? intval($_POST["page"]) : 1;

    $args = [
        "post_type" => "products",
        "posts_per_page" => 5,
        "paged" => $paged,
    ];

    $query = new WP_Query($args);

    if ($query->have_posts()):
        while ($query->have_posts()):
            $query->the_post(); ?>
            <article class="archive-product__card archive-product__card--horizontal" data-aos="fade-up" data-aos-delay="100" data-aos-duration="300">
                <a href="<?php the_permalink(); ?>" class="archive-product__card-link">
                    <?php if (has_post_thumbnail()): ?>
                        <div class="archive-product__card-thumb">
                            <?php the_post_thumbnail("large"); ?>
                        </div>
                    <?php endif; ?>
                    <div class="archive-product__card-content">
                        <h2 class="archive-product__card-title"><?php the_title(); ?></h2>
                        <div class="archive-product__card-excerpt">
                            <p><?php echo wp_kses_post(get_field("summary")); ?></p>
                        </div>
                        <p class="archive-product__card-meta">
                            <?php
                            $cats = get_the_category();
                            if (!empty($cats)) {
                                echo "<strong>Category:</strong> " . esc_html($cats[0]->name);
                            }
                            ?>
                        </p>
                        <span class="archive-product__card-arrow">↗</span>
                    </div>
                </a>
            </article>
        <?php
        endwhile;
        wp_reset_postdata();
    else:
         ?>
        <p>No more products found.</p>
    <?php
    endif;

    wp_die();
}

add_action("wp_ajax_load_more_products", "load_more_products");
add_action("wp_ajax_nopriv_load_more_products", "load_more_products");
