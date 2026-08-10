// vite.config.mjs
import path from "path";
import { defineConfig } from "vite";
import VitePluginBrowserSync from "vite-plugin-browser-sync";
import svgSpritePluginCjs from "vite-plugin-svg-sprite-component";

// vite-plugin-svg-sprite-component is CommonJS with `exports.default`. Loaded as
// real ESM (this file is .mjs) Node hands back the module object rather than the
// factory, so the callable lives one level down. The `??` keeps this working if
// the package ever ships a proper ESM build.
const svgSpritePlugin = svgSpritePluginCjs.default ?? svgSpritePluginCjs;

export default defineConfig({
  optimizeDeps: {
    include: ["rellax", "keen-slider"]
  },
  publicDir: "public",
  plugins: [
    svgSpritePlugin(),
    VitePluginBrowserSync({
      dev: {
        bs: {
          proxy: "http://localhost:8000",
          serveStatic: ["public"],
          ui: false,
          port: 3031,
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
      input: {
        app: path.resolve(import.meta.dirname, `src/assets/app.js`),
        "front-page": path.resolve(import.meta.dirname, `src/assets/js/front-page.js`),
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
    port: 3030,
    https: false,
    fs: {
      strict: false,
    },
    proxy: {
      "/api": {
        target: "http://localhost:8000",
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
