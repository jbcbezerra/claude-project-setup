# Session: File Architecture Redesign

**Date:** 2026-04-02
**Goal:** Design a highly maintainable file architecture based on core/domain/shared, with a consistent internal pattern of api service → state service → component for every domain feature.

---

## Claude Session Brain

### Session transcript
- `/home/joao/.claude/projects/-home-joao-Desktop-server-njams-frontend/eee700d7-725d-40dc-a371-cb13f9d33b9b.jsonl`

### Session working directory
- `/home/joao/.claude/projects/-home-joao-Desktop-server-njams-frontend/eee700d7-725d-40dc-a371-cb13f9d33b9b/`

---

## Summary

Performed a comprehensive codebase exploration (~2400 files, 557 directories) to understand the current architecture: scattered top-level feature directories, incomplete core/shared/feature structure, 3 separate API layers, and inconsistent internal patterns across features.

Designed a complete file architecture plan with 3 base layers (core, domain, shared), strict import direction rules, and a standardized internal structure for every domain subfeature using the proven job-list pattern (data-access/ + entities/ + state + component). Identified 12 domain boundaries and a 5-phase incremental migration strategy.

**Created:**
- `.agents/tasks/20260402-file-architecture-redesign/plan.md` — Full architecture plan

---

## Key Decisions

- **3 base directories:** `core/` (singleton infrastructure), `domain/` (business capabilities), `shared/` (reusable cross-domain)
- **Domain name kept as `trees-viewer/`** — not renamed to "monitoring" or "processes"
- **API services colocated with domains** — 30+ domain-specific APIs move out of `core/services/api/` into their domain's `_shared/api/` or subfeature's `data-access/`
- **`_shared/` convention** for domain-wide shared code (underscore prefix sorts first, visually distinct)
- **`header/` and `footer/` move to `core/layout/`** as app-shell infrastructure
- **Max 3 levels deep** within a domain — flatten instead of nesting deeper
- **Barrel files** in `data-access/` and `entities/` always; no mega barrels at domain or shared root
- **Tsconfig path aliases:** `@core/*`, `@shared/*`, `@domain/*` with relative imports within same domain
- **Import direction enforced:** domain → core/shared, shared → core, core → nothing
- **Incremental migration** across 5 phases, starting with features already using the target pattern
