/**
 * Progressive "load more" for a post archive.
 *
 * Expects markup like:
 *   <div data-load-more-list></div>
 *   <button data-load-more action="wpvs_load_more_works">Load more</button>
 *
 * Server side: src/functions/ajax.php
 */

export function loadMore() {
  const button = document.querySelector("[data-load-more]");
  const list = document.querySelector("[data-load-more-list]");

  if (!button || !list || !window.ajax_object) return;

  // Progressive enhancement: the server renders a normal pager so the archive
  // is fully navigable without JavaScript. Once this takes over, that pager
  // would disagree with the growing list, so it goes.
  document.querySelector(".archive-works__pagination")?.remove();

  const action = button.getAttribute("action") || "wpvs_load_more_works";
  let page = 1;
  let busy = false;

  button.addEventListener("click", async () => {
    if (busy) return;
    busy = true;
    button.disabled = true;

    try {
      const body = new URLSearchParams({
        action,
        page: String(page + 1),
        nonce: window.ajax_object.nonce,
      });

      const response = await fetch(window.ajax_object.ajaxurl, {
        method: "POST",
        credentials: "same-origin",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body,
      });

      if (!response.ok) throw new Error(`Request failed: ${response.status}`);

      const payload = await response.json();
      if (!payload.success) throw new Error("Server reported failure");

      list.insertAdjacentHTML("beforeend", payload.data.html);
      page = payload.data.page;

      // Remove the control entirely once the last page is in — leaving a
      // disabled button reads as broken.
      if (!payload.data.has_more) button.remove();
    } catch (error) {
      // Surfacing a failed fetch is the only feedback available here; the
      // button is re-enabled below so the visitor can retry.
      // eslint-disable-next-line no-console
      console.error("load-more:", error);
      button.disabled = false;
    } finally {
      busy = false;
    }
  });
}
