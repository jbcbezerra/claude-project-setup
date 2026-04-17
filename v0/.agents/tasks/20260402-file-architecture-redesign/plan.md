# File Architecture Redesign Plan

## Context

The app (~2400 files) has feature directories scattered across the root (`trees-viewer/`, `administration/`, `argos/`, `notifications/`, etc.) alongside an incomplete `core/`, `shared/`, and `feature/` structure. The goal is a predictable, self-documenting architecture based on **core / domain / shared** where every domain feature follows a consistent internal pattern: **api service → state service → component**.

---

## Architecture Overview

```
src/app/
├── core/                  # Singleton infrastructure, zero domain knowledge
├── domain/                # Business capabilities, owns routes + UI + state + API
├── shared/                # Reusable UI, cross-domain services, pipes, directives
├── app.module.ts
└── app.component.ts
```

**Import direction rules:**
- `domain/` → can import from `core/` and `shared/`
- `domain/` → NEVER imports from another `domain/` (extract to `shared/` if needed)
- `shared/` → can import from `core/`
- `core/` → NEVER imports from `shared/` or `domain/`

---

## 1. Core — Application Infrastructure

Only framework plumbing that is domain-agnostic and instantiated once.

```
core/
├── services/
│   ├── api/
│   │   ├── api.service.ts            # The single ApiService wrapper
│   │   ├── base-api.service.ts       # Base HTTP methods
│   │   └── models/                   # http-options.type.ts, api-crud-actions.interface.ts
│   ├── logger/
│   │   └── logger.service.ts
│   ├── router/
│   │   └── router-state.service.ts
│   └── websocket/
│       └── websocket-manager.service.ts
├── interceptors/
│   └── global-http-error-handler/
├── utils/                            # Pure functions, no Angular imports
│   ├── array.ts, date.ts, string.ts, object.ts, uri.ts, ...
│   └── form-validators/
├── layout/                           # App shell (header, footer)
│   ├── header/
│   └── footer/
├── abstract/
├── components/
│   └── network-error/
└── guards/
```

**What changes:** All 30+ domain-specific API services currently in `core/services/api/` move out to their respective domain. Only `ApiService`, `BaseApiService`, and their models remain.

---

## 2. Domain — Business Capabilities

### Domain Boundaries

| Domain folder | Current source | Notes |
|---|---|---|
| `domain/trees-viewer/` | `trees-viewer/` | Process search, list, details, diagrams, custom reports |
| `domain/administration/` | `administration/` | Legacy admin: JDBC, indexer, deployment, JMS, JNDI, etc. |
| `domain/operations/` | `feature/administration/` | Newer admin: jobs, user-mgmt, sessions, system-config |
| `domain/argos/` | `argos/` | Monitoring dashboards, alerts |
| `domain/notifications/` | `notifications/` | WebSocket listeners, notification list, toasts |
| `domain/error-list/` | `error-list/` | Error list, email alerts |
| `domain/plugins/` | `plugins/` | Replay plugin |
| `domain/auth/` | `auth/` + `sso/` | Login, logout, SSO, password flows |
| `domain/rules/` | `rules/` | Rule sets, conditions, actions |
| `domain/properties/` | `feature/properties/` | Query objects, settings |
| `domain/my-account/` | `feature/my-account/` | Account settings |
| `domain/logger-settings/` | `feature/logger-settings/` | Logger configuration |

### Internal Structure of Every Domain

```
domain/<name>/
├── <name>.routes.ts
├── <name>.component.ts/html              # Shell component
├── _shared/                              # Domain-wide code (underscore sorts first)
│   ├── api/                              # APIs used by multiple subfeatures in this domain
│   │   └── <name>-api.ts
│   ├── models/                           # Types shared across subfeatures
│   │   └── <name>-models.ts
│   └── constants/
├── <subfeature>/
│   ├── data-access/                      # HTTP boundary
│   │   ├── index.ts                      # Barrel export
│   │   ├── <sub>-api.ts                  # HTTP calls (providedIn: 'root')
│   │   ├── <sub>-dto.ts                  # Raw API response shapes
│   │   └── <sub>-mapper.ts              # DTO → domain model
│   ├── entities/                         # Domain models
│   │   ├── index.ts                      # Barrel export
│   │   └── <sub>-models.ts
│   ├── <sub>.component.ts                # UI
│   ├── <sub>.component.html
│   ├── <sub>.component.scss
│   ├── <sub>-state.ts                    # signalState + BaseState (logic)
│   └── <sub>-*.pipe.ts                   # Feature-specific pipes (if any)
└── <subfeature-b>/
    └── ... (same structure)
```

