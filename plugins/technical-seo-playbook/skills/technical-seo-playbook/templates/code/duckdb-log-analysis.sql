-- =============================================================================
-- duckdb-log-analysis.sql
-- Googlebot log parsing for crawl-budget diagnosis.
-- Run: duckdb -c ".read duckdb-log-analysis.sql"
--
-- Why DuckDB: zero infrastructure, reads gzipped logs directly, faster than
-- ELK for any site under ~100M hits/day. For larger scale, the same SQL
-- patterns work on BigQuery / Athena / ClickHouse with minor syntax changes.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Step 1 — Load logs (Combined Log Format / NCSA Extended)
-- -----------------------------------------------------------------------------
-- Adjust the column layout if your log format differs. The default layout below
-- assumes Nginx/Apache Combined Log Format:
--   $remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent
--   "$http_referer" "$http_user_agent"
--
-- Column positions in space-delimited mode (1-indexed):
--   column01 = remote_addr     column06 = user_agent (after second quote)
--   column04 = timestamp       column09 = status
--   column05 = "GET /path HTTP/1.1"   column10 = bytes
--
-- For real-world logs, prefer regex extraction (Step 2 below) — it is more
-- robust against quoted fields containing spaces.
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE raw_logs AS
SELECT * FROM read_csv_auto(
  '/var/log/nginx/access.log.gz',
  delim=' ',
  header=false,
  quote='"'
);

-- -----------------------------------------------------------------------------
-- Step 2 — Robust parse with regex extraction (recommended)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TABLE gbot AS
SELECT
  strptime(
    regexp_extract(line, '\[([^\]]+)\]', 1),
    '%d/%b/%Y:%H:%M:%S %z'
  ) AS ts,
  regexp_extract(line, '"GET ([^ ]+)', 1) AS url,
  CAST(regexp_extract(line, '" (\d{3})', 1) AS INTEGER) AS status,
  CAST(regexp_extract(line, '\d{3} (\d+)', 1) AS INTEGER) AS bytes,
  regexp_extract(line, '"([^"]*Googlebot[^"]*)"', 1) AS user_agent
FROM read_csv_auto(
  '/var/log/nginx/access.log.gz',
  delim='',
  header=false,
  columns={'line': 'VARCHAR'}
)
WHERE line LIKE '%Googlebot%';

-- -----------------------------------------------------------------------------
-- Query A — Crawl frequency by site section, last 30 days
-- -----------------------------------------------------------------------------
SELECT
  regexp_extract(url, '^/([^/?]+)', 1) AS section,
  status,
  COUNT(*) AS hits
FROM gbot
WHERE ts > now() - INTERVAL 30 DAY
GROUP BY 1, 2
ORDER BY hits DESC;

-- -----------------------------------------------------------------------------
-- Query B — Crawl waste: % of Googlebot hits that return non-200
-- Targets (per Botify and practitioner consensus):
--   - >15% 4xx     → fix internal links / sitemaps first
--   - >25% non-canonical → consolidate via 301/canonical
-- -----------------------------------------------------------------------------
SELECT
  status,
  COUNT(*) AS hits,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct
FROM gbot
WHERE ts > now() - INTERVAL 30 DAY
GROUP BY status
ORDER BY hits DESC;

-- -----------------------------------------------------------------------------
-- Query C — Daily crawl volume trend (detect throttling or growth)
-- If median Googlebot TTFB > 600ms, Google throttles. Watch for sudden drops.
-- -----------------------------------------------------------------------------
SELECT
  date_trunc('day', ts) AS day,
  COUNT(*) AS hits,
  COUNT(DISTINCT url) AS unique_urls
FROM gbot
WHERE ts > now() - INTERVAL 90 DAY
GROUP BY 1
ORDER BY 1;

-- -----------------------------------------------------------------------------
-- Query D — Crawl ratio per template (Botify methodology)
-- Crawl ratio = unique URLs crawled in 30 days / indexable URLs in structure
-- Healthy: 60–80%. < 40% indicates serious crawl waste.
-- Requires a separate `sitemap_urls` table with your indexable inventory.
-- -----------------------------------------------------------------------------
-- SELECT
--   template,
--   COUNT(DISTINCT g.url) AS crawled,
--   COUNT(DISTINCT s.url) AS indexable,
--   ROUND(100.0 * COUNT(DISTINCT g.url) / COUNT(DISTINCT s.url), 1) AS crawl_ratio_pct
-- FROM sitemap_urls s
-- LEFT JOIN gbot g
--   ON g.url = s.url
--   AND g.ts > now() - INTERVAL 30 DAY
-- GROUP BY template
-- ORDER BY crawl_ratio_pct;

-- -----------------------------------------------------------------------------
-- Query E — Most-crawled URLs returning 4xx (immediate fix list)
-- -----------------------------------------------------------------------------
SELECT url, status, COUNT(*) AS hits
FROM gbot
WHERE ts > now() - INTERVAL 30 DAY
  AND status BETWEEN 400 AND 499
GROUP BY url, status
ORDER BY hits DESC
LIMIT 100;

-- -----------------------------------------------------------------------------
-- Query F — Detect parameter / faceted-nav crawl traps
-- -----------------------------------------------------------------------------
SELECT
  regexp_extract(url, '^([^?]+)', 1) AS base_url,
  COUNT(DISTINCT url) AS distinct_param_variants,
  COUNT(*) AS total_hits
FROM gbot
WHERE url LIKE '%?%'
  AND ts > now() - INTERVAL 30 DAY
GROUP BY base_url
HAVING distinct_param_variants > 20
ORDER BY total_hits DESC
LIMIT 50;
