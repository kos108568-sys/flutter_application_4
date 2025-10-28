-- Создание таблицы disciplines в Supabase (PostgreSQL)
-- Структура синхронизирована с локальной SQLite

CREATE TABLE IF NOT EXISTS public.disciplines (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  lesson_type_id INTEGER REFERENCES public.lesson_types(id),
  semester TEXT
);

CREATE INDEX IF NOT EXISTS idx_disciplines_name ON public.disciplines(name);

ALTER TABLE public.disciplines ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow anonymous access to disciplines" ON public.disciplines FOR ALL USING (true);


