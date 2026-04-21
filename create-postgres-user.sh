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
