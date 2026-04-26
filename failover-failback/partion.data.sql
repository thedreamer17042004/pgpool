CREATE TABLE orders (
    order_id     SERIAL,
    customer_id  INT NOT NULL,
    order_date   DATE NOT NULL,
    amount       NUMERIC(10,2),
    PRIMARY KEY (order_id, order_date)
) PARTITION BY RANGE (order_date);

CREATE TABLE orders_2024_q1 PARTITION OF orders
FOR VALUES FROM ('2024-01-01') TO ('2024-04-01');

CREATE TABLE orders_2024_q2 PARTITION OF orders
FOR VALUES FROM ('2024-04-01') TO ('2024-07-01');

CREATE TABLE orders_2024_q3 PARTITION OF orders
FOR VALUES FROM ('2024-07-01') TO ('2024-10-01');

CREATE TABLE orders_2024_q4 PARTITION OF orders
FOR VALUES FROM ('2024-10-01') TO ('2025-01-01');


INSERT INTO orders (customer_id, order_date, amount)
VALUES (1, '2024-02-10', 100.50);

INSERT INTO orders (customer_id, order_date, amount)
VALUES (2, '2024-08-15', 250.00);

SELECT *
FROM orders
WHERE order_date = '2024-02-10';