-- Создание таблицы buildings в Supabase
-- Выполните этот скрипт в SQL Editor Supabase

CREATE TABLE IF NOT EXISTS buildings (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  address TEXT,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Индекс по имени
CREATE INDEX IF NOT EXISTS idx_buildings_name ON buildings(name);

-- Включение RLS
ALTER TABLE buildings ENABLE ROW LEVEL SECURITY;

-- Политика для анонимного доступа (как в departments; ослабленная для демо)
CREATE POLICY "Allow anonymous access to buildings" ON buildings
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
CREATE TRIGGER update_buildings_updated_at
  BEFORE UPDATE ON buildings
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Тестовые данные
INSERT INTO buildings (name, address, description) VALUES
  ('Корпус А', 'ул. Пример, 1', 'Главный корпус'),
  ('Корпус Б', 'ул. Пример, 2', 'Лаборатории'),
  ('Корпус В', 'ул. Пример, 3', 'Спорткомплекс')
ON CONFLICT DO NOTHING;


