-- Создание таблицы lesson_rules в Supabase (PostgreSQL)
-- Схема соответствует локальной SQLite-таблице

CREATE TABLE IF NOT EXISTS lesson_rules (
  id SERIAL PRIMARY KEY,
  lesson_type_id INTEGER NOT NULL REFERENCES lesson_types(id),
  audience_type_id INTEGER NOT NULL REFERENCES audience_types(id),
  allowed BOOLEAN NOT NULL DEFAULT TRUE
);

-- По желанию можно ускорить выборки индексами (раскомментируйте при необходимости)
-- CREATE INDEX IF NOT EXISTS idx_lesson_rules_lesson_type ON lesson_rules(lesson_type_id);
-- CREATE INDEX IF NOT EXISTS idx_lesson_rules_audience_type ON lesson_rules(audience_type_id);

-- При необходимости можно запретить дубликаты сочетаний (раскомментируйте)
-- ALTER TABLE lesson_rules
--   ADD CONSTRAINT uq_lesson_rules_pair UNIQUE (lesson_type_id, audience_type_id);


