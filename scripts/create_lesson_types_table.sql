-- Создание таблицы lesson_types в Supabase
-- Выполните этот скрипт в SQL Editor Supabase

CREATE TABLE IF NOT EXISTS lesson_types (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Создание индекса для быстрого поиска по имени
CREATE INDEX IF NOT EXISTS idx_lesson_types_name ON lesson_types(name);

-- Включение RLS (Row Level Security)
ALTER TABLE lesson_types ENABLE ROW LEVEL SECURITY;

-- Политика для анонимного доступа (для демонстрации)
-- В продакшене используйте более строгие политики
CREATE POLICY "Allow anonymous access to lesson_types" ON lesson_types
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
CREATE TRIGGER update_lesson_types_updated_at
  BEFORE UPDATE ON lesson_types
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Вставка тестовых данных
INSERT INTO lesson_types (name, description) VALUES
  ('Лекция', 'Теоретическое занятие'),
  ('Семинар', 'Практическое занятие с обсуждением'),
  ('Лабораторная работа', 'Практическое занятие в лаборатории'),
  ('Практическое занятие', 'Практическое занятие по предмету'),
  ('Консультация', 'Индивидуальная консультация'),
  ('Экзамен', 'Итоговая проверка знаний'),
  ('Зачет', 'Промежуточная проверка знаний')
ON CONFLICT DO NOTHING;
