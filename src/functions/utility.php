<?php

/**
 * utility functions
 */

/**
 * Render a reference to a symbol in the SVG sprite.
 *
 * Both arguments are escaped. Today every call site passes a literal, but this
 * is a starter theme: the moment someone passes a post field or a query value
 * through here, unescaped interpolation into an attribute is an XSS hole.
 *
 * @param string $name Symbol id within the sprite.
 * @param string $alt  Accessible name. Pass "" for decorative icons.
 * @return string
 */
function wpvs_get_svg_sprite($name, $alt = "")
{
    $name = esc_attr($name);

    // A decorative icon with an empty aria-label is still announced by some
    // screen readers, so hide it instead of labelling it with nothing.
    $label = $alt === "" ? ' aria-hidden="true"' : ' aria-label="' . esc_attr($alt) . '"';

    // href is the SVG2 attribute; xlink:href is retained alongside it because
    // Safari below 12 ignores the modern one.
    return '<svg class="svg-sprited svg-' . $name . '" role="img"' . $label . ">" . '<use href="#' . $name . '" xlink:href="#' . $name . '" />' . "</svg>";
}
