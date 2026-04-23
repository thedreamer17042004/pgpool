#!/bin/bash
# This script is run after failover_command to synchronize the Standby with the new Primary.
# SSH vào standby
#     ↓
# stop postgres
#     ↓
# pg_rewind (sync với primary mới)
#     ↓
# xóa slot cũ
#     ↓
# tạo config replication
#     ↓
# enable standby mode
#     ↓
# start postgres
set -o xtrace

# Special values:
# 1)  %d = node id
# 2)  %h = hostname
# 3)  %p = port number
# 4)  %D = node database cluster path
# 5)  %m = new primary node id
# 6)  %H = new primary node hostname
# 7)  %M = old main node id
# 8)  %P = old primary node id
# 9)  %r = new primary port number
# 10) %R = new primary database cluster path
# 11) %N = old primary node hostname
# 12) %S = old primary node port number
# 13) %% = '%' character

NODE_ID="$1"
NODE_HOST="$2"
NODE_PORT="$3"
NODE_PGDATA="$4"
NEW_PRIMARY_NODE_ID="$5"
NEW_PRIMARY_NODE_HOST="$6"
OLD_MAIN_NODE_ID="$7"
OLD_PRIMARY_NODE_ID="$8"
NEW_PRIMARY_NODE_PORT="$9"
NEW_PRIMARY_NODE_PGDATA="${10}"

PGHOME=/opt/bitnami/postgresql
REPLUSER=repl_user
PCP_USER=pgpool
PGPOOL_PATH=/opt/bitnami/pgpool/bin
PCP_PORT=9898
REPL_SLOT_NAME=$(echo ${NODE_HOST,,} | tr -- -. _)
POSTGRESQL_STARTUP_USER=postgres
SSH_KEY_FILE=id_rsa_pgpool
SSH_OPTIONS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i /home/postgres/.ssh/${SSH_KEY_FILE}"

echo follow_primary.sh: start: Standby node ${NODE_ID}

# Check the connection status of Standby
# ${PGHOME}/bin/pg_isready -h ${NODE_HOST} -p ${NODE_PORT} > /dev/null 2>&1
# psql -h pg-master -p 5432 -U postgres -c "SELECT 1" 
export PGPASSFILE=/home/postgres/.pgpass
psql -h ${NODE_HOST} -p ${NODE_PORT} -U ${POSTGRESQL_STARTUP_USER} -c "SELECT 1" > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo follow_primary.sh: node_id=${NODE_ID} is not running. skipping follow primary command
    exit 0
fi

# Test passwordless SSH
ssh -T ${SSH_OPTIONS} ${POSTGRESQL_STARTUP_USER}@${NEW_PRIMARY_NODE_HOST} ls /tmp > /dev/null

if [ $? -ne 0 ]; then
    echo follow_main.sh: passwordless SSH to ${POSTGRESQL_STARTUP_USER}@${NEW_PRIMARY_NODE_HOST} failed. Please setup passwordless SSH.
    exit 1
fi

# Get PostgreSQL major version
PGVERSION=`${PGHOME}/bin/psql -V | awk '{print $3}' | sed 's/\..*//' | sed 's/\([0-9]*\)[a-zA-Z].*/\1/'`
# psql -V
# → 17.2
# → awk → 17.2
# → sed  → 17
# → sed  → 17
if [ $PGVERSION -ge 12 ]; then
    RECOVERYCONF=${NODE_PGDATA}/myrecovery.conf
else
    RECOVERYCONF=${NODE_PGDATA}/recovery.conf
fi

# Synchronize Standby with the new Primary.
echo follow_primary.sh: pg_rewind for node ${NODE_ID}

# # Run checkpoint command to update control file before running pg_rewind
# ${PGHOME}/bin/psql -h ${NEW_PRIMARY_NODE_HOST} -p ${NEW_PRIMARY_NODE_PORT} postgres -c "checkpoint;"

# # Create replication slot "${REPL_SLOT_NAME}"
# ${PGHOME}/bin/psql -h ${NEW_PRIMARY_NODE_HOST} -p ${NEW_PRIMARY_NODE_PORT} postgres \
#     -c "SELECT pg_create_physical_replication_slot('${REPL_SLOT_NAME}');"  >/dev/null 2>&1

