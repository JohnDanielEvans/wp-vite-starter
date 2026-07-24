// modules/front-slider.js
import KeenSlider from "keen-slider";

export function initFrontPageSliders() {
  function updateCurrentSlide(sliderInstance, sliderSelector) {
    const details = sliderInstance.track.details;
    const slides = document.querySelectorAll(`${sliderSelector} .keen-slider__slide`);
    const perView = sliderInstance.options.slides.perView || 1;
    const centerOffset = Math.floor(perView / 2);
    const centeredSlideIndex = (details.rel + centerOffset) % slides.length;

    slides.forEach((slide) => slide.classList.remove("active"));
    const centeredSlide = slides[centeredSlideIndex];
    if (centeredSlide) centeredSlide.classList.add("active");
  }

  function initializeSlider(sliderSelector, options = {}) {
    const sliderElement = document.querySelector(sliderSelector);
    
    // Check if the slider element exists before initializing
    if (!sliderElement) {
      return null;
    }

    // Check if there are slides inside
    const slides = sliderElement.querySelectorAll('.keen-slider__slide');
    if (slides.length === 0) {
      return null;
    }

    const slider = new KeenSlider(sliderSelector, {
      loop: true,
      mode: "snap",
      centered: true,
      slides: {
        origin: "center",
        perView: 1,
        spacing: 25,
      },
      breakpoints: {
        "(min-width: 768px)": {
          slides: { perView: 2, spacing: 20 },
        },
        "(min-width: 1024px)": {
          slides: { perView: 3, spacing: 25 },
        },
      },
      ...options,
      created(s) {
        updateCurrentSlide(s, sliderSelector);
        addArrowNavigation(s, sliderSelector);
        window.addEventListener("resize", () => updateCurrentSlide(s, sliderSelector));
        addSlideClickListeners(s, sliderSelector);
      },
      slideChanged(s) {
        updateCurrentSlide(s, sliderSelector);
      },
    });

    window.addEventListener("load", () => {
      slider.update();
      updateCurrentSlide(slider, sliderSelector);
    });

    return slider;
  }

  function addSlideClickListeners(sliderInstance, sliderSelector) {
    const slides = document.querySelectorAll(`${sliderSelector} .keen-slider__slide`);
    slides.forEach((slide, index) => {
      slide.addEventListener("click", () => {
        const details = sliderInstance.track.details;
        const currentCenteredIndex = Math.round(details.abs);
        if (index !== currentCenteredIndex) sliderInstance.moveToIdx(index);
      });
    });
  }

  function addArrowNavigation(sliderInstance, sliderSelector) {
    const sliderElement = document.querySelector(sliderSelector);
    if (!sliderElement || !sliderElement.parentNode) return;

    const leftArrow = document.createElement("button");
    leftArrow.classList.add("arrow", "arrow--left");
    leftArrow.innerHTML = "&#9664;";
    leftArrow.addEventListener("click", () => sliderInstance.prev());

    const rightArrow = document.createElement("button");
    rightArrow.classList.add("arrow", "arrow--right");
    rightArrow.innerHTML = "&#9654;";
    rightArrow.addEventListener("click", () => sliderInstance.next());

    sliderElement.parentNode.appendChild(leftArrow);
    sliderElement.parentNode.appendChild(rightArrow);
  }

  // Initialize sliders only if they exist
  initializeSlider("#services-slider");
  initializeSlider("#products-slider");

  const testimonialsSlider = initializeSlider("#testimonials-slider", {
    slides: {
      perView: 1,
      spacing: 15,
    },
    breakpoints: {
      "(min-width: 768px)": {
        slides: { perView: 1, spacing: 20 },
      },
      "(min-width: 1024px)": {
        slides: { perView: 1, spacing: 25 },
      },
    },
  });

  // Only set up autoplay if testimonials slider was initialized
  if (testimonialsSlider) {
    let autoplayInterval;
    function startAutoplay() {
      autoplayInterval = setInterval(() => testimonialsSlider.next(), 5000);
    }
    function stopAutoplay() {
      clearInterval(autoplayInterval);
    }

    const testimonialsSliderElement = document.querySelector("#testimonials-slider");
    if (testimonialsSliderElement) {
      testimonialsSliderElement.addEventListener("mouseenter", stopAutoplay);
      testimonialsSliderElement.addEventListener("mouseleave", startAutoplay);
      testimonialsSliderElement.addEventListener("click", stopAutoplay);
      startAutoplay();
    }
  }
}
