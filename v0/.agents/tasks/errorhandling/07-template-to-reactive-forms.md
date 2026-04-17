# Migrate Template-Driven Forms to Reactive Forms

## Context

Several components still use legacy `ngForm`/`ngModel` template-driven forms while the rest of the codebase has moved to reactive forms with `NonNullableFormBuilder`. These legacy forms can't use the custom validators in `src/app/core/utils/form-validators/`, can't participate in the unified error display pattern (Task 05), and have less testable validation logic embedded in templates.

### Legacy Template-Driven Forms

- `src/app/auth/component/login/login.component.ts` — Login form
- `src/app/auth/component/create-admin/create-admin.component.ts` — Admin creation form
- `src/app/administration/user-admin/user-admin-list/set-password/set-password.component.ts` — Password setting form
- `src/app/administration/jndi-admin/jndi-admin-edit/jndi-admin-edit.component.ts` — JNDI admin edit
- `src/app/administration/jndi-admin/jndi-admin-edit/jndi-admin-edit.component.html` — Template with ngForm/ngModel
- `src/app/administration/jms-admin/jms-admin-edit/jms-admin-edit.component.ts` — JMS admin edit
- `src/app/administration/authentication-configuration/openid-connect.component.ts` — OpenID Connect config
- `src/app/sso/sso.component.ts` — SSO component

### Existing Reactive Form Patterns (Reference)

- `src/app/feature/my-account/user-change-password/user-change-password.component.ts` — Canonical reactive form example
- `src/app/feature/administration/system-configuration/system-configuration.abstract.ts` — Abstract base for config forms
- `src/app/administration/argos/general-settings-form/general-settings-form.component.ts` — Reactive form with validators

---

## Approach

### Migration Pattern

For each template-driven form:

```typescript
// Before (template-driven)
@ViewChild('myForm') form: NgForm;
username: string;
password: string;

// Template: <input [(ngModel)]="username" name="username" required>

// After (reactive)
private fb = inject(NonNullableFormBuilder);
form = this.fb.group({
  username: ['', Validators.required],
  password: ['', Validators.required],
});

// Template: <input [formControl]="form.controls.username">
```

### Migration Rules

1. **All `[(ngModel)]` bindings** become `FormControl` references
2. **Template validation attributes** (`required`, `minlength`, `pattern`) move to FormBuilder validators
3. **`#form="ngForm"` references** become the `FormGroup` class property
4. **`form.valid` / `form.invalid`** checks use the reactive form group
5. **Submit handlers** access `form.getRawValue()` instead of individual bound properties
6. **Remove `FormsModule`** imports if the component no longer needs template-driven forms

### Files to Migrate

**Auth forms (critical path):**
1. `src/app/auth/component/login/login.component.ts` + `.html` — Login form (username, password, optional fields)
2. `src/app/auth/component/create-admin/create-admin.component.ts` + `.html` — Admin creation (username, password, confirm)
3. `src/app/administration/user-admin/user-admin-list/set-password/set-password.component.ts` + `.html` — Password setting

**Admin forms:**
4. `src/app/administration/jndi-admin/jndi-admin-edit/jndi-admin-edit.component.ts` + `.html` — JNDI configuration
5. `src/app/administration/jms-admin/jms-admin-edit/jms-admin-edit.component.ts` + `.html` — JMS configuration

**SSO/Auth config:**
6. `src/app/administration/authentication-configuration/openid-connect.component.ts` + `.html` — OpenID Connect
7. `src/app/sso/sso.component.ts` + `.html` — SSO flow

### Scope

- ~8 components (with their templates)
- Each component: convert to NonNullableFormBuilder, migrate validation to TypeScript, update template bindings
- Do NOT change form behavior or validation rules — only the implementation pattern

---

## Execution

Process by risk level:
1. **Admin forms first** (JNDI, JMS) — Lower traffic, simpler forms, good practice run
2. **Password/admin creation** — Medium complexity
3. **Login form last** — Highest traffic, most critical. Extra careful testing.
4. **SSO/OpenID Connect** — Complex auth flows, test with SSO provider

For each form:
1. Create the reactive `FormGroup` in the component
2. Update the template to use `formControl`/`formGroup` directives
3. Update submit handler to use `form.getRawValue()`
4. Update tests if they exist
5. `ng build` → manual testing → move to next

---

## Verification

1. `ng build` — Compiles after each migration
2. **Login flow works** — Can log in with valid credentials, validation errors show for empty fields
3. **Admin creation works** — Can create admin user, password validation works
4. **Password setting works** — Can set password, confirm password matches
5. **JNDI/JMS forms work** — Can create/edit configurations
6. **SSO flow works** — Redirect and callback still function
7. `npm run test:prod` — Tests pass
8. Grep for `ngModel` in production code → Only in components that legitimately need two-way binding (not forms)
9. Grep for `ngForm` → Zero results

---

## Dependencies

- This task unblocks Task 05 (Unified Form Validation Display) for auth forms
- Should be coordinated with the standalone migration task if those components are being migrated simultaneously
