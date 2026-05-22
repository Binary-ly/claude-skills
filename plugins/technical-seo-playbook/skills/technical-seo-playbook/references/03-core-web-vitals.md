# 03 — Core Web Vitals — Engineering, Not Advice

Covers: LCP, INP, CLS — official thresholds, the engineering patterns that actually move them, and PerformanceObserver JS for production monitoring.

---

## 3.0 Official Thresholds (May 2026)

Per Google's `developers.google.com/search/docs/appearance/core-web-vitals` (last updated 2025-12-10):

- **LCP < 2.5s** (good); 2.5–4s needs improvement; >4s poor
- **INP < 200ms** (good); 200–500ms needs improvement; >500ms poor — **INP replaced FID on March 12, 2024**
- **CLS < 0.1** (good); 0.1–0.25 needs improvement; >0.25 poor

Measured at **p75 across a 28-day rolling window** from the Chrome User Experience Report (CrUX). **Lab metrics (Lighthouse) do not feed the ranking signal.**

> ⚠️ **Treat with caution**: Some third-party reports claim Google tightened LCP to 2.0s in a "March 2026" update; **this is not in Google's documentation as of May 2026** and should be treated as speculation until officially confirmed.

---

## 3.1 LCP < 2.5s — Engineering Patterns

### The four phases of LCP (per Barry Pollard, web.dev)

1. **TTFB** — server response
2. **Resource load delay** — discovery time
3. **Resource load duration** — bytes over wire
4. **Element render delay** — main-thread blocking after load

### Preload the LCP image AND set `fetchpriority="high"`

```html
<!-- in <head>, before any blocking script -->
<link rel="preload" as="image" href="/hero.avif"
      imagesrcset="/hero.avif 1x, /hero-2x.avif 2x"
      imagesizes="100vw"
      fetchpriority="high">

<!-- in <body> -->
<img src="/hero.avif" alt="..." width="1200" height="600"
     fetchpriority="high" loading="eager"
     srcset="/hero.avif 1x, /hero-2x.avif 2x">
```

The `fetchpriority="high"` attribute reached **Baseline 2024** (interoperable across all modern browsers) and tells the browser to upgrade this resource's priority — a measurable LCP win.

### Critical CSS extraction (Astro example)

```js
// astro.config.mjs
import { defineConfig } from 'astro/config'
import critters from 'astro-critters'
export default defineConfig({
  integrations: [critters({ preload: 'swap', logLevel: 'info' })],
})
```

Inline critical (above-the-fold) CSS, async-load the rest. **Target: critical CSS < 14 KB** to fit inside the initial TCP slow-start congestion window.

### Font loading — `font-display: swap` is correct, but watch for FOIT-induced CLS

```css
@font-face {
  font-family: 'Inter';
  src: url('/fonts/Inter-var.woff2') format('woff2-variations');
  font-weight: 100 900;
  font-display: swap;            /* render fallback immediately, swap when ready */
  size-adjust: 107%;             /* match fallback metrics — eliminates layout shift */
  ascent-override: 90%;
  descent-override: 22%;
  line-gap-override: 0%;
}
```

Preload the woff2 file from `<head>` to cut load delay:

```html
<link rel="preload" href="/fonts/Inter-var.woff2" as="font" type="font/woff2" crossorigin>
```

### Image format decision matrix (2026 reality)

| Format | Browser support | Compression vs JPEG | When to use |
|---|---|---|---|
| **AVIF** | Baseline since 2024 (all modern browsers) | ~50% smaller | Default for new sites |
| **WebP** | Universal | ~25–35% smaller | Safe fallback for legacy support |
| **JPEG XL** | Chrome dropped support in 2023; Safari only | Best quality/size | Niche; not worth it |
| **JPEG** | Universal | Baseline | Fallback only |

Serve with `<picture>`:

```html
<picture>
  <source srcset="/img.avif" type="image/avif">
  <source srcset="/img.webp" type="image/webp">
  <img src="/img.jpg" alt="..." width="800" height="600" loading="lazy">
</picture>
```

### CDN config — Cloudflare cache-everything for static assets

```
# Page Rule
Cache Level: Cache Everything
Edge Cache TTL: 1 month
Browser Cache TTL: 1 year (for hashed assets)
```

For HTML, set `Cache-Control: public, s-maxage=3600, stale-while-revalidate=86400` and trust the CDN to absorb traffic spikes.

---

## 3.2 INP < 200ms — Long-Task Breakup

Per web.dev's published CrUX summaries, INP is the most commonly failed Core Web Vital — independent practitioner readings of CrUX data in early 2026 put global INP "good" pass rates at **~87% of origins**, LCP at **68.3%**, and CLS at **80.9%**, with only **55.7% of origins passing all three** (DebugBear/whitehat-seo.co.uk syntheses, January 2026 CrUX).

### The breakup pattern with `scheduler.yield()` (Baseline 2024)

