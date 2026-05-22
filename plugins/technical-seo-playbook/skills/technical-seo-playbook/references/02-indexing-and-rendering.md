# 02 — Indexing & Rendering

Covers: SSR/SSG/ISR/CSR Googlebot behavior with measured indexation lag, hydration patterns that break SEO, dynamic and edge rendering, soft-404 detection and fixes, GSC Index Coverage remediation per error type.

---

## 2.1 SSR vs SSG vs ISR vs CSR — Googlebot Behavior

Per Martin Splitt's January 2025 Search Central Lightning Talk and the December 2025 update to Google's JavaScript SEO docs:

| Strategy | First-byte content | Render cost to Google | Indexation lag | Best for |
|---|---|---|---|---|
| **SSG** (Astro, Next `output: 'export'`) | Full HTML | None | Hours | Marketing pages, blogs |
| **SSR** (Next `app/`, Remix) | Full HTML | Negligible | Hours | E-commerce PDPs, news |
| **ISR** (Next `revalidate`) | Cached HTML, revalidated on demand | Negligible | Hours; depends on revalidate window | Large catalogs |
| **CSR** (Vite/CRA SPA) | Empty `<div id="root">` | Full render queue | Onely's documented experiments showed ~9× longer than HTML, with deep JS pages observed at up to 313 hours vs 36 hours for HTML | Authenticated apps only |

### Measured indexation lag

Per Onely's TGIF research: **60% of JavaScript content is indexed within 24 hours of HTML indexing; 32% remains unindexed after 30 days.** Splitt's "5-second median rendering" claim from Google I/O 2019 has been challenged repeatedly by independent studies and now refers to the **render step only**, not the full gap between crawl and render.

### Critical December 2025 documentation change from Google

> "All pages with a 200 HTTP status code are sent to the rendering queue. If the HTTP status code is non-200 (for example, on error pages with 404 status code), rendering might be skipped."

A CSR app that returns 200 with an empty body and then JS-redirects on 404 will have Google index the empty body. **The fix is server-side status codes, not client-side routing.**

---

## 2.2 Hydration Patterns That Break SEO

### Wrong — CSR-only conditional render

```jsx
// ❌ Content does not exist in initial HTML; Google sees an empty <main>
function ProductPage() {
  const [product, setProduct] = useState(null)
  useEffect(() => { fetch(`/api/p/${id}`).then(r => r.json()).then(setProduct) }, [])
  if (!product) return <Skeleton />
  return <main><h1>{product.name}</h1><p>{product.description}</p></main>
}
```

### Right — SSR with hydration in Next.js App Router

```tsx
// app/p/[slug]/page.tsx — server component, content in initial HTML
export async function generateMetadata({ params }) {
  const p = await getProduct(params.slug)
  return { title: p.title, description: p.description }
}
export default async function Page({ params }) {
  const product = await getProduct(params.slug)
  return (
    <main>
      <h1>{product.name}</h1>
      <p>{product.description}</p>
      <AddToCartButton id={product.id} /> {/* client component, hydrated */}
    </main>
  )
}
```

### Hydration mismatch — the silent ranking killer

When server-rendered HTML disagrees with client-rendered output, **React (since v18) re-renders the client tree and discards the server tree silently**. Googlebot already cached the server HTML; the discrepancy can cause "Crawled — currently not indexed" if Google later re-renders and finds different content.

Common culprits:
- `new Date()`
- `Math.random()`
- Locale/timezone-dependent output
- A/B test code running before hydration

### Fix pattern (Next.js)

```tsx
'use client'
import { useEffect, useState } from 'react'

export function ClientOnlyDate() {
  const [date, setDate] = useState<string | null>(null)
  useEffect(() => { setDate(new Date().toLocaleString()) }, [])
  return <span>{date ?? ''}</span> // empty on server, populated after hydration
}
```

---

## 2.3 Dynamic Rendering, Edge Rendering, Prerender Patterns

Google **deprecated dynamic rendering as a long-term solution in 2022**. Use SSR, SSG, or ISR. Edge rendering (Cloudflare Workers, Vercel Edge) is the modern replacement.

### Cloudflare Worker — Edge SSR with cache and bot detection

```js
export default {
  async fetch(req, env, ctx) {
    const ua = req.headers.get('user-agent') || ''
    const isBot = /googlebot|bingbot|gptbot|claudebot|perplexitybot/i.test(ua)
    const cache = caches.default
    const cacheKey = new Request(req.url, req)

    let res = await cache.match(cacheKey)
    if (!res) {
      res = await fetch(req)
      const ttl = isBot ? 3600 : 300
      const headers = new Headers(res.headers)
      headers.set('Cache-Control', `public, max-age=${ttl}`)
      res = new Response(res.body, { ...res, headers })
      ctx.waitUntil(cache.put(cacheKey, res.clone()))
    }
    return res
  }
}
```

---

## 2.4 Soft-404 Detection and Fixes

Google's algorithm flags soft 404s when a page returns 200 but contains "Page Not Found" semantics, has thin content, or redirects to an irrelevant destination (for example, a discontinued PDP → homepage).

### Detection (DuckDB over your crawl)

```sql
SELECT url, http_status, content_length, title
FROM crawl
WHERE http_status = 200
  AND (content_length < 5000
       OR title ILIKE '%not found%'
       OR title ILIKE '%error%')
ORDER BY content_length;
```

### Fixes

- **Deleted PDPs** → return **410 Gone**, not 200 with "out of stock" text.
- **Empty category pages** → either populate with content or 301 to the parent.
- **Redirected deleted pages** → must redirect to a *relevant* page; a blanket redirect to `/` triggers soft 404.

---

## 2.5 GSC Index Coverage — Remediation Per Error Type

| GSC status | Meaning | Fix |
|---|---|---|
| **Crawled — currently not indexed** | Google crawled but chose not to index | Quality signal. Improve content depth, internal links, E-E-A-T. |
| **Discovered — currently not indexed** | URL in queue, not yet crawled | Crawl-budget issue. Reduce low-value URLs, speed up TTFB. |
| **Duplicate without user-selected canonical** | Google picked a different canonical | Add `rel=canonical` to the version you want. |
| **Duplicate, Google chose different canonical** | Your canonical is being overridden | Increase signal alignment: internal links, sitemap, hreflang must all agree. |
| **Submitted URL not selected as canonical** | Sitemap says X, Google picks Y | Same fix. Audit hreflang/canonical conflicts. |
| **Excluded by 'noindex' tag** | Working as intended OR misconfig | Verify intent — accidental noindex on staging shipped to prod is the #1 outage cause. |
| **Soft 404** | See § 2.4 | Return correct status code or improve content. |
| **Page with redirect** | URL redirects, won't be indexed | Update internal links to the redirect target directly. |
| **Server error (5xx)** | Crawler got a 5xx | Server capacity / app stability issue. |
| **Blocked by robots.txt** | Crawl blocked | If you wanted it indexed, unblock; if not, use noindex instead. |

### Common mistakes (indexing)

- **Trusting Lighthouse's "Indexability" pass** — it can't tell you if Google has actually chosen to index. Only the URL Inspection API can.
- **Using `noindex,follow` on canonical pages thinking it preserves link equity.** Per Mueller (2019, repeated since), long-term `noindex,follow` is treated as `noindex,nofollow`.
