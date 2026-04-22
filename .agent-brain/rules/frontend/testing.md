# Testing Rules

All testing rules: structure, helpers, mocking, element selection, Vitest setup gotchas + hygiene, Cypress component tests.

---

## File Placement & Naming

- Unit tests: co-located next to source file as `{name}.spec.ts`.
- Cypress component tests: under `cypress/component/`, mirroring `src/app/` path.
- Mock files: `tests/mocks/services/{name}.mock.ts` or `tests/mocks/api/{name}.mock.ts`.

```
✅ Good:
date.spec.ts
auth.mock.ts

❌ Bad:
date.test.ts          # Use .spec.ts
dateSpec.ts           # Use kebab-case
date-unit.spec.ts     # Don't add test type
```

---

## Test Structure

Organize tests with `describe` blocks that mirror the code:

```typescript
describe('date utils', () => {
  describe('formatDuration', () => {
    it('should format milliseconds to human readable string', () => {
      expect(formatDuration(3600000)).toBe('1h');
    });

    it('should handle zero duration', () => {
      expect(formatDuration(0)).toBe('0ms');
    });
  });
});
```

Each `it()` block tests one concern. Prefer many small tests over few large ones.

---

## Test Data Helpers

Create helper functions with `Partial<T>` overrides to reduce duplication:

```typescript
const createJobDto = (overrides: Partial<JobDto> = {}): JobDto => ({
  id: 'job-123',
  jobKeyName: 'DEFAULT.myJob',
  amount: 5,
  interruptable: false,
  ...overrides,
});

it('should handle missing optional fields', () => {
  const result = toJob(createJobDto({ status: undefined }));
  expect(result.status).toBeNull();
});
```

- Place helpers at the top of the `describe` block.
- Use descriptive names matching the domain model (`createSession`, not `createMockSession`).
- Nest helpers for complex nested objects (`createUser` inside `createSessionDto`).

---

## Dayjs Initialization

**Always import `dayjs-init` at the top of test files** that exercise code using dayjs plugins:

```typescript
import '<relative-path>/core/utils/dayjs-init';
```

`main.ts` never runs under test, so plugins (`duration`, `utc`, `timezone`, etc.) won't be loaded otherwise. This import is load-bearing even if the spec never imports `dayjs` directly.

---

## Element Selection

Use `data-cy` attributes for reliable element selection in component tests:

```html
<button data-cy="submit-btn" (click)="onSubmit()">Submit</button>
```

```typescript
cy.get('[data-cy="submit-btn"]').click();
```

Prefer `data-cy` over CSS class or tag selectors — classes change for styling, `data-cy` is test-only and stable.

### `data-cy` naming conventions

- **Role-based, not structural.** Name by what the element *is* in the UI contract — `data-cy="fill"`, `data-cy="nodes-grid"`, `data-cy="header"` — not by its tag or position (`"inner-div"`, `"span-1"`).
- **Kebab-case** identifiers, one word or short compound (`"node-name"`, `"cpu-row"`, `"storage-section"`).
- **Every element a test might select gets one.** Internal layout wrappers that tests never reach don't need one.
- **Child components are selected by their `app-<tag>`, not by `data-cy`.** The element selector is already stable and conveys intent.

```typescript
// ✅ data-cy for DOM nodes inside the component under test
host().find('[data-cy="fill"]')

// ✅ element selector for child components
host().find('app-node-metric-card')

// ❌ class-based selection — fragile, changes with styling
host().find('.bg-emerald-500')

// ❌ structural data-cy — meaningless to a reader
host().find('[data-cy="div-2"]')
```

---

## Mocking Guidelines

### Shared mocks (in `tests/mocks/`)

Create when:
- Used by 3+ test files.
- Complex setup that shouldn't be duplicated.
- Represents a core service (auth, permissions, etc.).

```typescript
// tests/mocks/services/auth.mock.ts
export const createMockAuthService = (): Partial<AuthService> => ({
  currentUser: signal({ id: 'test-user', name: 'Test User' }),
  isAuthenticated: signal(true),
  login: vi.fn(),
  logout: vi.fn(),
});
```

### Inline mocks

For simple, one-off cases keep them in the test file:

```typescript
{ provide: UserService, useValue: { getUser: () => of(mockUser) } }
```

---

## DO / DON'T

### DO
- Test behavior, not implementation details.
- Use `fakeAsync`/`tick` for async code.
- Prefer testing through the public API.
- Clean up subscriptions and timers in `afterEach`.

