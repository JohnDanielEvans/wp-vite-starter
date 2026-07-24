<?php
// Updated hamburger menu markup with corrected class structure
?>
<nav
  id="hamburger-menu"
  class="global-hamburger-menu js-global-hamburger-menu"
  aria-hidden="true"
  aria-label="global navigation"
>
  <a class="logo-mobile" href="<?php echo home_url("/"); ?>">
    <?php get_template_part("./parts/picture", null, [
        "images" => [
            "src" => "logo.svg",
            "width" => "400",
            "height" => "",
            "alt" => "",
        ],
    ]); ?>
  </a>

  <?php wp_nav_menu([
      "theme_location" => "mobile",
      "menu" => "mobile",
      "walker" => new WPDocs_Walker_Nav_Menu(),
      "fallback_cb" => false,
  ]); ?>
</nav>
