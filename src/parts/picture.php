<?php
/**
 * Responsive image part.
 *
 * Emits a <picture> with AVIF and WebP sources for built raster images, falling
 * back to the original file. In local dev it emits a plain <img> pointing at the
 * Vite dev server, since the converted variants only exist after a build.
 *
 * Usage:
 *   get_template_part("./parts/picture", null, [
 *       "images" => ["src" => "hero.jpg", "width" => 800, "height" => 560, "alt" => ""],
 *       "lazy"   => true,
 *   ]);
 *
 * "src" is a filename inside src/assets/images/, or a full URL to use as-is.
 */

$images = $args["images"] ?? [];
$lazy = $args["lazy"] ?? false;

if (!function_exists("wpvs_is_full_url")) {
    function wpvs_is_full_url($url)
    {
        return strpos($url, "http://") === 0 || strpos($url, "https://") === 0;
    }
}

$raw = $images["src"] ?? "";
$is_full = $raw !== "" && wpvs_is_full_url($raw);
$has_helper = function_exists("wpvs_vite_src_images");

$src = $is_full ? $raw : ($has_helper ? wpvs_vite_src_images($raw) : "");

// Only raster sources have .avif/.webp variants — convert.images.mjs skips
// everything else. Declaring type="image/avif" on an SVG makes the browser
// trust the type and fail to decode it, so restrict the <source> tags.
$is_raster = (bool) preg_match('/\.(jpe?g|png)$/i', $raw);
$use_sources = !$is_full && $is_raster && $has_helper && defined("IS_TYPE") && IS_TYPE !== "local";
?>

<?php if ($use_sources): ?>
<picture>
  <source srcset="<?= esc_url(wpvs_vite_src_images($raw, "avif")) ?>" type="image/avif" />
  <source srcset="<?= esc_url(wpvs_vite_src_images($raw, "webp")) ?>" type="image/webp" />
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
<?php if ($use_sources): ?>
</picture>
<?php endif; ?>
