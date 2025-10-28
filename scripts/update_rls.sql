-- Сначала удалим существующие политики
DROP POLICY IF EXISTS "Allow read access for authenticated users" ON audiences;
DROP POLICY IF EXISTS "Allow insert access for authenticated users" ON audiences;
DROP POLICY IF EXISTS "Allow update access for authenticated users" ON audiences;

-- Создаем новые политики с правильными разрешениями
CREATE POLICY "Enable read access for all users" 
ON audiences FOR SELECT 
USING (true);

CREATE POLICY "Enable insert access for all users" 
ON audiences FOR INSERT 
WITH CHECK (true);

CREATE POLICY "Enable update access for all users" 
ON audiences FOR UPDATE 
USING (true)
WITH CHECK (true);

CREATE POLICY "Enable delete access for all users" 
ON audiences FOR DELETE 
USING (true);

-- Включаем RLS и политики для таблицы lesson_rules
ALTER TABLE lesson_rules ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "lr_select_all" ON lesson_rules;
DROP POLICY IF EXISTS "lr_insert_all" ON lesson_rules;
DROP POLICY IF EXISTS "lr_update_all" ON lesson_rules;
DROP POLICY IF EXISTS "lr_delete_all" ON lesson_rules;

CREATE POLICY "lr_select_all" ON lesson_rules FOR SELECT USING (true);
CREATE POLICY "lr_insert_all" ON lesson_rules FOR INSERT WITH CHECK (true);
CREATE POLICY "lr_update_all" ON lesson_rules FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "lr_delete_all" ON lesson_rules FOR DELETE USING (true);

-- Включаем RLS и политики для таблицы equipments
ALTER TABLE equipments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "eq_select_all" ON equipments;
DROP POLICY IF EXISTS "eq_insert_all" ON equipments;
DROP POLICY IF EXISTS "eq_update_all" ON equipments;
DROP POLICY IF EXISTS "eq_delete_all" ON equipments;

CREATE POLICY "eq_select_all" ON equipments FOR SELECT USING (true);
CREATE POLICY "eq_insert_all" ON equipments FOR INSERT WITH CHECK (true);
CREATE POLICY "eq_update_all" ON equipments FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "eq_delete_all" ON equipments FOR DELETE USING (true);

-- Включаем RLS и политики для таблицы buildings
ALTER TABLE buildings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "bd_select_all" ON buildings;
DROP POLICY IF EXISTS "bd_insert_all" ON buildings;
DROP POLICY IF EXISTS "bd_update_all" ON buildings;
DROP POLICY IF EXISTS "bd_delete_all" ON buildings;

CREATE POLICY "bd_select_all" ON buildings FOR SELECT USING (true);
CREATE POLICY "bd_insert_all" ON buildings FOR INSERT WITH CHECK (true);
CREATE POLICY "bd_update_all" ON buildings FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "bd_delete_all" ON buildings FOR DELETE USING (true);

-- Включаем RLS и политики для таблицы time_slots
ALTER TABLE time_slots ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "ts_select_all" ON time_slots;
DROP POLICY IF EXISTS "ts_insert_all" ON time_slots;
DROP POLICY IF EXISTS "ts_update_all" ON time_slots;
DROP POLICY IF EXISTS "ts_delete_all" ON time_slots;

CREATE POLICY "ts_select_all" ON time_slots FOR SELECT USING (true);
CREATE POLICY "ts_insert_all" ON time_slots FOR INSERT WITH CHECK (true);
CREATE POLICY "ts_update_all" ON time_slots FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "ts_delete_all" ON time_slots FOR DELETE USING (true);

-- Включаем RLS и политики для таблицы teachers
ALTER TABLE teachers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "tc_select_all" ON teachers;
DROP POLICY IF EXISTS "tc_insert_all" ON teachers;
DROP POLICY IF EXISTS "tc_update_all" ON teachers;
DROP POLICY IF EXISTS "tc_delete_all" ON teachers;

CREATE POLICY "tc_select_all" ON teachers FOR SELECT USING (true);
CREATE POLICY "tc_insert_all" ON teachers FOR INSERT WITH CHECK (true);
CREATE POLICY "tc_update_all" ON teachers FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "tc_delete_all" ON teachers FOR DELETE USING (true);

-- Включаем RLS и политики для таблицы disciplines
ALTER TABLE disciplines ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "ds_select_all" ON disciplines;
DROP POLICY IF EXISTS "ds_insert_all" ON disciplines;
DROP POLICY IF EXISTS "ds_update_all" ON disciplines;
DROP POLICY IF EXISTS "ds_delete_all" ON disciplines;

CREATE POLICY "ds_select_all" ON disciplines FOR SELECT USING (true);
CREATE POLICY "ds_insert_all" ON disciplines FOR INSERT WITH CHECK (true);
CREATE POLICY "ds_update_all" ON disciplines FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "ds_delete_all" ON disciplines FOR DELETE USING (true);

