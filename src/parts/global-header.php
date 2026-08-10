<!DOCTYPE html>
<html <?php language_attributes(); ?> class="no-js">
<head>
  <script>
    document.documentElement.classList.remove('no-js');
  </script>
  <style>
    .global-hamburger-menu {
      display: none !important;
    }
  </style>
  <meta charset="<?php bloginfo("charset"); ?>">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="icon" href="<?= URL_FAVICON ?>" />
  <link rel="apple-touch-icon" href="<?= wpvs_vite_src_static("apple-touch-icon.png") ?>">
<!-- CSS is enqueued via wp_enqueue_style in functions.php with versioning -->

  <?php wp_head(); ?>
</head>
<div id="curtain-loader"></div>
<body id="top" data-type="<?= IS_TYPE ?>" <?php body_class(); ?>>
  <a class="hidden" href="#content">Jump to Main Text</a>
  <header class="global-header">
      <nav aria-label="Primary">
          <a class="logo" href="<?php echo home_url("/"); ?>"><?php get_template_part("./parts/picture", null, [
    "images" => [
        "src" => "logo.svg",
        "width" => "212",
        "height" => "64",
        "alt" => "",
    ],
]); ?>
          </a>
          <?php wp_nav_menu([
              "theme_location" => "primary",
              "menu" => "primary",
              "walker" => new WPDocs_Walker_Nav_Menu(),
              "fallback_cb" => false,
          ]); ?>

<?php class WPDocs_Walker_Nav_Menu extends Walker_Nav_Menu
{
    /**
     * Starts the list before the elements are added.
     *
     * Adds classes to the unordered list sub-menus.
     *
     * @param string $output Passed by reference. Used to append additional content.
     * @param int    $depth  Depth of menu item. Used for padding.
     * @param array  $args   An array of arguments. @see wp_nav_menu()
     */
    function start_lvl(&$output, $depth = 0, $args = [])
    {
        // Depth-dependent classes.
        $indent = $depth > 0 ? str_repeat("\t", $depth) : ""; // code indent
        $display_depth = $depth + 1; // because it counts the first submenu as 0
        $classes = ["sub-menu", $display_depth % 2 ? "menu-odd" : "menu-even", $display_depth >= 2 ? "sub-sub-menu" : "", "menu-depth-" . $display_depth];
        $class_names = implode(" ", $classes);

        // Build HTML for output.
        $output .= "\n" . $indent . '<ul class="' . $class_names . '">' . "\n";
    }

    /**
     * Start the element output.
     *
     * Adds main/sub-classes to the list items and links.
     *
     * @param string $output Passed by reference. Used to append additional content.
     * @param object $item   Menu item data object.
     * @param int    $depth  Depth of menu item. Used for padding.
     * @param array  $args   An array of arguments. @see wp_nav_menu()
     * @param int    $id     Current item ID.
     */
    function start_el(&$output, $item, $depth = 0, $args = [], $id = 0)
    {
        global $wp_query;
        $indent = $depth > 0 ? str_repeat("\t", $depth) : ""; // code indent

        // Depth-dependent classes.
        $depth_classes = [$depth == 0 ? "main-menu-item" : "sub-menu-item", $depth >= 2 ? "sub-sub-menu-item" : "", $depth % 2 ? "menu-item-odd" : "menu-item-even", "menu-item-depth-" . $depth];
        $depth_class_names = esc_attr(implode(" ", $depth_classes));

        // Passed classes.
        $classes = empty($item->classes) ? [] : (array) $item->classes;
        $class_names = esc_attr(implode(" ", apply_filters("nav_menu_css_class", array_filter($classes), $item)));

        // Build HTML.
        $output .= $indent . '<li id="nav-menu-item-' . $item->ID . '" class="' . $depth_class_names . " " . $class_names . '">';

        // Link attributes.
        $attributes = !empty($item->attr_title) ? ' title="' . esc_attr($item->attr_title) . '"' : "";
        $attributes .= !empty($item->target) ? ' target="' . esc_attr($item->target) . '"' : "";
        $attributes .= !empty($item->xfn) ? ' rel="' . esc_attr($item->xfn) . '"' : "";
        $attributes .= !empty($item->url) ? ' href="' . esc_attr($item->url) . '"' : "";
        $attributes .= ' class="menu-link ' . ($depth > 0 ? "sub-menu-link" : "main-menu-link") . '"';

        // Build HTML output and pass through the proper filter.
        $item_output = sprintf('%1$s<a%2$s>%3$s%4$s%5$s</a>%6$s', $args->before, $attributes, $args->link_before, apply_filters("the_title", $item->title, $item->ID), $args->link_after, $args->after);
        $output .= apply_filters("walker_nav_menu_start_el", $item_output, $item, $depth, $args);
    }
} ?>

        <?php get_template_part("./parts/global-hamburger-menu-btn"); ?>
        <?php get_template_part("./parts/global-hamburger-menu"); ?>
      </nav>

  </header>
