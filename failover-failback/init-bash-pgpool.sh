#!/bin/bash
# GHI CHAY ALL CONTAINER THI PHAI CHAY FILE NAY NHE
# file nay se dc chay truoc khi thuc hien failover follow command and failback
# =====================
# SERVING PGPOOL CHAY O CHE DO ROOT
# =====================
chmod 700 /home/postgres/.ssh
chown -R postgres:postgres /home/postgres/.ssh
chmod 600 /home/postgres/.ssh/id_rsa_pgpool


# =====================
# SERVING PGPOOL
# =====================