# ESLint Setup — From Zero to Enforced Linting

## Context

The project currently has **no ESLint installation, no config, no lint script**. Code quality is enforced only through Prettier (formatting) and code review. There is no static analysis catching bugs, enforcing Angular best practices, or preventing regressions like direct `console.*` calls.

The project runs Angular 17.3.10 with TypeScript 5.2.2. Prettier 3.7.4 is already configured (`.prettierrc.json`, `.prettierignore`).

---

## Approach

### Phase 1: Install and Configure

#### 1.1 Install Dependencies

```bash
ng add @angular-eslint/schematics
```

This installs:
- `eslint`
- `@angular-eslint/builder`
- `@angular-eslint/eslint-plugin`
- `@angular-eslint/eslint-plugin-template`
- `@angular-eslint/template-parser`
- `@typescript-eslint/eslint-plugin`
- `@typescript-eslint/parser`

And creates an initial `eslint.config.js` (flat config format, the modern default).

Also install Prettier integration to avoid formatting conflicts:
```bash
npm install --save-dev eslint-config-prettier
```

#### 1.2 Create ESLint Configuration

Use flat config format (`eslint.config.js`) since legacy `.eslintrc` is deprecated.

Start with the `@angular-eslint` recommended preset, add `eslint-config-prettier` to disable formatting rules that conflict with Prettier, then layer on project-specific rules incrementally.

```javascript
// eslint.config.js (skeleton)
const angular = require("angular-eslint");
const tseslint = require("typescript-eslint");

module.exports = tseslint.config(
  // Base TypeScript + Angular presets
  ...tseslint.configs.recommended,
  ...angular.configs.tsRecommended,
  ...angular.configs.templateRecommended,

  // Prettier compat — disables formatting rules
  require("eslint-config-prettier"),

  // Project-specific overrides
  {
    files: ["src/**/*.ts"],
    rules: {
      // Phase 2 rules go here
    },
  },
  {
    files: ["src/**/*.html"],
    rules: {
      // Template rules go here
    },
  },

  // Ignore patterns
  {
    ignores: ["node_modules/", "dist/", "coverage/", "cypress/"],
  }
);
```

#### 1.3 Add Lint Script to `package.json`

```json
"scripts": {
  "lint": "ng lint",
  "lint:fix": "ng lint --fix"
}
```

#### 1.4 Update `angular.json`

The `ng add @angular-eslint/schematics` command should add the lint architect target automatically. Verify it creates:

```json
"lint": {
  "builder": "@angular-eslint/builder:lint",
  "options": {
    "lintFilePatterns": ["src/**/*.ts", "src/**/*.html"]
  }
}
```

---

### Phase 2: Rule Rollout Strategy

Do NOT enable all rules at once. The codebase has never been linted — enabling everything will produce thousands of violations and be impossible to review. Instead, roll out rules in waves.

#### Wave 1 — Low-noise, high-value (enable immediately)

These rules catch real bugs with minimal false positives:

```javascript
rules: {
  "no-console": "error",                          // Already prepared with eslint-disable comments (Task 01)
  "no-debugger": "error",                          // No debugger statements in production
  "no-duplicate-case": "error",                    // Duplicate switch cases
  "no-empty": ["error", { allowEmptyCatch: false }], // Empty blocks (aligns with Task 04)
  "no-constant-condition": "error",                // if(true), while(true)
  "no-unreachable": "error",                       // Code after return/throw
  "prefer-const": "error",                         // let → const where not reassigned
  "@typescript-eslint/no-unused-vars": ["error", { argsIgnorePattern: "^_" }],
  "@angular-eslint/no-empty-lifecycle-method": "error",
  "@angular-eslint/use-lifecycle-interface": "error",
}
```

For `no-console`: The error handling task (`.agents/tasks/errorhandling/01-centralized-logging.md`) already migrated most console calls to LoggerService and added `// eslint-disable-next-line no-console` to the ~8 approved exceptions. This rule should work out of the box.

#### Wave 2 — Style consistency (enable after initial cleanup)

```javascript
rules: {
  "@typescript-eslint/explicit-function-return-type": "off",  // Too noisy for existing code
  "@typescript-eslint/no-explicit-any": "warn",               // Start as warn, promote to error over time
  "@angular-eslint/component-selector": ["error", { type: "element", prefix: "app", style: "kebab-case" }],
  "@angular-eslint/directive-selector": ["error", { type: "attribute", prefix: "nj", style: "camelCase" }],
}
```

#### Wave 3 — Strictness (enable progressively)

```javascript
rules: {
  "@typescript-eslint/no-explicit-any": "error",   // Promoted from warn
  "@typescript-eslint/strict-boolean-expressions": "warn",
}
```

---

### Phase 3: Handle Existing Violations

After enabling Wave 1 rules, run `ng lint` and triage violations:

1. **Auto-fixable** (`prefer-const`, some `no-unused-vars`): Run `ng lint --fix`
2. **Quick manual fixes** (empty lifecycle methods, unreachable code): Fix in batches
3. **Larger fixes** (`no-explicit-any`, complex unused vars): Add `// eslint-disable-next-line` with TODO comments, create follow-up tasks

Do NOT mass-suppress violations. Each `eslint-disable` should have a reason comment.

---

### Phase 4: CI Integration

Add linting to the CI pipeline so violations block merges:

```yaml
# In CI config (GitHub Actions, Jenkins, etc.)
- run: npm run lint
```

This ensures no new violations land after the initial cleanup.

---

## Files to Create/Modify

**New files:**
- `eslint.config.js` — ESLint flat config

**Modified files:**
- `package.json` — Add ESLint dependencies + lint scripts
- `angular.json` — Add lint architect target

---

## Edge Cases

- **Prettier conflicts**: `eslint-config-prettier` disables all formatting-related ESLint rules. Prettier handles formatting, ESLint handles logic. No overlap.
- **HTML templates**: `@angular-eslint/template-parser` handles `.html` files. Template rules are separate from TypeScript rules.
- **Test files**: Consider relaxing some rules for `.spec.ts` files (e.g., `no-console`, `@typescript-eslint/no-explicit-any`). Add a separate config block for test files.
- **Cypress files**: Exclude from linting initially (`ignores: ["cypress/"]`). Can add `eslint-plugin-cypress` later.
- **Generated files**: Exclude `dist/`, `coverage/`, any auto-generated code.

---

## Execution Order

1. Install dependencies via `ng add @angular-eslint/schematics` + `eslint-config-prettier`
2. Create `eslint.config.js` with Wave 1 rules only
3. Run `ng lint` — assess violation count
4. Auto-fix what's possible (`ng lint --fix`)
5. Manually fix remaining Wave 1 violations in batches
6. Add `npm run lint` to CI
7. Enable Wave 2 rules after stabilization
8. Enable Wave 3 rules progressively

---

## Verification

1. `ng lint` exits with 0 (no violations)
2. `ng build` still works (ESLint doesn't affect build)
3. `npm run test:prod` — Tests still pass
4. Prettier and ESLint don't conflict — run both and verify no ping-pong formatting
5. CI blocks PRs with lint violations

---

## Dependencies

- **Task errorhandling/01** (Centralized Logging) should be done first so that `no-console` rule works cleanly out of the box with pre-placed `eslint-disable` comments.
- Coordinate with existing `.agents/tasks/20260402-type-safety-eslint` task if it overlaps with type-safety rules here.

---

## Estimated Scope

- ~1 hour for installation and config setup
- Wave 1 violation count: Unknown until first `ng lint` run. Expect 50-200 violations, most auto-fixable.
- Full rollout through Wave 3: Multiple sessions over weeks, done incrementally.
