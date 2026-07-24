import { gsap } from "gsap";
import { cubicBezier } from "./utility/cubic-bezier";

gsap.ticker.fps(60);

export const BREAKPOINT = 768;
export const BESTVIEW = {
  x: 1280,
  y: 800,
};

export const IS_TYPE_LOCAL = document.querySelector("body").dataset.type === "local" ? true : false;

// Duration
export const DURASION = {
  SHORT: 0.3,
  BASE: 0.4,
  FULL: 0.6,
  SCROLL: 1.0,
};

// Easing — mirrors $easing-transform / $easing-material in base/_variables.scss
export const EASING = {
  TRANSFORM: cubicBezier(0.43, 0.05, 0.17, 1),
  MATERIAL: cubicBezier(0.26, 0.16, 0.1, 1),
};
