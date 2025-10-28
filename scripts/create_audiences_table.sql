-- Создание таблицы audiences в Supabase (PostgreSQL)

CREATE TABLE IF NOT EXISTS public.audiences (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  capacity INTEGER,
  audience_type_id INTEGER REFERENCES public.audience_types(id),
  building_id INTEGER REFERENCES public.buildings(id),
  responsible_teacher_id INTEGER REFERENCES public.teachers(id),
  notes TEXT
);

CREATE INDEX IF NOT EXISTS idx_audiences_name ON public.audiences(name);

ALTER TABLE public.audiences ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow anonymous access to audiences" ON public.audiences FOR ALL USING (true);


