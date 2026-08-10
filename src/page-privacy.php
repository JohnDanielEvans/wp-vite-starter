<?php
/**
 * Privacy policy page template.
 *
 * The copy below is placeholder scaffolding that exists to demonstrate the
 * markup and styling hooks — it is NOT a privacy policy and has no legal
 * standing. Replace every section with your own, and have it reviewed by
 * someone qualified before the site goes live. WordPress also ships a policy
 * generator under Settings → Privacy that is a better starting point than this.
 */
get_template_part("./parts/global-header"); ?>

<div class="privacy">
  <div class="privacy__bg">
    <div class="container">
      <?php get_template_part("./parts/heading-page", null, [
          "title" => "PRIVACY POLICY",
      ]); ?>
      <div class="privacy__inner">
        <p class="privacy__text">
          Placeholder introduction. Describe who operates this site and what this
          policy covers, then replace the sections below with your own terms.
        </p>
        <div class="privacy__wrapper">
          <div class="privacy__contents">
            <h2 class="privacy__contents__title">Section 1 — What we collect</h2>
            <p class="privacy__contents__text">Placeholder body copy. Replace this with a description of the personal information the site collects.</p>
          </div>
          <div class="privacy__contents">
            <h2 class="privacy__contents__title">Section 2 — How we collect it</h2>
            <p class="privacy__contents__text">Placeholder body copy. Replace this with a description of how that information is gathered.</p>
          </div>
          <div class="privacy__contents">
            <h2 class="privacy__contents__title">Section 3 — How we use it</h2>
            <p class="privacy__contents__text">Placeholder body copy. Replace this with the purposes the information is used for. An unordered list renders like so:</p>
            <ul>
              <li>Placeholder list item</li>
              <li>Placeholder list item</li>
              <li>Placeholder list item</li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>

<?php get_template_part("./parts/global-footer");
?>
