# Session: UIRouter to Angular Router Migration Analysis

**Date:** 2026-04-01
**Goal:** Produce a comprehensive analysis and migration blueprint for migrating the nJAMS Frontend from `@uirouter/angular` to `@angular/router`.

---

## Claude Session Brain

### Session transcript
- `/home/joao/.claude/projects/-home-joao-Coding-work-njams-server-branches-njams-server-6-1-X-njams-frontend/01d44117-2214-419b-9b6c-60b7587adf66.jsonl`

### Session working directory
- `/home/joao/.claude/projects/-home-joao-Coding-work-njams-server-branches-njams-server-6-1-X-njams-frontend/01d44117-2214-419b-9b6c-60b7587adf66/`

---

## Summary

Performed a full codebase scan of the Angular 17 project's UIRouter usage and produced a detailed migration blueprint at `.agents/tasks/20260401-uirouter-to-angular-router-migration/plan.md`.

Key findings:
- 110+ UI-Router states across 65+ route files
- 40+ named view usages (~30 `<ui-view>` tags in 15+ templates) — the biggest migration challenge
- 50+ query parameters on the abstract `app.njams` state with squash/dynamic/raw behavior
- 9 hook files with 20+ transition hooks → must become Angular guards
- 28+ resolve files → must become functional `ResolveFn` or `APP_INITIALIZER`
- 185+ programmatic navigation calls all routed through a centralized `RouterStateService` — highest-leverage adaptation point
- 72 `UIRouterModule.forChild()` + 1 `forRoot()` to convert
- No sticky states or deep state redirect plugins in use

Files created:
- `.agents/tasks/20260401-uirouter-to-angular-router-migration/plan.md` — full migration blueprint

---

## Key Decisions

- Named views (the #1 gap) will be handled with a hybrid strategy: conditional rendering for app shell regions, layout wrapper components for feature layouts, and unnamed `<router-outlet>` for content switching
- `RouterStateService` is the highest-leverage target — adapting it shields 185+ navigation call sites from change
- Migration order: leaf modules first → feature modules → argos → trees viewer (most complex) → core shell → cleanup
- Estimated duration: 8-12 weeks (parallel) or 11-17 weeks (sequential)
- No `RouteReuseStrategy` needed since no sticky states or DSR are in use
