#!/bin/bash
set -e

mkdir -p /home/postgres/.ssh
chmod 700 /home/postgres/.ssh

if [ -f /root/.ssh/id_rsa_pgpool ]; then
    chown postgres:postgres /home/postgres/.ssh/id_rsa_pgpool
    chmod 600 /home/postgres/.ssh/id_rsa_pgpool
fi


# xu ly pgpass; postgresql client authentication
# ==============================
# CONFIG
# ==============================
PGPASS_FILE=/home/postgres/.pgpass
POSTGRES_PASSWORD="1234"
REPL_PASSWORD="repl_pass"

# 81dc9bdb52d04dc20036dbd8313ed055 = 1234
echo "pgpool:81dc9bdb52d04dc20036dbd8313ed055" >> /opt/bitnami/pgpool/etc/pcp.conf

chmod 0600 /opt/bitnami/pgpool/etc/pcp.conf

echo 'localhost:9898:pgpool:1234' > /home/postgres/.pcppass

chmod 0600 /home/postgres/.pcppass

# ==============================
# CREATE .pgpass
# ==============================
cat > ${PGPASS_FILE} <<EOF
# format: hostname:port:database:username:password

# replication user
pg-master:5432:replication:repl:${REPL_PASSWORD}
pg-slave:5432:replication:repl:${REPL_PASSWORD}
pg-slave-1:5432:replication:repl:${REPL_PASSWORD}
pgpool:5432:replication:repl:${REPL_PASSWORD}

# postgres user
pg-master:5432:postgres:postgres:${POSTGRES_PASSWORD}
pg-slave:5432:postgres:postgres:${POSTGRES_PASSWORD}
pg-slave-1:5432:postgres:postgres:${POSTGRES_PASSWORD}
pgpool:9999:postgres:postgres:${POSTGRES_PASSWORD}
EOF

echo "Created ${PGPASS_FILE}"

# ==============================
# SET PERMISSION
# ==============================
chown postgres:postgres ${PGPASS_FILE}
chmod 600 ${PGPASS_FILE}
echo "Permission set to 600"


exec /opt/bitnami/scripts/pgpool/entrypoint.sh /opt/bitnami/scripts/pgpool/run.sh
