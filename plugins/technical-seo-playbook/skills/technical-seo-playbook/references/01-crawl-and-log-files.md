# 01 — Crawl Architecture & Log-File SEO

Covers: robots.txt patterns per stack, crawl-budget math from raw access logs, URL parameter and faceted navigation traps, the noindex/canonical/disallow/410/301 decision tree, and XML sitemap architecture for 1M+ URL sites.

---

## 1.1 robots.txt — Stack-Specific Patterns

The robots.txt protocol is governed by **RFC 9309** (the IETF spec ratified in 2022). Googlebot fetches robots.txt every ~24 hours and caches up to 24 hours; **a 5xx for more than 30 days causes Google to treat the site as fully disallowed** (per Google Search Central's robots.txt documentation).

### WordPress (canonical pattern)

```
User-agent: *
Disallow: /wp-admin/
Allow: /wp-admin/admin-ajax.php
Disallow: /?s=
Disallow: /search/
Disallow: /*?replytocom=
Disallow: /*?attachment_id=
Disallow: /xmlrpc.php

# Faceted / parameter traps
Disallow: /*?orderby=
Disallow: /*?filter_*

# AI crawlers — opt out per crawler (do NOT block GoogleOther unless you mean to)
User-agent: GPTBot
Disallow: /

User-agent: ClaudeBot
Disallow: /

User-agent: PerplexityBot
Disallow: /

User-agent: Google-Extended
Disallow: /

Sitemap: https://example.com/sitemap_index.xml
```

`Google-Extended` controls Gemini training/grounding without affecting Googlebot indexing. `GoogleOther` is a general-purpose research crawler; blocking it does not affect Search ranking but blocks internal R&D fetches.

### Shopify

Shopify auto-generates `/robots.txt` from the storefront. Override via `robots.txt.liquid` (Online Store 2.0):

```liquid
{% for group in robots.default_groups %}
  {{- group.user_agent }}
  {%- for rule in group.rules -%}
    {{ rule }}
  {%- endfor -%}

  {%- if group.user_agent.value == '*' -%}
    {{ 'Disallow: /collections/*+*' }}
    {{ 'Disallow: /collections/*%2B*' }}
    {{ 'Disallow: /collections/*?*constraint*' }}
    {{ 'Disallow: /collections/*sort_by*' }}
    {{ 'Disallow: /*?variant=' }}
  {%- endif -%}

  {%- for sitemap in group.sitemaps -%}
    {{ sitemap }}
  {%- endfor -%}
{% endfor %}
```

The `/collections/*+*` patterns block the infinite tag combinations Shopify generates on filter clicks — a well-known crawl trap unique to the platform.

### Next.js (App Router) — programmatic `app/robots.ts`

```ts
import type { MetadataRoute } from 'next'

export default function robots(): MetadataRoute.Robots {
  return {
    rules: [
      { userAgent: '*', allow: '/', disallow: ['/api/', '/admin/', '/*?utm_'] },
      { userAgent: 'GPTBot', disallow: '/' },
      { userAgent: 'ClaudeBot', disallow: '/' },
    ],
    sitemap: 'https://example.com/sitemap.xml',
    host: 'https://example.com',
  }
}
```

### Astro/SSG

Ship `public/robots.txt` verbatim — there is no server to render it dynamically, which is the point.

### Headless / multi-stack

robots.txt MUST live at the apex of each host you want indexed: `https://www.example.com/robots.txt` is **not** used for `https://shop.example.com/`. Subdomains need their own.

### Common mistakes (robots.txt)

- **Blocking `/wp-content/` or `/_next/static/`** — this breaks rendering because the Web Rendering Service can't fetch CSS/JS. Per Google's December 2024 *Crawling December* series: "If WRS cannot fetch a rendering-critical resource, Google Search may have trouble extracting content."
- **Using `Disallow` to deindex a page.** Disallow blocks crawling, not indexing — Google will index the URL with anchor-text-only snippets. Use `noindex` instead.
- **Putting `Sitemap:` lines under a `User-agent` group.** Sitemap directives are global; place them at the top or bottom of the file.

---

## 1.2 Crawl-Budget Math from Raw Access Logs

Per Gary Illyes's January 2017 Google Webmaster Central post (still cited verbatim in 2025 documentation), **crawl budget = crawl rate limit × crawl demand**. Illyes added in 2024–2025 that "crawl budget is not something most sites need to worry about" — generally true under 10,000 URLs and with sub-200ms TTFB. Above that, you must measure.

### Verify Googlebot before you trust the user-agent (anyone can spoof it)

```bash
# Reverse DNS, then forward-confirm — the Google-published method
host 66.249.66.1
# expect: 66.1.249.66.in-addr.arpa domain name pointer crawl-66-249-66-1.googlebot.com.
host crawl-66-249-66-1.googlebot.com
# expect: crawl-66-249-66-1.googlebot.com has address 66.249.66.1
```

Google publishes verified IP ranges at `https://developers.google.com/search/apis/ipranges/googlebot.json` — use those for production filtering.

### Single-pass log parse (awk) — daily Googlebot hit counts by status code

```bash
awk '/Googlebot/ {
  split($4, t, ":"); date=substr(t[1],2);
  status=$9;
  counts[date"|"status]++
}
END { for (k in counts) print k, counts[k] }' access.log | sort
```

### DuckDB — recommended for any site over ~1M hits/day

Faster than ELK, no infra.

```sql
-- Load gzipped logs directly; no ETL
CREATE TABLE logs AS
SELECT * FROM read_csv_auto('access.log.gz',
  delim=' ', header=false, quote='"');

-- Crawl frequency by URL pattern, last 30 days
SELECT
  regexp_extract(column05, '^/([^/?]+)', 1) AS section,
  column09 AS status,
  COUNT(*) AS hits
FROM logs
WHERE column06 LIKE '%Googlebot%'
  AND strptime(column04, '[%d/%b/%Y:%H:%M:%S %z]') > now() - INTERVAL 30 DAY
GROUP BY 1,2
ORDER BY hits DESC;

-- Crawl waste: % of Googlebot hits that return non-200
SELECT
  status,
  COUNT(*) AS hits,
  100.0*COUNT(*)/SUM(COUNT(*)) OVER () AS pct
FROM logs WHERE column06 LIKE '%Googlebot%'
GROUP BY status ORDER BY hits DESC;
```

### Targets to act on

- If **>15% of Googlebot hits return 4xx** → fix internal links / sitemaps before anything else.
- If **>25% hit non-canonical URLs** → consolidate via 301/canonical.
- If **median Googlebot TTFB >600ms** → Google will throttle crawl rate. GSC Crawl Stats and Cloudflare's crawl-rate report confirm.

### Crawl ratio (per Botify's published methodology)

`Crawl ratio = unique URLs crawled in 30 days ÷ indexable URLs in structure`

Botify case data shows healthy sites land at **60–80%**; under **40% indicates serious crawl waste**. Pages deeper than click depth 5 from the homepage almost always show declining crawl ratios.

---

## 1.3 URL Parameter & Faceted Navigation Traps

The GSC URL Parameter tool was retired in 2022. There is no longer a Google-side knob — you must control parameters in your own infrastructure.

### The three patterns that generate infinite spaces (per Illyes's published guidance)

1. **Calendar widgets** with a `?date=next` link → infinite future.
2. **Faceted filters** that combine: `?color=red&size=M&brand=acme&sort=price` × N facets = factorial explosion.
3. **On-site search results** with `?q=` indexed.

### Fix pattern — Nginx, e-commerce facets

```nginx
# Strip tracking params at the edge, 301 to canonical
map $args $needs_strip {
    default 0;
    ~*(utm_|fbclid|gclid|mc_cid) 1;
}
server {
    if ($needs_strip) {
        return 301 $scheme://$host$uri;
    }

    # Block crawlers on faceted combinations >2 filters
    location ~ ^/category/ {
        if ($args ~* "filter_.*&filter_.*&filter_") {
            add_header X-Robots-Tag "noindex, follow" always;
        }
    }
}
```

### Faceted nav decision matrix

| Facet type | Treatment | Reason |
|---|---|---|
| Primary category (e.g. `/shoes/running/`) | Indexable, in sitemap | Distinct search demand |
| Single-facet refinement (`?color=red`) | Indexable IF >100 monthly searches; else `noindex,follow` | Demand-driven |
| 2+ facet combinations | `noindex,follow` + robots-blocked for >3 facets | Combinatorial explosion |
| Sort/view params (`?sort=`, `?view=`) | `rel=canonical` to base; `noindex,follow` | No unique demand |
| Pagination (`?page=2`) | Self-canonical, indexable | Distinct content |
| Session/tracking (`?sessionid=`, `?utm_`) | 301 strip OR `rel=canonical` | Duplication |

---

## 1.4 Decision Tree: noindex vs canonical vs Disallow vs 410 vs 301

This is the single most-confused area of technical SEO. The decision is mechanical:

```
Is the URL gone forever?
├── YES → Is there an equivalent replacement?
│   ├── YES → 301 to replacement (preserves PageRank)
│   └── NO  → 410 Gone (faster deindexing than 404; John Mueller has confirmed it is "a tiny bit faster")
└── NO (page exists but should not rank)
    ├── Is it a duplicate of another indexable page?
    │   └── YES → rel="canonical" to the master (link consolidation)
    ├── Should crawlers see it at all? (e.g. /admin/)
    │   └── NO  → Disallow in robots.txt (NOT for deindexing — for crawl waste)
    └── Should it be crawlable but not indexable? (thank-you pages, faceted combos)
        └── YES → meta robots noindex (NOT robots.txt — Google must crawl to see noindex)
```

### The classic mistake

`Disallow: /thank-you/` + `<meta name="robots" content="noindex">`. Googlebot never reaches the page to see the noindex, so the URL stays indexed with anchor-text-only snippets. Per Martin Splitt's Search Central Lightning Talk: "Use noindex meta tags or X-Robots-Tag for pages you want to be hidden from search results. Do not block those pages in robots.txt."

### 410 vs 404

Both deindex; 410 is processed slightly faster in practice. For mass-pruning a defunct section, return 410 plus a sitemap of remaining live URLs.

---

## 1.5 XML Sitemap Architecture for 1M+ URL Sites

**Sitemap protocol limits**, per sitemaps.org and enforced by Google: **50,000 URLs OR 50 MB uncompressed per file**. Sitemap index files can reference up to 50,000 sitemaps. Per Barry Adams's Polemic Digital analysis, **capping individual sitemaps at 10,000 URLs improves indexation completeness on large sites** — smaller buckets reveal which segment Google is failing on.

### Segmentation strategy for 1M+ URLs

```
/sitemap_index.xml
  ├── /sitemaps/products-active-2026-05.xml.gz   (10k URLs, lastmod fresh)
  ├── /sitemaps/products-evergreen-001.xml.gz    (10k URLs)
  ├── ...
  ├── /sitemaps/products-evergreen-099.xml.gz
  ├── /sitemaps/blog-2026.xml.gz
  ├── /sitemaps/blog-archive-pre-2025.xml.gz
  └── /sitemaps/categories.xml.gz
```

Segment by **freshness × content type**. Hot/active content in its own file gives Google a clear freshness signal.

### `lastmod` precision rules (per Google's 2023 sitemap docs, restated 2025)

- Must reflect a **meaningful** content change, not a republish/cache-bust.
- Google will start **ignoring `lastmod` if it is wrong on a majority of URLs**.
- Use W3C Datetime format: `2026-05-18T14:23:00+00:00` — full timestamp, not just date, for freshness-sensitive content.
- Omit `<priority>` and `<changefreq>` — Google ignores them.

### Next.js dynamic sitemap (App Router, sharded for 1M+)

```ts
// app/sitemap.ts
import type { MetadataRoute } from 'next'

export async function generateSitemaps() {
  const count = await db.products.count()
  return Array.from({ length: Math.ceil(count / 10000) }, (_, id) => ({ id }))
}

export default async function sitemap({ id }: { id: number }): Promise<MetadataRoute.Sitemap> {
  const products = await db.products.findMany({
    skip: id * 10000,
    take: 10000,
    where: { status: 'PUBLISHED' }, // only indexable
  })
  return products.map((p) => ({
    url: `https://example.com/p/${p.slug}`,
    lastModified: p.contentUpdatedAt, // NOT updatedAt — content change only
    changeFrequency: 'weekly',
    priority: 0.7,
  }))
}
```

Submit the index file in GSC and link it from `/robots.txt`. Do **not** submit each shard — let the index do its job.

### Common mistakes (sitemaps)

- Including **non-canonical URLs** (a `rel=canonical` pointing elsewhere means Google won't index this URL anyway).
- Including **4xx, 5xx, 301-redirecting, or `noindex` URLs** — degrades trust in your sitemap.
- **Bumping `lastmod` on every nightly cron** — Google will eventually ignore your lastmod entirely.
- Using `<priority>` to fight for indexation. Google has confirmed it does nothing.
