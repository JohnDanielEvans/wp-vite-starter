/**
 * Suppress the default action for an event.
 * @param {object} e The event object.
 */
const preventEvent = (e) => {
  e.preventDefault();
};

/**
 * @description Block scrolling.
 */
const scrollEventNone = () => {
  document.addEventListener("wheel", preventEvent, { passive: false });
  document.addEventListener("scroll", preventEvent, { passive: false });
  document.addEventListener("touchmove", preventEvent, { passive: false });
  document.addEventListener("keydown", preventEvent, { passive: false });
};

/**
 * @description Restore scrolling.
 */
const scrollEventAuto = () => {
  document.removeEventListener("wheel", preventEvent, { passive: false });
  document.removeEventListener("scroll", preventEvent, { passive: false });
  document.removeEventListener("touchmove", preventEvent, { passive: false });
  document.removeEventListener("keydown", preventEvent, { passive: false });
};

/**
 * Toggle background scroll locking.
 * @description Locks the page behind an overlay. Note this blocks scrolling
 * everywhere, including inside the overlay itself — if the overlay content needs
 * to scroll, position it `fixed` or handle its scrolling separately.
 * @param {boolean} state true locks scrolling, false restores it.
 */
export const disableNativeScroll = (state) => {
  state ? scrollEventNone() : scrollEventAuto();
};