**Depth rule:** Max 3 levels within a domain. Flatten instead of nesting deeper.

### Where API Services Live

| Scope | Location | Example |
|---|---|---|
| Used by 1 subfeature | `domain/x/subfeature/data-access/sub-api.ts` | `job-list-api.ts` |
| Used by multiple subfeatures in 1 domain | `domain/x/_shared/api/x-api.ts` | `job-api.ts` |
| Used by multiple domains | `shared/api/x-api.ts` | Rare, only if truly cross-domain |

### Concrete Example: `domain/operations/job/`

```
domain/operations/job/
├── job.component.ts/html
├── job.routes.ts
├── job-state.service.ts                  # Cross-subfeature state (signal)
├── job-list/
│   ├── data-access/
│   │   ├── index.ts
│   │   ├── job-list-api.ts
│   │   ├── job-dto.ts
│   │   └── job-mapper.ts
│   ├── entities/
│   │   ├── index.ts
│   │   └── job-models.ts
│   ├── job-list.component.ts/html/scss
│   ├── job-list-state.ts
│   └── job-interval.pipe.ts
└── job-execution-list/
    ├── data-access/
    │   └── job-execution-list-api.ts
    ├── job-execution-list.component.ts/html/scss
    └── job-execution-color.pipe.ts
```

---

## 3. Shared — Reusable Across Domains

```
shared/
├── components/                           # Presentational UI components
│   ├── bread-crumb/
│   ├── callout/
│   ├── dialogs/
│   ├── date-time-picker/
│   ├── nj-container/
│   ├── nj-pagination/
│   ├── nj-switch/
│   ├── progress-bar/
│   └── ...
├── directives/
│   ├── permissions-only/
│   ├── overflow-tooltip/
│   ├── ace-editor/
│   └── ...
├── pipes/
│   ├── bytes/
│   ├── duration/
│   ├── utc-to-local/
│   └── ...
├── services/                             # Cross-domain injectable services
│   ├── base-state.ts                     # Abstract base for all signal states
│   ├── permissions/
│   ├── user/                             # user-session, user-properties
│   ├── network/                          # connection service
│   └── ...
├── domain/                               # Cross-domain state (no UI, no routes)
│   └── config/                           # Server config used by multiple domains
│       ├── data-access/
│       └── config-state.ts
├── api/                                  # APIs used by 2+ domains (rare)
├── models/
├── interfaces/
├── enums/
├── constants/
└── utilities/                            # Helpers that depend on Angular (vs core/utils which are pure)
```

---

## 4. Tsconfig Path Aliases

```json
{
  "paths": {
    "@core/*": ["app/core/*"],
    "@shared/*": ["app/shared/*"],
    "@domain/*": ["app/domain/*"]
  }
}
```

Within the same domain, use relative imports. Across boundaries, use aliases.

---

## 5. Barrel File Strategy

- `data-access/index.ts` and `entities/index.ts` — always have barrels (small, focused)
- `_shared/` — barrel if 3+ export files
- Domain root — no barrel (domains are lazy-loaded, not imported by others)
- `shared/` and `core/` root — no mega barrel; each subdirectory can have its own

---

## 6. Migration Strategy (Incremental)

**Phase 1 — Structure + easy moves**
1. Create `domain/` directory
2. Move `feature/administration/` → `domain/operations/` (already uses target pattern)
3. Move `feature/my-account/`, `feature/properties/`, `feature/logger-settings/`
4. Move `header/`, `footer/` → `core/layout/`
5. Add `@domain/*` tsconfig path alias
6. Update route configs

**Phase 2 — Standalone features**
7. Move `auth/` + `sso/` → `domain/auth/`
8. Move `error-list/`, `notifications/`, `rules/`, `plugins/`

**Phase 3 — Large domains (incremental refactoring)**
9. `argos/` → `domain/argos/` (introduce `data-access/` / `entities/` as subfeatures are touched)
10. `administration/` → `domain/administration/`
11. `trees-viewer/` → `domain/trees-viewer/`

**Phase 4 — Clean up core**
12. Move domain-specific API services from `core/services/api/<name>/` into their domain's `_shared/api/` or subfeature's `data-access/`

**Phase 5 — Retire legacy**
13. Replace Promise-based `api/manual/endpoints/` with Observable-based `data-access/` APIs as features are refactored

---

## Verification

After each migration phase:
1. `ng build` — must compile without errors
2. `ng lint` — no new lint violations
3. Verify no circular dependencies via `madge --circular`
4. Spot-check lazy loading still works (routes load the correct domain modules)
5. Run existing tests for moved features
