-- ============================================================
-- EduForge – Phase 2 Schema Hardening
-- Idempotent: safe to re-run (run AFTER 001_initial_schema.sql)
-- ============================================================

-- ============================================================
-- Cleanup (makes script idempotent)
-- ============================================================

-- Policies replaced or added in this migration
DROP POLICY IF EXISTS "classes: teacher delete"  ON classes;
DROP POLICY IF EXISTS "topics: member read"      ON topics;
DROP POLICY IF EXISTS "topics: student read"     ON topics;
DROP POLICY IF EXISTS "materials: member read"   ON materials;
DROP POLICY IF EXISTS "materials: student read"  ON materials;

-- Trigger + function for materials updated_at
DROP TRIGGER   IF EXISTS set_materials_updated_at ON materials;
DROP FUNCTION  IF EXISTS public.set_updated_at();

-- AI key fetch function
DROP FUNCTION  IF EXISTS public.get_ai_api_key();

-- ============================================================
-- Table enhancements
-- ============================================================

-- updated_at column on materials (idempotent)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name   = 'materials'
      AND column_name  = 'updated_at'
  ) THEN
    ALTER TABLE materials ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
  END IF;
END $$;

-- join_code must be exactly 6 uppercase alphanumeric characters (idempotent)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE table_schema    = 'public'
      AND table_name      = 'classes'
      AND constraint_name = 'classes_join_code_format'
  ) THEN
    ALTER TABLE classes ADD CONSTRAINT classes_join_code_format
      CHECK (join_code ~ '^[A-Z0-9]{6}$');
  END IF;
END $$;

-- ============================================================
-- Performance indexes
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_topics_class_id           ON topics(class_id);
CREATE INDEX IF NOT EXISTS idx_materials_topic_id         ON materials(topic_id);
CREATE INDEX IF NOT EXISTS idx_quiz_attempts_student_id   ON quiz_attempts(student_id);
CREATE INDEX IF NOT EXISTS idx_class_students_class_id    ON class_students(class_id);
CREATE INDEX IF NOT EXISTS idx_class_students_student_id  ON class_students(student_id);

-- ============================================================
-- Trigger: auto-stamp updated_at when materials.content changes
-- ============================================================

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE TRIGGER set_materials_updated_at
  BEFORE UPDATE OF content ON materials
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ============================================================
-- RLS – additional and replacement policies
-- ============================================================

-- Teachers can delete their own classes
CREATE POLICY "classes: teacher delete"
  ON classes FOR DELETE
  USING (auth.uid() = teacher_id);

-- Students read ONLY published topics from classes they are enrolled in.
-- (Teachers already covered by "topics: teacher all" from migration 001)
-- The broad "topics: member read" from 001 is dropped above and replaced here.
CREATE POLICY "topics: student read"
  ON topics FOR SELECT
  USING (
    status = 'published' AND
    EXISTS (
      SELECT 1 FROM class_students
      WHERE class_id = topics.class_id AND student_id = auth.uid()
    )
  );

-- Students read materials belonging to published topics they are enrolled in.
-- (Teachers already covered by "materials: teacher all" from migration 001)
-- The broad "materials: member read" from 001 is dropped above and replaced here.
CREATE POLICY "materials: student read"
  ON materials FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM topics t
      WHERE t.id = materials.topic_id
        AND t.status = 'published'
        AND EXISTS (
          SELECT 1 FROM class_students cs
          WHERE cs.class_id = t.class_id AND cs.student_id = auth.uid()
        )
    )
  );

-- ============================================================
-- Secure RPC: return AI API key to authenticated teachers only
--
-- Usage:
--   await supabase.rpc('get_ai_api_key');
--
-- Setup:
--   1. Supabase Dashboard → Vault → New Secret
--      Name: ai_api_key  |  Value: your actual key
--   2. No code change needed – the function looks up by name.
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_ai_api_key()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role TEXT;
  v_key  TEXT;
BEGIN
  SELECT role INTO v_role
  FROM profiles
  WHERE id = auth.uid();

  IF v_role IS DISTINCT FROM 'teacher' THEN
    RAISE EXCEPTION 'Only teachers can access the AI API key'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT decrypted_secret INTO v_key
  FROM vault.decrypted_secrets
  WHERE name = 'ai_api_key';

  RETURN v_key;
END;
$$;
