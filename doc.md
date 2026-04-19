# Kết nối tới PostgreSQL ở localhost:5432 dùng username postgres vào database postgres(psql la command tool de ket noi va lam viec voi posgres)
psql -h localhost -p 5432 -U postgres -d postgres
# cach thoat khoi database 
\q
# cach thoat khoi container dung
exit
# cach xem cac extension da cai dat duoc hay chua
\dx
# xem config
cat /opt/bitnami/pgpool/conf/pgpool.conf
# xem password
cat /opt/bitnami/pgpool/conf/pool_passwd
# Xem node:
pcp_node_info -h localhost -U admin -p 9898 -n 0
# Attach/detach node:

pcp_detach_node -h localhost -U admin -p 9898 -n 0
pcp_attach_node -h localhost -U admin -p 9898 -n 0
# Xem status node trong SQL:

show pool_nodes;


# cach de bat log trong postgres server to test pgpool chay toi
# Trong postgresql.conf hãy bật thêm:

log_statement = 'all'
log_connections = on
log_disconnections = on
log_duration = on


# Hoặc vào psql rồi chạy:
ALTER SYSTEM SET log_statement = 'all';
ALTER SYSTEM SET log_connections = on;
ALTER SYSTEM SET log_disconnections = on;
ALTER SYSTEM SET log_duration = on;
SELECT pg_reload_conf();

# lay backend id to check if connection pool working properly
select pg_backend_pid();

show pool_processes;
