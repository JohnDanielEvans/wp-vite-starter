<?php

/**
 * variables
 */

define("URL_ASSETS", get_template_directory_uri() . "/assets/");
define("URL_CSS", URL_ASSETS . "css/");
define("URL_JS", URL_ASSETS . "js/");
define("URL_IMAGES", URL_ASSETS . "images/");

// url
define("URL_HOME", home_url("/"));
define("URL_ABOUT", URL_HOME . "about/");
define("URL_ARCHIVE", URL_HOME . "works/");
define("URL_PRIVACY", URL_HOME . "privacy/");

// external url
define("URL_CONTACT", home_url("/#contact"));

// Returns local in the local environment and production in the production environment.
define("IS_TYPE", wp_get_environment_type());
define("IS_TYPE_LOCAL", IS_TYPE === "local" ? true : false);
define("IS_TYPE_PRODUCTION", IS_TYPE === "production" ? true : false);

define("URL_STATIC", IS_TYPE === "local" ? "http://localhost:3030/static/" : get_theme_file_uri("/assets/images/"));
define("URL_FAVICON", URL_STATIC . "favicon.ico");
define("URL_TOUCH_ICON", URL_STATIC . "apple-touch-icon.png");
