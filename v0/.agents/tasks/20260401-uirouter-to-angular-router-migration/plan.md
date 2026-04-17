# Routing Migration Blueprint: @uirouter/angular → @angular/router

## Context

This project (nJAMS Frontend, Angular 17.3.10) currently uses `@uirouter/angular 13.0.0` with `@uirouter/core 6.1.0` for all routing. The migration to `@angular/router` is needed to align with the Angular ecosystem, reduce dependency on a third-party routing library, and enable modern Angular features (standalone components, functional guards/resolvers, etc.).

This document is a **read-only analysis and migration blueprint** — no code changes are proposed yet.

---

## 1. State Inventory & Hierarchy

### 1.1 Full State Tree

```
Root (UIRouterModule.forRoot — app.module.ts)
│   initial: '/main', otherwise: '/login', useHash: true
│
├── app (ABSTRACT) — IndexComponent
│   URL: ?idToken&redirectPath&redirectSearch
│   Resolves: SSO_ACTIVE, SETUP_RESOLVE, LAYOUT_RESOLVE
│   RedirectTo: app.njams.trees.viewer.main
│   │
│   └── app.njams (ABSTRACT) — Named view: userMenuView@. → UserMenuComponent
│       URL: ?query&from&to + 47 more query params (all squash/dynamic)
│       │
│       ├── app.njams.trees.** (LAZY → TreesViewerModule)
│       │   URL: /
│       │   │
│       │   └── app.njams.trees.viewer (ABSTRACT)
│       │       │
│       │       ├── app.njams.trees.viewer.main — 7 named views, 2 resolves
│       │       │   URL: /main
│       │       │   RedirectTo: ...main.details
│       │       │   Views: subNaviView@app, pathSelectorView@app, timePickerView@app,
│       │       │          reloadResultsView@app, mainView@app.njams.trees,
│       │       │          treeView@app.njams.trees, messagingState@app
│       │       │   │
│       │       │   ├── ...main.details — 2 named views (processView, detailsView)
│       │       │   │   │
│       │       │   │   ├── ...details.process — processContentView
│       │       │   │   │   ├── .details, .traces, .followUp, .chart, .gantt, .startdata
│       │       │   │   │   └── .instance (ABSTRACT)
│       │       │   │   │       └── .config, .mapping, .traces, .input, .output, .statistic
│       │       │   │   │
│       │       │   │   ├── ...details.eventList — processContentView
│       │       │   │   │   ├── .details, .traces, .followUp, .chart, .gantt, .startdata
│       │       │   │   │   └── .instance (ABSTRACT)
│       │       │   │   │       └── .eventDetails, .payload, .stackTrace
│       │       │   │   │
│       │       │   │   └── ...details.activitylist — processContentView
│       │       │   │       ├── .details, .traces, .followUp, .chart, .gantt, .startdata
│       │       │   │       └── .instance (ABSTRACT)
│       │       │   │           └── .config, .mapping, .statistic
│       │       │   │
│       │       │   └── ...main.details.overlay (ABSTRACT) — completeView@app
│       │       │
│       │       ├── app.njams.trees.viewer.properties — 2 named views
│       │       │   URL: /properties
│       │       │   ├── .BO/:mainObjectId (LAZY)
│       │       │   ├── .BS/:mainObjectId (LAZY)
│       │       │   ├── .DO/:mainObjectId (LAZY)
│       │       │   └── .QO/:mainObjectId (LAZY)
│       │       │
│       │       └── app.njams.trees.viewer.customreport — 2 named views
│       │           URL: /customreport
│       │           └── .tab/:tabId
│       │
│       ├── app.njams.errorList.** (LAZY → ErrorListModule)
│       │   URL: /errorList + 10 query params
│       │
│       ├── app.njams.rules.** (LAZY → RulesModule)
│       │   URL: /rules — permissions: administrator, rules_management
│       │
│       ├── app.njams.user.** (LAZY → UserModule)
│       │   URL: /user
│       │
│       ├── app.njams.argos.** (LAZY → ArgosModule)
│       │   URL: /argos — permissions: administrator, metrics_operator, metrics_user
│       │   RedirectTo: argosRedirect() (dynamic function)
│       │   ├── .category/{categoryId} — RedirectTo: categoryRedirect() (dynamic)
│       │   │   └── .dashboard/{dashboardId}
│       │   │       ├── .alerts/{componentId}
│       │   │       └── .history, .editor, .charts (LAZY)
│       │   ├── .alertOverview.** (LAZY)
│       │   ├── .componentsOverview.** (LAZY)
│       │   └── .ruleOverview.** (LAZY)
│       │
│       ├── app.njams.administration.** (LAZY → NjAdministrationModule)
│       │   URL: /administration — 23 lazy child modules
│       │   RedirectTo: ...admin-dashboard
│       │   permissions: administrator, server_operator, user_management, view_message_processing
│       │
│       └── app.njams.notificationlist.** (LAZY → NotificationListModule)
│           URL: /notificationlist
│
├── login (ABSTRACT) — AuthComponent
│   URL: /?query&redirectPath&redirectSearch
│   Resolve: INSTANCE_NAME_RESOLVE
│   ├── login.login — Named view: loginContent → LoginComponent
│   ├── login.createadmin
│   ├── login.changePassword
│   └── login.requestPassword
│
├── logout — LogoutPseudoPageComponent
│   URL: /logout
│
├── sso — SsoComponent
│   URL: /sso?error&id_token&query&redirectPath&redirectSearch
│   Resolve: INSTANCE_NAME_RESOLVE
│
└── shutdown — ShutdownComponent
    URL: /shutdown
```

