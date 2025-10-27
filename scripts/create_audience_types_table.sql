-- Создание таблицы audience_types в Supabase
-- Выполните этот скрипт в SQL Editor Supabase

CREATE TABLE IF NOT EXISTS audience_types (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Создание индекса для быстрого поиска по имени
CREATE INDEX IF NOT EXISTS idx_audience_types_name ON audience_types(name);

-- Включение RLS (Row Level Security)
ALTER TABLE audience_types ENABLE ROW LEVEL SECURITY;

-- Политика для анонимного доступа (для демонстрации)
-- В продакшене используйте более строгие политики
CREATE POLICY "Allow anonymous access to audience_types" ON audience_types
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
CREATE TRIGGER update_audience_types_updated_at
  BEFORE UPDATE ON audience_types
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Вставка тестовых данных
INSERT INTO audience_types (name, description) VALUES
  ('Лекционная', 'Аудитория для проведения лекций'),
  ('Семинарская', 'Аудитория для проведения семинаров'),
  ('Лабораторная', 'Аудитория для проведения лабораторных работ'),
  ('Компьютерная', 'Аудитория с компьютерами'),
  ('Спортивная', 'Спортивный зал')
ON CONFLICT DO NOTHING;