# if [ $? -ne 0 ]; then
#     echo follow_primary.sh: create replication slot \"${REPL_SLOT_NAME}\" failed. You may need to create replication slot manually.
# fi
# ==============================
# WAIT UNTIL NEW PRIMARY READY
# ==============================
echo "Waiting for new primary ${NEW_PRIMARY_NODE_HOST}..."

until ${PGHOME}/bin/psql -h ${NEW_PRIMARY_NODE_HOST} -p ${NEW_PRIMARY_NODE_PORT} -U ${POSTGRESQL_STARTUP_USER} -d postgres -c "SELECT 1" > /dev/null 2>&1
do
  sleep 2
done

echo "New primary is ready"

# ==============================
# CHECK IF NODE IS REALLY PRIMARY
# ==============================
IS_PRIMARY=$(${PGHOME}/bin/psql -h ${NEW_PRIMARY_NODE_HOST} -p ${NEW_PRIMARY_NODE_PORT} -U ${POSTGRESQL_STARTUP_USER} -d postgres -t -c "SELECT pg_is_in_recovery();" | xargs)

if [ "$IS_PRIMARY" != "f" ]; then
    echo "ERROR: Node ${NEW_PRIMARY_NODE_HOST} is still in recovery. Skip follow_primary."
    exit 1
fi

echo "Confirmed new primary"

# ==============================
# RUN CHECKPOINT
# ==============================
echo "Running CHECKPOINT on new primary..."

${PGHOME}/bin/psql -h ${NEW_PRIMARY_NODE_HOST} -p ${NEW_PRIMARY_NODE_PORT} -U ${POSTGRESQL_STARTUP_USER} -d postgres -c "CHECKPOINT;"

if [ $? -ne 0 ]; then
    echo "ERROR: CHECKPOINT failed"
    exit 1
fi

# ==============================
# CREATE REPLICATION SLOT
# ==============================
echo "Creating replication slot: ${REPL_SLOT_NAME}"

${PGHOME}/bin/psql -h ${NEW_PRIMARY_NODE_HOST} -p ${NEW_PRIMARY_NODE_PORT} -U ${POSTGRESQL_STARTUP_USER} -d postgres \
    -c "SELECT pg_create_physical_replication_slot('${REPL_SLOT_NAME}');" > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "WARNING: create replication slot failed. It may already exist or need manual check."
else
    echo "Replication slot created successfully"
fi
# set -o errexit la neu 1 lenh fail thi toan bo dung luon
# ${PGHOME}/bin/pg_ctl -w -m f -D ${NODE_PGDATA} stop stop postgres;-w la wait; -m f fast shutdown; -D data directory
# primary info --> la thong tin connect toi primary moi;

# sed -i -e \"\\\$ainclude_if_exists = '$(echo ${RECOVERYCONF} | sed -e 's/\//\\\//g')'\" \
#                -e \"/^include_if_exists = '$(echo ${RECOVERYCONF} | sed -e 's/\//\\\//g')'/d\" ${NODE_PGDATA}/postgresql.conf
# Xóa dòng include_if_exists = '...' cũ (nếu có)
# Thêm lại dòng include_if_exists = '...' mới vào cuối file postgresql.conf
# sed -e 's/\//\\\//g')'\"; Escape dấu / → vì sed dùng / làm delimiter ;vd:/data/recovery.conf → \/data\/recovery.conf de tranh loi bash
# >/dev/null(output) 2>&1(error) ném toàn bộ output + error vào thùng rác
# passfile=''/var/lib/pgsql/.pgpass''
    # ${PGHOME}/bin/pg_ctl -w -m smart -D ${NODE_PGDATA} stop
# ssh -T ${SSH_OPTIONS} ${POSTGRESQL_STARTUP_USER}@${NODE_HOST} "

#     set -o errexit


#     PG_PID=$(head -1 /bitnami/postgresql/data/postmaster.pid 2>/dev/null || echo "")
#     if [ -n "$PG_PID" ]; then
#         kill -SIGINT $PG_PID 2>/dev/null || true
#         # Chờ postgres dừng hẳn (tối đa 30s)
#         for i in $(seq 1 30);
#         do
#             [ -f "/bitnami/postgresql/data/postmaster.pid" ] || break
#             sleep 1
#         done
#     fi

#     ${PGHOME}/bin/pg_rewind -P -D ${NODE_PGDATA} --source-server=\"user=${POSTGRESQL_STARTUP_USER} host=${NEW_PRIMARY_NODE_HOST} port=${NEW_PRIMARY_NODE_PORT} dbname=postgres\"

