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