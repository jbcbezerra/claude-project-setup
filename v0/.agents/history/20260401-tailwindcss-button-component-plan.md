# Session: TailwindCSS Button Component Plan

**Date:** 2026-04-01
**Goal:** Plan the introduction of TailwindCSS to the Angular 17 project and design a reusable `nj-button` component with Cypress component tests, as the first step in migrating away from PrimeNG/Material UI.

---

## Claude Session Brain

### Session transcript
- `/home/joao/.claude/projects/-home-joao-Coding-work-njams-server-trunk-njams-frontend/5a90762a-6200-4675-891d-ebe3e278c4de.jsonl`

### Session working directory
- `/home/joao/.claude/projects/-home-joao-Coding-work-njams-server-trunk-njams-frontend/5a90762a-6200-4675-891d-ebe3e278c4de/`

---

## Summary

Analyzed the full Angular project setup (Angular 17.3.10, custom webpack builder, PrimeNG + PrimeFlex + Material coexistence, SCSS pipeline, Cypress E2E-only config) and the existing button styles in `_pbutton.scss` and `_buttons.scss`. Produced a detailed implementation plan for:

1. Installing TailwindCSS v3 with `tw-` prefix to avoid PrimeFlex collisions
2. Configuring PostCSS and Tailwind (preflight disabled, color tokens mirrored from `_colors.scss`)
3. Creating a standalone `nj-button` component with signals API supporting 7 variants, 3 sizes, disabled state, and icon-only mode
4. Setting up Cypress component testing infrastructure
5. Writing 10 component tests covering all button states

The plan was written to `.agents/tasks/20260401-tailwindcss-button-component/plan.md`.

---

## Key Decisions

- **TailwindCSS v3** (not v4) — better Angular/webpack compatibility and mature `prefix` option
- **`tw-` prefix** on all Tailwind classes to prevent collisions with PrimeFlex utilities
- **`preflight: false`** to preserve existing PrimeNG/global styles
- **Standalone component** with signals API (`input()`, `output()`, `computed()`) following project conventions
- **SCSS for variant/state styles** (leveraging existing color variables), Tailwind for structural utilities
- **Cypress component testing** (not just E2E) for isolated button validation
- Color tokens duplicated in `tailwind.config.js` from `_colors.scss` with cross-reference comments
