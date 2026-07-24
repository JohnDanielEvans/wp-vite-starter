/**
 * Minimal cubic-bezier easing factory.
 *
 * Returns a `(t) => progress` function suitable for use as a GSAP `ease`,
 * matching the same curve you would write as CSS `cubic-bezier(x1, y1, x2, y2)`.
 *
 * Solves x(t) = target via Newton-Raphson with a bisection fallback, then
 * evaluates y at the recovered parameter.
 */

const A = (a1, a2) => 1 - 3 * a2 + 3 * a1;
const B = (a1, a2) => 3 * a2 - 6 * a1;
const C = (a1) => 3 * a1;

// Horner-form evaluation of the bezier polynomial.
const calcBezier = (t, a1, a2) => ((A(a1, a2) * t + B(a1, a2)) * t + C(a1)) * t;

// Derivative, used by Newton-Raphson.
const getSlope = (t, a1, a2) => 3 * A(a1, a2) * t * t + 2 * B(a1, a2) * t + C(a1);

export function cubicBezier(x1, y1, x2, y2) {
  // Linear shortcut — no solving needed.
  if (x1 === y1 && x2 === y2) return (t) => t;

  return function ease(x) {
    if (x <= 0) return 0;
    if (x >= 1) return 1;

    let t = x;

    // Newton-Raphson: fast when the curve is well behaved.
    for (let i = 0; i < 8; i++) {
      const slope = getSlope(t, x1, x2);
      if (slope === 0) break;
      const error = calcBezier(t, x1, x2) - x;
      t -= error / slope;
    }

    // Bisection fallback for the flat-slope cases Newton misses.
    if (t < 0 || t > 1) {
      let lo = 0;
      let hi = 1;
      t = x;
      while (hi - lo > 1e-7) {
        if (calcBezier(t, x1, x2) < x) {
          lo = t;
        } else {
          hi = t;
        }
        t = (lo + hi) / 2;
      }
    }

    return calcBezier(t, y1, y2);
  };
}
