import globals from "globals";
import tsEslint from "typescript-eslint";
import eslint from "@eslint/js";
import eslintPrettier from "eslint-config-prettier";

export default tsEslint.config(
  eslint.configs.recommended,
  ...tsEslint.configs.recommendedTypeChecked,
  {
    ignores: [
      "_build/",
      "deps/",
      "local_deps/",
      "priv/static/",
      "assets/vendor/",
      "playwright/report/",
      "playwright/*.config.js",
    ],
  },
  {
    rules: {
      // See https://eslint.org/docs/latest/rules/no-warning-comments
      "no-warning-comments": [
        "error",
        {
          terms: [
            "broken",
            "bug",
            "error",
            "fixme",
            "hack",
            "optimize",
            "optimise",
            "review",
            "wtf",
            "xxx",
          ],
          location: "start",
          decoration: ["/", "*"],
        },
      ],
      "no-unused-vars": ["error", { argsIgnorePattern: "^_" }],
      "@typescript-eslint/no-unused-vars": "off",
      "no-console": "error",
    },
  },
  {
    files: ["**/*.js"],
    ...tsEslint.configs.disableTypeChecked,
  },
  {
    files: ["**/assets/css/**/*.js"],
    ...tsEslint.configs.disableTypeChecked,
    languageOptions: {
      globals: { require: true, module: true, __dirname: true },
    },
    rules: {
      "@typescript-eslint/no-require-imports": "off",
    },
  },
  {
    files: ["**/assets/js/**/*.js"],
    languageOptions: { globals: { ...globals.browser } },
  },
  {
    files: ["**/*.ts"],
    languageOptions: {
      parserOptions: {
        project: true,
      },
    },
    rules: {
      "no-unused-vars": "off",
      "@typescript-eslint/no-unused-vars": ["error", { argsIgnorePattern: "^_" }],
    },
  },
  eslintPrettier,
);
