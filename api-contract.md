# API Contract - Morning Pic 369 Worker API

> Status: Draft v1
> Target runtime: Cloudflare Worker
> Backing store: Cloudflare D1
> Scope: first backend slice for shared sync and early agent flows

---

## 1. Principles

- API is built for a local-first dashboard
- frontend sends batched sync operations, not many tiny ad hoc writes
- backend is source of truth once a write is accepted
- business rule failures must be returned clearly
- agent actions must be traceable and reviewable

---

## 2. Base Assumptions

- one business for current deployment: `morning-pic-369`
- one trusted owner and very small team
- auth can stay simple in early internal version, but all write endpoints should still be structured for future auth

---

## 3. Standard Headers

Recommended request headers:

| Header | Required | Purpose |
|---|---|---|
| `Content-Type: application/json` | yes for POST | JSON payload |
| `X-Business-Id` | yes | current business scope |
| `X-Client-Id` | yes | browser/device identity |
| `X-Actor-Id` | yes | actor label such as `owner` |
| `X-Actor-Type` | yes | `human`, `agent`, `system` |

---

## 4. Standard Response Envelope

Every API response should use a predictable top-level shape.

### Success

```json
{
  "ok": true,
  "data": {},
  "meta": {
    "requestId": "req_01JXYZ...",
    "serverTime": "2026-07-08T17:20:00+07:00"
  }
}
```

### Error

```json
{
  "ok": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "paymentStatus is invalid",
    "details": {
      "field": "paymentStatus"
    }
  },
  "meta": {
    "requestId": "req_01JXYZ...",
    "serverTime": "2026-07-08T17:20:00+07:00"
  }
}
```

---

## 5. Error Codes

| Code | Meaning |
|---|---|
| `BAD_REQUEST` | malformed input |
| `VALIDATION_ERROR` | field-level invalid data |
| `NOT_FOUND` | entity or record not found |
| `CONFLICT` | optimistic concurrency conflict |
| `BUSINESS_RULE_VIOLATION` | valid JSON but blocked by workflow rule |
| `UNAUTHORIZED` | actor not allowed |
| `FORBIDDEN` | authenticated but not allowed |
| `INTERNAL_ERROR` | unexpected worker failure |

---

## 6. Endpoint: GET /api/bootstrap

### Purpose

Load the startup dataset needed by the dashboard.

### Request

`GET /api/bootstrap?businessId=morning-pic-369`

### Response

```json
{
  "ok": true,
  "data": {
    "businessId": "morning-pic-369",
    "settings": [],
    "packages": [],
    "businessTargets": [],
    "orders": [],
    "productionJobs": []
  },
  "meta": {
    "requestId": "req_001",
    "serverTime": "2026-07-08T17:20:00+07:00"
  }
}
```

### v1 dataset scope

Return at least:
- `settings`
- `packages`
- `businessTargets`
- `orders`
- `productionJobs`

### Future expansion

Later include:
- `chats`
- `contentPosts`
- `adCampaigns`
- `adCreatives`
- `expenses`
- `cashReserve`

---

## 7. Endpoint: POST /api/sync

### Purpose

Accept a batch of sync operations from the browser.

### Request body

```json
{
  "businessId": "morning-pic-369",
  "clientId": "browser-main",
  "sentAt": "2026-07-08T17:20:00+07:00",
  "operations": [
    {
      "opId": "op_001",
      "type": "UPSERT_ENTITY",
      "entity": "orders",
      "record": {
        "id": "ord-001",
        "entity": "orders",
        "version": 3,
        "createdAt": "2026-07-08T16:00:00+07:00",
        "updatedAt": "2026-07-08T16:30:00+07:00",
        "updatedBy": "owner",
        "syncStatus": "pending",
        "payload": {
          "customer": "เธฃเนเธฒเธเธชเธเธนเนเธชเธกเธธเธเนเธเธฃ",
          "packageName": "เนเธเนเธ 2,999",
          "amount": 2999,
          "paymentStatus": "เธเธณเธฃเธฐเธเธฃเธ",
          "billingStatus": "เธงเธฒเธเธเธดเธฅเนเธฅเนเธง",
          "fulfillmentStatus": "เธฃเธญเธ•เธฃเธงเธ"
        }
      }
    }
  ]
}
```

### Supported operation types in v1

- `UPSERT_ENTITY`
- `DELETE_ENTITY`
- `RESOLVE_CONFLICT`

### Supported entities in v1

- `orders`
- `production_jobs`

### Response

```json
{
  "ok": true,
  "data": {
    "processedAt": "2026-07-08T17:20:02+07:00",
    "results": [
      {
        "opId": "op_001",
        "status": "accepted",
        "entity": "orders",
        "recordId": "ord-001",
        "serverVersion": 4,
        "serverUpdatedAt": "2026-07-08T17:20:02+07:00"
      }
    ],
    "conflicts": [],
    "errors": []
  },
  "meta": {
    "requestId": "req_002",
    "serverTime": "2026-07-08T17:20:02+07:00"
  }
}
```

### Result statuses

- `accepted`
- `conflict`
- `rejected`

---

## 8. Sync Validation Rules

### Shared rules

- `businessId` must exist
- `clientId` must be non-empty
- `operations` must be non-empty array
- `opId` must be unique
- `record.id` must be non-empty
- `record.version` must be integer >= 1
- `record.updatedAt` must be ISO timestamp

### Order-specific rules

- `amount >= 0`
- `paymentStatus` in:
  - `เธฃเธญเธเธณเธฃเธฐ`
  - `เธเธณเธฃเธฐเธเธฃเธ`
