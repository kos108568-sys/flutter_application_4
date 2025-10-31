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
  capacity INTEGER,
  audience_type_id INTEGER REFERENCES public.audience_types(id),
  building_id INTEGER REFERENCES public.buildings(id),
  responsible_teacher_id INTEGER REFERENCES public.teachers(id),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
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

-- Indexes
CREATE INDEX IF NOT EXISTS idx_audiences_name ON public.audiences(name);

-- RLS
ALTER TABLE public.audiences ENABLE ROW LEVEL SECURITY;
CREATE POLICY IF NOT EXISTS "anon_all_audiences"
  ON public.audiences FOR ALL TO anon USING (true) WITH CHECK (true);

-- Optional: grant to authenticated as well
CREATE POLICY IF NOT EXISTS "authenticated_all_audiences"
  ON public.audiences FOR ALL TO authenticated USING (true) WITH CHECK (true);

