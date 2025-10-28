-- Создание таблицы groups в Supabase (PostgreSQL)

CREATE TABLE IF NOT EXISTS public.groups (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  curator_teacher_id INTEGER REFERENCES public.teachers(id),
  student_count INTEGER,
  course INTEGER,
  department_id INTEGER REFERENCES public.departments(id),
  notes TEXT
);

CREATE INDEX IF NOT EXISTS idx_groups_name ON public.groups(name);

ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow anonymous access to groups" ON public.groups FOR ALL USING (true);


