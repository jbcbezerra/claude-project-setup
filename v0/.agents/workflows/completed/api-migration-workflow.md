# API Migration Workflow: Promise-based XHR → Observable-based HttpClient

## Overview

This project has two API layers:
- **Old (Legacy):** `src/app/api/manual/` — Custom XHR-based HTTP client returning `Promise<T>`
- **New (Target):** `src/app/core/services/api/` — Angular `HttpClient`-based services returning `Observable<T>`

This workflow describes how to migrate a single endpoint API from old to new, including updating all consumers.

---

## Prerequisites

Before starting, read these reference files to understand both patterns:
- Old base: `src/app/api/manual/base-api.ts`
- New base: `src/app/core/services/api/base-api.service.ts`
- New extended: `src/app/core/services/api/api.service.ts`
- Example old endpoint: `src/app/api/manual/endpoints/expression/expression-api.ts`
- Example new service: `src/app/core/services/api/user/user-api.service.ts`

---

## Step-by-Step Migration

### Step 1: Analyze the Old Endpoint

1. Read the old endpoint file (e.g., `src/app/api/manual/endpoints/<domain>/<domain>-api.ts`)
2. List all methods, their HTTP verbs, paths, request/response types
3. Note any special patterns:
   - File uploads (`postFile`) → use `ApiService.postToGetFile()` or custom multipart
   - File downloads (`getFile`) → use `ApiService.getFile()`
   - Custom headers or query params
   - Paging requests using `EntityPagingRequest`/`EntityPagingResponse`

### Step 2: Check If Partially Migrated

Search `src/app/core/services/api/` for an existing service covering this domain. Some endpoints may be partially migrated (e.g., `client-api.service.ts` exists but only has 2 of 4 methods from the old `client-api.ts`).

### Step 3: Create the New Service File

**Location:** `src/app/core/services/api/<domain>/<domain>-api.service.ts`

**Template:**
```typescript
import { inject, Injectable } from '@angular/core';
import { ApiService } from '../api.service';
import { Observable } from 'rxjs';
// Import types — prefer reusing existing model files from the old endpoint directory

@Injectable({
	providedIn: 'root',
})
export class <Domain>ApiService {
	readonly apiService: ApiService = inject(ApiService);

	// Methods here...
}
```

**Method mapping from old to new:**

| Old BaseApi Method | New Pattern |
|---|---|
| `this.getJson<T>(path)` | `this.apiService.get<T>(path)` |
| `this.post<T>(path, body)` | `this.apiService.post<T>(path, body)` |
| `this.put(path, body)` | `this.apiService.put(path, body)` |
| `this.delete<T>(path)` | `this.apiService.delete(path)` |
| `this.getFile(path)` | `this.apiService.getFile(path)` |
| `this.postFile<T>(path, blob)` | Custom — use `this.apiService.post()` with multipart FormData and appropriate headers |
| `this.postWithoutResponse(path, body)` | `this.apiService.post(path, body)` (Observable completes on success) |

**Key conventions:**
- Use `inject()` function, NOT constructor injection
- Use `readonly apiService: ApiService = inject(ApiService)`
- Return types: `Observable<T>` instead of `Promise<T>`
- Endpoint paths: keep the same paths as the old API (they hit the same backend)
- For query params: use `new HttpParams().set('key', value)` and pass as `{ params }` option
- Reuse existing model/interface files — import them from the old location or move them if appropriate

### Step 4: Find and Update All Consumers

This is the most critical and error-prone step.

1. **Search for all imports of the old API class:**
   ```
   grep -r "import.*<OldClassName>" src/app/ --include="*.ts"
   ```

2. **Search for all injections:**
   ```
   grep -r "<OldClassName>" src/app/ --include="*.ts"
   ```

