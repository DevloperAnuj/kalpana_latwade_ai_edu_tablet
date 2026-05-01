-- Phase 9: quiz_attempts table for student quiz submissions.
-- Teachers subscribed to this via Realtime (Phase 6) receive live updates.
-- Idempotent: safe to re-run if partially applied.

CREATE TABLE IF NOT EXISTS public.quiz_attempts (
  id            UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id    UUID         NOT NULL REFERENCES auth.users(id)       ON DELETE CASCADE,
  material_id   UUID         NOT NULL REFERENCES public.materials(id)  ON DELETE CASCADE,
  answers_json  JSONB        NOT NULL DEFAULT '{}',
  score         INT          NOT NULL DEFAULT 0,
  submitted_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

ALTER TABLE public.quiz_attempts ENABLE ROW LEVEL SECURITY;

-- Drop before recreate so re-runs never fail on "already exists"
DROP POLICY IF EXISTS "quiz_attempts: student insert"  ON public.quiz_attempts;
DROP POLICY IF EXISTS "quiz_attempts: student read own" ON public.quiz_attempts;
DROP POLICY IF EXISTS "quiz_attempts: teacher read"    ON public.quiz_attempts;

-- Students can insert their own attempts
CREATE POLICY "quiz_attempts: student insert"
  ON public.quiz_attempts
  FOR INSERT TO authenticated
  WITH CHECK (student_id = auth.uid());

-- Students can read their own attempts (for "last score" banner)
CREATE POLICY "quiz_attempts: student read own"
  ON public.quiz_attempts
  FOR SELECT TO authenticated
  USING (student_id = auth.uid());

-- Teachers can read attempts for topics belonging to their classes
CREATE POLICY "quiz_attempts: teacher read"
  ON public.quiz_attempts
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM   public.materials  m
      JOIN   public.topics     t ON t.id = m.topic_id
      JOIN   public.classes    c ON c.id = t.class_id
      WHERE  m.id  = quiz_attempts.material_id
      AND    c.teacher_id = auth.uid()
    )
  );

-- Enable Realtime (ignore error if already a member of the publication)
DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.quiz_attempts;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
