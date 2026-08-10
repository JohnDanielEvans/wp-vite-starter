/**
 * Convert images to WebP and AVIF using sharp.
 * https://sharp.pixelplumbing.com/
 *
 * Walks the source image directory and, for every JPEG and PNG, writes WebP and
 * AVIF variants into the output directory. The original is copied across as
 * well, so `parts/picture.php` always has a fallback source to point at. Files
 * in any other format are copied through untouched.
 */

import sharp from "sharp";
import { globSync } from "glob";
import path from "path";
import fse from "fs-extra";

const sharpOption = {
  effort: 0,
  quality: 60,
};

const srcDir = "src/assets/images";
const distDir = "dist/assets/images";

(async () => {
  // Do NOT empty distDir: Vite has already emitted hashed assets (SVG sprite
  // output, inlined imports) here. Emptying it silently drops them from the
  // packaged theme. Ensure it exists and write alongside.
  await fse.ensureDirSync(distDir);
  const images = globSync(`${srcDir}/*`);

  for (const image of images) {
    const parse = path.parse(image);
    const name = parse.name;
    const extension = parse.ext;

    if (extension === ".jpg" || extension === ".jpeg" || extension === ".png") {
      const webpFile = `${distDir}/${name}.webp`;
      const avifFile = `${distDir}/${name}.avif`;

      await sharp(image).webp(sharpOption).toFile(webpFile);
      await sharp(image).avif(sharpOption).toFile(avifFile);
      await fse.copySync(image, `${distDir}/${parse.base}`);
    } else {
      await fse.copySync(image, `${distDir}/${parse.base}`);
    }
  }
})();