### 1.2 Abstract States Summary

| Abstract State | Role | Component |
|---|---|---|
| `app` | Root shell, SSO/session setup | IndexComponent |
| `app.njams` | Param container, user menu | UserMenuComponent (named view) |
| `app.njams.trees.viewer` | Viewer container | None |
| `app.njams.trees.viewer.main.details.overlay` | Full-screen overlay | CompleteViewComponent |
| `app.njams.trees.viewer.main.details.process.instance` | Instance detail tabs | None |
| `app.njams.trees.viewer.main.details.eventList.instance` | Event instance tabs | None |
| `app.njams.trees.viewer.main.details.activitylist.instance` | Activity instance tabs | None |
| `app.njams.administration` | Admin container | NjAdministrationComponent |
| `login` | Auth container | AuthComponent |

**Angular Router equivalent:** Abstract states become parent routes with `children: [...]` and either a component with `<router-outlet>` or `redirectTo` on the parent path.

---

## 2. Feature Mapping

### 2.1 Named Views

**Current usage: 40+ named view targets across the application.**

This is the **single largest migration challenge**. UI-Router allows a single state to populate multiple `<ui-view>` outlets in different parts of the component tree. Angular Router supports named `<router-outlet>`s but only as siblings within the same parent component template.

#### High-Impact Named View Patterns

| Pattern | States Using It | View Targets |
|---|---|---|
| App shell regions | `app.njams.trees.viewer.main` | `subNaviView@app`, `pathSelectorView@app`, `timePickerView@app`, `reloadResultsView@app`, `messagingState@app` |
| Trees viewer split | `app.njams.trees.viewer.main`, `.properties`, `.customreport` | `mainView@app.njams.trees`, `treeView@app.njams.trees` |
| Details content | `.process`, `.eventList`, `.activitylist` + their children | `processContentView`, `detailsContentView@app.njams.trees.viewer.main.details` |
| Index main | Many feature modules | `indexMainView@app` |
| User menu | `app.njams` | `userMenuView@.` |
| Argos regions | Category, dashboard states | `categoryView@...`, `dashboardView@...` |

#### Migration Strategy for Named Views

**Option A (Recommended): Component Composition Pattern**
- Replace named views with component inputs/outputs and structural reorganization
- The parent layout component renders all regions directly, receiving the "active" child component via `<router-outlet>`
- Header regions (subNavi, pathSelector, timePicker, etc.) become part of the parent component template, conditionally shown based on active route
- Use `@if` with route state checks or a shared service to toggle header regions

