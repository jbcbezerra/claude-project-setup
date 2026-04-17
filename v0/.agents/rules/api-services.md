# API Services — Conventions & Rules

Rules for creating and modifying API services in `src/app/core/services/api/`.

---

## File & Class Naming

- File: `<domain>-api.service.ts` inside `src/app/core/services/api/<domain>/`
- Class: `<Domain>ApiService` (e.g., `ClientApiService`, `LifecycleApiService`)
- One service per domain — group related endpoints in a single service

## Injectable Pattern

Always use tree-shakable `providedIn: 'root'`. Never register in a module.

```typescript
@Injectable({
	providedIn: 'root',
})
export class ExampleApiService {
```

## Dependency Injection

Always use the `inject()` function. Never use constructor injection.

```typescript
readonly apiService: ApiService = inject(ApiService);
```

- Use `readonly` visibility (not `private`)
- Always inject `ApiService` (not `BaseApiService` or `HttpClient` directly)

## Endpoint Comments

Group methods by their REST endpoint path using section comments. This makes it easy to locate which methods correspond to which backend endpoint:

```typescript
// ========== /user/properties/{name} ==========
setUserProperty(key: string, value: any): Observable<any> {
	return this.apiService.post(`/user/properties/${customEncodeURIComponent(key)}`, value);
}

// ========== /user/properties ==========
getUserProperties(): Observable<StringKeyStringValue> {
	return this.apiService.get<StringKeyStringValue>(`/user/properties`);
}

// ========== /user/privilege ==========
hasPrivileges(body: PrivilegeRequest[]): Observable<Privilege[]> {
	return this.apiService.post<Privilege[]>(`/user/privilege`, body);
}

getSystemPrivileges(): Observable<PrivilegeResponse[]> {
	return this.apiService.get<PrivilegeResponse[]>(`/user/privilege`);
}
```

- Use the format `// ========== /endpoint/path ==========`
- Place the comment above the first method that hits that endpoint
- Methods sharing the same endpoint path (different HTTP verbs) go under the same comment
- Include path parameters as `{name}` in the comment

## Method Conventions

### Return Types

All methods return `Observable<T>`. Never return `Promise<T>`.

```typescript
getItems(): Observable<Item[]> {
	return this.apiService.get<Item[]>('/items');
}
```

Explicit return type annotations are optional — the type is inferred from `ApiService` generics. Include them when the type adds clarity (complex generics, paging responses).

### Method Naming

| Operation | Prefix | Example |
|-----------|--------|---------|
| Fetch single | `get*` | `getFeatureById(id)` |
| Fetch list | `getAll*`, `list*` | `getAllFeatures()`, `listDependencies()` |
| Create | `create*` | `createQueryObject(...)` |
| Update | `update*`, `change*`, `set*` | `updateUserAttributes(body)` |
| Delete | `delete*`, `remove*` | `deleteQueryObject(id)` |
| Check/test | `check*`, `has*`, `is*` | `checkReady()`, `hasPrivileges(body)` |
| Toggle/activate | `activate*`, `deactivate*` | `activateAdvancedDataProcessingStatistic()` |

### Available HTTP Methods

| Method | Signature | Notes |
|--------|-----------|-------|
| `get<T>` | `this.apiService.get<T>(path, options?)` | Single item |
| `getAll<T>` | `this.apiService.getAll<T>(path, options?)` | Array of items |
| `post<T>` | `this.apiService.post<T>(path, body?, options?)` | Create / action |
| `put<T>` | `this.apiService.put<T>(path, body?, options?)` | Update |
| `delete<T>` | `this.apiService.delete<T>(path, options?)` | Delete |
| `head` | `this.apiService.head(path, options?)` | Head check |
| `getFile` | `this.apiService.getFile(path, options?)` | Binary download (GET) |
| `postToGetFile` | `this.apiService.postToGetFile(path, body)` | Binary download (POST) |

## Path Parameters

Use template literals with `customEncodeURIComponent` for dynamic path segments:

```typescript
import { customEncodeURIComponent } from '../../../utils/uri';

getComponentState(name: string): Observable<ComponentState> {
	return this.apiService.get<ComponentState>(`/lifecycle/${customEncodeURIComponent(name)}`);
}
```

## Query Parameters

Always use `HttpParams` — never concatenate query strings into the URL.

```typescript
import { HttpParams } from '@angular/common/http';

getDataProcessingStatistic(period: string) {
	const params = new HttpParams().set('period', period);
	return this.apiService.get<DataProcessingStats[]>('/processing/statistic/dataprocessingstats', { params });
}
```

For multiple params, chain `.set()` calls:

```typescript
const params = new HttpParams()
	.set('period', period)
	.set('details', details);
```

## Model Types

- Co-locate type/interface files alongside the service in the same domain directory
- Reuse existing model/interface files via import — check if the type already exists before creating a new one
- For complex domains, use sub-directories (e.g., `usermanagement/authentication/`, `usermanagement/privileges/`)
- Cross-domain shared types live in `models/` (e.g., paging interfaces in `models/paging/`)
- Export types from the model file, not from the service file
- No barrel/index files — use explicit path imports to individual files

## Complete Example

```typescript
import { inject, Injectable } from '@angular/core';
import { ApiService } from '../api.service';
import { Observable } from 'rxjs';
import { HttpParams } from '@angular/common/http';
import { customEncodeURIComponent } from '../../../utils/uri';
import { Item } from './models/item';

@Injectable({
	providedIn: 'root',
})
export class ItemApiService {
	readonly apiService: ApiService = inject(ApiService);

	// ========== /item ==========
	getAllItems(): Observable<Item[]> {
		return this.apiService.getAll<Item>('/item');
	}

	createItem(body: Item): Observable<Item> {
		return this.apiService.post<Item>('/item', body);
	}

	// ========== /item/{id} ==========
	getItem(id: number): Observable<Item> {
		return this.apiService.get<Item>(`/item/${customEncodeURIComponent(id)}`);
	}

	updateItem(id: number, body: Partial<Item>): Observable<any> {
		return this.apiService.put(`/item/${customEncodeURIComponent(id)}`, body);
	}

	deleteItem(id: number): Observable<any> {
		return this.apiService.delete(`/item/${customEncodeURIComponent(id)}`);
	}

	// ========== /item/search ==========
	searchItems(query: string, page: number): Observable<Item[]> {
		const params = new HttpParams()
			.set('query', query)
			.set('page', page);
		return this.apiService.get<Item[]>('/item/search', { params });
	}
}
```
