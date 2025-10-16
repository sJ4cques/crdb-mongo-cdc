-- Inicialización de CockroachDB
CREATE DATABASE IF NOT EXISTS app;
USE app;

CREATE TABLE IF NOT EXISTS orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer STRING NOT NULL,
  total DECIMAL(18,2) NOT NULL DEFAULT 0.00,
  origin STRING NOT NULL DEFAULT 'crdb',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_orders_updated_at ON orders(updated_at);
docker compose ps
