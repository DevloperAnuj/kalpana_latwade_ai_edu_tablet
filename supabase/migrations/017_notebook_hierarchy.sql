-- Phase 16 follow-up: notebook hierarchy (subject → chapter → topic) + page patterns

-- 1. Add type column to notebooks (default 'topic' so existing data is valid)
ALTER TABLE notebooks
  ADD COLUMN IF NOT EXISTS type TEXT DEFAULT 'topic'
    CHECK (type IN ('subject', 'chapter', 'topic'));

-- 2. Add ordering within a parent
ALTER TABLE notebooks
  ADD COLUMN IF NOT EXISTS order_index INT DEFAULT 0;

-- 3. Add page pattern to note_pages
ALTER TABLE note_pages
  ADD COLUMN IF NOT EXISTS pattern TEXT DEFAULT 'ruled'
    CHECK (pattern IN ('ruled', 'grid', 'graph'));

-- 4. Backfill: existing root notebooks (parent_id IS NULL) stay as 'topic'.
--    When the app first runs it will optionally create a default "General"
--    subject and move orphaned topics under it (handled in app code, not here).

-- 5. Index for fast child lookups (parent_id already has one from migration 016,
--    but add a composite covering type for filtered list queries).
CREATE INDEX IF NOT EXISTS notebooks_parent_type_idx
  ON notebooks (parent_id, type);
