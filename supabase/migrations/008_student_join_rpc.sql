-- ============================================================
-- EduForge – Phase 7: Student class-join RPC
-- Idempotent: safe to re-run
-- ============================================================
-- Students cannot SELECT from `classes` by join_code before they
-- are enrolled (the "classes: member read" RLS only covers
-- enrolled members and the owning teacher).
-- A SECURITY DEFINER function bypasses that restriction and
-- handles validation + enrollment atomically.
-- ============================================================

CREATE OR REPLACE FUNCTION public.join_class_by_code(p_join_code TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_class    RECORD;
  v_student  UUID := auth.uid();
  v_role     TEXT;
BEGIN
  -- Verify the caller is a student
  SELECT role INTO v_role FROM profiles WHERE id = v_student;
  IF v_role IS DISTINCT FROM 'student' THEN
    RAISE EXCEPTION 'Only students can join classes'
      USING ERRCODE = 'P0001';
  END IF;

  -- Find class by join code (normalise to uppercase, strip whitespace)
  SELECT id, name INTO v_class
  FROM classes
  WHERE join_code = upper(trim(p_join_code));

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Invalid join code. Please check and try again.'
      USING ERRCODE = 'P0002';
  END IF;

  -- Guard against duplicate enrollment
  IF EXISTS (
    SELECT 1 FROM class_students
    WHERE class_id = v_class.id AND student_id = v_student
  ) THEN
    RAISE EXCEPTION 'You are already a member of this class.'
      USING ERRCODE = 'P0003';
  END IF;

  -- Enroll the student
  INSERT INTO class_students(class_id, student_id)
  VALUES (v_class.id, v_student);

  RETURN jsonb_build_object(
    'class_id',   v_class.id::text,
    'class_name', v_class.name
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.join_class_by_code(TEXT) TO authenticated;
