-- Создание таблицы group_subject_teachers в Supabase (PostgreSQL)

CREATE TABLE IF NOT EXISTS public.group_subject_teachers (
  id SERIAL PRIMARY KEY,
  group_id INTEGER NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
  teacher_id INTEGER NOT NULL REFERENCES public.teachers(id) ON DELETE CASCADE,
  discipline_id INTEGER NOT NULL REFERENCES public.disciplines(id) ON DELETE CASCADE,
  total_hours INTEGER NOT NULL,
  start_date DATE,
  end_date DATE,
  notes TEXT,
  UNIQUE (group_id, teacher_id, discipline_id)
);

CREATE INDEX IF NOT EXISTS idx_gst_group ON public.group_subject_teachers(group_id);
CREATE INDEX IF NOT EXISTS idx_gst_teacher ON public.group_subject_teachers(teacher_id);
CREATE INDEX IF NOT EXISTS idx_gst_discipline ON public.group_subject_teachers(discipline_id);

ALTER TABLE public.group_subject_teachers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow anonymous access to group_subject_teachers" ON public.group_subject_teachers FOR ALL USING (true);


