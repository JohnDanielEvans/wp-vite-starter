<?php
$images = $args["images"] ?? [];
$lazy = $args["lazy"] ?? false;

if (!function_exists("is_full_url")) {
    function is_full_url($url)
    {
        return strpos($url, "http://") === 0 || strpos($url, "https://") === 0;
    }
}

$src = isset($images["src"]) && is_full_url($images["src"]) ? $images["src"] : (function_exists("vite_src_images") ? vite_src_images($images["src"]) : "");
?>

<?php if (defined("IS_TYPE") && IS_TYPE === "production" && function_exists("vite_src_images")): ?>
  <source srcset="<?= vite_src_images($images["src"], "avif") ?>" type="image/avif" />
<?php endif; ?>
<img
  src="<?= esc_url($src) ?>"
  width="<?= esc_attr($images["width"] ?? "") ?>"
  height="<?= esc_attr($images["height"] ?? "") ?>"
  alt="<?= esc_attr($images["alt"] ?? "") ?>"
  loading="<?= $lazy ? "lazy" : "eager" ?>"
  decoding="async"
  class="<?= esc_attr($images["class"] ?? "") ?>"
  <?php if (!empty($images["data"]) && is_array($images["data"])):
      foreach ($images["data"] as $key => $value): ?>
      data-<?= esc_attr($key) ?>="<?= esc_attr($value) ?>"
    <?php endforeach;
  endif; ?>
/>
