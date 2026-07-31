import js from "@eslint/js";
import tseslint from "typescript-eslint";

export default tseslint.config({
	ignores: ["dist/**", "*.mjs"],
	...js.configs.recommended,
	...tseslint.configs.recommendedTypeChecked,
	languageOptions: {
		parserOptions: {
			projectService: true,
			tsconfigRootDir: new URL(".", import.meta.url).pathname,
		},
	},
	rules: {
		// Structural rules that protect the product, not style preferences.
		// A floating promise in a Lambda means the invocation ends before
		// the write completes. Silent data loss, impossible to reproduce.
		"@typescript-eslint/no-floating-promises": "error",
		"@typescript-eslint/await-thenable": "error",
		"@typescript-eslint/require-await": "error",
		// `as any` is how tenant isolation quietly stops being enforced.
		"@typescript-eslint/no-explicit-any": "error",
		"@typescript-eslint/no-unsafe-assignment": "warn",
		"@typescript-eslint/no-unsafe-member-access": "warn",
		"no-console": "error", // use the logger, so lines are JSON and queryable
		eqeqeq: ["error", "always"],
		"@typescript-eslint/no-unused-vars": [
			"error",
			{ argsIgnorePattern: "^_", varsIgnorePattern: "^_" },
		],
	},
});