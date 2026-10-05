import { hamburgerMenu } from "./modules/hamburger-menu";
import { loadMore } from "./modules/load-more";
import { viewportFix, viewportSize } from "./utility/viewport";
import 'aos/dist/aos.css';
import AOS from 'aos';

document.addEventListener("DOMContentLoaded", () => {
  const menu = document.querySelector('.global-hamburger-menu');
  if (menu) {
    menu.style.removeProperty('display');
  }
  hamburgerMenu();
  loadMore();
});

// viewport-related logic on full page load
window.addEventListener("load", () => {
  viewportSize();
  viewportFix();

  // Initialize AOS with modern settings
  setTimeout(() => {
    AOS.init({
      duration: 800,
      once: true,
      mirror: false,
      offset: 50,
      easing: 'ease-out-cubic',
    });
    AOS.refreshHard();
  }, 100);

  // Show header with animation
  document.querySelector(".global-header")?.classList.add("header-loaded");

  // Remove loading curtain
  const curtain = document.getElementById('curtain-loader');
  if (curtain) {
    setTimeout(() => {
      curtain.classList.add('loaded');
    }, 600);
  }
});

window.addEventListener("resize", () => {
  viewportSize();
  viewportFix();
  AOS.refresh();
});

// Modern scroll-based header behavior
(function() {
  const header = document.querySelector(".global-header");
  if (!header) return;

  let lastScrollY = 0;
  let ticking = false;
  const scrollThreshold = 100;
  const hideThreshold = 15;

  function updateHeader() {
    const currentScrollY = window.scrollY;
    
    // Add/remove scrolled class for styling
    if (currentScrollY > scrollThreshold) {
      header.classList.add("scrolled");
    } else {
      header.classList.remove("scrolled");
    }
    
    // Hide/show header on scroll direction
    const scrollDelta = currentScrollY - lastScrollY;
    
    if (Math.abs(scrollDelta) > hideThreshold) {
      if (scrollDelta > 0 && currentScrollY > scrollThreshold) {
        // Scrolling down - hide header
        header.style.transform = "translateY(-100%)";
      } else {
        // Scrolling up - show header
        header.style.transform = "translateY(0)";
      }
      lastScrollY = currentScrollY;
    }
    
    ticking = false;
  }

  window.addEventListener("scroll", () => {
    if (!ticking) {
      requestAnimationFrame(updateHeader);
      ticking = true;
    }
  }, { passive: true });
})();

// Smooth scroll for anchor links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
  anchor.addEventListener('click', function (e) {
    const targetId = this.getAttribute('href');
    if (targetId === '#') return;
    
    const targetElement = document.querySelector(targetId);
    if (targetElement) {
      e.preventDefault();
      const headerHeight = document.querySelector('.global-header')?.offsetHeight || 0;
      const targetPosition = targetElement.getBoundingClientRect().top + window.pageYOffset - headerHeight;
      
      window.scrollTo({
        top: targetPosition,
        behavior: 'smooth'
      });
    }
  });
});
