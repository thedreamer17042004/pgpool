#!/bin/bash

echo "Starting setup..."

# Create postgres group/user if not exists
if ! getent group postgres >/dev/null 2>&1; then
    groupadd -g 1001 postgres
fi

if ! id postgres >/dev/null 2>&1; then
    useradd -u 1001 -g 1001 -m -d /home/postgres -s /bin/bash postgres
fi


# Setup SSH for root
mkdir -p /root/.ssh
chmod 700 /root/.ssh

# Setup SSH for postgres user
mkdir -p /home/postgres/.ssh
chmod 700 /home/postgres/.ssh
chown -R postgres:postgres /home/postgres/.ssh

if [ -f /tmp/id_rsa_pgpool.pub ]; then
    cat /tmp/id_rsa_pgpool.pub >> /root/.ssh/authorized_keys
    chmod 600 /root/.ssh/authorized_keys

    cat /tmp/id_rsa_pgpool.pub >> /home/postgres/.ssh/authorized_keys
    chmod 600 /home/postgres/.ssh/authorized_keys
    chown postgres:postgres /home/postgres/.ssh/authorized_keys

    echo "SSH key added for root and postgres"
else
    echo "WARNING: /tmp/id_rsa_pgpool.pub not found"
fi

touch /opt/bitnami/postgresql/conf/conf.d/demo.conf
chmod 600 /opt/bitnami/postgresql/conf/conf.d/demo.conf
chown postgres:postgres /opt/bitnami/postgresql/conf/conf.d/demo.conf

# pcp 
# echo 'localhost:9898:pgpool:1234' > /home/postgres/.pcppass
# chmod 600 /home/postgres/.pcppass

# echo 'localhost:9898:pgpool:1234' > /root/.pcppass
# chmod 600 /root/.pcppass

# Ensure sshd runtime dir exists
mkdir -p /var/run/sshd

echo "Starting SSHD..."
/usr/sbin/sshd

# if ! grep -q "^wal_log_hints *= *on" /bitnami/postgresql/data/postgresql.conf 2>/dev/null; then
#     echo "wal_log_hints = on" >> /bitnami/postgresql/data/postgresql.conf
#     echo "Added wal_log_hints = on"
# else
#     echo "wal_log_hints already enabled"
# fi
# tao replication user

echo "Starting PostgreSQL..."
/opt/bitnami/scripts/postgresql/entrypoint.sh /opt/bitnami/scripts/postgresql/run.sh &

echo "host replication repl_user 172.22.0.0/16 md5" >> /opt/bitnami/postgresql/conf/pg_hba.conf

echo "Container is alive"

tail -f /dev/null