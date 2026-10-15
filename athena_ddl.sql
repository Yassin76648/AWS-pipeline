CREATE DATABASE IF NOT EXISTS dw;

CREATE EXTERNAL TABLE IF NOT EXISTS dw.dim_customer (
    customer_id       BIGINT,
    first_name        STRING,
    last_name         STRING,
    full_name         STRING,
    email             STRING,
    city              STRING,
    country           STRING,
    registration_date DATE
)
STORED AS PARQUET
LOCATION 's3://yassin-s3-bucket-161828268081-eu-north-1-an/processed/ecommerce/dim_customer/';

CREATE EXTERNAL TABLE IF NOT EXISTS dw.dim_category (
    category_id   BIGINT,
    category_name STRING
)
STORED AS PARQUET
LOCATION 's3://yassin-s3-bucket-161828268081-eu-north-1-an/processed/ecommerce/dim_category/';

CREATE EXTERNAL TABLE IF NOT EXISTS dw.dim_department (
    department_id   BIGINT,
    department_name STRING
)
STORED AS PARQUET
LOCATION 's3://yassin-s3-bucket-161828268081-eu-north-1-an/processed/ecommerce/dim_department/';

CREATE EXTERNAL TABLE IF NOT EXISTS dw.dim_product (
    product_id   BIGINT,
    category_id  BIGINT,
    product_name STRING,
    brand        STRING,
    price        DECIMAL(12,2),
    cost         DECIMAL(12,2),
    stock        INT
)
STORED AS PARQUET
LOCATION 's3://yassin-s3-bucket-161828268081-eu-north-1-an/processed/ecommerce/dim_product/';

CREATE EXTERNAL TABLE IF NOT EXISTS dw.dim_supplier (
    supplier_id   BIGINT,
    supplier_name STRING,
    country       STRING
)
STORED AS PARQUET
LOCATION 's3://yassin-s3-bucket-161828268081-eu-north-1-an/processed/ecommerce/dim_supplier/';

CREATE EXTERNAL TABLE IF NOT EXISTS dw.dim_employee (
    employee_id   BIGINT,
    manager_id    BIGINT,
    department_id BIGINT,
    first_name    STRING,
    last_name     STRING,
    full_name     STRING,
    salary        DECIMAL(12,2),
    hire_date     DATE
)
STORED AS PARQUET
LOCATION 's3://yassin-s3-bucket-161828268081-eu-north-1-an/processed/ecommerce/dim_employee/';

CREATE EXTERNAL TABLE IF NOT EXISTS dw.dim_shipper (
    shipper_id   BIGINT,
    company_name STRING
)
STORED AS PARQUET
LOCATION 's3://yassin-s3-bucket-161828268081-eu-north-1-an/processed/ecommerce/dim_shipper/';

CREATE EXTERNAL TABLE IF NOT EXISTS dw.dim_payment_method (
    payment_method_id INT,
    payment_method    STRING
)
STORED AS PARQUET
LOCATION 's3://yassin-s3-bucket-161828268081-eu-north-1-an/processed/ecommerce/dim_payment_method/';

CREATE EXTERNAL TABLE IF NOT EXISTS dw.dim_order_status (
    order_status_id INT,
    order_status    STRING
)
STORED AS PARQUET
LOCATION 's3://yassin-s3-bucket-161828268081-eu-north-1-an/processed/ecommerce/dim_order_status/';

CREATE EXTERNAL TABLE IF NOT EXISTS dw.dim_date (
    date         DATE,
    date_id      INT,
    year         INT,
    quarter      INT,
    month        INT,
    month_name   STRING,
    day          INT,
    day_of_week  INT,
    day_name     STRING,
    week_of_year INT
)
STORED AS PARQUET
LOCATION 's3://yassin-s3-bucket-161828268081-eu-north-1-an/processed/ecommerce/dim_date/';

CREATE EXTERNAL TABLE IF NOT EXISTS dw.fact_order (
    order_id        BIGINT,
    customer_id     BIGINT,
    date_id         INT,
    order_date      DATE,
    order_status_id INT
)
STORED AS PARQUET
LOCATION 's3://yassin-s3-bucket-161828268081-eu-north-1-an/processed/ecommerce/fact_order/';

CREATE EXTERNAL TABLE IF NOT EXISTS dw.fact_order_detail (
    order_detail_id  BIGINT,
    order_id         BIGINT,
    product_id       BIGINT,
    quantity         INT,
    unit_price       DECIMAL(12,2),
    discount         DECIMAL(12,2),
    gross_amount     DECIMAL(14,2),
    discount_amount  DECIMAL(14,2),
    total_amount     DECIMAL(14,2)
)
STORED AS PARQUET
LOCATION 's3://yassin-s3-bucket-161828268081-eu-north-1-an/processed/ecommerce/fact_order_detail/';

CREATE EXTERNAL TABLE IF NOT EXISTS dw.fact_payment (
    payment_id        BIGINT,
    order_id          BIGINT,
    date_id           INT,
    payment_date      DATE,
    payment_method_id INT,
    amount            DECIMAL(14,2)
)
STORED AS PARQUET
LOCATION 's3://yassin-s3-bucket-161828268081-eu-north-1-an/processed/ecommerce/fact_payment/';

CREATE EXTERNAL TABLE IF NOT EXISTS dw.fact_shipment (
    shipment_id   BIGINT,
    order_id      BIGINT,
    shipper_id    BIGINT,
    ship_date     DATE,
    delivery_date DATE,
    shipping_days INT
)
STORED AS PARQUET
LOCATION 's3://yassin-s3-bucket-161828268081-eu-north-1-an/processed/ecommerce/fact_shipment/';

CREATE EXTERNAL TABLE IF NOT EXISTS dw.fact_customer_sales (
    customer_id         BIGINT,
    total_orders        BIGINT,
    total_quantity       BIGINT,
    gross_sales          DECIMAL(24,2),
    total_discount        DECIMAL(24,2),
    total_sales           DECIMAL(24,2),
    average_order_line    DECIMAL(18,6),
    first_order_date      DATE,
    last_order_date       DATE,
    customer_segment      STRING
)
STORED AS PARQUET
LOCATION 's3://yassin-s3-bucket-161828268081-eu-north-1-an/processed/ecommerce/fact_customer_sales/';

CREATE EXTERNAL TABLE IF NOT EXISTS dw.fact_product_sales (
    product_id          BIGINT,
    total_orders        BIGINT,
    units_sold            BIGINT,
    gross_sales            DECIMAL(24,2),
    total_discount          DECIMAL(24,2),
    total_sales             DECIMAL(24,2),
    average_unit_price      DECIMAL(16,6)
)
STORED AS PARQUET
LOCATION 's3://yassin-s3-bucket-161828268081-eu-north-1-an/processed/ecommerce/fact_product_sales/';

CREATE EXTERNAL TABLE IF NOT EXISTS dw.bridge_product_supplier (
    product_id  BIGINT,
    supplier_id BIGINT
)
STORED AS PARQUET
LOCATION 's3://yassin-s3-bucket-161828268081-eu-north-1-an/processed/ecommerce/bridge_product_supplier/';