3. **For each consumer file, apply these transformations:**

   **a. Update imports:**
   ```typescript
   // OLD
   import { ExpressionApi } from '../../api/manual/endpoints/expression/expression-api';
   // NEW
   import { ExpressionApiService } from '../../core/services/api/expression/expression-api.service';
   ```

   **b. Update injection:**
   ```typescript
   // OLD (constructor injection)
   constructor(private expressionApi: ExpressionApi) {}
   // NEW (inject function — preferred)
   readonly expressionApiService: ExpressionApiService = inject(ExpressionApiService);
   // OR (constructor injection — acceptable if file already uses this pattern)
   constructor(private expressionApiService: ExpressionApiService) {}
   ```

   **c. Convert Promise chains to Observable subscriptions:**

   **Simple `.then()` → `.subscribe()`:**
   ```typescript
   // OLD
   this.expressionApi.test(request).then(result => {
     this.result = result;
   });
   // NEW
   this.expressionApiService.test(request).subscribe(result => {
     this.result = result;
   });
   ```

   **`.then().catch()` → `.subscribe({ next, error })`:**
   ```typescript
   // OLD
   this.api.doSomething()
     .then(result => { this.data = result; })
     .catch(error => { this.error = error.message; });
   // NEW
   this.apiService.doSomething().subscribe({
     next: result => { this.data = result; },
     error: error => { this.error = error.message; },
   });
   ```

   **Chained `.then()` → `.pipe()` with operators:**
   ```typescript
   // OLD
   this.api.getData()
     .then(data => this.transform(data))
     .then(transformed => { this.result = transformed; });
   // NEW
   this.apiService.getData().pipe(
     map(data => this.transform(data))
   ).subscribe(transformed => {
     this.result = transformed;
   });
   ```

   **Returned Promises → Returned Observables:**
   If a service method returns a Promise from the old API, it now returns an Observable. All callers of that service method must also be updated.
   ```typescript
   // OLD (in a service)
   getData() {
     return this.api.fetchData(); // returns Promise
   }
   // NEW
   getData() {
     return this.apiService.fetchData(); // returns Observable
   }
   ```

   **`await` usage → pipe/subscribe or convert:**
   ```typescript
   // OLD
   const data = await this.api.fetchData();
   this.processData(data);
   // NEW (Option A: subscribe)
   this.apiService.fetchData().subscribe(data => {
     this.processData(data);
   });
   // NEW (Option B: keep await with lastValueFrom — use sparingly)
   import { lastValueFrom } from 'rxjs';
   const data = await lastValueFrom(this.apiService.fetchData());
   this.processData(data);
   ```

   **Promise.all → forkJoin:**
   ```typescript
   // OLD
   Promise.all([this.api.getA(), this.api.getB()]).then(([a, b]) => { ... });
   // NEW
   import { forkJoin } from 'rxjs';
   forkJoin([this.apiService.getA(), this.apiService.getB()]).subscribe(([a, b]) => { ... });
   ```

### Step 5: Update or Remove Old API Registration

After all consumers are migrated:
1. Check if the old API class is still imported anywhere
2. If no remaining consumers, remove it from `src/app/api/manual/endpoints/`
3. Remove its provider from `src/app/api/manual/api.module.ts` if listed there

### Step 6: Validate

1. Run `ng build` or the project's build command to check for compile errors
2. Run relevant tests
3. Verify no remaining imports of the old API class exist

---

## Completed Migrations

