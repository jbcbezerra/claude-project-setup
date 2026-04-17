# Consolidate WebSocket Error Handling

## Context

The codebase has 3 overlapping WebSocket error handling systems that accumulated over time:

1. **`WebSocketManagerService`** (newer) — `src/app/core/services/websocket/websocket-manager.service.ts`
   - Exponential backoff retry (5 retries, 30s cap)
   - State tracking via BehaviorSubject (idle, connecting, connected, disconnected, failed-to-connect)
   - Shared observable streams with shareReplay

2. **`AbstractSocketConnection`** (legacy) — `src/app/notifications/sockets/abstract-socket-connection.ts`
   - Fixed 10s scheduler interval for reconnection
   - Manual enable/disable state management
   - Used by notification sockets

3. **`SocketDisconnectionService`** (deprecated) — `src/app/footer/socket-center/services/socket-disconnection.service.ts`
   - 10s grace period before marking backend offline
   - Being replaced by `WebSocketHealthStateService`

These systems have different retry strategies, different offline detection thresholds (3s vs 10s), and different state models. When the backend goes down, the three systems race to detect it, sometimes producing conflicting signals.

### Supporting Files

- `src/app/core/services/websocket/websocket-health-state.service.ts` — Global socket health monitor (all-connected, not-all-connected, all-disconnected) with 3s confirmation delay
- `src/app/notifications/sockets/web-socket-communication.ts` — Concrete WebSocket implementation with message parsing
- `src/app/notifications/sockets/connection-failed-error.ts` — Custom Error class for WebSocket failures
- `src/app/footer/socket-center/services/socket-collection.service.ts` — Manages collection of active sockets
- `src/app/footer/socket-center/socket-collection-status.ts` — Socket collection status types
- `src/app/notifications/sockets/notification-socket.service.ts` — Legacy notification socket (deprecated)
- `src/app/core/services/websocket/sockets/notification-socket.service.ts` — Core notification socket

---

## Approach

### Step 1: Identify All Socket Consumers

Map every component/service that creates or consumes a WebSocket connection:
- Notification sockets (real-time alerts, shutdown, restart, logout, keep-alive)
- Alert sockets (Argos monitoring)
- Any other real-time features

### Step 2: Migrate Legacy Sockets to WebSocketManagerService

For each socket currently extending `AbstractSocketConnection`:
1. Create the connection via `WebSocketManagerService.connect(name, url, options)`
2. Subscribe to the managed observable stream
3. Remove the `AbstractSocketConnection` subclass

### Step 3: Remove Deprecated Infrastructure

Once all sockets use `WebSocketManagerService`:
1. Delete `src/app/notifications/sockets/abstract-socket-connection.ts`
2. Delete `src/app/footer/socket-center/services/socket-disconnection.service.ts` (already deprecated)
3. Delete `src/app/notifications/sockets/connection-failed-error.ts` (if no longer needed)
4. Clean up `src/app/footer/socket-center/services/socket-collection.service.ts` (consolidate into WebSocketManagerService if overlapping)
5. Remove the deprecated `src/app/notifications/sockets/notification-socket.service.ts`

### Step 4: Unify Offline Detection

Standardize on `WebSocketHealthStateService` with a single threshold:
- Remove the 10s grace period from `SocketDisconnectionService`
- Use the 3s confirmation delay from `WebSocketHealthStateService` consistently
- Ensure `ConnectionService.setBackendOffline()` is called from exactly one path

### Files to Modify

**Migrate:**
- All services extending `AbstractSocketConnection` → use `WebSocketManagerService`
- `src/app/footer/socket-center/` components → use `WebSocketHealthStateService` for status

**Delete:**
- `src/app/notifications/sockets/abstract-socket-connection.ts`
- `src/app/notifications/sockets/abstract-socket-connection.spec.ts`
- `src/app/footer/socket-center/services/socket-disconnection.service.ts`
- `src/app/notifications/sockets/notification-socket.service.ts` (legacy duplicate)
- `src/app/notifications/sockets/connection-failed-error.ts` (if unused after migration)

**Keep and update:**
- `src/app/core/services/websocket/websocket-manager.service.ts` — May need minor extensions
- `src/app/core/services/websocket/websocket-health-state.service.ts` — Becomes the single health authority
- `src/app/notifications/sockets/web-socket-communication.ts` — Review if still needed as separate layer

---

## Execution

1. Inventory all `AbstractSocketConnection` subclasses and their consumers
2. For each socket, migrate to `WebSocketManagerService` — one socket at a time
3. After all sockets migrated, remove legacy infrastructure
4. Update footer/socket-center to use only `WebSocketHealthStateService`
5. Verify single offline detection path

---

## Verification

1. `ng build` — Compiles
2. WebSocket connections establish and reconnect correctly (test by stopping/restarting backend)
3. Offline detection fires exactly once (not from multiple systems)
4. Network error overlay appears on backend failure
5. Recovery detection works — auto-reconnect when backend comes back
6. Notification sockets receive real-time updates
7. `npm run test:prod` — Tests pass
8. Grep for `AbstractSocketConnection` → Zero results
9. Grep for `SocketDisconnectionService` → Zero results
