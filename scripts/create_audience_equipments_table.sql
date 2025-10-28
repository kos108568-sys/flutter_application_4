-- Создание таблицы audience_equipments в Supabase (PostgreSQL)

CREATE TABLE IF NOT EXISTS public.audience_equipments (
  id SERIAL PRIMARY KEY,
  audience_id INTEGER NOT NULL REFERENCES public.audiences(id) ON DELETE CASCADE,
  equipment_id INTEGER NOT NULL REFERENCES public.equipments(id) ON DELETE CASCADE,
  UNIQUE (audience_id, equipment_id)
);

CREATE INDEX IF NOT EXISTS idx_aud_eq_audience ON public.audience_equipments(audience_id);
CREATE INDEX IF NOT EXISTS idx_aud_eq_equipment ON public.audience_equipments(equipment_id);

ALTER TABLE public.audience_equipments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow anonymous access to audience_equipments" ON public.audience_equipments FOR ALL USING (true);