#     [ -d \"${NODE_PGDATA}\" ] && rm -rf ${NODE_PGDATA}/pg_replslot/*

#     cat > ${RECOVERYCONF} << EOT
# primary_conninfo = 'host=${NEW_PRIMARY_NODE_HOST} port=${NEW_PRIMARY_NODE_PORT} user=${REPLUSER} application_name=${NODE_HOST} '
# recovery_target_timeline = 'latest'
# primary_slot_name = '${REPL_SLOT_NAME}'
# EOT

#     if [ ${PGVERSION} -ge 12 ]; then
#         sed -i -e \"\\\$ainclude_if_exists = '$(echo ${RECOVERYCONF} | sed -e 's/\//\\\//g')'\" \
#                -e \"/^include_if_exists = '$(echo ${RECOVERYCONF} | sed -e 's/\//\\\//g')'/d\" ${NODE_PGDATA}/postgresql.conf
#         touch ${NODE_PGDATA}/standby.signal
#     else
#         echo \"standby_mode = 'on'\" >> ${RECOVERYCONF}
#     fi

#     ${PGHOME}/bin/pg_ctl -l /dev/null -w -D ${NODE_PGDATA} start

# "

ssh -T ${SSH_OPTIONS} ${POSTGRESQL_STARTUP_USER}@${NODE_HOST} 'bash -s' <<EOF
set -e

PGDATA="${NODE_PGDATA}"
PGHOME="${PGHOME}"
RECOVERYCONF="${RECOVERYCONF}"


   ${PGHOME}/bin/pg_ctl -w -m f -D ${NODE_PGDATA} stop

export PGPASSWORD="1234"
# pg_rewind

\$PGHOME/bin/pg_rewind -P -D "\$PGDATA" \
  --source-server="user=${POSTGRESQL_STARTUP_USER} host=${NEW_PRIMARY_NODE_HOST} port=${NEW_PRIMARY_NODE_PORT} dbname=postgres"

rm -rf "\$PGDATA/pg_replslot/"*

cat > "\$RECOVERYCONF" <<EOT
primary_conninfo = 'host=${NEW_PRIMARY_NODE_HOST} port=${NEW_PRIMARY_NODE_PORT} user=${REPLUSER} replication=database password=1234 application_name=${NODE_HOST} '
recovery_target_timeline = 'latest'
primary_slot_name = '${REPL_SLOT_NAME}'
EOT

PG_VERSION=\$(${PGHOME}/bin/postgres -V | awk '{print \$3}' | cut -d. -f1)
 echo "1"
echo "include_if_exists = '\$RECOVERYCONF'" >> "\$PGHOME/conf/conf.d/demo.conf"



exec \$PGHOME/bin/pg_ctl \
  -D "\$PGDATA" \
  -l /tmp/postgres.log \
  -w \
   -o "-c config_file=/opt/bitnami/postgresql/conf/postgresql.conf \
      -c hba_file=/opt/bitnami/postgresql/conf/pg_hba.conf" \
  start

EOF


# If start Standby successfully, attach this node de bao cho pgpool biet la tao da hoat dong h co the truy cap vao cluster node duoc roi
if [ $? -eq 0 ]; then

    # Run pcp_attact_node to attach Standby node to Pgpool-II.
    ${PGPOOL_PATH}/pcp_attach_node -w -h localhost -U $PCP_USER -p ${PCP_PORT} -n ${NODE_ID}

    if [ $? -ne 0 ]; then
        echo ERROR: follow_primary.sh: end: pcp_attach_node failed
        exit 1
    fi

else

    # If start Standby failed, drop replication slot "${REPL_SLOT_NAME}"
    ${PGHOME}/bin/psql -h ${NEW_PRIMARY_NODE_HOST} -p ${NEW_PRIMARY_NODE_PORT} postgres \
        -c "SELECT pg_drop_replication_slot('${REPL_SLOT_NAME}');"  >/dev/null 2>&1

    if [ $? -ne 0 ]; then
        echo ERROR: follow_primary.sh: drop replication slot \"${REPL_SLOT_NAME}\" failed. You may need to drop replication slot manually.
    fi

    echo ERROR: follow_primary.sh: end: follow primary command failed
    exit 1
fi

echo follow_primary.sh: end: follow primary command is completed successfully
exit 0