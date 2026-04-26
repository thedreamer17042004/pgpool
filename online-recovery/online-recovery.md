# b1: chay file init-before-failback.sh
# b2 run pcp_recovery_node
pcp_recovery_node -h localhost -p 9898 -U pgpool -n 0
(cach tren bi loi the following )
<!--function pgpool_recovery(unknown, unknown, unknown, unknown, integer, unknown, unknown) does not exist at character 8

2026-04-26 16:00:51.255 GMT [399] HINT:  No function matches the given name and argument types. You might need to add explicit type casts.

2026-04-26 16:00:51.255 GMT [399] STATEMENT:  SELECT pgpool_recovery('recovery_1st_stage.sh', 'pg-master', '/bitnami/postgresql/data', '5432', 0, '5432', 'pg-slave') -->

or run in postgres
#chay tai master node
SELECT pgpool_recovery('recovery_1st_stage.sh', 'pg-master', '/bitnami/postgresql/data', '5432', 0, '5432', 'pg-slave');


# b3: then start node at node die tro ve hoat dong node with role postgres

/opt/bitnami/postgresql/bin/pg_ctl \
  -D /bitnami/postgresql/data \
  -l /tmp/postgres.log \
  -w \
  -o "-c config_file=/opt/bitnami/postgresql/conf/postgresql.conf -c hba_file=/opt/bitnami/postgresql/conf/pg_hba.conf" \
  start

# stop
/opt/bitnami/postgresql/bin/pg_ctl -D /bitnami/postgresql/data stop 


# relation
https://www.pgpool.net/docs/46/en/html/example-cluster.html#PCP-AUTHENTICATION