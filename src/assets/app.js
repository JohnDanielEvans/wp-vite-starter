// entry point
// include your assets here

// get styles
import "./css/app.scss";

// get scripts
import "./js/app.js";

// get svg
const svgs = import.meta.glob("./svg-sprite/*.svg");
for (const path in svgs) {
  svgs[path](); // Dynamically import each SVG
}

// // get images
// const images = import.meta.glob("./images/**");
