-- Morning Pic 369
-- Central database schema v1
-- Target: Cloudflare D1 / SQLite
-- Scope: first backend slice for orders, production_jobs, activity_log

PRAGMA foreign_keys = ON;

BEGIN TRANSACTION;

CREATE TABLE IF NOT EXISTS businesses (
  id TEXT PRIMARY KEY,
  slug TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  timezone TEXT NOT NULL DEFAULT 'Asia/Bangkok',
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS packages (
  id TEXT PRIMARY KEY,
  business_id TEXT NOT NULL,
  name TEXT NOT NULL,
  price INTEGER NOT NULL CHECK (price >= 0),
  images INTEGER NOT NULL CHECK (images >= 0),
  role TEXT NOT NULL,
  monthly_cap INTEGER NOT NULL CHECK (monthly_cap >= 0),
  revision_free INTEGER NOT NULL CHECK (revision_free >= 0),
  delivery_days INTEGER NOT NULL CHECK (delivery_days >= 0),
  is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (business_id, name),
  FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS orders (
  id TEXT PRIMARY KEY,
  business_id TEXT NOT NULL,
  customer TEXT NOT NULL,
  package_id TEXT,
  package_name TEXT NOT NULL,
  amount INTEGER NOT NULL CHECK (amount >= 0),
  payment_status TEXT NOT NULL CHECK (
    payment_status IN ('เธฃเธญเธเธณเธฃเธฐ', 'เธเธณเธฃเธฐเธเธฃเธ')
  ),
  billing_status TEXT NOT NULL CHECK (
    billing_status IN ('เธขเธฑเธเนเธกเนเธงเธฒเธเธเธดเธฅ', 'เธงเธฒเธเธเธดเธฅเนเธฅเนเธง', 'เธฃเธฑเธเน€เธเธดเธเนเธฅเนเธง')
  ),
  fulfillment_status TEXT NOT NULL CHECK (
    fulfillment_status IN ('เธฃเธญเธเนเธญเธกเธนเธฅ', 'เธเธณเธฅเธฑเธเธเธฅเธดเธ•', 'เธฃเธญเธ•เธฃเธงเธ', 'เธชเนเธเนเธฅเนเธง')
  ),

  version INTEGER NOT NULL DEFAULT 1 CHECK (version >= 1),
  created_by TEXT NOT NULL DEFAULT 'owner',
  updated_by TEXT NOT NULL DEFAULT 'owner',
  last_touched_by_type TEXT NOT NULL DEFAULT 'human' CHECK (
    last_touched_by_type IN ('human', 'agent', 'system')
  ),
  assigned_agent TEXT NOT NULL DEFAULT '',
  execution_mode TEXT NOT NULL DEFAULT 'manual' CHECK (
    execution_mode IN ('manual', 'human-in-the-loop', 'agent-auto')
  ),
  agent_status TEXT NOT NULL DEFAULT 'idle' CHECK (
    agent_status IN ('idle', 'drafted', 'queued', 'running', 'needs-review', 'approved', 'rejected', 'failed')
  ),
  handoff_note TEXT NOT NULL DEFAULT '',

  client_updated_at TEXT,
  last_synced_at TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE,
  FOREIGN KEY (package_id) REFERENCES packages(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS production_jobs (
  id TEXT PRIMARY KEY,
  business_id TEXT NOT NULL,
  order_id TEXT,
  customer TEXT NOT NULL,
  package_id TEXT,
  package_name TEXT NOT NULL,
  images INTEGER NOT NULL CHECK (images >= 0),
  owner TEXT NOT NULL,
  due_date TEXT NOT NULL,
  status TEXT NOT NULL CHECK (
    status IN ('เธฃเธญเน€เธฃเธดเนเธก', 'เธเธณเธฅเธฑเธเธเธฅเธดเธ•', 'เธฃเธญเธ•เธฃเธงเธ', 'เนเธเนเธฃเธญเธ 1', 'เน€เธเธดเธเธฃเธญเธ', 'เธชเนเธเนเธฅเนเธง')
  ),
  revisions INTEGER NOT NULL DEFAULT 0 CHECK (revisions >= 0),
  issue TEXT NOT NULL DEFAULT '',

  version INTEGER NOT NULL DEFAULT 1 CHECK (version >= 1),
  created_by TEXT NOT NULL DEFAULT 'owner',
  updated_by TEXT NOT NULL DEFAULT 'owner',
  last_touched_by_type TEXT NOT NULL DEFAULT 'human' CHECK (
    last_touched_by_type IN ('human', 'agent', 'system')
  ),
  assigned_agent TEXT NOT NULL DEFAULT '',
  execution_mode TEXT NOT NULL DEFAULT 'manual' CHECK (
    execution_mode IN ('manual', 'human-in-the-loop', 'agent-auto')
  ),
  agent_status TEXT NOT NULL DEFAULT 'idle' CHECK (
    agent_status IN ('idle', 'drafted', 'queued', 'running', 'needs-review', 'approved', 'rejected', 'failed')
  ),
  handoff_note TEXT NOT NULL DEFAULT '',

  client_updated_at TEXT,
  last_synced_at TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE,
  FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE SET NULL,
  FOREIGN KEY (package_id) REFERENCES packages(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS activity_log (
  id TEXT PRIMARY KEY,
  business_id TEXT NOT NULL,
  entity TEXT NOT NULL,
  record_id TEXT NOT NULL,
  action TEXT NOT NULL CHECK (
    action IN ('UPSERT_ENTITY', 'DELETE_ENTITY', 'AGENT_DRAFT', 'AGENT_APPROVE', 'AGENT_REJECT', 'SYNC_CONFLICT')
  ),
  actor_type TEXT NOT NULL CHECK (
    actor_type IN ('human', 'agent', 'system')
  ),
  actor_id TEXT NOT NULL,
  before_version INTEGER,
  after_version INTEGER,
  client_op_id TEXT,
  summary TEXT NOT NULL DEFAULT '',
  payload_before_json TEXT,
  payload_after_json TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS sync_outbox (
  id TEXT PRIMARY KEY,
  business_id TEXT NOT NULL,
  client_id TEXT NOT NULL,
  op_id TEXT NOT NULL UNIQUE,
  entity TEXT NOT NULL,
  record_id TEXT NOT NULL,
  operation_type TEXT NOT NULL CHECK (
    operation_type IN ('UPSERT_ENTITY', 'DELETE_ENTITY', 'RESOLVE_CONFLICT')
  ),
  payload_json TEXT NOT NULL,
  sync_status TEXT NOT NULL DEFAULT 'pending' CHECK (
    sync_status IN ('pending', 'accepted', 'conflict', 'failed')
  ),
  error_message TEXT NOT NULL DEFAULT '',
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS agent_runs (
  id TEXT PRIMARY KEY,
  business_id TEXT NOT NULL,
  agent_name TEXT NOT NULL,
  scope_entity TEXT NOT NULL,
  scope_record_id TEXT,
  trigger_source TEXT NOT NULL CHECK (
    trigger_source IN ('human', 'system', 'schedule')
  ),
  status TEXT NOT NULL CHECK (
    status IN ('queued', 'running', 'needs-review', 'approved', 'rejected', 'failed', 'completed')
  ),
  input_json TEXT NOT NULL,
  output_json TEXT,
  review_note TEXT NOT NULL DEFAULT '',
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_packages_business_name
  ON packages (business_id, name);

CREATE INDEX IF NOT EXISTS idx_orders_business_updated
  ON orders (business_id, updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_orders_business_payment
  ON orders (business_id, payment_status);

CREATE INDEX IF NOT EXISTS idx_orders_business_fulfillment
  ON orders (business_id, fulfillment_status);

CREATE INDEX IF NOT EXISTS idx_production_jobs_business_updated
  ON production_jobs (business_id, updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_production_jobs_business_status
  ON production_jobs (business_id, status);

CREATE INDEX IF NOT EXISTS idx_production_jobs_order_id
  ON production_jobs (order_id);

CREATE INDEX IF NOT EXISTS idx_activity_log_business_entity_record
  ON activity_log (business_id, entity, record_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_sync_outbox_business_status
  ON sync_outbox (business_id, sync_status, created_at ASC);

CREATE INDEX IF NOT EXISTS idx_agent_runs_business_status
  ON agent_runs (business_id, status, created_at DESC);

INSERT OR IGNORE INTO businesses (id, slug, name, timezone)
VALUES ('biz-morning-pic-369', 'morning-pic-369', 'Morning Pic 369', 'Asia/Bangkok');

COMMIT;
