-- ============================================================
-- EduForge – Phase 2 Fix: read role from sign-up metadata
-- Idempotent: safe to re-run
-- ============================================================
-- The handle_new_user trigger previously hardcoded role='teacher'.
-- Now it reads raw_user_meta_data->>'role' supplied by the client
-- and falls back to 'student' for any unexpected value.
-- ============================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role TEXT;
BEGIN
  v_role := COALESCE(NEW.raw_user_meta_data->>'role', 'student');

  IF v_role NOT IN ('teacher', 'student') THEN
    v_role := 'student';
  END IF;

  INSERT INTO public.profiles (id, role)
  VALUES (NEW.id, v_role);

  RETURN NEW;
END;
$$;
