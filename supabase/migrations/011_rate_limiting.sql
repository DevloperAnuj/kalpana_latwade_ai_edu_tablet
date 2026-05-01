-- Phase 11 §2.4 – Rate limiting for AI generation calls.
-- Idempotent: safe to re-run.

CREATE TABLE IF NOT EXISTS public.rate_limits (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  teacher_id  UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  action      TEXT        NOT NULL,
  window_start TIMESTAMPTZ NOT NULL DEFAULT date_trunc('minute', NOW()),
  call_count  INT         NOT NULL DEFAULT 1,
  UNIQUE (teacher_id, action, window_start)
);

ALTER TABLE public.rate_limits ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "rate_limits: own" ON public.rate_limits;
CREATE POLICY "rate_limits: own"
  ON public.rate_limits
  FOR ALL TO authenticated
  USING (teacher_id = auth.uid())
  WITH CHECK (teacher_id = auth.uid());

-- RPC: atomically check and increment.
-- Returns TRUE if the call is allowed, FALSE if the limit is exceeded.
CREATE OR REPLACE FUNCTION public.check_and_increment_rate_limit(
  p_action TEXT,
  p_max_calls INT DEFAULT 10
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_window TIMESTAMPTZ := date_trunc('minute', NOW());
  v_count  INT;
BEGIN
  INSERT INTO public.rate_limits (teacher_id, action, window_start, call_count)
  VALUES (auth.uid(), p_action, v_window, 1)
  ON CONFLICT (teacher_id, action, window_start)
  DO UPDATE SET call_count = rate_limits.call_count + 1
  RETURNING call_count INTO v_count;

  RETURN v_count <= p_max_calls;
END;
$$;
