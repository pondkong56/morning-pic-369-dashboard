# Sync Contract - Morning Pic 369

> Purpose: define the first backend sync contract between `app.html` and the future API
> Scope v1: `orders` and `production_jobs`
> Status: Draft v1

---

## 1. Principles

- Frontend remains local-first
- Every write becomes a sync event
- Backend validates and writes canonical state
- Conflicts must be visible
- Business transitions must be auditable

---

## 2. Entity Names

Supported in first slice:
- `orders`
- `production_jobs`

Planned next:
- `chats`
- `content_posts`
- `ad_creatives`
- `ad_campaigns`

---

## 3. Shared Record Envelope

Every synced record should carry:

```json
{
  "id": "ord-001",
  "entity": "orders",
  "version": 3,
  "createdAt": "2026-07-08T16:00:00+07:00",
  "updatedAt": "2026-07-08T16:30:00+07:00",
  "updatedBy": "owner",
  "syncStatus": "pending",
  "payload": {}
}
```

### Shared fields

| Field | Type | Meaning |
|---|---|---|
| `id` | string | stable client/server id |
| `entity` | string | domain table name |
| `version` | integer | optimistic concurrency number |
| `createdAt` | ISO string | record creation time |
| `updatedAt` | ISO string | latest local edit time |
| `updatedBy` | string | actor id or label |
| `syncStatus` | string | `local-only`, `pending`, `synced`, `conflict`, `failed` |
| `payload` | object | entity-specific data |

---

## 4. Batch Sync Request

### Endpoint

`POST /api/sync`

### Request body

```json
{
  "businessId": "morning-pic-369",
  "clientId": "browser-main",
  "sentAt": "2026-07-08T16:45:00+07:00",
  "operations": [
    {
      "opId": "op-1720431900-001",
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

---

## 5. Batch Sync Response

```json
{
  "ok": true,
  "processedAt": "2026-07-08T16:45:02+07:00",
  "results": [
    {
      "opId": "op-1720431900-001",
      "status": "accepted",
      "entity": "orders",
      "recordId": "ord-001",
      "serverVersion": 4,
      "serverUpdatedAt": "2026-07-08T16:45:02+07:00"
    }
  ],
  "conflicts": [],
  "errors": []
}
```

### Result statuses
- `accepted`
- `conflict`
- `rejected`

---

## 6. Order Payload Contract

### Required payload fields

```json
{
  "customer": "เธฃเนเธฒเธเธชเธเธนเนเธชเธกเธธเธเนเธเธฃ",
  "packageName": "เนเธเนเธ 2,999",
  "amount": 2999,
  "paymentStatus": "เธเธณเธฃเธฐเธเธฃเธ",
  "billingStatus": "เธงเธฒเธเธเธดเธฅเนเธฅเนเธง",
  "fulfillmentStatus": "เธฃเธญเธ•เธฃเธงเธ"
}
```

### Rules

- `amount` must be numeric
- `paymentStatus` allowed:
  - `เธฃเธญเธเธณเธฃเธฐ`
  - `เธเธณเธฃเธฐเธเธฃเธ`
- `billingStatus` allowed:
  - `เธขเธฑเธเนเธกเนเธงเธฒเธเธเธดเธฅ`
  - `เธงเธฒเธเธเธดเธฅเนเธฅเนเธง`
  - `เธฃเธฑเธเน€เธเธดเธเนเธฅเนเธง`
- `fulfillmentStatus` allowed:
  - `เธฃเธญเธเนเธญเธกเธนเธฅ`
  - `เธเธณเธฅเธฑเธเธเธฅเธดเธ•`
  - `เธฃเธญเธ•เธฃเธงเธ`
  - `เธชเนเธเนเธฅเนเธง`

### Business checks

- if `paymentStatus = เธเธณเธฃเธฐเธเธฃเธ`, backend may require linked production job existence or auto-create it
- if `fulfillmentStatus = เธชเนเธเนเธฅเนเธง`, linked production job should be checked for consistency

---

## 7. Production Job Payload Contract

### Required payload fields

```json
{
  "orderId": "ord-001",
  "customer": "เธฃเนเธฒเธเธชเธเธนเนเธชเธกเธธเธเนเธเธฃ",
  "packageName": "เนเธเนเธ 2,999",
  "images": 15,
  "owner": "Freelance Editor",
  "dueDate": "2026-07-12",
  "status": "เธฃเธญเธ•เธฃเธงเธ",
  "revisions": 1,
  "issue": ""
}
```

### Rules

- `images` must be numeric
- `revisions` must be numeric and >= 0
- `status` allowed:
  - `เธฃเธญเน€เธฃเธดเนเธก`
  - `เธเธณเธฅเธฑเธเธเธฅเธดเธ•`
  - `เธฃเธญเธ•เธฃเธงเธ`
  - `เนเธเนเธฃเธญเธ 1`
  - `เน€เธเธดเธเธฃเธญเธ`
  - `เธชเนเธเนเธฅเนเธง`

### Business checks

- if `status = เธชเนเธเนเธฅเนเธง`, backend should sync linked order `fulfillmentStatus = เธชเนเธเนเธฅเนเธง`
- if `revisions > 1`, backend may normalize status to `เน€เธเธดเธเธฃเธญเธ`

---

## 8. Conflict Contract

Conflict happens when:
- client `version` is older than server `version`
- a record was changed remotely after the browser last synced

### Conflict response example

```json
{
  "opId": "op-1720431900-001",
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

### Frontend behavior

- keep local draft
- mark row as `conflict`
- show compare action later
- do not silently overwrite

---

## 9. Bootstrap Contract

### Endpoint

`GET /api/bootstrap?businessId=morning-pic-369`

### Response shape

```json
{
  "businessId": "morning-pic-369",
  "serverTime": "2026-07-08T16:45:00+07:00",
  "data": {
    "settings": [],
    "packages": [],
    "businessTargets": [],
    "orders": [],
    "production_jobs": []
  }
}
```

### Purpose

- hydrate app on load
- allow eventual switch from pure local mode to hybrid mode

---

## 10. Audit Contract

Every accepted write should create an audit row like:

```json
{
  "entity": "orders",
  "recordId": "ord-001",
  "action": "UPSERT_ENTITY",
  "actorType": "human",
  "actorId": "owner",
  "beforeVersion": 3,
  "afterVersion": 4,
  "timestamp": "2026-07-08T16:45:02+07:00"
}
```

This is essential once AI agents start touching records.

---

## 11. Agent-Safe Extension

Future agent writes should use the same sync path, but with:

```json
{
  "updatedBy": "agent:production-agent",
  "payload": {
    "assignedAgent": "Production Agent",
    "executionMode": "human-in-the-loop",
    "agentStatus": "drafted",
    "handoffNote": "Suggest mark as delay risk"
  }
}
```

### Rule

Agent writes that affect money, payment, or customer-facing status should require review before final acceptance.

---

## 12. Recommended First Implementation

### Frontend
- create `syncService`
- add outbox queue
- wrap all order and production writes through service

### Backend
- implement `/api/bootstrap`
- implement `/api/sync`
- validate `orders` and `production_jobs`
- write audit rows

### Database
- create tables for:
  - `orders`
  - `production_jobs`
  - `activity_log`

---

## 13. Next Deliverable

Best next file to create:

- `db-schema.sql`

That will turn this contract into a concrete database slice for the first backend rollout.
