# Unify Form Validation Error Display

## Context

The codebase has 3 different patterns for displaying form validation errors:

1. **PrimeNG pTooltip + icon** (most common) — Error icon with tooltip containing message. Used in password change, user admin, system config forms.
2. **Angular Material mat-error** (limited use) — Used in rules-action, rule-condition, follow-up, replay-as components.
3. **Raw *ngIf/@if conditionals** — Inline error text rendered conditionally. Used across various admin forms.

This creates inconsistent UX (users see different error display styles depending on which form they're in) and forces every new form author to pick a pattern and implement it from scratch. Validation messages are also scattered across individual components rather than centralized.

### Current Validator Library

Custom validators in `src/app/core/utils/form-validators/`:
- `general.validators.ts` — `noSpacesValidator` → `{ containsSpaces: true }`
- `password.validator.ts` — `passwordsMatchValidator` → `{ passwordsMismatch: true }`, `notSameAsOldPasswordValidator` → `{ oldPasswordSameAsNew: true }`

Abstract base: `src/app/feature/administration/system-configuration/system-configuration.abstract.ts`

---

## Approach

### Step 1: Create a Shared Form Field Error Component

Create `src/app/shared/components/form-field-error/form-field-error.component.ts`:

```typescript
@Component({
  selector: 'app-form-field-error',
  standalone: true,
  template: `
    @if (control?.invalid && control?.touched) {
      <small class="form-field-error">{{ errorMessage | translate }}</small>
    }
  `
})
export class FormFieldErrorComponent {
  control = input<AbstractControl | null>();
  messages = input<Record<string, string>>({});
  // Computes the first matching error message
}
```

### Step 2: Create a Default Validation Message Map

Create `src/app/core/utils/form-validators/validation-messages.ts`:

```typescript
export const DEFAULT_VALIDATION_MESSAGES: Record<string, string> = {
  required: 'validation.required',
  minlength: 'validation.minlength',
  maxlength: 'validation.maxlength',
  pattern: 'validation.pattern',
  email: 'validation.email',
  min: 'validation.min',
  max: 'validation.max',
  containsSpaces: 'validation.no_spaces',
  passwordsMismatch: 'validation.passwords_mismatch',
  oldPasswordSameAsNew: 'validation.old_password_same',
};
```

This integrates with the existing `TranslateService` (ngx-translate) i18n setup.

### Step 3: Migrate Forms to Use Shared Component

Replace inline error display with `<app-form-field-error>`:

**Priority 1 — Canonical examples (establish the pattern):**
- `src/app/feature/my-account/user-change-password/user-change-password.component.html` — Current pTooltip pattern
- `src/app/administration/user-admin/user-admin-edit/user-admin-edit.component.html`

**Priority 2 — System configuration forms (all share abstract base):**
- `src/app/feature/administration/system-configuration/system/system.component.html`
- `src/app/feature/administration/system-configuration/user-management/user-management.component.html`
- `src/app/feature/administration/system-configuration/merger/merger.component.html`
- `src/app/feature/administration/system-configuration/processing/processing.component.html`
- `src/app/feature/administration/system-configuration/retention/retention.component.html`
- `src/app/feature/administration/system-configuration/statistics/statistics.component.html`
- `src/app/feature/administration/system-configuration/jobs/jobs.component.html`

**Priority 3 — Material mat-error components (replace with shared component):**
- `src/app/rules/rules-menu/rule-set-view/rule-view/rules-action/rules-action.component.html`
- `src/app/rules/rules-menu/rule-set-view/rule-view/rule-condition/rule-condition.component.html`
- `src/app/trees-viewer/nj-main/nj-process-details/follow-up/follow-up.component.html`
- `src/app/plugins/nj-replay/app/replay-as/replay-as.component.html`

**Priority 4 — Admin forms:**
- `src/app/administration/jndi-admin/jndi-admin-header/jndi-admin-header.component.html`
- `src/app/administration/data-provider-admin/error-handlers/error-handlers.component.html`
- `src/app/administration/jdbc/jdbc.component.html`
- `src/app/error-list/email-alerts/email-alerts-edit/email-alerts-edit.component.html`
- `src/app/feature/administration/job/job.component.ts`

**Priority 5 — Auth forms (blocked by Task 07 — template-driven → reactive migration):**
- `src/app/auth/component/login/login.component.html`
- `src/app/auth/component/create-admin/create-admin.component.html`
- `src/app/administration/user-admin/user-admin-list/set-password/set-password.component.html`

### Scope

- ~30 form templates to migrate
- 1 new shared component
- 1 new validation messages file
- Add translation keys to i18n files

---

## Execution

1. Create `FormFieldErrorComponent` and `DEFAULT_VALIDATION_MESSAGES`
2. Add translation keys to locale files
3. Migrate the canonical example (`user-change-password`) to validate the pattern
4. Migrate system configuration forms (they share the abstract base, so changes propagate)
5. Migrate Material mat-error forms
6. Migrate remaining admin forms
7. Auth forms last (depends on Task 07)

---

## Verification

1. `ng build` — Compiles after each batch
2. Visual review — Error messages appear consistently across all migrated forms
3. `npm run test:prod` — Tests pass
4. Grep for inline `pTooltip` error patterns and `mat-error` → Count decreasing toward zero
5. All error states still trigger correctly (required, minlength, custom validators)

---

## Dependencies

- Task 07 (Template-Driven → Reactive Forms) should be done first for auth forms, since `FormFieldErrorComponent` requires reactive `FormControl` references.
