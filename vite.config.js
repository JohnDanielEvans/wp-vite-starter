// vite.config.js
import path from "path";
import { defineConfig } from "vite";
import VitePluginBrowserSync from "vite-plugin-browser-sync";
import svgSpritePlugin from "vite-plugin-svg-sprite-component";

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
      "~bootstrap": path.resolve(__dirname, "node_modules/bootstrap"),
      jquery: "jquery/dist/jquery.min.js",
      "@assets": path.resolve(__dirname, "src/assets"),
      "@static": path.resolve(__dirname, "public/static"),
    },
  },
  build: {
    commonjsOptions: {
      include: [/node_modules/],
    },
    assetsInlineLimit: 0,
    outDir: path.resolve(__dirname, "./dist"),
    emptyOutDir: true,
    target: "es2018",
    rollupOptions: {
      input: {
        app: path.resolve(__dirname, `src/assets/app.js`),
        "front-page": path.resolve(__dirname, `src/assets/js/front-page.js`),
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
