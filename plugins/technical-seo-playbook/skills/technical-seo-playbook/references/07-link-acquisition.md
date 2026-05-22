# 07 — Link Acquisition (Technical Side)

Covers: digital PR data-asset patterns, programmatic page templates that earn links, broken-link reclamation via Ahrefs/Semrush APIs (code samples), disavow file syntax and when it still matters in 2026.

*No outreach scripts — the technical infrastructure that earns and reclaims links.*

---

## 7.1 Digital PR Data-Asset Patterns

**Build pages that journalists cite, not pages that ask for links.**

### Template

```
/data/{topic}-statistics-2026/
  - H1: "{Topic} Statistics 2026: 47 New Data Points"
  - Above the fold: 3-5 headline numbers in <blockquote>
  - Embed-code generator (iframe with backlink baked in)
  - Methodology section with sample size, dates, sources
  - Schema: Dataset + Article
```

### Include an embed widget

```html
<iframe src="https://example.com/embed/chart-1" width="600" height="400" frameborder="0"></iframe>
<a href="https://example.com/data/topic-stats-2026/">Source: Acme 2026 Topic Report</a>
```

---

## 7.2 Programmatic Link-Bait Templates

- **Free calculators** (mortgage, salary, AVIF/WebP savings).
- **Comparison pages**: "X vs Y" for tools journalists reference.
- **State-by-state / country-by-country** breakdowns of statistics you own.
- **Live dashboards** updated daily (with stable URLs).

---

## 7.3 Broken-Link Reclamation (Ahrefs API)

```python
import os, requests

AHREFS_KEY = os.environ['AHREFS_KEY']
TARGET = 'example.com'

# Pull backlinks pointing to broken pages on your domain
r = requests.get('https://api.ahrefs.com/v3/site-explorer/broken-backlinks',
    headers={'Authorization': f'Bearer {AHREFS_KEY}'},
    params={'target': TARGET, 'mode': 'domain', 'limit': 1000, 'select':
            'url_from,url_to,http_code,anchor,domain_rating_source'})
broken = r.json()['backlinks']

# Filter: high-DR sources, 404/410 on our side
candidates = [b for b in broken
              if b['http_code'] in (404, 410) and b['domain_rating_source'] >= 30]

# Suggest 301 targets
for c in candidates:
    print(f"301 {c['url_to']} → ?  (linked from DR{c['domain_rating_source']} {c['url_from']})")
```

**The same pattern works with Semrush's Backlinks API** (`/backlinks_overview` endpoint).

---

## 7.4 Disavow File — Syntax and 2026 Relevance

### Syntax (per Google docs)

- **Max 100,000 lines, max 2 MB**.
- One URL or domain per line.
- Domain-level: prefix with `domain:`.
- Comments with `#`.
- **Subpaths/wildcards are NOT supported.**

```
# Reclamation file — last updated 2026-05-18
# Manual action: link spam, received 2026-04-22
domain:spammynetwork.example
domain:pbn-hub-7.example
https://random-blog.example/comments/page-5.html
```

### 2026 relevance

Disavow is now **primarily for manual actions only**. Per Mueller (repeated 2023–2025), Google's link-spam algorithm ignores most low-quality links automatically.

Per **Glenn Gabe's June 15, 2023 GSQi case study**, "Disavowing The Disavow Tool" — a site owner finally removed a disavow file with 15K+ domains, stopped continually disavowing links, and "then surged back from the dead."

### Use disavow only when

1. You have a **confirmed manual action** for unnatural links.
2. You have **documented evidence of a negative SEO attack**.
3. You **acquired a domain with a known black-hat history**.

In all other cases the file does nothing useful and **risks disavowing legitimate links.**
