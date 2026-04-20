// testing connection pool
const { Pool } = require("pg");

// CONNECT TỚI PGPOOL (không phải PostgreSQL trực tiếp)
const pool = new Pool({
  host: "localhost",     // Pgpool host
  port: 9999,            // default Pgpool port
  user: "postgres",
  password: "1234",
  database: "postgres",
  max: 5,               // số connection client mở
});


async function main() {
  const results = [];

    await Promise.all(
    Array.from({ length: 100 }).map(async () => {
        const client = await pool.connect();
        const res = await client.query("SELECT pg_backend_pid()");
        results.push(res.rows[0].pg_backend_pid);
        client.release();
    })
    );

    console.log(results);
    console.log("Unique:", new Set(results).size);
}

main();