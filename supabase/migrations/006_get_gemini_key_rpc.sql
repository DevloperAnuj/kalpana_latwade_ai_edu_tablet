-- ============================================================
-- EduForge – Secure RPC for Gemini API key
-- Reads 'gm_api_key' from Supabase Vault.
-- Only teachers may call it.
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_gemini_api_key()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role TEXT;
  v_key  TEXT;
BEGIN
  SELECT role INTO v_role FROM public.profiles WHERE id = auth.uid();
  IF v_role <> 'teacher' THEN
    RAISE EXCEPTION 'Only teachers can access the Gemini API key';
  END IF;

  SELECT decrypted_secret INTO v_key
    FROM vault.decrypted_secrets
   WHERE name = 'gm_api_key'
   LIMIT 1;

  RETURN v_key;
END;
$$;

REVOKE ALL ON FUNCTION public.get_gemini_api_key() FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.get_gemini_api_key() TO authenticated;
