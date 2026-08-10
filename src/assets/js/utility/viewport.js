const viewport = document.querySelector('meta[name="viewport"]');

/**
 * @description Pin the viewport at 375px on narrower screens. Below that width
 * the layout would otherwise shrink past its minimum; locking the viewport lets
 * the device scale the page down instead of reflowing it.
 */
export const viewportFix = () => {
  const value = window.outerWidth > 375 ? "width=device-width,initial-scale=1" : "width=375";
  if (viewport.getAttribute("content") !== value) viewport.setAttribute("content", value);
};

/**
 * @description Publish the viewport size as the `--vw` / `--vh` custom
 * properties, each holding 1% of the respective dimension. Use these instead of
 * the `vh` unit on mobile, where the browser chrome makes `100vh` taller than
 * the visible area.
 */
export const viewportSize = () => {
  const vw = window.innerWidth * 0.01;
  const vh = window.innerHeight * 0.01;

  document.documentElement.style.setProperty("--vw", `${vw}px`);
  document.documentElement.style.setProperty("--vh", `${vh}px`);
};
