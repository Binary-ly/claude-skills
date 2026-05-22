# Action Plans — 30/60/90 Day

Two playbooks: one for a brand-new site, one for an established site with traffic decline.

---

## A. 30/60/90-Day Plan — Brand-New Site

### Day 0–30: Foundation

- [ ] HTTPS everywhere; HSTS header; canonical host (www vs. no-www) decided and 301-enforced.
- [ ] `/robots.txt` correct for stack (see `references/01-crawl-and-log-files.md` § 1.1); GSC and Bing Webmaster Tools verified.
- [ ] XML sitemap index live, segmented by content type; submitted to GSC.
- [ ] All pages SSR or SSG — no client-side-only renders for content pages.
- [ ] Core Web Vitals measured in production via `web-vitals/attribution`; p75 targets met on initial 50 URLs.
- [ ] Structured data: Organization (with Wikidata `sameAs`), BreadcrumbList on every URL, Article on posts, Product on PDPs.
- [ ] GSC Bulk Data Export to BigQuery enabled.

### Day 31–60: Architecture

- [ ] Internal linking: every important URL ≤ 3 clicks from home.
- [ ] Hub-and-spoke topic clusters established for top 3 target topics.
- [ ] Author pages for every content producer with full `Person` markup.
- [ ] hreflang correct if multi-locale; reciprocal validation in CI.
- [ ] Log-file pipeline (DuckDB) tracking Googlebot daily.
- [ ] First 30 backlinks earned from data-asset pages.

### Day 61–90: Optimization

- [ ] CrUX p75 thresholds met across all major templates.
- [ ] Indexation rate **> 80% of submitted URLs** (GSC Coverage).
- [ ] First AI Overview citations measured (Profound, Otterly, or BrightEdge).
- [ ] Content velocity: **4+ pieces per month**, each with author markup, original data, and structured data.
- [ ] No "Discovered — currently not indexed" pages in GSC for canonical content.

---

## B. 30/60/90-Day Plan — Established Site With Traffic Decline

### Day 0–30: Diagnose

- [ ] Identify decline trigger: pull GSC clicks by day, overlay Search Engine Land update-tracker dates.
- [ ] Check GSC Manual Actions panel — **rule out manual**.
- [ ] Run full crawl (Screaming Frog or Sitebulb); export to BigQuery.
- [ ] Pull 90-day Googlebot logs; calculate crawl ratio per template (see `references/01-crawl-and-log-files.md` § 1.2). **Flag any template < 40%**.
- [ ] Audit CrUX field data per template — identify failing templates.
- [ ] Identify "Crawled — currently not indexed" cluster — flag for quality intervention.
- [ ] Identify pages that lost the most clicks vs. 12 months ago; cluster by topic.

### Day 31–60: Stop the Bleed

- [ ] HCU-style intervention: prune or improve the **worst 10–20% of pages** (measure traffic + quality, don't blanket-delete).
- [ ] Fix all CWV-failing templates; deploy and validate in GSC.
- [ ] Rebuild internal linking around remaining strong pages.
- [ ] Audit and remove site reputation abuse risks (third-party coupon/review subfolders).
- [ ] Update YMYL pages with current dates, expert reviewers, citations.
- [ ] Repair broken hreflang reciprocity; remove hreflang on non-indexable URLs.

### Day 61–90: Rebuild

- [ ] Refresh **top 50 declining pages** with new data, current dates, expanded author E-E-A-T markup.
- [ ] Build **3–5 new data-asset pages** targeting industry citation patterns.
- [ ] Submit reconsideration request if a manual action exists.
- [ ] Measure: GSC impressions for refreshed pages should lift within 30 days; **click recovery typically lags 60–90 days on HCU-hit content**.
- [ ] If still declining at day 90 with no documented update: **deeper content/quality audit; the issue is rarely technical at this stage**.
