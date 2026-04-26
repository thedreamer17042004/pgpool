SELECT pg_is_in_recovery();
--> để kiểm tra xem node hiện tại là master hay là slave; false là master; true là slave;

🎯 Mục tiêu
Bạn sẽ tự làm:

Master chết → promote slave → hệ thống chạy lại
🧪 Bước 1: Xác định master & slave

Vào từng node:

docker exec -it pg-master psql -U postgres
SELECT pg_is_in_recovery();

👉 Kết quả:

false → master
true → slave
🧪 Bước 2: Test data trước

Trên master:

CREATE TABLE test_failover (id INT);
INSERT INTO test_failover VALUES (1);

Trên slave:

SELECT * FROM test_failover;

👉 thấy data → OK

💥 Bước 3: Giả lập master chết
docker stop pg-master

👉 Lúc này:

hệ thống sẽ không ghi được nữa
vì chưa có master
🔥 Bước 4: Promote slave (QUAN TRỌNG)

Vào slave:

docker exec -it pg-slave psql -U postgres
SELECT pg_promote();

👉 Sau đó check lại:

SELECT pg_is_in_recovery();

👉 phải trả:

false

✔ Slave đã thành master

🧪 Bước 5: Test lại write
INSERT INTO test_failover VALUES (2);
SELECT * FROM test_failover;

👉 OK → failover thành công

🔁 Bước 6: (Optional) bring old master back
docker start pg-master

👉 Nhưng:

nó KHÔNG tự thành slave lại ❌
bạn phải re-init replication
⚠️ Điểm nguy hiểm (rất quan trọng)

Manual failover có rủi ro:

❌ Split-brain
Nếu master chưa chết hẳn
bạn promote slave → có 2 master

👉 dữ liệu sẽ toang

🧠 So với auto failover
Feature	Manual	Patroni
Độ nhanh	chậm	nhanh
Độ an toàn	thấp	cao
Tự động	❌	✅
🔥 Khi nào dùng manual?

✔ Dev / test
✔ Debug replication
✔ Hiểu hệ thống

❌ Production

✅ Kết luận

Manual failover =

Stop master → pg_promote() → done
👉 Gợi ý cho bạn

Bạn nên làm 3 test này:

✔ replication OK
✔ manual failover OK
✔ sau đó chuyển sang Patroni

# tiep do de chuyen master to slave thi ta sua file dock compose va doi master thanh slave thoi a roi chay lai test lai se thay su khac biet