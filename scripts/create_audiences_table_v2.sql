-- Re-create audiences table to match app model (audience_model.dart)
-- Safe to run multiple times

-- Helper: updated_at trigger function (idempotent)
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Table: public.audiences
CREATE TABLE IF NOT EXISTS public.audiences (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  type TEXT,
  capacity INTEGER,
  building_id INTEGER REFERENCES public.buildings(id),
  teacher_id INTEGER REFERENCES public.teachers(id) ON DELETE SET NULL,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.audience_lesson_types (
  id SERIAL PRIMARY KEY,
  audience_id INTEGER NOT NULL REFERENCES public.audiences(id) ON DELETE CASCADE,
  lesson_type_id INTEGER NOT NULL REFERENCES public.lesson_types(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (audience_id, lesson_type_id)
);

-- Trigger to maintain updated_at
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'update_audiences_updated_at'
  ) THEN
    CREATE TRIGGER update_audiences_updated_at
      BEFORE UPDATE ON public.audiences
      FOR EACH ROW
      EXECUTE FUNCTION public.update_updated_at_column();
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'update_audience_lesson_types_updated_at'
  ) THEN
    CREATE TRIGGER update_audience_lesson_types_updated_at
      BEFORE UPDATE ON public.audience_lesson_types
      FOR EACH ROW
      EXECUTE FUNCTION public.update_updated_at_column();
  END IF;
END $$;

-- Indexes
CREATE INDEX IF NOT EXISTS idx_audiences_name ON public.audiences(name);
CREATE INDEX IF NOT EXISTS idx_audience_lesson_types_audience ON public.audience_lesson_types(audience_id);

-- RLS
ALTER TABLE public.audiences ENABLE ROW LEVEL SECURITY;
CREATE POLICY IF NOT EXISTS "anon_all_audiences"
  ON public.audiences FOR ALL TO anon USING (true) WITH CHECK (true);

-- Optional: grant to authenticated as well
CREATE POLICY IF NOT EXISTS "authenticated_all_audiences"
  ON public.audiences FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE public.audience_lesson_types ENABLE ROW LEVEL SECURITY;
CREATE POLICY IF NOT EXISTS "anon_all_audience_lesson_types"
  ON public.audience_lesson_types FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY IF NOT EXISTS "authenticated_all_audience_lesson_types"
  ON public.audience_lesson_types FOR ALL TO authenticated USING (true) WITH CHECK (true);

