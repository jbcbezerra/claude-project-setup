# Phase 1: Native Replacements — lodash, uuid, file-saver

## Context

Three utility libraries (`lodash`, `uuid`, `file-saver`) are used minimally and can be fully replaced with native browser APIs. This is the lowest-risk modernization step with zero behavioral changes.

**Dependencies:** None. Can start immediately.
**Estimated effort:** 1–2 hours per library.
**Bundle savings:** ~28 KB gzipped.

---

## 1A. Remove lodash

**Current version:** 4.14.119 (types only — `@types/lodash`)
**Files affected:** 8

### Inventory of usages

| File | Usage | Replacement |
|------|-------|-------------|
| `src/app/argos/dashboard/editor/editor.component.ts` | `_.cloneDeep(c)` | `structuredClone(c)` |
| `src/app/header/messaging-state-icon/messaging-state-dashboard/messaging-state-dashboard.component.ts` | `lowerCase(str)` | `str.replace(/([A-Z])/g, ' $1').trim().toLowerCase()` |
| `src/app/trees-viewer/nj-main/nj-process-details/nj-events-content/nj-events-content.component.ts` | `lowerCase(str)` | Same as above |
| `src/app/core/utils/uri.ts` | `import { replace } from 'lodash'` | Dead import — delete the line |
| `src/app/argos/dashboard/editor/joint/paper.ts` | `import _ from 'lodash'` | Dead import — delete the line |

### Steps

1. **Replace `_.cloneDeep`** in `editor.component.ts`:
   - Find: `import _ from 'lodash'` and all `_.cloneDeep(...)` calls
   - Replace with: `structuredClone(...)` (native, supported in all modern browsers)
   - Note: `structuredClone` handles the same deep-clone cases as `_.cloneDeep` for plain objects/arrays

2. **Replace `lowerCase`** in 2 files:
   - Lodash `lowerCase` converts `camelCase` → `camel case`, `PascalCase` → `pascal case`
   - Create a small utility or inline: `str.replace(/([A-Z])/g, ' $1').trim().toLowerCase()`
   - Alternatively, if the input is already lowercase/simple: just use `.toLowerCase()`
   - **Verify** what the actual input values are before choosing the replacement

3. **Delete dead imports** in `uri.ts` and `paper.ts`:
   - These files import lodash but never use the imported symbols
   - Simply remove the import lines

4. **Remove from package.json:**
   - Remove `@types/lodash` from `devDependencies`
   - Verify lodash is not in `dependencies` (it shouldn't be — only types are installed)

### Verification
- `npm run build` — no compilation errors
- `npm run test` — all tests pass
- Manual: verify dashboard editor cloning works, messaging state labels display correctly, events content labels display correctly

---

## 1B. Remove uuid

**Current version:** 9.0.1
**Files affected:** ~13

### Inventory of usages

All usages follow the pattern:
```typescript
import { v4 as uuidv4 } from 'uuid';
// ...
const id = uuidv4();
```

**Key files:**
- `src/shared/services/textcomplete/completer.model.ts`
- `src/trees-viewer/nj-main/nj-process-details/nj-input-mapping/` (multiple files)
- `src/argos/dashboard/charts/default-chart-config.ts`
- `src/argos/dashboard/editor/` (multiple files)

### Steps

1. **Find all uuid imports:**
   ```
   grep -r "from 'uuid'" src/
   ```

2. **Replace each usage:**
   - `uuidv4()` → `crypto.randomUUID()`
   - `crypto.randomUUID()` is available in all modern browsers and returns the same UUID v4 format
   - Remove the `import { v4 as uuidv4 } from 'uuid'` line from each file

3. **Remove from package.json:**
   - Remove `uuid` from `dependencies`
   - Remove `@types/uuid` from `devDependencies`

### Verification
- `npm run build` — no compilation errors
- `npm run test` — all tests pass
- Manual: create new dashboard components, input mappings — verify IDs are generated correctly

---

## 1C. Remove file-saver

**Current version:** 2.0.2
**Files affected:** 5

### Inventory of usages

- `src/core/utils/file.ts` — main utility that imports `saveAs` from `file-saver`
- `src/error-list/email-alerts/email-alerts-list/email-alerts-list.component.ts`
- `src/trees-viewer/nj-custom-report/nj-custom-report.service.ts`
- 2 other files that use the `file.ts` utility indirectly

### Steps

1. **Create native saveAs in `src/core/utils/file.ts`:**
   ```typescript
   export function saveAs(blob: Blob, filename: string): void {
     const url = URL.createObjectURL(blob);
     const a = document.createElement('a');
     a.href = url;
     a.download = filename;
     document.body.appendChild(a);
     a.click();
     document.body.removeChild(a);
     URL.revokeObjectURL(url);
   }
   ```

2. **Update imports** in all files that import from `file-saver`:
   - Change `import { saveAs } from 'file-saver'` → `import { saveAs } from '@core/utils/file'`
   - Or if they already use `file.ts`, just ensure the function is exported from there

3. **Remove from package.json:**
   - Remove `file-saver` from `dependencies`
   - Remove `@types/file-saver` from `devDependencies`

### Verification
- `npm run build` — no compilation errors
- `npm run test` — all tests pass
- Manual: test file export in email alerts list, custom report export, any other download functionality