-- Включаем RLS и политики для таблицы groups
ALTER TABLE groups ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "gr_select_all" ON groups;
DROP POLICY IF EXISTS "gr_insert_all" ON groups;
DROP POLICY IF EXISTS "gr_update_all" ON groups;
DROP POLICY IF EXISTS "gr_delete_all" ON groups;

CREATE POLICY "gr_select_all" ON groups FOR SELECT USING (true);
CREATE POLICY "gr_insert_all" ON groups FOR INSERT WITH CHECK (true);
CREATE POLICY "gr_update_all" ON groups FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "gr_delete_all" ON groups FOR DELETE USING (true);

-- Включаем RLS и политики для таблицы audience_types
ALTER TABLE audience_types ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "at_select_all" ON audience_types;
DROP POLICY IF EXISTS "at_insert_all" ON audience_types;
DROP POLICY IF EXISTS "at_update_all" ON audience_types;
DROP POLICY IF EXISTS "at_delete_all" ON audience_types;

CREATE POLICY "at_select_all" ON audience_types FOR SELECT USING (true);
CREATE POLICY "at_insert_all" ON audience_types FOR INSERT WITH CHECK (true);
CREATE POLICY "at_update_all" ON audience_types FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "at_delete_all" ON audience_types FOR DELETE USING (true);

-- Включаем RLS и политики для таблицы audience_equipments
ALTER TABLE audience_equipments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "ae_select_all" ON audience_equipments;
DROP POLICY IF EXISTS "ae_insert_all" ON audience_equipments;
DROP POLICY IF EXISTS "ae_update_all" ON audience_equipments;
DROP POLICY IF EXISTS "ae_delete_all" ON audience_equipments;

CREATE POLICY "ae_select_all" ON audience_equipments FOR SELECT USING (true);
CREATE POLICY "ae_insert_all" ON audience_equipments FOR INSERT WITH CHECK (true);
CREATE POLICY "ae_update_all" ON audience_equipments FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "ae_delete_all" ON audience_equipments FOR DELETE USING (true);

-- Включаем RLS и политики для таблицы lesson_types
ALTER TABLE lesson_types ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "lt_select_all" ON lesson_types;
DROP POLICY IF EXISTS "lt_insert_all" ON lesson_types;
DROP POLICY IF EXISTS "lt_update_all" ON lesson_types;
DROP POLICY IF EXISTS "lt_delete_all" ON lesson_types;

CREATE POLICY "lt_select_all" ON lesson_types FOR SELECT USING (true);
CREATE POLICY "lt_insert_all" ON lesson_types FOR INSERT WITH CHECK (true);
CREATE POLICY "lt_update_all" ON lesson_types FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "lt_delete_all" ON lesson_types FOR DELETE USING (true);

-- Включаем RLS и политики для таблицы group_subject_teachers
ALTER TABLE group_subject_teachers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "gst_select_all" ON group_subject_teachers;
DROP POLICY IF EXISTS "gst_insert_all" ON group_subject_teachers;
DROP POLICY IF EXISTS "gst_update_all" ON group_subject_teachers;
DROP POLICY IF EXISTS "gst_delete_all" ON group_subject_teachers;

CREATE POLICY "gst_select_all" ON group_subject_teachers FOR SELECT USING (true);
CREATE POLICY "gst_insert_all" ON group_subject_teachers FOR INSERT WITH CHECK (true);
CREATE POLICY "gst_update_all" ON group_subject_teachers FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "gst_delete_all" ON group_subject_teachers FOR DELETE USING (true);

-- Включаем RLS и политики для таблицы departments
ALTER TABLE departments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "dp_select_all" ON departments;
DROP POLICY IF EXISTS "dp_insert_all" ON departments;
DROP POLICY IF EXISTS "dp_update_all" ON departments;
DROP POLICY IF EXISTS "dp_delete_all" ON departments;

CREATE POLICY "dp_select_all" ON departments FOR SELECT USING (true);
CREATE POLICY "dp_insert_all" ON departments FOR INSERT WITH CHECK (true);
CREATE POLICY "dp_update_all" ON departments FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "dp_delete_all" ON departments FOR DELETE USING (true);

-- Включаем RLS и политики для таблицы teacher_disciplines (связь многие-ко-многим)
ALTER TABLE teacher_disciplines ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "td_select_all" ON teacher_disciplines;
DROP POLICY IF EXISTS "td_insert_all" ON teacher_disciplines;
DROP POLICY IF EXISTS "td_update_all" ON teacher_disciplines;
DROP POLICY IF EXISTS "td_delete_all" ON teacher_disciplines;

CREATE POLICY "td_select_all" ON teacher_disciplines FOR SELECT USING (true);
CREATE POLICY "td_insert_all" ON teacher_disciplines FOR INSERT WITH CHECK (true);
CREATE POLICY "td_update_all" ON teacher_disciplines FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "td_delete_all" ON teacher_disciplines FOR DELETE USING (true);