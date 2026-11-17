import json, time
from datetime import datetime, timezone

import boto3
import requests

BUCKET = "nikhil-ecom-raw-2026"
STORE, BASE = "snitch", "https://snitch.co.in"
HEADERS = {"User-Agent": "Mozilla/5.0 (student analytics project)"}
s3 = boto3.client("s3")


def scrape_store(base):
    products, seen, page = [], set(), 1
    while True:
        for attempt in range(4):
            r = requests.get(f"{base}/products.json",
                             params={"limit": 250, "page": page},
                             headers=HEADERS, timeout=30)
            if r.status_code == 429:
                time.sleep(10 * (attempt + 1))
                continue
            break
        r.raise_for_status()
        new = [p for p in r.json().get("products", []) if p["id"] not in seen]
        if not new:
            break
        seen.update(p["id"] for p in new)
        products.extend(new)
        print(f"page {page}: {len(products)} unique so far")
        page += 1
        time.sleep(2)
    return products


now = datetime.now(timezone.utc)
products = scrape_store(BASE)
key = f"raw/products/store={STORE}/dt={now:%Y-%m-%d}/{STORE}_{now:%Y%m%dT%H%M%SZ}.json"
s3.put_object(Bucket=BUCKET, Key=key,
              Body=json.dumps(products).encode("utf-8"),
              ContentType="application/json")
print(f"OK {len(products)} unique products -> s3://{BUCKET}/{key}")