#!/usr/bin/env python3
"""
GSC API extraction — pull 90 days of Search Analytics data and write to CSV.

Setup:
  1. Create a Google Cloud project, enable the Search Console API.
  2. Create a service account, download the JSON key as 'service-account.json'.
  3. In GSC: Settings → Users and permissions → Add the service account email
     as a user with at least Restricted permission.
  4. pip install google-api-python-client google-auth-oauthlib

For a domain property, SITE = 'sc-domain:example.com'.
For a URL-prefix property, SITE = 'https://example.com/'.
"""

from googleapiclient.discovery import build
from google.oauth2 import service_account
import csv
import datetime as dt

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
    if not batch:
        break
    rows.extend(batch)
    body['startRow'] += len(batch)
    if len(batch) < body['rowLimit']:
        break

with open('gsc.csv', 'w', newline='') as f:
    w = csv.writer(f)
    w.writerow(['query', 'page', 'device', 'country',
                'clicks', 'impressions', 'ctr', 'position'])
    for r in rows:
        w.writerow([*r['keys'], r['clicks'], r['impressions'], r['ctr'], r['position']])

print(f"Wrote {len(rows)} rows to gsc.csv")
