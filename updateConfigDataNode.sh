#!/usr/bin/env bash

echo "Updating postgresql.conf to multinode data node configuration.."
cat <<'EOF' >> "${PGDATA}/postgresql.conf"

# Multinode configurations
max_connections = 100
max_prepared_transactions = 150
# This is rather small, but as this Helm Chart may be used to spin up
# 1 access node and 4 data nodes on a single minikube/microk8s this is set
# to a conservative value
shared_buffers = 300MB
work_mem = 16MB
timescaledb.passfile = '../.pgpass'
log_connections = 'on'
log_line_prefix = '%t [%p]: [%c-%l] %u@%d,app=%a [%e] '
log_min_duration_statement = '1s'
log_statement = ddl
log_checkpoints = 'on'
log_lock_waits = 'on'
# These values are set as the default data volume size
# is small as well.
min_wal_size = 256MB
max_wal_size = 512MB
temp_file_limit = 1GB
EOF

echo "Check if Access node is UP"
READY=$((pg_isready -q -h ${POSTGRES_HOST_ACCESS_NODE} && echo OK) || echo FAIL)
while [ "$READY" !=  "OK" ];
do sleep 5;
echo "Waiting for ACCESS NODE is UP and RESPONDING";
READY=$((pg_isready -q -h ${POSTGRES_HOST_ACCESS_NODE} && echo OK) || echo FAIL)
done

echo "Add this node to the cluster"
echo "SELECT add_data_node('${HOSTNAME}', host => '${HOSTNAME}');" > /tmp/addNode.sql
psql "user='${POSTGRES_USER}' password='${POSTGRES_PASSWORD_ACCESS_NODE}' host='${POSTGRES_HOST_ACCESS_NODE}' dbname='${POSTGRES_DB_ACCESS_NODE}'" -f /tmp/addNode.sql