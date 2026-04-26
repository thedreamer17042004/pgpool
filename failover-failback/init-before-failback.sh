#!/bin/bash
# truoc khi khoi phuc lai node da die thi chay file nay  chay tren master chinh thoi
# ========================
# SERVING PREVIOUS FAILBACK chay o che do ROOT
# ========================


cp /opt/bitnami/scripts/recovery_1st_stage.sh /bitnami/postgresql/data/
chown postgres:postgres /home/postgres/.ssh/id_rsa_pgpool
chmod 600 /home/postgres/.ssh/id_rsa_pgpool

psql -U postgres -d postgres -c "CREATE EXTENSION IF NOT EXISTS pgpool_recovery;"


# GHI CHU 
# #  quyen root moi change dc 
# chmod 600 /home/postgres/.ssh/id_rsa_pgpool