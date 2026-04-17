# Type Safety & ESLint Setup

## Context

The project has 456+ `any` type usages across 227 files, no ESLint configuration, several TypeScript strict options disabled (`strictPropertyInitialization`, `noImplicitThis`, `noUncheckedIndexedAccess`), and `angularCompilerOptions` (including `strictTemplates`) commented out. This task establishes linting infrastructure and a gradual type safety improvement path.

---

## Phase 1: ESLint Setup

### Step 1: Install Angular ESLint

```bash
ng add @angular-eslint/schematics
```

This adds:
- `@angular-eslint/builder`
- `@angular-eslint/eslint-plugin`
- `@angular-eslint/eslint-plugin-template`
- `@angular-eslint/template-parser`
- `@typescript-eslint/eslint-plugin`
- `@typescript-eslint/parser`

### Step 2: Configure Rules

Create `.eslintrc.json` with Angular-recommended rules plus:

```json
{
  "rules": {
    "@typescript-eslint/no-explicit-any": "warn",
    "@typescript-eslint/no-unused-vars": "warn",
    "@angular-eslint/prefer-on-push-component-change-detection": "warn",
    "@angular-eslint/use-lifecycle-interface": "error",
    "@angular-eslint/no-empty-lifecycle-method": "warn"
  }
}
```

Start with `warn` (not `error`) for `no-explicit-any` to avoid blocking builds during gradual migration.

### Step 3: Add Lint Script

**File:** `package.json`
```json
"lint": "ng lint",
"lint:fix": "ng lint --fix"
```

---

## Phase 2: Gradual `any` Reduction

### Strategy: Fix-on-Touch

Don't do a mass `any` replacement. Instead:
1. Fix `any` types in files being modified for other tasks
2. Prioritize: service return types > component inputs/outputs > event handlers > internal variables
3. Track progress: run `grep -r ": any" --include="*.ts" | wc -l` periodically

### High-Value Targets

- **API service return types** — replace `any` with generated/defined interfaces
- **Event handlers** — use proper Angular event types (`Event`, `KeyboardEvent`, etc.)
- **Component @Input/@Output** — define proper types for component APIs
- **Template context variables** — typed via `strictTemplates`

---

## Phase 3: TypeScript Strict Options

Enable incrementally in `tsconfig.json`, each as a separate commit:

1. **`strictPropertyInitialization: true`** — requires definite assignment or initialization for class properties. Fix with `!` (definite assignment assertion) or actual initialization.

2. **`noImplicitThis: true`** — errors on `this` with implicit `any` type. Mostly affects callback functions — fix with arrow functions or explicit typing.

3. **`noUnusedLocals: true`** + **`noUnusedParameters: true`** — catches dead code. Prefix intentionally unused params with `_`.

4. **`noUncheckedIndexedAccess: true`** — makes array/object indexed access return `T | undefined`. Most impactful change — requires null checks after array access.

5. **`isolatedModules: true`** — ensures files can be transpiled independently. Catches `const enum` and namespace re-exports.

---

## Phase 4: Angular Compiler Options

**File:** `tsconfig.json` — uncomment the `angularCompilerOptions` block:

```json
"angularCompilerOptions": {
  "strictInjectionParameters": true,
  "strictInputAccessModifiers": true,
  "strictTemplates": true,
  "enableI18nLegacyMessageIdFormat": false
}
```

**Requires AOT to be enabled first** (see `20260402-aot-build-configuration` task).

`strictTemplates` will surface template type errors — expect many initial errors that are currently hidden by JIT compilation.

---

## Verification

1. `ng lint` — runs without configuration errors
2. `ng build` — compiles after each strict option is enabled
3. Track `any` count over time: target <200 within 3 months
4. `npm run test:prod` — tests pass
5. CI pipeline includes `ng lint` step
