-- Add remote media URL columns to exercises table.
-- Also adds duo_image_path which was modelled in Dart but missing from the DB.
-- Creates the exercise-media storage bucket for uploaded professional content.

ALTER TABLE public.exercises ADD COLUMN IF NOT EXISTS duo_image_path  TEXT;
ALTER TABLE public.exercises ADD COLUMN IF NOT EXISTS image_url       TEXT;
ALTER TABLE public.exercises ADD COLUMN IF NOT EXISTS duo_image_url   TEXT;
ALTER TABLE public.exercises ADD COLUMN IF NOT EXISTS video_url       TEXT;

-- Public read-only storage bucket for exercise media (images + videos).
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'exercise-media',
  'exercise-media',
  true,
  524288000,
  ARRAY['image/jpeg','image/png','image/webp','video/mp4','video/quicktime','video/webm']
)
ON CONFLICT (id) DO NOTHING;

-- Allow anyone (anon + authenticated) to read from the bucket.
DROP POLICY IF EXISTS "exercise-media public read" ON storage.objects;
CREATE POLICY "exercise-media public read"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'exercise-media');
