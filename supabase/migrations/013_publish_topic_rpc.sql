-- Phase 11 §3.2 – Atomic publish_topic RPC.
-- Wraps topic insert + 5 material upserts in a single transaction.
-- Rolls back entirely if any step fails.

CREATE OR REPLACE FUNCTION public.publish_topic(
  p_class_id    UUID,
  p_teacher_id  UUID,
  p_title       TEXT,
  p_raw_content TEXT,
  p_mindmap     JSONB,
  p_flashcards  JSONB,
  p_infographic JSONB,
  p_table_data  JSONB,
  p_quiz        JSONB
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_topic_id UUID;
BEGIN
  -- Verify caller owns the class
  IF NOT EXISTS (
    SELECT 1 FROM public.classes
    WHERE id = p_class_id AND teacher_id = auth.uid() AND deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Permission denied: class not found or not owned by caller';
  END IF;

  -- Insert topic
  INSERT INTO public.topics (class_id, teacher_id, title, raw_content, status)
  VALUES (p_class_id, p_teacher_id, p_title, p_raw_content, 'published')
  RETURNING id INTO v_topic_id;

  -- Upsert all five material types
  INSERT INTO public.materials (topic_id, type, json_data) VALUES
    (v_topic_id, 'mindmap',      p_mindmap),
    (v_topic_id, 'flashcards',   p_flashcards),
    (v_topic_id, 'infographic',  p_infographic),
    (v_topic_id, 'table',        p_table_data),
    (v_topic_id, 'quiz',         p_quiz)
  ON CONFLICT (topic_id, type) DO UPDATE SET json_data = EXCLUDED.json_data;

  RETURN v_topic_id;
END;
$$;
