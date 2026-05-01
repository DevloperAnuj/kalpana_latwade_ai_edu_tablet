-- ============================================================
-- EduForge – Phase 1 Initial Schema
-- Run this in Supabase Dashboard → SQL Editor
-- Safe to re-run: drops all policies/triggers before recreating
-- ============================================================

-- ============================================================
-- Cleanup (makes script idempotent)
-- ============================================================

-- Storage policies
DROP POLICY IF EXISTS "lesson_files: teacher upload"   ON storage.objects;
DROP POLICY IF EXISTS "lesson_files: teacher read own" ON storage.objects;

-- quiz_attempts
DROP POLICY IF EXISTS "quiz_attempts: student own"    ON quiz_attempts;
DROP POLICY IF EXISTS "quiz_attempts: student insert" ON quiz_attempts;
DROP POLICY IF EXISTS "quiz_attempts: student read"   ON quiz_attempts;
DROP POLICY IF EXISTS "quiz_attempts: teacher read"   ON quiz_attempts;

-- materials
DROP POLICY IF EXISTS "materials: member read" ON materials;
DROP POLICY IF EXISTS "materials: teacher all" ON materials;

-- topics
DROP POLICY IF EXISTS "topics: member read" ON topics;
DROP POLICY IF EXISTS "topics: teacher all" ON topics;

-- class_students
DROP POLICY IF EXISTS "class_students: member read" ON class_students;
DROP POLICY IF EXISTS "class_students: student join" ON class_students;

-- classes
DROP POLICY IF EXISTS "classes: teacher insert" ON classes;
DROP POLICY IF EXISTS "classes: member read"    ON classes;
DROP POLICY IF EXISTS "classes: teacher update" ON classes;

-- profiles
DROP POLICY IF EXISTS "profiles: own read"   ON profiles;
DROP POLICY IF EXISTS "profiles: own insert" ON profiles;
DROP POLICY IF EXISTS "profiles: own update" ON profiles;

-- Trigger + function
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- profiles (extends auth.users)
CREATE TABLE IF NOT EXISTS profiles (
  id           UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role         TEXT NOT NULL CHECK (role IN ('teacher', 'student')),
  display_name TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- classes
CREATE TABLE IF NOT EXISTS classes (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  teacher_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name       TEXT NOT NULL,
  join_code  TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- class_students (join table)
CREATE TABLE IF NOT EXISTS class_students (
  class_id   UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  joined_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (class_id, student_id)
);

-- topics
CREATE TABLE IF NOT EXISTS topics (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  class_id    UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  title       TEXT NOT NULL,
  lesson_text TEXT,
  status      TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published')),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- materials (one row per generated artefact type)
CREATE TABLE IF NOT EXISTS materials (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  topic_id   UUID NOT NULL REFERENCES topics(id) ON DELETE CASCADE,
  type       TEXT NOT NULL CHECK (type IN ('mindmap', 'flashcards', 'infographic', 'table', 'quiz')),
  content    JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- quiz_attempts
CREATE TABLE IF NOT EXISTS quiz_attempts (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id   UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  material_id  UUID NOT NULL REFERENCES materials(id) ON DELETE CASCADE,
  answers      JSONB NOT NULL DEFAULT '{}',
  score        NUMERIC,
  attempted_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- Trigger: auto-create profile on sign-up (bypasses RLS)
-- ============================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, role)
  VALUES (NEW.id, 'teacher');
  RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- Row Level Security
-- ============================================================

ALTER TABLE profiles      ENABLE ROW LEVEL SECURITY;
ALTER TABLE classes       ENABLE ROW LEVEL SECURITY;
ALTER TABLE class_students ENABLE ROW LEVEL SECURITY;
ALTER TABLE topics        ENABLE ROW LEVEL SECURITY;
ALTER TABLE materials     ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_attempts ENABLE ROW LEVEL SECURITY;

-- ---------- profiles ----------
CREATE POLICY "profiles: own read"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "profiles: own insert"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles: own update"
  ON profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- ---------- classes ----------
CREATE POLICY "classes: teacher insert"
  ON classes FOR INSERT
  WITH CHECK (
    auth.uid() = teacher_id AND
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'teacher')
  );

CREATE POLICY "classes: member read"
  ON classes FOR SELECT
  USING (
    auth.uid() = teacher_id OR
    EXISTS (
      SELECT 1 FROM class_students
      WHERE class_id = classes.id AND student_id = auth.uid()
    )
  );

CREATE POLICY "classes: teacher update"
  ON classes FOR UPDATE
  USING (auth.uid() = teacher_id)
  WITH CHECK (auth.uid() = teacher_id);

-- ---------- class_students ----------
CREATE POLICY "class_students: member read"
  ON class_students FOR SELECT
  USING (
    student_id = auth.uid() OR
    EXISTS (SELECT 1 FROM classes WHERE id = class_id AND teacher_id = auth.uid())
  );

CREATE POLICY "class_students: student join"
  ON class_students FOR INSERT
  WITH CHECK (student_id = auth.uid());

-- ---------- topics ----------
CREATE POLICY "topics: member read"
  ON topics FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM classes c
      WHERE c.id = topics.class_id
        AND (
          c.teacher_id = auth.uid() OR
          EXISTS (
            SELECT 1 FROM class_students
            WHERE class_id = c.id AND student_id = auth.uid()
          )
        )
    )
  );

CREATE POLICY "topics: teacher all"
  ON topics FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM classes
      WHERE id = topics.class_id AND teacher_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM classes
      WHERE id = topics.class_id AND teacher_id = auth.uid()
    )
  );

-- ---------- materials ----------
CREATE POLICY "materials: member read"
  ON materials FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM topics t
      JOIN classes c ON c.id = t.class_id
      WHERE t.id = materials.topic_id
        AND (
          c.teacher_id = auth.uid() OR
          EXISTS (
            SELECT 1 FROM class_students
            WHERE class_id = c.id AND student_id = auth.uid()
          )
        )
    )
  );

CREATE POLICY "materials: teacher all"
  ON materials FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM topics t
      JOIN classes c ON c.id = t.class_id
      WHERE t.id = materials.topic_id AND c.teacher_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM topics t
      JOIN classes c ON c.id = t.class_id
      WHERE t.id = materials.topic_id AND c.teacher_id = auth.uid()
    )
  );

-- ---------- quiz_attempts ----------
CREATE POLICY "quiz_attempts: student insert"
  ON quiz_attempts FOR INSERT
  WITH CHECK (student_id = auth.uid());

CREATE POLICY "quiz_attempts: student read"
  ON quiz_attempts FOR SELECT
  USING (student_id = auth.uid());

CREATE POLICY "quiz_attempts: teacher read"
  ON quiz_attempts FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM materials m
      JOIN topics t ON t.id = m.topic_id
      JOIN classes c ON c.id = t.class_id
      WHERE m.id = quiz_attempts.material_id AND c.teacher_id = auth.uid()
    )
  );

-- ============================================================
-- Storage bucket: lesson_files (private)
-- ============================================================

INSERT INTO storage.buckets (id, name, public)
VALUES ('lesson_files', 'lesson_files', false)
ON CONFLICT (id) DO NOTHING;

-- Teachers upload only to their own UID-prefixed folder
CREATE POLICY "lesson_files: teacher upload"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'lesson_files' AND
    auth.uid()::text = (storage.foldername(name))[1] AND
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'teacher')
  );

CREATE POLICY "lesson_files: teacher read own"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'lesson_files' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );
