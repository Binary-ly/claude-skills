# 11 — Monitoring & Measurement

Covers: GSC API extraction with Python (full code), BigQuery + GSC bulk data export schema and useful queries, log-file analysis pipeline (DuckDB + Python or ELK), rank tracking sanity (why position numbers lie post-personalization).

---

## 11.1 GSC API Extraction with Python

```python
# Requires: pip install google-api-python-client google-auth-oauthlib
from googleapiclient.discovery import build
from google.oauth2 import service_account
import csv, datetime as dt

SCOPES = ['https://www.googleapis.com/auth/webmasters.readonly']
KEY = 'service-account.json'
SITE = 'sc-domain:example.com'

creds = service_account.Credentials.from_service_account_file(KEY, scopes=SCOPES)
svc = build('searchconsole', 'v1', credentials=creds)

body = {
  'startDate': (dt.date.today() - dt.timedelta(days=90)).isoformat(),
  'endDate':   dt.date.today().isoformat(),
  'dimensions': ['query', 'page', 'device', 'country'],
  'rowLimit': 25000,
  'startRow': 0,
}
rows = []
while True:
    resp = svc.searchanalytics().query(siteUrl=SITE, body=body).execute()
    batch = resp.get('rows', [])
    if not batch: break
    rows.extend(batch)
    body['startRow'] += len(batch)
    if len(batch) < body['rowLimit']: break

with open('gsc.csv', 'w', newline='') as f:
    w = csv.writer(f)
    w.writerow(['query','page','device','country','clicks','impressions','ctr','position'])
    for r in rows:
        w.writerow([*r['keys'], r['clicks'], r['impressions'], r['ctr'], r['position']])
```

---

## 11.2 BigQuery + GSC Bulk Data Export

Setup per Google's docs (`developers.google.com/search/blog/2023/02/bulk-data-export`):

1. Enable the BigQuery API on a GCP project.
2. Grant `search-console-data-export@system.gserviceaccount.com` the **BigQuery Job User** and **BigQuery Data Editor** roles.
3. In GSC: **Settings → Bulk data export** → enter project ID and dataset location.

### Schema (auto-created)

- **`searchconsole.searchdata_site_impression`**: site-level (query, country, device, search_type, date, impressions, clicks, sum_position).
- **`searchconsole.searchdata_url_impression`**: URL-level (adds url, is_amp_top_stories, is_video, is_anonymized_discover, etc.).
- **`searchconsole.ExportLog`**: status tracking.

### Useful queries

```sql
-- Striking distance: queries ranking 11-20 with high impressions
SELECT query, url, SUM(impressions) imps, AVG(sum_position/impressions)+1 pos
FROM `proj.searchconsole.searchdata_url_impression`
WHERE data_date BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 28 DAY) AND CURRENT_DATE()
  AND query IS NOT NULL
GROUP BY query, url
HAVING pos BETWEEN 11 AND 20 AND imps > 100
ORDER BY imps DESC LIMIT 200;

-- Query cannibalization: same query, multiple URLs ranking
SELECT query, COUNT(DISTINCT url) urls, SUM(clicks) clicks
FROM `proj.searchconsole.searchdata_url_impression`
WHERE data_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 28 DAY)
GROUP BY query HAVING urls > 2 ORDER BY clicks DESC LIMIT 100;
```

### Cap storage costs

```sql
ALTER TABLE searchconsole.searchdata_url_impression
SET OPTIONS(partition_expiration_days=395);
```

---

## 11.3 Log-File Analysis (DuckDB + Python)

```python
import duckdb
con = duckdb.connect('logs.duckdb')
con.execute("""
  CREATE TABLE IF NOT EXISTS gbot AS
  SELECT
    strptime(regexp_extract(line, '\\[([^\\]]+)\\]', 1), '%d/%b/%Y:%H:%M:%S %z') ts,
    regexp_extract(line, '"GET ([^ ]+)', 1) url,
    CAST(regexp_extract(line, '" (\\d{3})', 1) AS INTEGER) status,
    CAST(regexp_extract(line, '\\d{3} (\\d+)', 1) AS INTEGER) bytes
  FROM read_csv_auto('/var/log/nginx/access.log.gz', delim='', header=false, columns={'line': 'VARCHAR'})
  WHERE line LIKE '%Googlebot%'
""")

# Crawl waste report
print(con.execute("""
  SELECT status, COUNT(*) hits,
         100.0*COUNT(*) / SUM(COUNT(*)) OVER () AS pct
  FROM gbot WHERE ts > now() - INTERVAL 30 DAY
  GROUP BY status ORDER BY hits DESC
""").df())
```

---

## 11.4 Rank-Tracking Sanity

**Position numbers in third-party trackers (Semrush, Ahrefs, AccuRanker) come from scraped, non-personalized results.**

Real users see SERPs personalized by:
- **Location** (down to ZIP code)
- **Device** (mobile/desktop/tablet)
- **Search history**
- **Account language**
- **AI Overview triggering**

### How to use the data

Treat **tracker positions as a directional signal, not ground truth**.

**Trust GSC's "average position"** for actual user experience — it is measured from impressions in real SERPs.
