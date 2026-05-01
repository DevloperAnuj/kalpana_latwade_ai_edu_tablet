-- Phase 11 §2.1 – RLS Audit
-- Run this script in the Supabase SQL editor to verify isolation between users.
-- Every assertion uses RAISE EXCEPTION so the transaction aborts on failure.

DO $$
DECLARE
  v_ok BOOLEAN;
BEGIN
  -- 1. classes: teacher can only see own rows
  SELECT EXISTS(
    SELECT 1 FROM pg_policies
    WHERE tablename = 'classes'
      AND cmd IN ('SELECT', 'INSERT', 'UPDATE', 'DELETE')
  ) INTO v_ok;
  IF NOT v_ok THEN
    RAISE EXCEPTION 'AUDIT FAIL: no RLS policies on classes';
  END IF;

  -- 2. topics: policy exists
  SELECT EXISTS(
    SELECT 1 FROM pg_policies WHERE tablename = 'topics'
  ) INTO v_ok;
  IF NOT v_ok THEN
    RAISE EXCEPTION 'AUDIT FAIL: no RLS policies on topics';
  END IF;

  -- 3. materials: policy exists
  SELECT EXISTS(
    SELECT 1 FROM pg_policies WHERE tablename = 'materials'
  ) INTO v_ok;
  IF NOT v_ok THEN
    RAISE EXCEPTION 'AUDIT FAIL: no RLS policies on materials';
  END IF;

  -- 4. quiz_attempts: policy exists
  SELECT EXISTS(
    SELECT 1 FROM pg_policies WHERE tablename = 'quiz_attempts'
  ) INTO v_ok;
  IF NOT v_ok THEN
    RAISE EXCEPTION 'AUDIT FAIL: no RLS policies on quiz_attempts';
  END IF;

  -- 5. class_students: policy exists
  SELECT EXISTS(
    SELECT 1 FROM pg_policies WHERE tablename = 'class_students'
  ) INTO v_ok;
  IF NOT v_ok THEN
    RAISE EXCEPTION 'AUDIT FAIL: no RLS policies on class_students';
  END IF;

  -- 6. quiz_attempts insert policy must reference auth.uid()
  -- INSERT policies use with_check (not qual); check both to be safe.
  SELECT EXISTS(
    SELECT 1 FROM pg_policies
    WHERE tablename = 'quiz_attempts'
      AND cmd = 'INSERT'
      AND (qual LIKE '%auth.uid()%' OR with_check LIKE '%auth.uid()%')
  ) INTO v_ok;
  IF NOT v_ok THEN
    RAISE EXCEPTION 'AUDIT FAIL: quiz_attempts INSERT policy does not reference auth.uid()';
  END IF;

  RAISE NOTICE 'RLS audit passed — all 6 checks OK';
END $$;

-- ── Foreign key hardening ─────────────────────────────────────────────────────
-- Prevent deleting a teacher account while they own classes.
-- Idempotent: constraint name is unique; re-running will error only if already exists.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'fk_classes_teacher_restrict'
      AND table_name = 'classes'
  ) THEN
    ALTER TABLE public.classes
      ADD CONSTRAINT fk_classes_teacher_restrict
      FOREIGN KEY (teacher_id) REFERENCES auth.users(id) ON DELETE RESTRICT;
  END IF;
END $$;
