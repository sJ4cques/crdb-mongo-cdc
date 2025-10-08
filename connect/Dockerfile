FROM confluentinc/cp-kafka-connect:7.6.1

# Debezium MongoDB Source
RUN confluent-hub install --no-prompt debezium/debezium-connector-mongodb:3.1.2

# JDBC Sink (para escribir en Cockroach vía JDBC/PostgreSQL)
RUN confluent-hub install --no-prompt confluentinc/kafka-connect-jdbc:10.7.4

# MongoDB Sink (para upsert en colecciones)
RUN confluent-hub install --no-prompt mongodb/kafka-connect-mongodb:1.12.0

