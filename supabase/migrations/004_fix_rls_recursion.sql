-- ============================================================
-- EduForge – Fix RLS infinite recursion on class_students
-- Idempotent: safe to re-run
-- ============================================================
-- Root cause:
--   class_students SELECT policy → EXISTS (SELECT FROM classes) →
--   classes SELECT policy → EXISTS (SELECT FROM class_students) → loop
--
-- Fix: a SECURITY DEFINER helper reads classes bypassing RLS,
-- so class_students policy never re-enters the classes RLS chain.
-- ============================================================

-- Helper: bypass RLS to check if the calling user owns a class
CREATE OR REPLACE FUNCTION public.is_teacher_of_class(p_class_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM classes
    WHERE id = p_class_id AND teacher_id = auth.uid()
  );
$$;

-- Replace the policy that caused the cycle
DROP POLICY IF EXISTS "class_students: member read" ON class_students;

CREATE POLICY "class_students: member read"
  ON class_students FOR SELECT
  USING (
    student_id = auth.uid() OR
    public.is_teacher_of_class(class_id)
  );
