-- Phase 14: Handwritten Notes
-- notebooks, note_pages, sync_metadata tables with RLS

-- ── Notebooks ────────────────────────────────────────────────────────────────

CREATE TABLE notebooks (
  id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID         NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title       TEXT         NOT NULL,
  description TEXT,
  parent_id   UUID         REFERENCES notebooks(id) ON DELETE CASCADE,
  tags        TEXT[]       NOT NULL DEFAULT '{}',
  is_archived BOOLEAN      NOT NULL DEFAULT FALSE,
  topic_id    UUID,        -- soft ref to topics(id); no FK to avoid cross-table deps
  created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX notebooks_user_id_idx    ON notebooks(user_id);
CREATE INDEX notebooks_parent_id_idx  ON notebooks(parent_id) WHERE parent_id IS NOT NULL;
CREATE INDEX notebooks_updated_at_idx ON notebooks(updated_at);

-- ── Note Pages ────────────────────────────────────────────────────────────────

CREATE TABLE note_pages (
  id           UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  notebook_id  UUID         NOT NULL REFERENCES notebooks(id) ON DELETE CASCADE,
  page_number  INT          NOT NULL,
  title        TEXT,
  strokes      JSONB        NOT NULL DEFAULT '[]',
  text_content TEXT,
  thumbnail_url TEXT,
  created_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  UNIQUE(notebook_id, page_number)
);

CREATE INDEX note_pages_notebook_id_idx  ON note_pages(notebook_id);
CREATE INDEX note_pages_updated_at_idx   ON note_pages(updated_at);

-- ── Sync Metadata ─────────────────────────────────────────────────────────────

CREATE TABLE sync_metadata (
  id              UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID         NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  last_sync_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  pending_changes INT          NOT NULL DEFAULT 0,
  UNIQUE(user_id)
);

-- ── Updated-at triggers ───────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER notebooks_updated_at
  BEFORE UPDATE ON notebooks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER note_pages_updated_at
  BEFORE UPDATE ON note_pages
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ── Row-Level Security ────────────────────────────────────────────────────────

ALTER TABLE notebooks     ENABLE ROW LEVEL SECURITY;
ALTER TABLE note_pages    ENABLE ROW LEVEL SECURITY;
ALTER TABLE sync_metadata ENABLE ROW LEVEL SECURITY;

-- Notebooks: owner-only
CREATE POLICY "notebooks: owner all"
  ON notebooks FOR ALL
  USING  (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Note pages: accessible only if the parent notebook belongs to the user
CREATE POLICY "note_pages: owner all"
  ON note_pages FOR ALL
  USING (
    notebook_id IN (
      SELECT id FROM notebooks WHERE user_id = auth.uid()
    )
  )
  WITH CHECK (
    notebook_id IN (
      SELECT id FROM notebooks WHERE user_id = auth.uid()
    )
  );

-- Sync metadata: owner-only
CREATE POLICY "sync_metadata: owner all"
  ON sync_metadata FOR ALL
  USING  (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
