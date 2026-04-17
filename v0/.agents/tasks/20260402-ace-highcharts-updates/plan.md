# Phase 4: Ace Editor & Highcharts Version Updates

## Context

`ace-builds` is at v1.4.2 (from 2018, current stable is ~1.36+) and `ace-diff` is at v2.3.0 (current is 3.x). Both have years of bug fixes, performance improvements, and security patches. The existing Angular directive wrappers use stable Ace APIs and should survive the update with minimal changes.

`highcharts` is at v11.1.0 (reasonably recent, latest is ~11.4+). A minor version bump is low risk.

**Dependencies:** None. Can start immediately.
**Estimated effort:** 3–5 hours for Ace, 1 hour for Highcharts.

---

## 4A. Update ace-builds (1.4.2 → latest)

### Current integration

**Custom wrappers:**
- `src/shared/directives/ace-editor/ace-editor.directive.ts` — main Ace directive
- `src/shared/directives/ace-editor/nj-ace-editor.ts` — custom wrapper class
- `src/shared/directives/ace-diff-editor/ace-diff-editor.directive.ts` — diff editor directive

**Webpack aliases** in `webpack.config.js` (lines 63–69):
```javascript
'ace': path.resolve(__dirname, 'node_modules/ace-builds/src-min'),
'brace': path.resolve(__dirname, 'node_modules/ace-builds/src-min'),
'ace-diff': path.resolve(__dirname, 'node_modules/ace-diff/dist'),
```

**Module imports** in `app.module.ts` (lines 9–21):
```typescript
import 'ace-builds/src-min/mode-json';
import 'ace-builds/src-min/mode-javascript';
import 'ace-builds/src-min/mode-xml';
// ... etc
```

**Files using Ace:** ~47 files (through the directive wrapper)

### Steps

1. **Update packages:**
   ```bash
   npm install ace-builds@latest
   npm install ace-diff@latest
   ```

2. **Check Ace module path structure:**
   - In ace-builds 1.4.x, modes/themes are at `ace-builds/src-min/mode-json`
   - In newer versions, they may be at `ace-builds/src-min-noconflict/mode-json`
   - Update all import paths in `app.module.ts` accordingly
   - Update webpack aliases if the directory structure changed

3. **Review ace-diff 2.x → 3.x breaking changes:**
   - ace-diff 3.x has a different constructor API
   - Update `AceDiffEditorDirective` to match the new API
   - Key changes: configuration options may be renamed, DOM structure may differ
   - Read the ace-diff changelog/migration guide

4. **Update @types packages:**
   ```bash
   npm install @types/ace@latest @types/ace-diff@latest
   ```
   Or check if newer ace-builds ships its own types (making @types unnecessary).

5. **Test all editor modes** used in the project:
   - JSON mode (most common)
   - JavaScript mode
   - XML mode
   - SQL mode
   - HTML mode
   - Groovy mode
   - Plain text mode

### Key files to modify
- `webpack.config.js` — update aliases if path structure changed
- `src/app/app.module.ts` — update import paths for modes/themes
- `src/shared/directives/ace-diff-editor/ace-diff-editor.directive.ts` — update for ace-diff 3.x API
- `src/argos/rule-overview/rule-completions.ts` — direct ace import, verify compatibility
- `package.json` — version bumps

### Risk areas
- ace-diff 2.x → 3.x is a major version change — the diff editor directive needs careful review
- Webpack aliases may need adjustment for new file paths
- Custom completions in `rule-completions.ts` may use internal Ace APIs that changed

---

## 4B. Update highcharts (11.1.0 → latest)

### Current integration

**Custom wrapper:** `src/shared/components/nj-highcharts/nj-highcharts.component.ts`
- Simple wrapper: calls `Highcharts.chart(el, config)` in `ngAfterViewInit`
- Manages chart destruction in `ngOnDestroy`
- Input: `@Input() config: Highcharts.Options`

**Theme:** `src/shared/components/nj-highcharts/default-theme.ts`
- Extends Highcharts prototypes (`Point.prototype.highlight`, `Pointer.prototype.reset`)
- Sets global options via `Highcharts.setOptions()`

**Module declarations:** `src/app/types/external-libraries.d.ts`
- Custom `declare module` for highcharts sub-modules

**Files using charts:** ~25

### Steps

1. **Update package:**
   ```bash
   npm install highcharts@latest
   ```

2. **Check for breaking changes** in Highcharts 11.1 → 11.4:
   - Review Highcharts changelog for deprecated options
   - The project uses: highcharts-more, map, exporting, drilldown, funnel, heatmap, sankey, treemap, xrange, boost, solid-gauge, broken-axis
   - Most of these are stable modules unlikely to have breaking changes in a minor version bump

3. **Verify custom type declarations** in `external-libraries.d.ts`:
   - Check if newer highcharts ships better TypeScript types
   - If so, the custom `declare module` entries may be unnecessary and can be removed

4. **Decision: Keep custom wrapper vs. adopt highcharts-angular:**
   - **Recommendation: Keep custom wrapper**
   - The wrapper is ~116 lines, well-tested, and works correctly
   - `highcharts-angular` adds a dependency for marginal benefit
   - Only consider switching if the wrapper needs significant changes for the new version

### Key files to verify
- `src/shared/components/nj-highcharts/nj-highcharts.component.ts` — wrapper still works
- `src/shared/components/nj-highcharts/default-theme.ts` — prototype extensions still valid
- `src/app/types/external-libraries.d.ts` — type declarations still needed
- `src/argos/dashboard/charts/charts.component.ts` — chart usage
- All metric dashboard components

---

## Verification

1. `npm run build` — no compilation errors
2. `npm run test` — all tests pass
3. **Manual testing:**
   - **Ace Editor:** Open every type of editor in the app (rule editor, email alert editor, config editors, replay viewer). Verify syntax highlighting, code completion, diff view all work.
   - **Highcharts:** Open dashboards with charts. Verify rendering, tooltips, drilldown, export, zoom. Check Gantt chart in process details. Check metric charts in administration dashboard.
4. Check browser console for deprecation warnings from either library
