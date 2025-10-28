-- Создание таблицы time_slots в Supabase
-- Выполните этот скрипт в SQL Editor Supabase

CREATE TABLE IF NOT EXISTS time_slots (
  id SERIAL PRIMARY KEY,
  order_number INTEGER NOT NULL,
  start_time TEXT NOT NULL,
  end_time TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Индекс по порядковому номеру
CREATE INDEX IF NOT EXISTS idx_time_slots_order ON time_slots(order_number);

-- Включение RLS
ALTER TABLE time_slots ENABLE ROW LEVEL SECURITY;

-- Политика для анонимного доступа (как в departments; ослабленная для демо)
CREATE POLICY "Allow anonymous access to time_slots" ON time_slots
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
CREATE TRIGGER update_time_slots_updated_at
  BEFORE UPDATE ON time_slots
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Тестовые данные (пример слотов)
INSERT INTO time_slots (order_number, start_time, end_time, description) VALUES
  (1, '08:30', '10:00', '1-я пара'),
  (2, '10:10', '11:40', '2-я пара'),
  (3, '11:50', '13:20', '3-я пара')
ON CONFLICT DO NOTHING;


