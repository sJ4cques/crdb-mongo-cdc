-- Inicialización de PostgreSQL
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS public.orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer TEXT NOT NULL,
  total NUMERIC(18,2) NOT NULL DEFAULT 0.00,
  origin TEXT NOT NULL DEFAULT 'pg',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Trigger para updated_at y origin
CREATE OR REPLACE FUNCTION set_updated_at_and_origin()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at := now();
  NEW.origin := COALESCE(NEW.origin, 'pg');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_set_updated_at_and_origin ON public.orders;
CREATE TRIGGER trg_set_updated_at_and_origin
BEFORE INSERT OR UPDATE ON public.orders
FOR EACH ROW EXECUTE FUNCTION set_updated_at_and_origin();

CREATE INDEX IF NOT EXISTS idx_orders_updated_at ON public.orders(updated_at);
