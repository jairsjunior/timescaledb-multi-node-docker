#!/usr/bin/env bash

echo "Updating postgresql.conf to multinode access node configuration.."
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

echo "Create .pgpass file to add datanode user and pass credentials.."
echo "*:*:*:${POSTGRES_USER}:${POSTGRES_PASSWORD_DATA_NODE}" > "${PGDATA}/../.pgpass"
chown postgres:postgres "${PGDATA}/../.pgpass"
chmod 0600 "${PGDATA}/../.pgpass"

pg_ctl reload