**Option B: Named Router Outlets (Limited)**
- Angular supports `<router-outlet name="foo">` but they must be siblings, not scattered across component trees
- Only viable for truly sibling layouts (e.g., main + sidebar)

**Option C: Wrapper/Layout Components**
- Create intermediate layout components that compose the correct set of child components per feature area
- E.g., `MainLayoutComponent` includes QueryBar, TimePicker, ReloadResults, and renders main content via `<router-outlet>`
- Best for feature-level layouts where named views at an ancestor level can be "pulled down" into a dedicated layout

**Recommended per region:**
- App shell header regions (subNavi, timePicker, etc.) → **Option A** (conditional rendering)
- Trees viewer split (mainView + treeView) → **Option C** (layout component)
- Content switching (processContentView, detailsContentView) → Unnamed `<router-outlet>` (single child swap)
- Feature main content (indexMainView@app) → Primary unnamed `<router-outlet>` in app shell

### 2.2 Resolves (28+ resolve files)

| Resolve | File | Purpose | Migration Target |
|---|---|---|---|
| SSO_ACTIVE | `sso-active.resolve.ts` | Check OIDC config | Functional `ResolveFn` on app route |
| SETUP_RESOLVE | `setup.resolve.ts` | User session init | Functional `ResolveFn` — side-effect heavy, consider `APP_INITIALIZER` |
| LAYOUT_RESOLVE | `layout.resolve.ts` | Load permissions + view settings | Functional `ResolveFn` or `APP_INITIALIZER` |
| INSTANCE_NAME_RESOLVE | `instance-name.resolve.ts` | Fetch instance name | Functional `ResolveFn` on login route |
| CONTAINER_ADJUSTMENT_RESOLVE | `container-adjustment.resolve.ts` | Adjust container UI | Side-effect — move to component `OnInit` |
| AVAILABLE_OBJECT_TYPES_RESOLVE | `available-object-types.resolve.ts` | Load object types | Functional `ResolveFn` |
| CATEGORIES_RESOLVE | Argos | Load categories | Functional `ResolveFn` |
| DASHBOARDS_RESOLVE | Category | Load dashboards | Functional `ResolveFn` with `Transition` → `ActivatedRouteSnapshot` |
| DIRECTION_IN/OUT_RESOLVE | Process details | Set direction constant | Remove resolve, pass as route `data` |
| TYPE_PAYLOAD/STACK_TRACE_RESOLVE | Event instance | Set type constant | Remove resolve, pass as route `data` |
| MAIN_OBJECT_ID_RESOLVE | Business objects | Extract param | Remove resolve, read from `ActivatedRoute.params` |
| TAB_RESOLVE | Custom report | Tab ID | Remove resolve, read from `ActivatedRoute.params` |
| IGNORE_INACTIVITY_RESOLVE | Properties, custom report | Disable inactivity | Side-effect — move to component or guard |

**Migration approach:** Convert all data-fetching resolves to Angular functional `ResolveFn`. Side-effect resolves should move to `APP_INITIALIZER`, component lifecycle, or guards. Constant-value resolves become route `data`.

### 2.3 Transition Hooks → Guards & Interceptors

| Hook File | Hook Type | Purpose | Angular Equivalent |
|---|---|---|---|
| **index.hooks.ts** | `onBefore` to `app.njams.trees.**` | Session check | `CanActivate` guard (functional) |
| **index.hooks.ts** | `onFinish` from `login.*` | Landing page redirect | `CanActivate` guard on app route or post-login service logic |
| **index.hooks.ts** | `onEnter` to `app.njams.**` | idToken cleanup | `CanActivate` guard or resolver (one-time) |
| **nj-main.hooks.ts** | `onEnter` entering main | Path reset + time range calc | `CanActivate` guard or `OnInit` in component |
| **nj-details-wrapper.hooks.ts** | 4x `onBefore` | Conditional sub-state redirect based on logId, layout tabs | `CanActivate` guard with dynamic redirect (most complex) |
| **properties.hooks.ts** | `onBefore` | Redirect to type-specific sub-state | `CanActivate` guard with redirect |
| **domain-objects.hooks.ts** | `onBefore` | Preserve sub-state when returning | `CanActivate` guard with redirect |
| **query-objects.hooks.ts** | `onBefore` | Prevent redirect from privileges | `CanActivate` guard |
| **message-processing.hooks.ts** | `onFinish` | Permission check with fallback | `CanActivate` guard |
| **admin-dashboard.hooks.ts** | `onFinish` | Permission check | `CanActivate` guard |
| **admin-dashboard.hooks.ts** | `onExit` | Logging | `CanDeactivate` guard |
| **rules-overview.hooks.ts** | `onExit` | Unsaved changes dialog | `CanDeactivate` guard |

