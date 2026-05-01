-- ============================================================
-- EduForge – Topics and Materials tables
-- Safe to re-run: drops and recreates to fix schema drift.
-- These tables are Phase 4 additions with no prior real data.
-- ============================================================

-- updated_at helper (idempotent)
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

-- Drop in dependency order so foreign keys don't block
DROP TABLE IF EXISTS public.materials CASCADE;
DROP TABLE IF EXISTS public.topics    CASCADE;

-- ── Topics ────────────────────────────────────────────────
CREATE TABLE public.topics (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  class_id    UUID        NOT NULL REFERENCES public.classes(id)   ON DELETE CASCADE,
  teacher_id  UUID        NOT NULL REFERENCES public.profiles(id)  ON DELETE CASCADE,
  title       TEXT        NOT NULL,
  raw_content TEXT        NOT NULL,
  status      TEXT        NOT NULL DEFAULT 'draft'
                          CHECK (status IN ('draft', 'published')),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_topics_class_id   ON public.topics(class_id);
CREATE INDEX idx_topics_teacher_id ON public.topics(teacher_id);
CREATE INDEX idx_topics_status     ON public.topics(status);

CREATE TRIGGER topics_updated_at
  BEFORE UPDATE ON public.topics
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ── Materials ─────────────────────────────────────────────
CREATE TABLE public.materials (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  topic_id   UUID        NOT NULL REFERENCES public.topics(id) ON DELETE CASCADE,
  type       TEXT        NOT NULL
                         CHECK (type IN ('mindmap','flashcards','infographic','table','quiz')),
  json_data  JSONB       NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (topic_id, type)
);

CREATE INDEX idx_materials_topic_id ON public.materials(topic_id);

CREATE TRIGGER materials_updated_at
  BEFORE UPDATE ON public.materials
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ── RLS ───────────────────────────────────────────────────
ALTER TABLE public.topics    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.materials ENABLE ROW LEVEL SECURITY;

-- Teachers: full CRUD on their own topics
CREATE POLICY "topics: teacher crud" ON public.topics
  FOR ALL
  USING     (teacher_id = auth.uid())
  WITH CHECK (teacher_id = auth.uid());

-- Students: read published topics in classes they've joined
CREATE POLICY "topics: student read" ON public.topics
  FOR SELECT
  USING (
    status = 'published' AND
    EXISTS (
      SELECT 1 FROM public.class_students cs
      WHERE cs.class_id = topics.class_id
        AND cs.student_id = auth.uid()
    )
  );

-- Teachers: full CRUD on materials belonging to their topics
CREATE POLICY "materials: teacher crud" ON public.materials
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.topics t
      WHERE t.id = materials.topic_id
        AND t.teacher_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.topics t
      WHERE t.id = materials.topic_id
        AND t.teacher_id = auth.uid()
    )
  );

-- Students: read materials for published topics in their classes
CREATE POLICY "materials: student read" ON public.materials
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.topics t
      JOIN public.class_students cs ON cs.class_id = t.class_id
      WHERE t.id = materials.topic_id
        AND t.status = 'published'
        AND cs.student_id = auth.uid()
    )
  );
