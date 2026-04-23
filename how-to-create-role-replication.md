# cach tao replication user
# tren primary
CREATE ROLE repl_user WITH
LOGIN
REPLICATION
PASSWORD 'reply_pass';


(giai thich
2. Giải thích từng phần
LOGIN → user được phép đăng nhập
REPLICATION → cho phép streaming WAL
PASSWORD → dùng để xác thực trong pg_hba.conf) 

--> or
ALTER ROLE repl_user WITH
LOGIN
REPLICATION
ENCRYPTED PASSWORD '1234';

# 🔐 4. pg_hba.conf (bắt buộc đi kèm)
# on primary
host replication repl_user 0.0.0.0/0 md5
or
host replication repl_user <standby_ip>/32 md5

- load
pg_ctl reload
OR
 SELECT pg_reload_conf();
# testing
psql -h PRIMARY -U repl_user -d postgres -c "SELECT 1;"

# kiem tra xem dung chua
SELECT rolname, rolreplication, rolcanlogin
FROM pg_roles
WHERE rolname = 'repl_user';


echo "host replication repl_user 172.22.0.0/16 md5" >> /opt/bitnami/postgresql/conf/pg_hba.conf




=======================
/bitnami/postgresql/data/myrecovery.conf

/opt/bitnami/postgresql/conf/conf.d/custom.conf

echo "include_if_exists = '/bitnami/postgresql/data/myrecovery.conf'" >> "/opt/bitnami/postgresql/conf/conf.d/custom.conf"


b1: 
echo "host replication repl_user 172.22.0.0/16 md5" >> /opt/bitnami/postgresql/conf/pg_hba.conf

b2: 

CREATE ROLE repl_user WITH
LOGIN
REPLICATION
PASSWORD '1234';

# for testing 
tai pg-slave-1
psql -h pg-slave -p 5432 -U repl_user -d postgres

