-- Fix Supabase security linter warnings.

-- 1. Enable RLS on MigrationLog (server-only table, TD-02 §8).
ALTER TABLE public."MigrationLog" ENABLE ROW LEVEL SECURITY;

-- 2. Fix mutable search_path on set_updated_at function.
ALTER FUNCTION public.set_updated_at() SET search_path = public;
