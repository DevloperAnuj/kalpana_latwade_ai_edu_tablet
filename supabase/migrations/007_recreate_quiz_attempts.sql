-- ============================================================
-- EduForge – Migration 007: Recreate quiz_attempts + Realtime
-- Background: migration 005 ran DROP TABLE materials CASCADE,
-- which cascaded to drop quiz_attempts. This restores it and
-- enables Supabase Realtime so teachers see live quiz results.
-- ============================================================

-- Drop old policies (safe to re-run)
DROP POLICY IF EXISTS "quiz_attempts: student insert" ON public.quiz_attempts;
DROP POLICY IF EXISTS "quiz_attempts: student read"   ON public.quiz_attempts;
DROP POLICY IF EXISTS "quiz_attempts: teacher read"   ON public.quiz_attempts;

-- Recreate the table
CREATE TABLE IF NOT EXISTS public.quiz_attempts (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id   UUID        NOT NULL REFERENCES public.profiles(id)   ON DELETE CASCADE,
  material_id  UUID        NOT NULL REFERENCES public.materials(id)  ON DELETE CASCADE,
  -- Array of answer indices (0-3), one per question, in order.
  -- Example: [0, 2, 1, 3] means student chose A, C, B, D.
  answers      JSONB       NOT NULL DEFAULT '[]',
  score        INTEGER     NOT NULL DEFAULT 0,
  attempted_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS
ALTER TABLE public.quiz_attempts ENABLE ROW LEVEL SECURITY;

-- Students insert their own attempts
CREATE POLICY "quiz_attempts: student insert"
  ON public.quiz_attempts FOR INSERT
  WITH CHECK (student_id = auth.uid());

-- Students read their own attempts
CREATE POLICY "quiz_attempts: student read"
  ON public.quiz_attempts FOR SELECT
  USING (student_id = auth.uid());

-- Teachers read attempts for their classes (via materials → topics → classes)
CREATE POLICY "quiz_attempts: teacher read"
  ON public.quiz_attempts FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM   public.materials m
      JOIN   public.topics    t ON t.id  = m.topic_id
      JOIN   public.classes   c ON c.id  = t.class_id
      WHERE  m.id = quiz_attempts.material_id
        AND  c.teacher_id = auth.uid()
    )
  );

-- Enable Supabase Realtime so teachers receive live INSERT events
ALTER PUBLICATION supabase_realtime ADD TABLE public.quiz_attempts;