```js
// ❌ Long task — single 1000ms block
function processAll(items) {
  for (const item of items) processItem(item)
}

// ✅ Yielding pattern — keeps p75 INP < 50ms even with heavy work
async function processAll(items) {
  for (let i = 0; i < items.length; i++) {
    processItem(items[i])
    if (i % 50 === 0) {
      await scheduler.yield?.() ?? new Promise(r => setTimeout(r, 0))
    }
  }
}
```

The `scheduler.yield()` continuation runs at a **higher priority than queued tasks**, so your work resumes before new third-party scripts cut in line.

### 50 ms batches (per Lee Robinson's tested pattern, 2024 Web Performance Calendar)

```js
const BATCH_DURATION = 50 // ms
let lastYield = performance.now()
function shouldYield() {
  if (performance.now() - lastYield > BATCH_DURATION) {
    lastYield = performance.now()
    return true
  }
  return false
}
async function handleClick() {
  for (const item of items) {
    if (shouldYield()) await scheduler.yield()
    process(item)
  }
}
```

### Defer analytics/tracking until after paint (saves 20–100 ms INP)

```js
// ❌ Synchronous dataLayer.push inside click handler
btn.addEventListener('click', () => {
  updateUI()
  dataLayer.push({ event: 'click', /* ... */ }) // blocks paint
})

// ✅ Schedule after the browser paints
btn.addEventListener('click', () => {
  updateUI()
  requestAnimationFrame(() => {
    requestAnimationFrame(() => {
      dataLayer.push({ event: 'click', /* ... */ })
    })
  })
})
```

**Real-world impact** — per Arjen Karel's documented case study at Subito (Italy's largest classifieds marketplace): disabling a single TikTok tracking script loaded via GTM dropped INP from **208 ms to roughly 170 ms** — a single script worth 38 ms.

### Web Worker offload for heavy parse/compute

```js
// main.js
const worker = new Worker('/parser.js')
worker.postMessage({ csv: largeFile })
worker.onmessage = (e) => render(e.data.rows)

// parser.js
self.onmessage = ({ data }) => {
  const rows = parseCSV(data.csv) // never blocks main thread
  self.postMessage({ rows })
}
```

---

## 3.3 CLS < 0.1

### Always set explicit dimensions

```html
<img src="/p.jpg" alt="" width="800" height="600">
<iframe src="..." width="560" height="315"></iframe>
<video width="1280" height="720" poster="/poster.jpg" preload="metadata"></video>
```

### Use `aspect-ratio` for responsive containers

```css
.media {
  aspect-ratio: 16 / 9;
  width: 100%;
}
```

### Reserve space for ads

```html
<div class="ad-slot" style="min-height: 250px;">
  <!-- 300x250 ad will inject here -->
</div>
```

### Font-induced shift

Use `size-adjust` (see § 3.1) or the `font-size-adjust: ex-height 0.5;` declaration to match x-heights between fallback and webfont.

---

## 3.4 PerformanceObserver — Production Monitoring

```js
// LCP
new PerformanceObserver((entryList) => {
  const entries = entryList.getEntries()
  const lcp = entries[entries.length - 1]
  navigator.sendBeacon('/vitals', JSON.stringify({
    metric: 'LCP', value: lcp.startTime, element: lcp.element?.tagName, url: location.pathname
  }))
}).observe({ type: 'largest-contentful-paint', buffered: true })

// CLS (session-windowed per Google's spec)
let cls = 0, sessionValue = 0, sessionEntries = []
new PerformanceObserver((list) => {
  for (const entry of list.getEntries()) {
    if (entry.hadRecentInput) continue
    const first = sessionEntries[0]
    const last  = sessionEntries[sessionEntries.length - 1]
    if (sessionValue && entry.startTime - last.startTime < 1000 && entry.startTime - first.startTime < 5000) {
      sessionValue += entry.value; sessionEntries.push(entry)
    } else {
      sessionValue = entry.value; sessionEntries = [entry]
    }
    if (sessionValue > cls) {
      cls = sessionValue
      navigator.sendBeacon('/vitals', JSON.stringify({ metric: 'CLS', value: cls, url: location.pathname }))
    }
  }
}).observe({ type: 'layout-shift', buffered: true })

// INP — easier with the official web-vitals library
import { onINP, onLCP, onCLS } from 'web-vitals/attribution'
onINP(({ value, attribution }) => {
  navigator.sendBeacon('/vitals', JSON.stringify({
    metric: 'INP', value,
    target: attribution.interactionTarget,
    type: attribution.interactionType,
    longest: attribution.longestScript?.invoker
  }))
})
```

The `web-vitals/attribution` build (v4+) tells you **exactly which element/script caused the bad INP** — far more useful than the raw number.

### Common mistakes (CWV)

- **Optimizing the Lighthouse score** instead of CrUX field data. Only field data is the ranking signal.
- **Treating CLS as a one-time fix.** It accumulates across the page lifetime; ads loaded after first paint can spike it.
- **Using `loading="lazy"` on the LCP image. Never.** It defers the most important asset.
