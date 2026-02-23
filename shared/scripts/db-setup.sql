-- Ohio Mutual Claims Database Schema
-- Run once: psql -U openclaw -d openclaw_claims -f db-setup.sql
--
-- Design: Single JSONB column (claim_data) stores the full claim document
-- matching the claim.schema.json structure. This means every agent reads/writes
-- the same JSON shape whether it's in the DB or in memory.

CREATE TABLE IF NOT EXISTS claims (
    claim_id        TEXT PRIMARY KEY,                 -- CLM-2026-00001
    status          TEXT NOT NULL DEFAULT 'FNOL_RECEIVED',
    channel         TEXT NOT NULL DEFAULT 'telegram',
    user_id         TEXT NOT NULL,
    policy_id       TEXT,
    claim_data      JSONB NOT NULL DEFAULT '{}',      -- Full claim JSON per claim.schema.json
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS claim_media (
    id              SERIAL PRIMARY KEY,
    claim_id        TEXT NOT NULL REFERENCES claims(claim_id),
    file_path       TEXT NOT NULL,
    media_type      TEXT DEFAULT 'image',
    original_name   TEXT,
    uploaded_at     TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for common queries
CREATE INDEX IF NOT EXISTS idx_claims_user ON claims(user_id);
CREATE INDEX IF NOT EXISTS idx_claims_status ON claims(status);
CREATE INDEX IF NOT EXISTS idx_claims_policy ON claims(policy_id);
CREATE INDEX IF NOT EXISTS idx_media_claim ON claim_media(claim_id);
CREATE INDEX IF NOT EXISTS idx_claims_data_gin ON claims USING GIN (claim_data);

-- Auto-update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS claims_updated ON claims;
CREATE TRIGGER claims_updated
    BEFORE UPDATE ON claims
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();