### 2.4 State Parameters

#### Global Query Parameters (50+ on `app.njams`)

The `app.njams` abstract state defines 50+ query parameters with `squash: true` and `dynamic: true`. This is a **critical migration challenge**.

**Current behavior:**
- Parameters are inherited by all child states
- `dynamic: true` allows param changes without state reload
- `squash: true` omits default values from URL
- `raw: true` disables encoding

**Angular Router equivalent:**
- Query parameters are globally accessible via `ActivatedRoute.queryParamMap` — no need to declare them on a parent route
- Dynamic updates: use `router.navigate([], { queryParams: {...}, queryParamsHandling: 'merge' })`
- No squash equivalent — handle defaults in the consuming service
- The centralized `RouterStateService` can manage encoding/decoding

#### Path Parameters

| Parameter | States | Type |
|---|---|---|
| `:mainObjectId` | Properties BO/BS/DO/QO | path |
| `{categoryId}` | Argos category | path |
| `{dashboardId}` | Argos dashboard | path |
| `{componentId}` | Argos alerts | string |
| `:tabId` | Custom report tab | path |

**Migration:** Path params map directly to Angular Router `:param` syntax. The `{param}` UI-Router syntax becomes `:param`.

---

## 3. URL & Redirection Logic

### 3.1 `otherwise` Configuration
- **Current:** `otherwise: '/login'` in `UIRouterModule.forRoot()`
- **Angular equivalent:** Wildcard route `{ path: '**', redirectTo: '/login' }` at the end of root routes

### 3.2 `initial` Configuration
- **Current:** `initial: '/main'`
- **Angular equivalent:** `{ path: '', redirectTo: '/main', pathMatch: 'full' }` at root level

### 3.3 Static `redirectTo`
- `app` → `app.njams.trees.viewer.main` → Becomes `redirectTo` on the empty-path route
- `app.njams.administration` → `...admin-dashboard`
- `app.njams.trees.viewer.main` → `...main.details`
- Multiple other static redirects

### 3.4 Dynamic `redirectTo` Functions

| Function | File | Logic | Angular Equivalent |
|---|---|---|---|
| `argosRedirect()` | `argos.redirect.ts` | Resolves categories, redirects to first | `CanActivate` guard that injects service, returns `UrlTree` |
| `categoryRedirect()` | `category.redirect.ts` | Resolves dashboards, redirects to first | `CanActivate` guard that injects service, returns `UrlTree` |

### 3.5 No Sticky States or Deep State Redirect
Confirmed: no `@uirouter/sticky-states` or `@uirouter/dsr` — no `RouteReuseStrategy` needed.

### 3.6 Trailing Slash Removal
- **Current:** `app-router.config.ts` removes trailing slashes via URL rule factory
- **Angular equivalent:** `UrlSerializer` override or `APP_INITIALIZER` with `Location` strategy

### 3.7 Hash-Based Routing
- **Current:** `useHash: true`
- **Angular equivalent:** `RouterModule.forRoot(routes, { useHash: true })` or `provideRouter(routes, withHashLocation())`

---

## 4. Template & Component Audit

### 4.1 `<ui-view>` Tags (~30 occurrences across 15+ templates)

**Tier 1 — App Shell (critical path):**

| File | Named View | Angular Replacement |
|---|---|---|
| `app.component.html` | `<ui-view>` (unnamed, root) | `<router-outlet>` |
| `index.component.html` | `messagingState`, `timePickerView`, `reloadResultsView`, `completeView`, `indexMainView` | Conditional component rendering (`@if` + route check) or named outlets |
| `footer.component.html` | `pathSelectorView` | Conditional component rendering |

