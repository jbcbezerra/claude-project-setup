# Session: Material to PrimeNG Migration Plan

**Date:** 2026-04-01
**Goal:** Analyze all Angular Material usages across the njams-frontend project and create a detailed phased migration plan to replace them with PrimeNG v17 components.

---

## Claude Session Brain

### Session transcript
- `/home/joao/.claude/projects/-home-joao-Coding-work-njams-server-branches-njams-server-6-1-X-njams-frontend/814cc078-c5ba-480d-9ec4-d7a52cff0d18.jsonl`

### Session working directory
- `/home/joao/.claude/projects/-home-joao-Coding-work-njams-server-branches-njams-server-6-1-X-njams-frontend/814cc078-c5ba-480d-9ec4-d7a52cff0d18/`

---

## Summary

Performed a comprehensive codebase analysis of all Angular Material (16.2.14 legacy) usages across the project. Found Material in ~107 TS files and ~65 HTML templates, while PrimeNG 17.18.0 is already the dominant UI library (295+ imports). Created a detailed 8-phase migration plan covering: dead code cleanup, tooltips, selects/dropdowns (34 files), autocomplete (4 files), simple tables (8 files), tables with SelectionModel (21 files), paginators (2 files), and final cleanup/uninstall.

Key findings:
- The NjDialog system already uses PrimeNG in its template despite importing Material modules (dead code)
- No `mat-checkbox`, `mat-button`, or `mat-icon` usage in any HTML templates
- CDK `SelectionModel` is used in 21 files for table row selection
- CDK Virtual Scroll (tree component) should be kept as `@angular/cdk` is independent of `@angular/material`
- Existing PrimeNG table patterns (sessions, failsafe, index-tasks) serve as reference implementations

---

## Key Decisions

- Migration ordered by risk: low-risk first (dead code, tooltips), highest-risk last (tables with selection)
- `@angular/cdk` will be kept installed for virtual scroll in tree.component.ts
- PrimeNG's built-in table pagination replaces standalone `mat-paginator` (only 2 instances)
- `SelectionModel` replaced by `p-table`'s `[(selection)]` + `p-tableCheckbox` pattern
- `material.module.ts` deleted after Phase 2 (select migration) since it only provides `MAT_LEGACY_SELECT_CONFIG`
- Plan written to `.agents/tasks/20260401-material-to-primeng-migration/plan.md`
