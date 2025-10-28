-- Создание таблицы teachers в Supabase (PostgreSQL)
-- По структуре, идентичной локальной SQLite

CREATE TABLE IF NOT EXISTS public.teachers (
  id SERIAL PRIMARY KEY,
  full_name TEXT NOT NULL,
  department_id INTEGER REFERENCES public.departments(id),
  email TEXT,
  phone TEXT,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_teachers_full_name ON teachers(full_name);

ALTER TABLE public.teachers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow anonymous access to teachers" ON public.teachers FOR ALL USING (true);

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_teachers_updated_at
  BEFORE UPDATE ON public.teachers
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Связующая таблица преподаватель-предмет
CREATE TABLE IF NOT EXISTS public.teacher_disciplines (
  id SERIAL PRIMARY KEY,
  teacher_id INTEGER NOT NULL REFERENCES public.teachers(id) ON DELETE CASCADE,
  discipline_id INTEGER NOT NULL REFERENCES public.disciplines(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE (teacher_id, discipline_id)
);

CREATE INDEX IF NOT EXISTS idx_td_teacher ON public.teacher_disciplines(teacher_id);
CREATE INDEX IF NOT EXISTS idx_td_discipline ON public.teacher_disciplines(discipline_id);

ALTER TABLE public.teacher_disciplines ENABLE ROW LEVEL SECURITY;
