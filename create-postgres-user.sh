#!/bin/bash
#!/bin/bash

set -e

mkdir -p /home/postgres/.ssh
chmod 700 /home/postgres/.ssh

if [ -f /root/.ssh/id_rsa_pgpool ]; then
    # cp /root/.ssh/id_rsa_pgpool /home/postgres/.ssh/id_rsa_pgpool
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


# set -e

# if ! getent group postgres >/dev/null 2>&1; then
#     groupadd -g 1001 postgres
# fi

# if ! id postgres >/dev/null 2>&1; then
#     useradd -u 1001 -g 1001 -m -d /home/postgres -s /bin/bash postgres
# fi

# mkdir -p /home/postgres/.ssh

# if [ -f /root/.ssh/id_rsa_pgpool ]; then
#     cp /root/.ssh/id_rsa_pgpool /home/postgres/.ssh/id_rsa_pgpool
#     chmod 600 /home/postgres/.ssh/id_rsa_pgpool
# fi

# chown -R postgres:postgres /home/postgres
# chmod 700 /home/postgres/.ssh

# # thêm đoạn này
# chown -R postgres:postgres /opt/bitnami/pgpool
# chmod -R u+w /opt/bitnami/pgpool/conf

# exec su - postgres -c "/opt/bitnami/scripts/pgpool/run.sh"
