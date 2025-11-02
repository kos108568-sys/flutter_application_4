-- Создание таблицы audiences в Supabase (PostgreSQL)

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
  UNIQUE (audience_id, lesson_type_id)
);

CREATE INDEX IF NOT EXISTS idx_audiences_name ON public.audiences(name);
CREATE INDEX IF NOT EXISTS idx_audience_lesson_types_audience ON public.audience_lesson_types(audience_id);

ALTER TABLE public.audiences ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow anonymous access to audiences" ON public.audiences FOR ALL USING (true);

ALTER TABLE public.audience_lesson_types ENABLE ROW LEVEL SECURITY;
CREATE POLICY IF NOT EXISTS "Allow anonymous access to audience_lesson_types"
  ON public.audience_lesson_types FOR ALL USING (true);


