# Phase 5: Specialized Library Cleanup

## Context

Several remaining libraries need type fixes, maintenance updates, or can be left as-is. This phase addresses JointJS type mismatches, replaces the unmaintained `pegjs`, and documents decisions for libraries that should be kept.

**Dependencies:** Phase 2 (jQuery removal) should complete first for clean JointJS type work.
**Estimated effort:** 2–3 hours.

---

## 5A. JointJS — Fix Type Mismatch

### Problem
- `jointjs` is at v3.4.2 but `@types/jointjs` is at v2.0.0 — major version mismatch
- JointJS 3.x ships its own TypeScript definitions
- The outdated `@types/jointjs` may cause incorrect type checking and IDE errors

### Files using JointJS (~16 files)
- `src/argos/dashboard/editor/joint/rect.ts`
- `src/argos/dashboard/editor/joint/paper.ts`
- `src/argos/dashboard/editor/joint/link.ts`
- `src/argos/dashboard/editor/joint/graph.ts`
- `src/argos/dashboard/editor/editor.component.ts`
- `src/argos/dashboard/cell-updater.service.ts`
- Several other dashboard editor files

### Steps

1. **Remove outdated type packages:**
   ```bash
   npm uninstall @types/jointjs @types/backbone
   ```

2. **Verify JointJS 3.x built-in types work:**
   - Run `npm run build` and check for type errors in JointJS-related files
   - If JointJS types reference `dia`, `g`, `shapes` namespaces — these should resolve from the package itself

3. **Fix any type errors** that arise from the type package switch:
   - Some custom type augmentations may be needed
   - Check imports like `import { dia, g, shapes } from 'jointjs'` still resolve

4. **Note for future:** JointJS 4.x is expected to drop jQuery/Backbone dependencies. When released, upgrading to 4.x will allow full jQuery removal from `node_modules`.

---

## 5B. Replace pegjs with peggy

### Problem
`pegjs` v0.10.0 is unmaintained (last release 2017). `peggy` is the actively maintained community fork with the same API and `.pegjs` grammar format.

### Current usage
- Search for `.pegjs` file imports and pegjs-loader in webpack config
- Used for rule/expression parsing in ~2 files

### Steps

1. **Install replacement:**
   ```bash
   npm install peggy
   npm uninstall pegjs
   ```

2. **Update webpack loader:**
   - Replace `pegjs-loader` with `peggy-loader` in `webpack.config.js`
   - The loader config format is the same

3. **Update any programmatic usage:**
   ```typescript
   // Before
   import * as peg from 'pegjs';
   // After
   import * as peggy from 'peggy';
   ```
   - If only `.pegjs` files are imported (processed by the loader), no code changes needed

4. **Remove from angular.json** `allowedCommonJsDependencies` if `pegjs` is listed

---

## 5C. Libraries to Keep As-Is

### svg-pan-zoom (v3.6.0)
- **Decision: KEEP**
- Only 3 files, well-contained in zoom services
- No security concerns, no jQuery dependency
- Alternatives (panzoom, d3-zoom) offer no advantage at this scale

### x2js (v3.2.3)
- **Decision: KEEP**
- Only 1 file (`nj-diagram-configuration.service.ts`)
- Specialized XML↔JSON conversion
- Small and stable

### jmespath (v0.16.0)
- **Decision: KEEP**
- Only used in `jmes-path-generator.service.ts`
- Specialized JMESPath query language implementation
- No alternative needed

### js-yaml (v4.1.0)
- **Decision: KEEP**
- Only 1 file (`font-icon-picker.component.ts`)
- YAML parsing — no Angular-specific alternative exists
- Already at a recent version

### dayjs (v1.11.10)
- **Decision: KEEP** — this is the modern replacement being migrated TO
- See `.agents/tasks/20260402-moment-to-dayjs-consolidation/plan.md`

---

## Verification

1. `npm run build` — no compilation errors after type changes
2. `npm run test` — all tests pass
3. **Manual testing:**
   - Dashboard editor: create/edit/move diagram elements (JointJS)
   - Any rule/expression parser features (peggy)
4. Verify no new TypeScript errors in IDE for JointJS files
