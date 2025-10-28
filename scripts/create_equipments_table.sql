-- Создание таблицы equipments в Supabase
-- Выполните этот скрипт в SQL Editor Supabase

CREATE TABLE IF NOT EXISTS equipments (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Индекс по имени
CREATE INDEX IF NOT EXISTS idx_equipments_name ON equipments(name);

-- Включение RLS
ALTER TABLE equipments ENABLE ROW LEVEL SECURITY;

-- Политика для анонимного доступа (как в departments; ослабленная для демо)
CREATE POLICY "Allow anonymous access to equipments" ON equipments
  FOR ALL USING (true);

-- Функция для авто-обновления updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Триггер для авто-обновления updated_at
CREATE TRIGGER update_equipments_updated_at
  BEFORE UPDATE ON equipments
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Тестовые данные
INSERT INTO equipments (name, description) VALUES
  ('Проектор', 'Full HD'),
  ('Компьютер', 'Системный блок и монитор'),
  ('Интерактивная доска', 'С сенсорным вводом')
ON CONFLICT DO NOTHING;


