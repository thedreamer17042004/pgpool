# cach de append them cau hinh file pgpool.conf vao pgpool.conf mac dinh
PGPOOL_USER_CONF_FILE
# cach tao ssh key 
ssh-keygen -t rsa -b 4096 -f id_rsa_pgpool
# chay container bang quyen root 
docker exec -it -u root pg-slave bash


# huong dan de cai ssh vao container
# Trên host:

ssh-keygen -t rsa -b 4096 -f id_rsa_pgpool -N ""

Sẽ tạo:

id_rsa_pgpool
id_rsa_pgpool.pub


# Sau đó mount private key vào container pgpool:

volumes:
  - ./id_rsa_pgpool:/root/.ssh/id_rsa_pgpool:ro
  - ./failover.sh:/opt/bitnami/scripts/failover.sh


# Rồi mount public key vào container standby:

pg-slave:
  volumes:
    - ./id_rsa_pgpool.pub:/tmp/id_rsa_pgpool.pub:ro


# Sau khi container lên, vào pg-slave:

docker exec -it pg-slave bash


# Tạo thư mục SSH:

mkdir -p /root/.ssh
chmod 700 /root/.ssh
cat /tmp/id_rsa_pgpool.pub >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys


# Sau đó trong pg-slave cần có SSH server. Cài:

apt update
apt install -y openssh-server
mkdir -p /var/run/sshd
service ssh start

--note:
✅ Cách fix trên pg-slave

Vào container pg-slave:

docker exec -it pg-slave bash


Sửa config:

vi /etc/ssh/sshd_config


Thêm hoặc bật:

PubkeyAuthentication yes

🔄 Restart SSH service
service ssh restart

# client cai de ket noi toi
apt install -y openssh-client


# Rồi test từ pgpool:

docker exec -it pgpool bash
ssh -o StrictHostKeyChecking=no -i /root/.ssh/id_rsa_pgpool root@pg-slave

--fix loi khi ma bad permissions
chmod 700 /root/.ssh
chmod 600 /root/.ssh/id_rsa_pgpool

-- de xem quyen doc ghi file
ls -l filename

-- showlog 
ssh -vvv -i /root/.ssh/id_rsa_pgpool bitnami@pg-slave



docker build -f Dockerfile.postgres -t postgres-custom .