**Tier 2 — Trees Viewer (most complex):**

| File | Named View(s) | Angular Replacement |
|---|---|---|
| `trees-viewer.component.html` | `treeView`, `mainView`, `processView`, `detailsView` | Named outlets or component composition |
| `nj-process.component.html` | `processContentView` | `<router-outlet>` (single child swap) |
| `nj-process-details.component.html` | `detailsContentView` | `<router-outlet>` (single child swap) |

**Tier 3 — Feature areas:**

| File | Named View(s) | Angular Replacement |
|---|---|---|
| `auth.component.html` | `loginContent` | `<router-outlet>` |
| `argos.component.html` | `indexView` | `<router-outlet>` |
| `category.component.html` | `categoryView`, `dashboardView` | Named outlets or composition |
| `dashboard.component.html` | `chartsView` | `<router-outlet>` |
| `alerts.component.html` | `detailsView` | `<router-outlet>` or composition |
| `email-alerts.component.html` | `emailAlertsView` | `<router-outlet>` |
| `nj-custom-report.component.html` | `customReportsView` | `<router-outlet>` |
| `nj-custom-report-tile-wizard.component.html` | `customReportWizardView` | `<router-outlet>` |
| `properties.component.html` | unnamed `ui-view` | `<router-outlet>` |
| `nj-administration.component.html` | unnamed `ui-view` | `<router-outlet>` |
| `indexer-connection.component.html` | unnamed `ui-view` | `<router-outlet>` |
| `message-processing.component.html` | unnamed `ui-view` | `<router-outlet>` |

### 4.2 `uiSref` Directives (5 occurrences)

| File | Usage | Angular Replacement |
|---|---|---|
| `email-alerts.component.html:2` | `uiSref="app.njams.errorList"` | `routerLink="/errorList"` |
| `email-alerts.component.html:5` | `uiSref="app.njams.errorList.config"` | `routerLink="/errorList/config"` |
| `user-menu.component.html:19` | `uiSref="app.njams.user"` | `routerLink="/user"` |
| `user-menu.component.html:27` | `uiSref="app.njams.notificationlist"` | `routerLink="/notificationlist"` |
| `user-menu.component.html:31` | `uiSref="logout"` | `routerLink="/logout"` |

### 4.3 `uiSrefActive` (1 occurrence)

| File | Usage | Angular Replacement |
|---|---|---|
| `email-alerts.component.html:5` | `uiSrefActive="active"` | `routerLinkActive="active"` |

### 4.4 Programmatic Navigation (185+ occurrences across 40+ files)

All navigation goes through `RouterStateService.go()`. Key patterns:

```typescript
// Simple navigation
this.routerStateService.go('app.njams.user');

// With parameters
this.routerStateService.go('app.njams.trees.viewer.main.details.process.chart', params);

// Relative navigation (current state)
this.routerStateService.go('.', {}, { reload: 'app.njams.rules' });

// With options
this.routerStateService.go('shutdown', { hold: true });
```

**Migration approach:** Adapt `RouterStateService` to wrap Angular `Router` instead of UIRouter `StateService`. This is the **highest-leverage change** — updating one service adapts 185+ call sites. Will need a state-name → URL-path mapping for the transition period, or convert all call sites to use URL paths.

### 4.5 State Checks (includes/is)

`RouterStateService.includes()` and `.is()` are used for conditional UI rendering (active tabs, visible regions). Angular equivalent: `Router.isActive()` or `ActivatedRoute` checks.

### 4.6 IsStatePipe

`src/app/shared/pipes/is-state/is-state.pipe.ts` — a `pure: false` pipe calling `routerStateService.is(state)`. Must be adapted to use `router.isActive()` or `router.url` comparison.

### 4.7 UIRouterModule Registration Points

72 `UIRouterModule.forChild()` calls + 1 `UIRouterModule.forRoot()` — all must be converted or removed.

---

## 5. Gap Analysis

### 5.1 No 1-to-1 Equivalent

