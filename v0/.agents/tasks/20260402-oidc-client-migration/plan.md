# Phase 3: oidc-client → oidc-client-ts Migration

## Context

`oidc-client` v1.10.1 is deprecated and unmaintained since 2021. It has known security advisories. `oidc-client-ts` is the actively maintained TypeScript fork by the same community, with a near-identical API surface. Only 2 files in the project import from this library.

**Dependencies:** None. Can start immediately.
**Estimated effort:** 1–2 hours + SSO testing.
**Bundle savings:** Neutral (same size, different package).

---

## Inventory

### Files affected

1. **`src/app/sso/oidc-adapter.ts`**
   - Imports: `OidcClientSettings`, `UserManager`
   - Creates UserManager instance for SSO flow

2. **`src/core/services/api/user/user-api.service.ts`**
   - Imports: `User` type from `oidc-client`
   - Uses the User type for SSO user data

---

## Steps

### 1. Install oidc-client-ts
```bash
npm install oidc-client-ts
npm uninstall oidc-client
```

### 2. Update imports in oidc-adapter.ts
```typescript
// Before
import { OidcClientSettings, UserManager } from 'oidc-client';

// After
import { UserManagerSettings, UserManager } from 'oidc-client-ts';
```

**Key API changes:**
- `OidcClientSettings` → `UserManagerSettings` (renamed interface)
- `UserManager` constructor API is the same
- `signinRedirect()`, `signinRedirectCallback()`, `signoutRedirect()` — same API
- `getUser()` returns `Promise<User | null>` — same
- Some settings may have new optional fields or deprecated fields — review the settings object

### 3. Update imports in user-api.service.ts
```typescript
// Before
import { User } from 'oidc-client';

// After
import { User } from 'oidc-client-ts';
```

The `User` type interface is compatible — has `profile`, `access_token`, `id_token`, `expired`, etc.

### 4. Check for any other references
```bash
grep -r "oidc-client" src/ --include="*.ts"
```

### 5. Package cleanup
- Remove `oidc-client` from `dependencies` in `package.json`
- `oidc-client-ts` is now the replacement

---

## Verification

1. `npm run build` — no compilation errors
2. `npm run test` — all tests pass
3. **Manual testing (critical — SSO is auth-sensitive):**
   - Test full SSO login flow with the configured identity provider
   - Test SSO logout flow
   - Test token refresh / session persistence
   - Test silent renew if configured
   - Verify user profile data is correctly parsed after login
4. Test with OIDC provider in both redirect and popup modes if both are used
