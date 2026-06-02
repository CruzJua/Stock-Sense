-- ─────────────────────────────────────────────────────────────────────────────
-- Migration: Add Notifications Infrastructure
--
-- Creates the device_tokens table used by the send-notifications Edge Function
-- to know which FCM/APNs token belongs to which user.
--
-- pg_cron setup:
--   pg_cron is only available on cloud Supabase (not local dev).
--   After deploying to cloud, run the cron.schedule() call manually in the
--   Supabase SQL Editor — it's documented below as a comment.
-- ─────────────────────────────────────────────────────────────────────────────

-- Device tokens table — stores the FCM push token for each user's device.
-- A user can have multiple devices, so there's no unique constraint on user_id.
CREATE TABLE IF NOT EXISTS public.device_tokens (
  id         uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    uuid        REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  token      text        NOT NULL,
  platform   text        CHECK (platform IN ('android', 'ios', 'web')),
  created_at timestamptz DEFAULT now()
);

-- Row Level Security — users can only manage their own tokens.
ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own device tokens"
  ON public.device_tokens
  FOR ALL
  USING (auth.uid() = user_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- CLOUD ONLY — pg_cron setup
-- Run the following in the Supabase SQL Editor after deploying to cloud.
-- Replace <project-ref> with your Supabase project reference ID and
-- <service-role-key> with your project's service role secret.
-- ─────────────────────────────────────────────────────────────────────────────
--
-- CREATE EXTENSION IF NOT EXISTS pg_cron;
--
-- SELECT cron.schedule(
--   'daily-inventory-sweep',
--   '0 8 * * *',   -- Every day at 08:00 UTC
--   $$
--     SELECT net.http_post(
--       url     := 'https://<project-ref>.supabase.co/functions/v1/send-notifications',
--       headers := '{"Authorization": "Bearer <service-role-key>"}'::jsonb,
--       body    := '{}'::jsonb
--     );
--   $$
-- );
