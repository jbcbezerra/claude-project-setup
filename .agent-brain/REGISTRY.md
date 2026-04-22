# Agent Brain Registry

> Index of all brain files. Read this FIRST every session.

## Context

<!-- Tier 1: Read on session start -->

## Rules

<!-- Hard constraints for writing code -->

### Frontend (Angular)

- [Angular General](rules/frontend/angular-general.md) — Standalone-only (no NgModules), `inject()` DI, inline types, arrow functions for utilities, relative-path imports, `type` over `interface`.
- [Component](rules/frontend/component.md) — Components extend `BaseComponent`, `inject()` for DI, `readonly` fields, signal-based `input()`/`output()`, `computed()` for derivations, pure helpers as module-level const arrows, `DestroyRef` over `OnDestroy`.
- [Templates](rules/frontend/templates.md) — Built-in control flow (`@if`/`@for`/`@switch`) with mandatory `track`, no method calls in display bindings, native `[class]`/`[style]` over `NgClass`/`NgStyle`, Tailwind arbitrary-value gotcha (`text-[0.65rem]` needs object-map `[class]` binding), self-closing rules, section comments.
- [File Organization](rules/frontend/file-organization.md) — Domain layout under `src/app/domain/<name>/`, `pages/`+`components/` split at domain root, fractal `components/` nesting, no `.component`/`.service` suffixes, `models/` for types/mappers/constants, `*-state.ts` state services, `{component}-utils.ts` for sibling-shared helpers, barrel exports.
- [Styling](rules/frontend/styling.md) — Tailwind CSS 4 is the styling framework. Theme tokens from `src/styles.css` `@theme`, `dark:` variant for dark mode, `host:` metadata for classes + input-driven bindings, `rem` over `px`.
- [Linting & Formatting](rules/frontend/linting.md) — ESLint flat config via `angular-eslint` + `typescript-eslint` + `eslint-config-prettier/flat`; scripts (`lint`, `lint:fix`, `format`, `format:check`); template a11y rules; allowed exception: attribute-selector components for DOM-native tags.
- [Output Naming](rules/frontend/output-naming.md) — Never name `output()` after DOM events. Prefer `pressed`, `copyRequest`, `closed`, `searchChanged`. Avoids `@angular-eslint/no-output-native` suppression AND the native-event double-fire.
- [API Services](rules/frontend/api-services.md) — Conventions for domain API files in `core/services/api/<domain>/<domain>-api.ts` (naming, `Api` injection, endpoint-comment grouping, `HttpParams`, anti-patterns).
- [DTOs, Mappers & Domain Models](rules/frontend/dto-mapper-models.md) — DTOs live next to the API service; Models + Mappers live in the component's `models/` folder. `type` over `interface`, DTOs use `?:` + `string` dates, models use `| null` + `dayjs.Dayjs`, mappers named `to{Model}`/`to{Model}List`.
- [Datetime](rules/frontend/datetime.md) — Day.js is the only date library; plugins load centrally in `core/utils/dayjs-init.ts`; no `dayjs.Dayjs` in public signatures.
- [Testing](rules/frontend/testing.md) — `.spec.ts` co-located, `dayjs-init` side-effect in specs, `data-cy` selectors + naming, Cypress test scope, mount-helper idiom, shared mocks under `tests/mocks/`, Vitest setup gotchas + hygiene, never mock `DOCUMENT`.

## Patterns

<!-- Code templates to copy from -->

### Frontend (Angular)

- [BaseComponent](patterns/frontend/base-component.md) — Abstract base class every `@Component` extends. Injects `Logger`, emits an init debug line. Pairs with `rules/frontend/component.md`.
- [BaseService](patterns/frontend/base-service.md) — Abstract base class API services and stateful singletons extend. Injects `Logger`, emits an init debug line. Pairs with `rules/frontend/api-services.md`.
- [Api / BaseApi](patterns/frontend/api-http-client.md) — `HttpClient` wrapper every domain API injects. Centralizes base URL, headers, `take(1)`, endpoint normalization. `BaseApi` is abstract + generic; `Api` is the concrete singleton.
- [Logger](patterns/frontend/logger.md) — Level-filtered, session-persistent logger. Supporting pattern for BaseComponent and BaseService.
- [Dumb Component](patterns/frontend/dumb-component.md) — Canonical shape for a presentational component: inputs + `computed()`, `host:` classes, no wrapper `div`, empty `.scss`, module-level pure helpers.

## Decisions

<!-- ADRs explaining non-obvious choices -->

## Knowledge

<!-- Domain logic, business rules, external API docs -->

## Workflows

- [New Feature Area](workflows/new-feature-area.md) — Adding modules with knowledge capture
- [Post-Migration](workflows/post-migration.md) — After large migrations or refactors
- [Onboard Agent](workflows/onboard-agent.md) — Session start orientation
- [Conform Dumb Component](workflows/conform-dumb-component.md) — Per-component subagent playbook to retrofit a presentational component to brain rules + ship a passing component spec. Fan out in parallel.

## Commands

<!-- Terminal command reference -->

## Specs

<!-- Design specs from superpowers:brainstorming -->

## Tasks

<!-- Active implementation plans and handoffs -->

## Log

<!-- Execution summaries -->

## Inbox

<!-- User drop zone for unstructured input — process with /brain-promote -->
