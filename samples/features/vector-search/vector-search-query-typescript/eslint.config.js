// @ts-check
import eslint from "@eslint/js";
import tseslint from "typescript-eslint";

export default tseslint.config(
  {
    ignores: ["dist/**", "node_modules/**", "output/**"],
  },
  eslint.configs.recommended,
  ...tseslint.configs.recommended,
  {
    rules: {
      // Sample code prints diagnostics and prompts to the console by design.
      "no-console": "off",
    },
  },
  {
    // Plain Node.js scripts (not type-checked TypeScript source).
    files: ["scripts/**/*.js"],
    languageOptions: {
      globals: {
        process: "readonly",
        console: "readonly",
      },
    },
  }
);