- `configuration/configuration-api.ts` → `configuration-api.service.ts` (all 5 methods, old file removed)
- `expression/expression-api.ts` → `expression-api.service.ts` (old file removed)
- `email-alert/email-alert-api.ts` → `email-alert-api.service.ts` (all 8 methods, old file removed)
- `logging/logging-api.ts` → `logging-api.service.ts` (6 methods, old file removed)
- `mail/mail-api.ts` → `mail-api.service.ts` (3 methods, old file removed)
- `kafka/kafka-api.ts` → `kafka-api.service.ts` (7 methods, old file removed)
- `ldap/ldap-api.ts` → `ldap-api.service.ts` (4 methods, old file removed)
- `server/server-api.ts` → `server-api.service.ts` (9 methods, old file kept for type exports)
- `notification/notification-api.ts` → `notification-api.service.ts` (7 methods, old file removed)
- `database/database-h2-api.ts` → `database-api.service.ts` (2 methods merged into existing service, old file removed)
- `indexer/indexer-retention-api.ts` → `indexer-api.service.ts` (2 methods merged into existing service, old file removed)
- `indexer/indexer-tasks-api.ts` → `indexer-api.service.ts` (3 methods merged into existing service, old file removed)
- `main-object-tree/main-object-tree-api.ts` → `main-object-tree-api.service.ts` (1 method, old file removed)
- `process-diagram/process-diagram-api.ts` → `process-diagram-api.service.ts` (1 method, old file removed)
- `main-object/main-object-api.ts` → `main-object-api.service.ts` (3 methods, old file removed)
- `oidc/oidc-api.ts` → `oidc-api.service.ts` (4 methods, old file removed)
- `reports/reports-api.ts` → `reports-api.service.ts` (3 methods, old file removed)
- `reports/reports-custom-api.ts` → `reports-custom-api.service.ts` (2 methods, old file removed)
- `roles/roles-api.ts` → `roles-api.service.ts` (9 methods, old file removed)
- `reports/reports-tab-api.ts` → `reports-tab-api.service.ts` (10 methods, old file removed)
- `reports/reports-tile-api.ts` → `reports-tile-api.service.ts` (5 methods, old file removed)
- `rules/rules-api.ts` → `rules-api.service.ts` (11 methods incl. postFile, old file removed)
- `follow-up/follow-up-api.ts` → `follow-up-api.service.ts` (2 methods, old file removed)
- `domain-object/domain-object-api.ts` → `domain-object-api.service.ts` (8 methods, old file removed)
- `lifecycle/lifecycle-api.ts` → `lifecycle-api.service.ts` (1 method, consumer-only migration, old file removed)
- `metrics/alerts/metrics-alerts-api.ts` → `metrics-alerts-api.service.ts` (5 methods, old file removed)
- `jndi-connection/jndi-connection-api.ts` → `jndi-connection-api.service.ts` (7 methods, old file removed, 6 consumers updated)
- `feature/replay/feature-replay-api.ts` → `replay-api.service.ts` (method added to existing service, old file removed, 7 consumers updated)
- `jms-connection/jms-connection-api.ts` → `jms-connection-api.service.ts` (7 methods, old file removed, 6 consumers updated)
- `failsafe/failsafe-api.ts` → `failsafe-api.service.ts` (consumer-only migration, old file removed)
- `job/job-api.ts` → `job-api.service.ts` (consumer-only migration, old file + shared/api/job-api.ts removed)
- `metrics/configuration/metrics-configuration-api.ts` → `metrics-configuration-api.service.ts` (15 methods, old file removed, 14 consumers + spec updated)
- `metrics/graph/metrics-graph-api.ts` → `metrics-graph-api.service.ts` (new service, old file removed, 15 consumers + spec updated)
- `metrics/rule/metrics-rule-api.ts` → `metrics-rule-api.service.ts` (new service, old file removed, 10 consumers updated)
- `database/database-api.ts` → `database-api.service.ts` (consumer-only migration, old file removed, 1 consumer updated)
- `usermanagement/objects/usermanagement-objects-api.ts` → `usermanagement-objects-api.service.ts` (5 methods, old file removed, 4 consumers updated)
- `processing/data-provider/processing-data-provider-api.ts` → `processing-data-provider-api.service.ts` (8 methods, old file removed, 4 consumers + spec updated)
- `indexer/indexer-api.ts` → `indexer-api.service.ts` (consumer-only migration, listIndexesDetails updated with HttpParams, old file removed, 7 consumers updated)
- `process/process-api.ts` → `process-api.service.ts` (38 methods, old file removed, 15 consumers updated)
- `search/search-api.ts` → `search-api.service.ts` (14 methods + getProcessInstanceZip merged from old SearchApiService, old files removed, 24 consumers + spec updated)
- `usermanagement/privileges/usermanagement-privileges-api.ts` → `usermanagement-privileges-api.service.ts` (4 methods, old file removed, 4 consumers updated)
- `processing/error-handler/processing-error-handler-api.ts` → `processing-error-handler-api.service.ts` (4 methods, old file removed, 3 consumers + spec updated)
- `communication/communication-api.ts` → `communication-api.service.ts` (consumer-only migration, old file removed, 3 consumers + spec updated)
- `processing/merger/processing-merger-api.ts` → `processing-merger-api.service.ts` (4 methods, old file removed, 1 consumer updated)
- `usermanagement/layout/usermanagement-layout-api.ts` → `usermanagement-layout-api.service.ts` (6 methods, old file removed, 1 direct consumer + 2 downstream consumers updated)
- `user/user-api.ts` → `user-api.service.ts` (consumer-only migration, User import fixed to usermanagement/user, old file removed, 14 consumers + 2 specs updated)
- `processing/statistic/processing-statistic-api.ts` → `processing-statistic-api.service.ts` (12 methods, HttpParams for refresh query param, old file removed, 8 consumers updated)
- `usermanagement/roles/usermanagement-roles-api.ts` → `usermanagement-roles-api.service.ts` (2 methods, old file removed, 2 consumers updated)
- `public/public-api.ts` → `public-api.service.ts` (consumer-only migration, customEncodeURIComponent added to getPublicConfiguration, old file removed, 1 spec updated)
- `search/search-facets-api.ts` → `search-facets-api.service.ts` (consumer-only migration, signature change body→path param, old file removed, 1 consumer updated)
- `client/client-api.ts` → `client-api.service.ts` (consumer-only migration, old file removed, 3 consumers updated)
- `query-object/query-object-api.ts` → `query-object-api.service.ts` (8 methods, method signatures changed from object to positional params, old file removed, 5 consumers updated)
- `usermanagement/initial-admin/usermanagement-initial-admin-api.ts` → `usermanagement-initial-admin-api.service.ts` (2 methods, old file removed, 2 consumers updated)
- `usermanagement/authentication/usermanagement-authentication-api.ts` → `usermanagement-authentication-api.service.ts` (6 methods, old file removed, 11 consumers updated)
- `server/server-api.ts` → `server-api.service.ts` (types extracted to server-api.types.ts, old file removed, 1 consumer type import updated)
- `usermanagement/users/usermanagement-users-api.service.ts` → `usermanagement-users-api.service.ts` (14 methods, HttpParams for query params, old file removed, 10 consumers updated, fixed unsubscribed Observable bug in user-management.component.ts)

## Migration Complete

All 56 endpoints have been migrated from `src/app/api/manual/endpoints/` to `src/app/core/services/api/`. The `api.module.ts` providers array is now empty. No classes extend `BaseApi`. All migrations verified with `ng build --configuration=production`.

---

## Important Notes

- **Do NOT change the HTTP endpoint paths** — the backend REST API remains the same
- **Model/interface files** can often be reused from the old location; move them only if it makes sense
- **The old `api.module.ts`** registers providers — after migration, the new services use `providedIn: 'root'` so no module registration is needed
- **Consumer migration is mandatory** — creating the new service without updating consumers leaves the old API still in use
- **Test thoroughly** — the switch from Promise to Observable can introduce subtle timing differences