| UI-Router Feature | Gap | Angular Workaround |
|---|---|---|
| **Named views (40+ usages)** | Angular named outlets must be siblings; UI-Router views can target any ancestor | Restructure templates: parent layout renders all regions, child component via `<router-outlet>`. Use services/signals for dynamic header content |
| **`dynamic: true` params** | UI-Router updates params without reloading component | Use `queryParams` with `queryParamsHandling: 'merge'`; subscribe to `queryParamMap` observable in components |
| **`squash: true`** | No equivalent — Angular always serializes params | Handle defaults in the consuming service; omit default values when building queryParams |
| **Transition `injector().get()`** | Hooks access DI container via transition | Guards/resolvers use standard Angular `inject()` |
| **`onFinish` hooks** | No post-activation hook in Angular Router | Use resolver return value + component OnInit, or `Router.events` (NavigationEnd) |
| **`redirectTo` as function** | Angular `redirectTo` is string-only | Use `CanActivate` guard returning `UrlTree` for dynamic redirects |
| **State dot notation navigation** | `go('app.njams.trees.viewer.main')` | Must use URL paths or build a mapping utility |
| **50+ inherited query params** | Declared on parent, inherited by all children | Query params are global in Angular Router — no declaration needed, just read via `queryParamMap` |
| **`raw: true` encoding** | UI-Router disables URI encoding per param | Handle in `RouterStateService` encoding/decoding layer |
| **`array: true` params** | UI-Router serializes arrays natively | Serialize manually (e.g., `param=a&param=b` or JSON) |

### 5.2 Direct Equivalents

| UI-Router Feature | Angular Router Equivalent |
|---|---|
| `abstract: true` | Parent route with `children` + `<router-outlet>` |
| `loadChildren` | `loadChildren` (same concept, slightly different syntax) |
| `resolve` | `resolve` with functional `ResolveFn` |
| `onBefore` hooks | `CanActivate` / `CanMatch` functional guards |
| `onExit` hooks | `CanDeactivate` functional guards |
| `data.permissions` | Route `data` property + `CanActivate` guard |
| `useHash: true` | `withHashLocation()` or `{ useHash: true }` |
| `otherwise` | `{ path: '**', redirectTo: '...' }` |

---

## 6. Suggested Migration Order

### Phase 0: Foundation (No routing changes)
1. **Adapt `RouterStateService`** to support both UIRouter and Angular Router via an abstraction interface
2. **Create a state-name-to-URL mapping** utility for the 185+ `go()` calls
3. **Convert all UI-Router resolves** to Angular functional `ResolveFn` format (can coexist)
4. **Create functional guards** for all transition hooks (can be written and tested before wiring)
5. **Create a permissions guard** to replace `NjPermissionsService.checkRoutePermissions()` hook usage

### Phase 1: Leaf Modules (Simple, No Named Views)
Start with modules that have no named views and minimal hooks:

1. **`shutdown`** — Single route, no resolves, no hooks, no named views
2. **`logout`** — Single route, simple params
3. **`sso`** — Single route with resolve
4. **`login`** (auth module) — 4 states, 1 named view (loginContent), 1 resolve
5. **`app.njams.user`** — Single state, named view `indexMainView@app` only
6. **`app.njams.rules`** — Single state, permissions, named view `indexMainView@app`
7. **`app.njams.notificationlist`** — Single state, named view `indexMainView@app`

### Phase 2: Feature Modules with Some Complexity
8. **`app.njams.errorList`** — Named view + complex query params + email alerts sub-routes
9. **`app.njams.administration`** — 23 lazy children, abstract parent, permissions, but each child is mostly simple
10. **Individual admin sub-modules** (dashboard, message-processing, jobs, etc.) — one at a time

### Phase 3: Argos Module (Dynamic Redirects)
11. **`app.njams.argos`** — Dynamic redirect functions, nested lazy children, permissions
12. **Argos category/dashboard** — Dynamic redirects, named views, alerts sub-routes
13. **Rule overview** — `CanDeactivate` guard (unsaved changes)

