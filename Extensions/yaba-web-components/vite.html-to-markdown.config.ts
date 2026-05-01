import { fileURLToPath } from "node:url"
import { defineConfig } from "vite"
import { nodePolyfills } from "vite-plugin-node-polyfills"
import { resolve } from "path"

const __dirname = fileURLToPath(new URL(".", import.meta.url))

/** Prepend to the IIFE so JavaScriptCore has minimal browser-like globals. */
const jscShim = `(function (g) {
  if (typeof g.globalThis === "undefined") g.globalThis = g;
  if (typeof g.window === "undefined") g.window = g;
  if (typeof g.self === "undefined") g.self = g;
  if (typeof g.document === "undefined")
    g.document = {
      createElement: function () { return {}; },
      createTextNode: function (t) { return { textContent: t }; },
      querySelector: function () { return null; },
      querySelectorAll: function () { return []; },
      addEventListener: function () {},
      removeEventListener: function () {}
    };
  if (typeof g.navigator === "undefined") g.navigator = { userAgent: "JavaScriptCore" };
  if (typeof g.location === "undefined") g.location = { href: "" };
  // The uuid npm package uses Web Crypto (getRandomValues / randomUUID); JavaScriptCore does not provide crypto by default.
  if (typeof g.crypto === "undefined" || typeof g.crypto.getRandomValues !== "function") {
    g.crypto = {
      getRandomValues: function (arr) {
        for (var i = 0; i < arr.length; i++) arr[i] = Math.floor(Math.random() * 256);
        return arr;
      },
    };
  }
})(
  typeof globalThis !== "undefined"
    ? globalThis
    : typeof self !== "undefined"
      ? self
      : typeof window !== "undefined"
        ? window
        : this
);
`

/**
 * Standalone IIFE for Darwin JavaScriptCore: linkedom + Readability, then unified + rehype + remark.
 * `vite-plugin-node-polyfills` supplies Buffer / process for the unified ecosystem.
 */
export default defineConfig({
  plugins: [
    nodePolyfills({
      include: [
        "buffer",
        "process",
        "util",
        "stream",
        "events",
        "string_decoder",
        "path",
      ],
      globals: {
        Buffer: true,
        global: true,
        process: true,
      },
    }),
  ],
  build: {
    emptyOutDir: false,
    minify: "esbuild",
    lib: {
      entry: resolve(__dirname, "src/html-to-markdown/main.ts"),
      name: "HTMLToMarkdown",
      formats: ["iife"],
      fileName: () => "html-to-markdown.bundle.min",
    },
    outDir: "dist",
    rollupOptions: {
      output: {
        entryFileNames: "html-to-markdown.bundle.min.js",
        extend: true,
        banner: jscShim,
      },
    },
  },
  resolve: {
    alias: {
      "@": resolve(__dirname, "src"),
    },
  },
})
