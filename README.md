# AWS E-commerce Data Pipeline

An end-to-end data pipeline on AWS that combines **historical CSV data** with **new orders pulled incrementally from an ordering API**, transforms everything with **PySpark** into a **star-schema data warehouse** (Parquet on S3), and exposes it for SQL analytics through **Amazon Athena**.

> Individual project built during Samsung Innovation Campus (Big Data track).

---

## Architecture

```
  Ordering API (FastAPI)                 Historical data (12 CSV files)
          |                                          |
          |  GET /api/orders?from_order_id=...       |  uploaded once
          v                                          v
  +------------------+                     +----------------------+
  | Ingestion        |   order_<id>.json   |  S3: raw/ecommerce/  |
  | (AWS Lambda)     | ------------------> |  S3: api_raw/orders/ |
  | + checkpoint     |                     +----------+-----------+
  +------------------+                                |
                                                      v
                                          +-----------------------+
                                          | PySpark transformation|
                                          | clean, merge, model   |
                                          +-----------+-----------+
                                                      |
                                                      v
                                          +-----------------------+
                                          | S3: processed/        |
                                          | ecommerce/ (Parquet)  |
                                          +-----------+-----------+
                                                      |
                                                      v
                                          +-----------------------+
                                          | Amazon Athena (dw)    |
                                          | SQL analytics         |
                                          +-----------------------+
```

## What it does

1. **Incremental API ingestion.** A Lambda function reads the last processed `OrderID` from a checkpoint file in S3, asks the API only for newer orders, validates each one, and stores it as its own JSON file (`api_raw/orders/order_<id>.json`). The checkpoint is updated only after a successful upload, so re-running never duplicates orders.
2. **Merge historical and API data.** The notebook reads the 12 historical CSV files and the API JSON files, flattens the nested JSON (order, order details, payment, shipment), and unions both sources into one dataset per entity.
3. **Clean and validate.** Column names are standardised, empty rows are dropped, and duplicate keys are checked (no duplicate `ShipmentID` found).
4. **Model a star schema.** Dimensions, facts and one bridge table are built in PySpark and written as Snappy-compressed Parquet to S3.
5. **Query with Athena.** `athena_ddl.sql` registers all tables as external tables in a `dw` database.

## Data volumes (from the notebook run)

| Entity | Historical | From API | Combined |
|---|---:|---:|---:|
| Orders | 50,000 | 300 | **50,300** |
| Order details | 100,000 | 732 | **100,732** |
| Payments | 45,000 | 300 | **45,300** |
| Shipments | 40,000 | 300 | **40,291** (after dropping an empty row) |

## Warehouse model

**Dimensions (10):** `dim_customer`, `dim_product`, `dim_category`, `dim_department`, `dim_supplier`, `dim_employee`, `dim_shipper`, `dim_payment_method`, `dim_order_status`, `dim_date`

**Facts (6):** `fact_order`, `fact_order_detail`, `fact_payment`, `fact_shipment`, plus two aggregated facts: `fact_customer_sales` (orders, quantity, gross and net sales, discounts, customer segment) and `fact_product_sales` (units sold, sales, average price)

**Bridge (1):** `bridge_product_supplier` resolves the many-to-many relationship between products and suppliers.

`dim_date` is generated from the min and max order dates, and `dim_payment_method` and `dim_order_status` are built from the distinct values found in the data.

## Tech stack

Python, PySpark, AWS Lambda, Amazon S3, Amazon Athena, Parquet, FastAPI (source API), boto3, Hadoop-AWS (S3A connector)

## Repository structure

| File | Purpose |
|---|---|
| `lambda_Function.py` | Lambda ingestion: checkpoint, API call, validation, upload to S3 |
| `run_ingestion_local.py` | Runs the same ingestion logic locally against a local API and my own bucket (generates 3 test batches of 100 orders first) |
| `Ecommerce_transformation_local.ipynb` | PySpark ETL: read, clean, merge, model, write Parquet |
| `athena_ddl.sql` | Creates the `dw` database and all external tables |

## How to run

**Prerequisites:** Python 3.9+, Java 8 or 11 (for Spark), an AWS account with an S3 bucket, and the ordering API running locally.

```bash
pip install pyspark boto3 urllib3 python-dotenv
```

1. **Create a `.env` file** next to the notebook (never commit it):
   ```
   AWS_ACCESS_KEY_ID=...
   AWS_SECRET_ACCESS_KEY=...
   AWS_REGION=eu-north-1
   ```
2. **Set your bucket name** in `run_ingestion_local.py` and in the configuration cell of the notebook.
3. **Upload the 12 historical CSV files** to `s3://<your-bucket>/raw/ecommerce/`.
4. **Ingest new orders** (API must be running on `127.0.0.1:8000`):
   ```bash
   python run_ingestion_local.py
   ```
   Or deploy `lambda_Function.py` to AWS Lambda and set `BUCKET` and `API_URL`.
5. **Run the notebook** `Ecommerce_transformation_local.ipynb` top to bottom. On Windows, Spark needs `HADOOP_HOME` set (the notebook uses `C:\hadoop`).
6. **Create the Athena tables:** replace the bucket name in `athena_ddl.sql`, then run it in the Athena query editor.

## Example queries

```sql
-- Monthly sales
SELECT d.year, d.month_name, SUM(f.total_amount) AS sales
FROM dw.fact_order o
JOIN dw.fact_order_detail f ON f.order_id = o.order_id
JOIN dw.dim_date d ON d.date_id = o.date_id
GROUP BY d.year, d.month, d.month_name
ORDER BY d.year, d.month;

-- Top 10 customers by sales
SELECT c.full_name, s.total_sales
FROM dw.fact_customer_sales s
JOIN dw.dim_customer c ON c.customer_id = s.customer_id
ORDER BY s.total_sales DESC
LIMIT 10;
```

## Design decisions

- **Checkpoint in S3** keeps ingestion incremental and idempotent without needing a database.
- **One JSON file per order** keeps raw data immutable and easy to replay.
- **Parquet with Snappy** keeps Athena scans cheap and fast.
- **Pre-aggregated facts** (`fact_customer_sales`, `fact_product_sales`) speed up common questions.
- **Local runner reuses the Lambda code** so the exact production logic is tested locally.

## Possible improvements

- Schedule the Lambda with Amazon EventBridge and run the ETL as an AWS Glue job.
- Partition large fact tables by date to reduce Athena scan cost.
- Load the model into Amazon Redshift (the notebook already has a commented configuration for it).
- Add automated data-quality tests and move configuration to environment variables.

## Author

**Yassin Shaaban**, Data Engineer
[LinkedIn](https://www.linkedin.com/in/yassin-shaaban-7b1945342/) | [GitHub](https://github.com/Yassin76648)
