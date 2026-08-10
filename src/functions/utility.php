<?php

/**
 * utility functions
 */

/**
 * @return SVG
 */
function wpvs_get_svg_sprite($name, $alt = "")
{
    return '<svg class="svg-sprited svg-' . $name . '" role="img" aria-label="' . $alt . '"><use xlink:href="#' . $name . '" /></svg>';
}
