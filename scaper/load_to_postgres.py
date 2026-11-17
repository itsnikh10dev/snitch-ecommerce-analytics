import json, os
import boto3, psycopg2
from psycopg2.extras import execute_values
from dotenv import load_dotenv

load_dotenv()
BUCKET = "nikhil-ecom-raw-2026"
PREFIX = "raw/products/store=snitch/"

s3 = boto3.client("s3")
conn = psycopg2.connect(host="localhost", port=5432, dbname="ecom_db",
                        user="postgres", password=os.environ["PG_PASSWORD"])
cur = conn.cursor()

cur.execute("create schema if not exists raw")
cur.execute("""
create table if not exists raw.products_raw (
    id bigserial primary key,
    source_file text,
    loaded_at timestamptz default now(),
    v jsonb
)""")
conn.commit()

cur.execute("select distinct source_file from raw.products_raw")
done = {r[0] for r in cur.fetchall()}

paginator = s3.get_paginator("list_objects_v2")
for page in paginator.paginate(Bucket=BUCKET, Prefix=PREFIX):
    for obj in page.get("Contents", []):
        key = obj["Key"]
        if key in done or not key.endswith(".json"):
            continue
        body = s3.get_object(Bucket=BUCKET, Key=key)["Body"].read()
        products = json.loads(body)
        execute_values(cur,
            "insert into raw.products_raw (source_file, v) values %s",
            [(key, json.dumps(p)) for p in products])
        conn.commit()
        print(f"loaded {len(products)} rows from {key}")

cur.execute("select count(*), count(distinct v->>'id') from raw.products_raw")
print("rows, unique products:", cur.fetchone())
conn.close()