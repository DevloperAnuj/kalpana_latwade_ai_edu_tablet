-- Phase 12 – Profile Management
-- Adds roll_number, prevents role changes, grants teacher read-access to student
-- profiles (required for quiz-results join), and backfills empty display_names.

-- ── roll_number column ────────────────────────────────────────────────────────
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS roll_number TEXT;

CREATE INDEX IF NOT EXISTS idx_profiles_roll_number
  ON public.profiles(roll_number)
  WHERE roll_number IS NOT NULL;

-- ── Immutable-role trigger ────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.prevent_role_change()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF OLD.role IS DISTINCT FROM NEW.role THEN
    RAISE EXCEPTION 'Role cannot be changed once assigned';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS enforce_role_immutable ON public.profiles;
CREATE TRIGGER enforce_role_immutable
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.prevent_role_change();

-- ── Teacher read policy for class-member profiles ─────────────────────────────
-- Without this, PostgREST embedded joins (profiles(display_name, roll_number) on
-- quiz_attempts queries) return NULL because the default policy only allows
-- auth.uid() = id.
DROP POLICY IF EXISTS "profiles: teacher read class members" ON public.profiles;
CREATE POLICY "profiles: teacher read class members"
  ON public.profiles FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM class_students cs
      JOIN classes c ON c.id = cs.class_id
      WHERE cs.student_id = profiles.id
        AND c.teacher_id = auth.uid()
    )
  );

-- ── Backfill empty display_names from email prefix ────────────────────────────
UPDATE public.profiles p
SET display_name = split_part(u.email, '@', 1)
FROM auth.users u
WHERE u.id = p.id
  AND (p.display_name IS NULL OR trim(p.display_name) = '');