- `billingStatus` in:
  - `เธขเธฑเธเนเธกเนเธงเธฒเธเธเธดเธฅ`
  - `เธงเธฒเธเธเธดเธฅเนเธฅเนเธง`
  - `เธฃเธฑเธเน€เธเธดเธเนเธฅเนเธง`
- `fulfillmentStatus` in:
  - `เธฃเธญเธเนเธญเธกเธนเธฅ`
  - `เธเธณเธฅเธฑเธเธเธฅเธดเธ•`
  - `เธฃเธญเธ•เธฃเธงเธ`
  - `เธชเนเธเนเธฅเนเธง`

### Production-specific rules

- `images >= 0`
- `revisions >= 0`
- `status` in:
  - `เธฃเธญเน€เธฃเธดเนเธก`
  - `เธเธณเธฅเธฑเธเธเธฅเธดเธ•`
  - `เธฃเธญเธ•เธฃเธงเธ`
  - `เนเธเนเธฃเธญเธ 1`
  - `เน€เธเธดเธเธฃเธญเธ`
  - `เธชเนเธเนเธฅเนเธง`

---

## 9. Sync Business Rules

### Orders

- if order becomes `paymentStatus = เธเธณเธฃเธฐเธเธฃเธ`
  - backend may auto-create linked production job if absent
- if order becomes `fulfillmentStatus = เธชเนเธเนเธฅเนเธง`
  - backend should check linked production job consistency

### Production Jobs

- if production job becomes `status = เธชเนเธเนเธฅเนเธง`
  - backend should update linked order to `fulfillmentStatus = เธชเนเธเนเธฅเนเธง`
- if `revisions > 1`
  - backend may normalize production status to `เน€เธเธดเธเธฃเธญเธ`

### Audit

Every accepted operation must create an `activity_log` row.

---

## 10. Conflict Handling

### When to return conflict

Return `CONFLICT` when:
- client `version < server version`
- record was changed remotely after client snapshot

### Conflict result example

```json
{
  "opId": "op_001",
  "status": "conflict",
  "entity": "orders",
  "recordId": "ord-001",
  "clientVersion": 3,
  "serverVersion": 5,
  "serverRecord": {
    "id": "ord-001",
    "entity": "orders",
    "version": 5,
    "payload": {}
  }
}
```

### Frontend expected behavior

- keep local draft
- mark row as `conflict`
- let human compare before overwrite

---

## 11. Endpoint: GET /api/reports/summary

### Purpose

Return pre-aggregated metrics for dashboard reports.

### Request

`GET /api/reports/summary?businessId=morning-pic-369&range=month`

### Query params

| Param | Required | Values |
|---|---|---|
| `businessId` | yes | current business |
| `range` | no | `today`, `week`, `month` |
| `from` | no | ISO date |
| `to` | no | ISO date |

### Response

```json
{
  "ok": true,
  "data": {
    "revenue": 18992,
    "expenses": 8000,
    "profit": 10992,
    "paidOrders": 6,
    "pendingOrders": 2,
    "capacityUsed": 37.5
  },
  "meta": {
    "requestId": "req_003",
    "serverTime": "2026-07-08T17:20:05+07:00"
  }
}
```

### v1 note

This can stay small in first build and grow later.

---

## 12. Endpoint: POST /api/agent-runs

### Purpose

Create a new AI-assisted task without letting the agent write directly into business data first.

### Request body

```json
{
  "businessId": "morning-pic-369",
  "agentName": "Production Agent",
  "scopeEntity": "production_jobs",
  "scopeRecordId": "prod-002",
  "triggerSource": "human",
  "input": {
    "task": "analyze delay risk"
  }
}
```

### Response

```json
{
  "ok": true,
  "data": {
    "agentRunId": "run_001",
    "status": "queued"
  },
  "meta": {
    "requestId": "req_004",
    "serverTime": "2026-07-08T17:20:08+07:00"
  }
}
```

### Rules

- agent runs create drafts first
- they do not directly mutate core tables in v1
- money, payment, billing, fulfillment, and customer-facing actions require review

---

## 13. Endpoint: GET /api/agent-runs/:id

### Purpose

Fetch agent run status and output.

### Response

```json
{
  "ok": true,
  "data": {
    "id": "run_001",
    "status": "needs-review",
    "agentName": "Production Agent",
    "output": {
      "summary": "risk is high because due date is close and customer materials are incomplete"
    }
  },
  "meta": {
    "requestId": "req_005",
    "serverTime": "2026-07-08T17:20:12+07:00"
  }
}
```

---

## 14. Recommended HTTP Status Mapping

| Situation | Status |
|---|---|
| success | `200` |
| create accepted | `202` for queued agent runs |
| bad request | `400` |
| unauthorized | `401` |
| forbidden | `403` |
| not found | `404` |
| conflict | `409` |
| server error | `500` |

---

## 15. Logging Expectations

For every request, log:
- `requestId`
- `businessId`
- `clientId`
- `actorId`
- `actorType`
- endpoint
- response status
- timing

For every accepted write, also log:
- `entity`
- `recordId`
- `beforeVersion`
- `afterVersion`

---

## 16. Security Notes

- never trust browser-side role claims without server checks later
- never accept secret-bearing payloads from frontend
- sanitize all JSON before persistence
- rate-limit sync endpoint later if usage grows

---

## 17. Recommended Next Implementation

Best next move after this file:

1. scaffold Worker routes for:
   - `/api/bootstrap`
   - `/api/sync`
   - `/api/reports/summary`
   - `/api/agent-runs`
2. create `phase-2-tasks.md`
3. add frontend `syncService` adapter shape

For the safest coding start, do `/api/bootstrap` and `/api/sync` first.
