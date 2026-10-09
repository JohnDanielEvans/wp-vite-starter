// vite.config.mjs
import path from "path";
import { defineConfig } from "vite";
import VitePluginBrowserSync from "vite-plugin-browser-sync";
import svgSpritePluginCjs from "vite-plugin-svg-sprite-component";
import { VITE_PORT, BROWSERSYNC_PORT, WP_URL } from "./scripts/ports.mjs";

// vite-plugin-svg-sprite-component is CommonJS with `exports.default`. Loaded as
// real ESM (this file is .mjs) Node hands back the module object rather than the
// factory, so the callable lives one level down. The `??` keeps this working if
// the package ever ships a proper ESM build.
const svgSpritePlugin = svgSpritePluginCjs.default ?? svgSpritePluginCjs;

// Ports come from .env (or the environment), not from literals here, so two
// checkouts of this project can run side by side without editing config.
// See scripts/ports.mjs.

export default defineConfig({
  publicDir: "public",
  plugins: [
    svgSpritePlugin(),
    VitePluginBrowserSync({
      dev: {
        bs: {
          proxy: WP_URL,
          serveStatic: ["public"],
          ui: false,
          port: BROWSERSYNC_PORT,
          open: false,
          ghostMode: false,
        },
      },
    }),
  ],
  resolve: {
    alias: {
      "~bootstrap": path.resolve(import.meta.dirname, "node_modules/bootstrap"),
      "@assets": path.resolve(import.meta.dirname, "src/assets"),
      "@static": path.resolve(import.meta.dirname, "public/static"),
    },
  },
  build: {
    commonjsOptions: {
      include: [/node_modules/],
    },
    assetsInlineLimit: 0,
    outDir: path.resolve(import.meta.dirname, "./dist"),
    emptyOutDir: true,
    target: "es2018",
    rollupOptions: {
      // Add a page-level entry here and emit its tag in parts/global-footer.php.
      input: {
        app: path.resolve(import.meta.dirname, `src/assets/app.js`),
      },
      output: {
        entryFileNames: `assets/js/[name].js`,
        chunkFileNames: `assets/js/[name].js`,
        assetFileNames: ({ name }) => {
          if (/\.(gif|jpeg|jpg|png|svg|webp)$/.test(name ?? "")) {
            return "assets/images/[name][extname]";
          }
          if (/\.css$/.test(name ?? "")) {
            return "assets/css/[name][extname]";
          }
          if (/\.js$/.test(name ?? "")) {
            return "assets/js/[name][extname]";
          }
          return "assets/[name][extname]";
        },
        manualChunks(id) {
          if (id.includes("node_modules")) {
            return "vendor";
          }
        },
      },
      preserveEntrySignatures: false
    },
  },
  css: {
    preprocessorOptions: {
      scss: {
        additionalData: "",
      },
    },
    devSourcemap: false,
  },
  server: {
    host: true,
    cors: true,
    strictPort: true,
    port: VITE_PORT,
    https: false,
    fs: {
      strict: false,
    },
    proxy: {
      "/api": {
        target: WP_URL,
        changeOrigin: true,
        secure: false,
      },
    },
    watch: {
      ignored: ["**/dist/**", "**/public/**", "**/static/**"],
    },
  },
  preview: {
    port: 3000,
  },
});