### DON'T
- Test private methods directly.
- Test framework behavior (Angular's change detection, etc.).
- Use `setTimeout` in tests — use `fakeAsync`/`tick`.
- Share mutable state between tests.
- Test third-party library internals.

---

## Coverage Expectations

| Code Type | Target |
|-----------|--------|
| Utils / pure functions | 90%+ |
| Services (business logic) | 80%+ |
| Components (with logic) | 70%+ |
| Components (presentational) | Optional |
| API services | 60%+ |

Focus coverage on business logic, not boilerplate.

---

## Cypress Component Tests

Rules specific to Cypress component tests in an Angular project.

### Test scope — one component per spec

Each component's spec tests that component only. A parent's spec verifies children are **present**, rendered in the expected **count and position**, and receive the **correct data** (via text flow-through on `app-<child>` element selectors). A parent's spec never re-asserts behavior that the child's own spec already covers.

Corollary: **do not write integration-style specs at Cypress CT level**. If a behavior spans components, the child's own spec carries it.

### Mount helper idiom

Every spec wraps `cy.mount(...)` in a file-level helper named `mount<Component>`. The helper only imports the component under test — its children are pulled in via its own `imports:` array.

- **Primitive inputs:** inline them in the template string passed to the helper (`'<app-resource-bar [usage]="40"/>'`).
- **Object / array inputs:** build the template binding through small expression helpers (`nodeExpr`, `arrayExpr`) and expose an `opts` interface on the mount function so each `it` stays on one line of setup.
- **Repeated object inputs:** create a `make<Model>(overrides: Partial<<Model>> = {}) => <Model>` factory with a valid, un-opinionated default.

```typescript
// ✅ primitive — inline in template
function mountResourceBar(template: string) {
    return cy.mount(template, { imports: [ResourceBarComponent] });
}
mountResourceBar('<app-resource-bar [usage]="40"/>');

// ✅ object/array — expression builder + opts
interface MountOpts { nodes?: NodeMetrics[]; loading?: boolean; }
function mountPanel(opts: MountOpts = {}) {
    const nodes = arrayExpr(opts.nodes ?? [], nodeExpr);
    return cy.mount(`<app-metrics-panel [nodes]="${nodes}" [loading]="${opts.loading ?? false}"/>`,
        { imports: [MetricsPanelComponent] });
}
```

### Compose selector helpers

Keep selector chains small and named. Each helper returns a `Cypress.Chainable` and composes on top of the parent selector. The top of every file looks like:

```typescript
const host = () => cy.get('app-<name>');
const <region> = () => host().find('[data-cy="<region>"]');
const <subRegion> = () => <region>().find('[data-cy="<sub>"]');
```

This keeps each `it` body to a few assertions and avoids repeating `cy.get('app-x [data-cy="y"]')` strings.

### Always use template mounting

Mount components via template strings, never via class reference with `componentProperties`. Cypress 13's `componentProperties` uses `Object.assign`, which overwrites Angular signal inputs (`input()`, `input.required()`) and causes runtime errors.

```typescript
/* CORRECT */
cy.mount('<app-my-comp [icon]="\'check\'" size="lg"/>', {
  imports: [MyComponent],
  providers: [/* … */],
});

/* WRONG — breaks signal inputs */
cy.mount(MyComponent, {
  componentProperties: { icon: 'check', size: 'lg' },
});
```

Template mounting also renders the real host element (`<app-my-comp>`) in the DOM, so host bindings (classes, inline styles) are testable with `cy.get('app-my-comp')`.

### Disable FontAwesome timers when testing FA components

Any test file that renders a component using `FaIconComponent` must disable FontAwesome's `MutationObserver` and `requestAnimationFrame` at module level. Without this, zone.js `fakeAsync` throws periodic timer errors.

```typescript
import { config as faConfig } from '@fortawesome/fontawesome-svg-core';
faConfig.autoReplaceSvg = false;
faConfig.observeMutations = false;
```

Place this at the top of the file, outside any `describe` block.

### Provide FaIconLibrary with required icons

FontAwesome icons must be registered explicitly. Use a `useFactory` provider to create a `FaIconLibrary` and add only the icons the test needs.

```typescript
import { FaIconLibrary } from '@fortawesome/angular-fontawesome';
import { faCheck, faUser } from '@fortawesome/free-solid-svg-icons';

providers: [
  {
    provide: FaIconLibrary,
    useFactory: () => {
      const lib = new FaIconLibrary();
      lib.addIcons(faCheck, faUser);
      return lib;
    },
  },
],
```

### Extract a mount helper per describe block

Wrap the `cy.mount` call in a helper function at the top of each test file to avoid repeating imports, providers, and boilerplate across tests.

```typescript
function mountMyComponent(template: string) {
  return cy.mount(template, {
    imports: [MyComponent],
    providers: [/* shared providers */],
  });
}

it('renders default state', () => {
  mountMyComponent('<app-my-comp [icon]="\'check\'"/>');
  // assertions…
});
```

### Assert inline styles via `have.attr`, not `have.css`

Host bindings like `[style.width]` set inline styles. `should('have.css', …)` returns computed values in pixels, which won't match rem values. Use `have.attr` on the `style` attribute instead:

```typescript
/* CORRECT — matches the inline style string */
cy.get('app-my-comp')
  .should('have.attr', 'style')
  .and('contain', 'width: 1.77rem');

/* WRONG — computed CSS returns pixels, not rem */
cy.get('app-my-comp')
  .should('have.css', 'width', '1.77rem');
```

### Place tests under `cypress/component/`

Test files live under `cypress/component/`, mirroring the component's path under `src/app/`. This keeps them under `cypress/tsconfig.json` so Cypress types (`describe`, `it`, `cy`) resolve in the IDE without extra config.

```
cypress/component/shared/components/circled-icon/
  circled-icon.cy.ts

src/app/shared/components/circled-icon/
  circled-icon.ts
  circled-icon.html
  circled-icon.scss
```

Import the component under test using a **relative path**, per the Imports section in [angular-general.md](angular-general.md). Do not use `app/...` baseUrl-style imports — even though `cypress/tsconfig.json` may set `baseUrl: "../src"`, this project does not use path aliases in any toolchain:

```typescript
import { CircledIconComponent } from '../../../../../src/app/shared/components/circled-icon/circled-icon';
```

### Cypress anti-patterns

```typescript
/* WRONG — class-based mount with componentProperties */
cy.mount(CircledIconComponent, {
  componentProperties: { icon: 'check' } as any,
});

/* WRONG — asserting rem values via have.css */
cy.get('app-circled-icon').should('have.css', 'width', '1.77rem');

/* WRONG — missing FA config disabling (causes periodic timer errors) */
// no faConfig.autoReplaceSvg = false;
// no faConfig.observeMutations = false;
describe('MyIconComponent', () => { … });

/* WRONG — importing icons not registered in the FaIconLibrary provider */
// Template uses 'star' but only faCheck was added to the library
```

---

## Vitest: Setup Gotchas

Framework-level traps for Vitest under `@analogjs/vite-plugin-angular`. All four have bitten real projects; every new spec file inherits them implicitly.

### The analog tsconfig trap

`@analogjs/vite-plugin-angular` hardcodes `tsconfig.spec.json` under `NODE_ENV=test` and **silently** drops any file missing from its `files`/`include` list. If `src/test-setup.ts` falls out of compilation, every test fails with `Need to call TestBed.initTestEnvironment() first` — and `console.log` / `throw` inside the setup file never surface.

Mitigation: point the analog plugin at a dedicated vitest tsconfig that explicitly lists `src/test-setup.ts` in `files`/`include`.

### Config file must be `.mts`

When `package.json` has no `"type": "module"`, Vite treats a `.ts` config file as CJS and fails to load the ESM-only analog plugin. Name the Vitest config `vitest.config.mts`, not `.ts`.

### Analog plugin version pinning

`@analogjs/vite-plugin-angular`, Vite, and Vitest must be upgraded together — each analog major line tracks a specific Vite/Vitest line. Never bump one without the other two.

### `test.coverage.all: true` is silently ignored

Under the analog plugin, both v8 and istanbul coverage providers only report files that were loaded at test runtime; the `coverage.include` glob does **not** eagerly pull untouched files through the transform. Report coverage via the file-level denominator in the downstream tool (e.g. Sonar's `sonar.sources`), not via `coverage.all: true`.

---

## Vitest: Test Hygiene

Project-wide spec-writing rules. These apply to every Vitest file regardless of whether it tests a util, service, or component.

- **No `any`** in test code. Use `as never`, `as unknown as T`, or real type fixtures.
- **No logic in tests** beyond `it.each` — no `if`/`for`/`switch` around assertions.
- **Public API only.** Don't import private helpers, don't reach into internals.
- **No `done()` callbacks.** Use `async`/`await` or return a Promise. Vitest 1.x warns on `done` and assertions may silently no-op.
- **No snapshot tests for plain values** — use explicit `toBe` / `toEqual`.
- **Cover every exported symbol** of the file under test. If an exported constant exists, assert at least its shape or a sentinel value.
- **No shared mutable state between `it` blocks.** Reset in `beforeEach`, never at module scope.
- **Explicit imports from `vitest`** (`describe`, `it`, `expect`, `beforeEach`, `afterEach`, `vi`) even when globals are enabled.
- **Imports**: relative paths only — no `app/...` or `@app/...` aliases. See the Imports section in [angular-general.md](angular-general.md).
- **Error-throwing functions**: `expect(() => fn()).toThrow(/message substring/)`, not try/catch.

---

## Vitest: Never Mock DOCUMENT

When testing services that `inject(DOCUMENT)`, use the real JSDOM document provided by the test environment. Do **not** override the `DOCUMENT` token with a plain object.

Angular's `DOMTestComponentRenderer.removeAllRootElements()` calls `this._doc.querySelectorAll()` during `TestBed.resetTestingModule()`. Providing a minimal mock like `{ location: { pathname: '/foo/' } }` breaks this teardown and fails every test with:

```
TypeError: this._doc.querySelectorAll is not a function
```

If your service reads `document.location.pathname`, accept that JSDOM returns `'/'` and write expectations accordingly.

```typescript
// GOOD — use real JSDOM document, adapt expectations
TestBed.configureTestingModule({
    providers: [MyState, /* other mocks, but NOT DOCUMENT */],
});
const state = TestBed.inject(MyState);
expect(state.resolvedUrl()).toBe('/swagger/index.html'); // pathname='/' in JSDOM
```

### Anti-patterns

```typescript
// BAD — breaks Angular test teardown
TestBed.configureTestingModule({
    providers: [
        MyState,
        { provide: DOCUMENT, useValue: { location: { pathname: '/custom/' } } },
    ],
});
// → TypeError: this._doc.querySelectorAll is not a function
```