### Phase 4: Trees Viewer (Most Complex — Named Views)
14. **`app.njams.trees.viewer.customreport`** — 2 named views, tab routing
15. **`app.njams.trees.viewer.properties`** — 2 named views, 4 object type children, hooks
16. **`app.njams.trees.viewer.main`** — **7 named views**, most complex state
17. **`nj-details-wrapper`** — 4 `onBefore` hooks with complex conditional routing
18. **Process details / Event details / Activity list** — Deep state hierarchy with instance sub-states

### Phase 5: Core Shell
19. **`app.njams`** — 50+ query params, user menu named view
20. **`app`** — Root abstract state, resolves (SSO, setup, layout)
21. **`app.module.ts`** — Replace `UIRouterModule.forRoot()` with `provideRouter()`
22. **Remove UIRouter dependencies** from `package.json`

### Phase 6: Cleanup
23. Remove all `.hooks.ts` files (replaced by guards)
24. Remove all `*-router.config.ts` files
25. Remove UIRouter imports from all modules
26. Update `RouterStateService` to remove UIRouter abstraction layer
27. Run full regression testing

---

## Key Files to Modify

| File | Change |
|---|---|
| `app.module.ts` | Replace `UIRouterModule.forRoot()` with `provideRouter()` |
| `app.component.html` | `<ui-view>` → `<router-outlet>` |
| `core/services/router/router-state.service.ts` | Adapt to wrap Angular Router |
| 65+ `*.routes.ts` files | Convert `Ng2StateDeclaration[]` to Angular `Routes` |
| 9 `*.hooks.ts` files | Convert to functional guards |
| 8 `*-router.config.ts` files | Remove (hooks registered via route config) |
| 28+ `*.resolve.ts` files | Convert to functional `ResolveFn` |
| 20+ `*.module.ts` files | Remove `UIRouterModule.forChild()` imports |
| 4 templates with `<ui-view>` | Replace with `<router-outlet>` |
| 5 templates with `uiSref` | Replace with `routerLink` |
| 3 files with `UIRouterGlobals` | Replace with `Router` / `ActivatedRoute` |

---

## Estimated Duration

| Phase | Duration | Parallelizable? |
|---|---|---|
| Phase 0: Foundation | 1-2 weeks | No (prerequisite) |
| Phase 1: Leaf Modules | 2-3 weeks | Yes (after Phase 0) |
| Phase 2: Feature Modules | 1-2 weeks | Yes (after Phase 0) |
| Phase 3: Argos Module | 1-2 weeks | Yes (after Phase 0) |
| Phase 4: Trees Viewer | 3-4 weeks | After Phase 0 + 3 |
| Phase 5: Core Shell | 1-2 weeks | After all prior phases |
| Phase 6: Cleanup | 1-2 weeks | After Phase 5 |
| **Total (sequential)** | **11-17 weeks** | |
| **Total (parallel Phases 1-3)** | **8-12 weeks** | |

---

## Risk Mitigation

| Risk | Mitigation |
|---|---|
| Named view restructuring breaks layout | Visual regression tests before migration |
| 185+ navigation calls break | `RouterStateService` adapter shields all call sites |
| URL structure changes break bookmarks | Same URL segments preserved; hash routing maintained |
| Lazy loading behavior changes | Test each lazy module independently |
| Parameter encoding/decoding changes | `RouterStateService` handles encoding centrally |
| Permission checks break | Extract all permission patterns into reusable guard factory |
| `reload` option not directly supported | Custom `RouteReuseStrategy` or param-change trigger |

---

## Verification Plan

1. **Unit tests:** All existing component/service tests should continue to pass after each phase
2. **E2E navigation tests:** Verify all routes are reachable with correct URLs
3. **Query parameter preservation:** Verify 50+ params survive navigation and browser refresh
4. **Guard verification:** Test all permission-based access control
5. **Lazy loading:** Verify all modules still load on demand (check network tab)
6. **Hash routing:** Verify `#/` prefix is preserved in all URLs
7. **Deep linking:** Verify bookmarked URLs still work
8. **Redirect chains:** Verify dynamic redirects (argos, category) work correctly
9. **Back/forward navigation:** Verify browser history works correctly
10. **Unsaved changes:** Verify CanDeactivate guards prompt correctly
