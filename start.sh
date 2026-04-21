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

# Ensure sshd runtime dir exists
mkdir -p /var/run/sshd

echo "Starting SSHD..."
/usr/sbin/sshd

echo "Starting PostgreSQL..."
exec /opt/bitnami/scripts/postgresql/entrypoint.sh /opt/bitnami/scripts/postgresql/run.sh
