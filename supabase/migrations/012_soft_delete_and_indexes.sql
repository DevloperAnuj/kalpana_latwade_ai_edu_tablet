-- Phase 11 §3.3 + §3.4 + §5.1
-- Soft-delete columns, unique join-code index, and composite performance indexes.
-- Idempotent: uses IF NOT EXISTS / IF EXISTS guards throughout.

-- ── §3.3 Soft delete ─────────────────────────────────────────────────────────

ALTER TABLE public.classes
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ DEFAULT NULL;

ALTER TABLE public.topics
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ DEFAULT NULL;

-- Update existing RLS SELECT policies to exclude soft-deleted rows.
-- We drop and recreate to keep them idempotent.

-- classes – teacher can see only own non-deleted rows
DROP POLICY IF EXISTS "classes: teacher select" ON public.classes;
CREATE POLICY "classes: teacher select"
  ON public.classes
  FOR SELECT TO authenticated
  USING (teacher_id = auth.uid() AND deleted_at IS NULL);

-- topics – teacher sees own topics that are not deleted
DROP POLICY IF EXISTS "topics: teacher select" ON public.topics;
CREATE POLICY "topics: teacher select"
  ON public.topics
  FOR SELECT TO authenticated
  USING (
    deleted_at IS NULL
    AND EXISTS (
      SELECT 1 FROM public.classes c
      WHERE c.id = topics.class_id
        AND c.teacher_id = auth.uid()
        AND c.deleted_at IS NULL
    )
  );

-- topics – student sees published non-deleted topics in enrolled classes
DROP POLICY IF EXISTS "topics: student select" ON public.topics;
CREATE POLICY "topics: student select"
  ON public.topics
  FOR SELECT TO authenticated
  USING (
    status = 'published'
    AND deleted_at IS NULL
    AND EXISTS (
      SELECT 1 FROM public.class_students cs
      WHERE cs.class_id = topics.class_id
        AND cs.student_id = auth.uid()
    )
  );

-- ── §3.4 Unique join code (active classes only) ───────────────────────────────

DROP INDEX IF EXISTS public.unique_join_code_active;
CREATE UNIQUE INDEX unique_join_code_active
  ON public.classes (join_code)
  WHERE deleted_at IS NULL;

-- ── §5.1 Composite performance indexes ───────────────────────────────────────

-- Topics list for a class (most common query)
CREATE INDEX IF NOT EXISTS idx_topics_class_status_deleted
  ON public.topics (class_id, status, deleted_at);

-- Quiz attempts for a material, newest first
CREATE INDEX IF NOT EXISTS idx_quiz_attempts_material_submitted
  ON public.quiz_attempts (material_id, submitted_at DESC);

-- Class-student lookups
CREATE INDEX IF NOT EXISTS idx_class_students_class_student
  ON public.class_students (class_id, student_id);

-- Materials by topic
CREATE INDEX IF NOT EXISTS idx_materials_topic_type
  ON public.materials (topic_id, type);
