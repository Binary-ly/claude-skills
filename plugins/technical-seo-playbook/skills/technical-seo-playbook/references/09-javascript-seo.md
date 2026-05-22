# 09 — JavaScript SEO Deep Dive

Covers: two-pass indexing reality in 2026, edge rendering with Cloudflare Workers / Vercel Edge with code samples, hydration mismatches that nuke rankings, client-side routing patterns that work vs don't.

---

## 9.1 Two-Pass Indexing Reality in 2026

Per Martin Splitt's 2024–2025 statements:

> "The two waves of indexing play less and less of a role. I expect eventually rendering crawling and indexing will come closer together."

However, **two-pass behavior is still observable for low-priority pages.**

### The critical December 2025 documentation change

(cited in `references/02-indexing-and-rendering.md`)

> **Non-200 status codes may skip rendering entirely.**

A CSR app that serves a 200 wrapper with JS-controlled 404 routing is **invisible to Google's rendering tier for those URLs**.

---

## 9.2 Edge Rendering — Cloudflare Workers

```js
// Render React/Preact at the edge — full HTML to bots, hydrated SPA to humans
import { renderToString } from 'preact-render-to-string'
import App from './app'

export default {
  async fetch(req) {
    const ua = req.headers.get('user-agent') || ''
    const data = await fetch(`https://api.example.com/${new URL(req.url).pathname}`).then(r => r.json())
    const html = renderToString(App({ data }))
    return new Response(`
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <title>${data.title}</title>
        <meta name="description" content="${data.description}">
        <link rel="canonical" href="${req.url}">
      </head>
      <body>
        <div id="root">${html}</div>
        <script>window.__DATA__ = ${JSON.stringify(data)}</script>
        <script type="module" src="/client.js"></script>
      </body>
      </html>
    `, { headers: { 'content-type': 'text/html', 'cache-control': 'public, s-maxage=300' } })
  }
}
```

---

## 9.3 Hydration Mismatches That Nuke Rankings

See `references/02-indexing-and-rendering.md` § 2.2 for the React 18 mechanism.

### The pattern that has cost the most rankings in client engagements

Rendering localized text **server-side via the `Accept-Language` header**, then **re-rendering client-side based on a cookie** that defaults to English. Googlebot lands on a German page server-side, hydrates to English client-side, and Google can't decide what language the page is in.

### Fix

Pin **server and client to the same source of truth** (URL-based locale, not headers/cookies).

---

## 9.4 Client-Side Routing Patterns

### Wrong (history-only, no real URL)

```jsx
// hash-based routing — Googlebot sees one URL: /
<Link to="#/products/123">Product 123</Link>
```

### Right (real URLs with SSR fallback)

```jsx
// Each route has its own crawlable URL
<Link to="/products/123">Product 123</Link>
// AND the server can render /products/123 directly
```

**Verify with `curl https://example.com/products/123`** — if the HTML contains the product name, you're correct.
