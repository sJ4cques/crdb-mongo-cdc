# crdb-mongo-cdc

Laboratorio que levanta CockroachDB, PostgreSQL, Redpanda (Kafka) y un
worker de Kafka Connect con los conectores JDBC para poder replicar filas
entre ambas bases relacionales.

## Servicios principales

* **CockroachDB** – Se levanta en modo inseguro para simplificar las pruebas
  locales. El puerto SQL expuesto en el host es `26259` (se mapea al `26258`
  interno del contenedor) y la consola web queda disponible en `8088`.
* **PostgreSQL** – Base de datos de ejemplo con usuario/contraseña `app`.
* **Redpanda** – Broker Kafka y su consola web (`localhost:8081`).
* **Kafka Connect** – Imagen basada en `cp-kafka-connect:7.6.1` con el
  conector JDBC de Confluent instalado.

## Inicialización de los esquemas

Al levantar `docker compose up -d` se ejecutan dos scripts:

* [`sql/postgres-init.sql`](sql/postgres-init.sql) crea la tabla `public.orders`
  en PostgreSQL y añade un trigger para actualizar los campos
  `updated_at` y `origin` en cada `INSERT`/`UPDATE`.
* [`sql/crdb-init.sql`](sql/crdb-init.sql) crea la base `app` en CockroachDB,
  la tabla `orders` y declara `updated_at` con `ON UPDATE now()` para que
  los conectores JDBC puedan detectar modificaciones sin tener que tocar
  manualmente la columna.

> **Nota:** Antes existía una línea espuria (`docker compose ps`) en el script
> de Cockroach que interrumpía la ejecución con un error de sintaxis. Se ha
> eliminado y aprovechamos para asegurarnos de que `updated_at` se
> actualice automáticamente.

## Conectores JDBC

Los archivos del directorio [`connectors/`](connectors/) se pueden registrar
mediante la API REST de Kafka Connect.

Ejemplo para registrar los conectores necesarios para replicar en ambos
sentidos entre CockroachDB y PostgreSQL:

```bash
# Fuente: PostgreSQL -> tópico pg_public.orders
curl -s -X PUT \
  -H 'Content-Type: application/json' \
  --data @connectors/source-pg-jdbc.json \
  http://localhost:8083/connectors/source-pg-jdbc/config

# Sink: CockroachDB <- tópico pg_public.orders
curl -s -X POST \
  -H 'Content-Type: application/json' \
  --data @connectors/sink-crdb-from-pg.json \
  http://localhost:8083/connectors

# Fuente: CockroachDB -> tópico crdb_orders
curl -s -X PUT \
  -H 'Content-Type: application/json' \
  --data @connectors/source-crdb-jdbc.json \
  http://localhost:8083/connectors/source-crdb-jdbc/config

# Sink: PostgreSQL <- tópico crdb_orders
curl -s -X POST \
  -H 'Content-Type: application/json' \
  --data @connectors/sink-pg-from-crdb.json \
  http://localhost:8083/connectors
```

Ambos conectores `source` leen las tablas usando el modo `timestamp`. Por
eso es imprescindible que los `UPDATE` de las aplicaciones incrementen la
columna `updated_at`. En PostgreSQL lo maneja el trigger y en CockroachDB el
`ON UPDATE now()` añadido en el script de inicialización.

## Verificación rápida

1. Insertar datos en PostgreSQL:
   ```sql
   INSERT INTO orders (customer, total) VALUES ('Alice', 100);
   ```
2. Insertar datos en CockroachDB:
   ```sql
   INSERT INTO orders (customer, total) VALUES ('Bob', 125);
   ```
3. Confirmar que ambos registros aparecen en la base opuesta tras unos
   segundos. Si no se ven cambios, revisar los logs de los conectores y
   comprobar que los tópicos `pg_public.orders` y `crdb_orders` reciben
   eventos.

## Limitaciones

* Los conectores JDBC no propagan eliminaciones (`delete.enabled=false`).
* Las transformaciones adicionales (por ejemplo, normalizar tipos numéricos)
  deben configurarse según las necesidades de cada proyecto.
