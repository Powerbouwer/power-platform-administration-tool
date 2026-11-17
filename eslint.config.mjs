import { defineConfig, globalIgnores } from "eslint/config";
import globals from "globals";
import html from "eslint-plugin-html";
import js from "@eslint/js";
import microsoftPowerApps from "@microsoft/eslint-plugin-power-apps";

export default defineConfig([
  globalIgnores([
    "**/node_modules/**",
    "**/.vitepress/dist/**",
    "**/.vitepress/cache/**",
    "**/naming-reports/**",
  ]),

  // Node.js specific configuration
  {
    extends: ["js/all"],
    files: ["**/*.{js,mjs,cjs}", "!**/webresources/**"],
    languageOptions: { globals: globals.node },
    plugins: { js },
  },
  // Webresources specific configuration.
  // These are specific to webresources and include both JavaScript and HTML files.
  // This configuration ensures that webresources follow the correct linting rules for browser-based code.
  // Webresources do not use Node.js to import modules and run code, they are intended for browser environments.
  {
    extends: ["js/all", "@microsoft/power-apps/paCheckerHosted"],
    files: ["**/webresources/**/*.{js,mjs,cjs,html,htm}"],
    languageOptions: { globals: { Xrm: "readonly" } },
    plugins: { "@microsoft/power-apps": microsoftPowerApps, html, js },
  },
]);
