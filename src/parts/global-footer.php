<footer class="global-footer">
  <div class="footer-container" data-aos="fade-up" data-aos-delay="200" data-aos-duration="800">
    <div class="row">
      <div class="col-6 col-lg-3 mb-4">
        <h6><?php bloginfo("name"); ?></h6>
        <p><?php bloginfo("description"); ?></p>
      </div>

      <div class="col-6 col-lg-3 mb-4">
        <h6>Quick Links</h6>
        <?php wp_nav_menu([
            "theme_location" => "footer",
            "menu" => "footer",
            "container" => false,
            "items_wrap" => '<ul class="list-unstyled">%3$s</ul>',
            "fallback_cb" => false,
        ]); ?>
      </div>
    </div>
  </div>

  <hr class="footer-break">

  <div class="footer-bottom">
    <p class="copyright">&copy; <?php echo date("Y"); ?> <?php bloginfo("name"); ?>. All rights reserved.</p>
    <div class="last-links">
      <?php wp_nav_menu([
          "theme_location" => "legal",
          "menu" => "legal",
          "container" => false,
          "items_wrap" => "%3\$s",
          "fallback_cb" => false,
      ]); ?>
    </div>
  </div>
</footer>

<?php wp_footer(); ?>

<!-- Endpoint + nonce for the AJAX helpers in functions/ajax.php.
     Emitted in every environment: scoping this to local dev leaves
     window.ajax_object undefined in production, where the endpoint is
     precisely what the built bundles need. -->
<script>
  window.ajax_object = {
    ajaxurl: "<?php echo esc_url(admin_url("admin-ajax.php")); ?>",
    nonce: "<?php echo esc_js(wp_create_nonce("wpvs_load_more")); ?>"
  };
</script>

<?php if (defined("IS_TYPE") && IS_TYPE === "local"): ?>
  <!-- Local dev: Vite handles HMR -->
  <script type="module" src="http://localhost:3030/@vite/client"></script>
  <script type="module" src="http://localhost:3030/src/assets/app.js"></script>
  <?php if (is_front_page()): ?>
    <script type="module" src="http://localhost:3030/src/assets/js/front-page.js"></script>
  <?php endif; ?>
<?php else: ?>
  <!-- Production: versioned bundles -->
  <script type="module" src="<?= wpvs_vite_src_js("app.js") ?>" defer></script>
  <?php if (is_front_page()): ?>
    <script type="module" src="<?= wpvs_vite_src_js("front-page.js") ?>"></script>
  <?php endif; ?>
<?php endif; ?>

</body>
</html>
