#!/bin/bash

echo "Starting setup..."

# 2. Setup SSH key login (nếu file tồn tại)
mkdir -p /root/.ssh
chmod 700 /root/.ssh

if [ -f /tmp/id_rsa_pgpool.pub ]; then
    cat /tmp/id_rsa_pgpool.pub >> /root/.ssh/authorized_keys
    echo "SSH key added"
else
    echo "WARNING: /tmp/id_rsa_pgpool.pub not found"
fi

# chown -R bitnami:bitnami /root/.ssh

# 3. đảm bảo sshd runtime dir
mkdir -p /var/run/sshd

echo "Starting SSHD..."
/usr/sbin/sshd

echo "Starting PostgreSQL..."
exec /opt/bitnami/scripts/postgresql/entrypoint.sh /opt/bitnami/scripts/postgresql/run.sh