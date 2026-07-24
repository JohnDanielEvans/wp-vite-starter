import { disableNativeScroll } from "../utility/disable-native-scroll";

export const hamburgerMenu = () => {
  const body = document.querySelector("body");
  const menu = document.querySelector(".js-global-hamburger-menu");
  const btn = document.querySelector(".js-global-hamburger-menu-btn");
  let isOpen = false;

  const openMenu = () => {
    disableNativeScroll(true);
    body.classList.add("is-hamburger-menu-open");
    btn.setAttribute("aria-expanded", "true");
    btn.setAttribute("aria-label", "Close Menu");
    menu.classList.add("is-open");
    menu.setAttribute("aria-hidden", "false");

    // Optional: close menu when clicking any nav link inside it
    const links = menu.querySelectorAll("a");
    links.forEach((link) => {
      link.addEventListener("click", closeMenu);
    });
  };

  const closeMenu = () => {
    disableNativeScroll(false);
    body.classList.remove("is-hamburger-menu-open");
    btn.setAttribute("aria-expanded", "false");
    btn.setAttribute("aria-label", "Open Menu");
    menu.classList.remove("is-open");
    menu.setAttribute("aria-hidden", "true");
  };

  btn.addEventListener("click", () => {
    isOpen = !isOpen;
  
    if (isOpen) {
      openMenu();
    } else {
      closeMenu();
    }
  });
};
document.addEventListener("DOMContentLoaded", function () {
  const productTrigger = document.querySelector("#nav-menu-item-19"); // Products
  const productDropdown = document.querySelector(".custom-products-dropdown");
  
  const servicesTrigger = document.querySelector("#nav-menu-item-18"); // Services
  const servicesDropdown = document.querySelector(".custom-services-dropdown");

  function setupDropdown(trigger, dropdown) {
    if (trigger && dropdown) {
      let timeout;

      const showDropdown = () => {
        dropdown.classList.add("is-visible");
        clearTimeout(timeout);
      };

      const hideDropdown = () => {
        timeout = setTimeout(() => {
          dropdown.classList.remove("is-visible");
        }, 200);
      };

      trigger.addEventListener("mouseenter", showDropdown);
      trigger.addEventListener("mouseleave", hideDropdown);
      dropdown.addEventListener("mouseenter", showDropdown);
      dropdown.addEventListener("mouseleave", hideDropdown);
    }
  }

  setupDropdown(productTrigger, productDropdown);
  setupDropdown(servicesTrigger, servicesDropdown);
});
