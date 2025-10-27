-- Создание таблицы departments в Supabase
-- Выполните этот скрипт в SQL Editor Supabase

CREATE TABLE IF NOT EXISTS departments (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Создание индекса для быстрого поиска по имени
CREATE INDEX IF NOT EXISTS idx_departments_name ON departments(name);

-- Включение RLS (Row Level Security)
ALTER TABLE departments ENABLE ROW LEVEL SECURITY;

-- Политика для анонимного доступа (для демонстрации)
-- В продакшене используйте более строгие политики
CREATE POLICY "Allow anonymous access to departments" ON departments
  FOR ALL USING (true);

-- Функция для автоматического обновления updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Триггер для автоматического обновления updated_at
CREATE TRIGGER update_departments_updated_at
  BEFORE UPDATE ON departments
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Вставка тестовых данных
INSERT INTO departments (name) VALUES
  ('Кафедра информатики'),
  ('Кафедра математики'),
  ('Кафедра физики'),
  ('Кафедра экономики')
ON CONFLICT DO NOTHING;
