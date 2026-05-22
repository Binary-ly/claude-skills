# Optimizing LCP, CLS, and INP

Sources:
- https://web.dev/articles/optimize-lcp
- https://web.dev/articles/optimize-cls
- https://web.dev/explore/how-to-optimize-inp

---

## LCP Optimization — 4-Step Framework

Target: ≤ 2.5s for 75% of page visits. LCP has 4 sub-parts; optimize all 4.

### Step 1 — Eliminate Resource Load Delay

Make the LCP resource discoverable as early as possible in the HTML.

**Preload with high priority:**
```html
<link rel="preload" fetchpriority="high" as="image"
      href="/hero-image.webp" type="image/webp">
```

**Fetchpriority attribute:**
```html
<!-- High priority for LCP image -->
<img fetchpriority="high" src="/hero-image.webp" alt="Hero">

<!-- Low priority for below-fold/carousel images -->
<img fetchpriority="low" src="/carousel-3.webp" alt="Slide 3">
```

**Anti-patterns — avoid these on the LCP image (each adds unnecessary latency):**
- `loading="lazy"` — always adds unnecessary delay
- `data-src` (lazy-load plugins) — hides src from browser's preload scanner
- Dynamically adding the LCP image via JavaScript
- CSS background images that aren't preloaded

### Step 2 — Eliminate Element Render Delay

Ensure the LCP element renders immediately after its resource finishes loading.

**Reduce render-blocking CSS:**
```html
<!-- Inline critical CSS -->
<style>
  /* Only above-the-fold styles — keep tiny */
  .hero { ... }
</style>

<!-- Defer non-critical CSS (load asynchronously) -->
<link rel="stylesheet" href="/non-critical.css" media="print" onload="this.media='all'">
<!-- Note: this media="print" technique is a common pattern for deferring CSS;
     the web.dev optimize-lcp article focuses on inlining critical CSS and
     minimizing render-blocking stylesheets -->
```

**Make scripts non-blocking:**
```html
<!-- WRONG — synchronous script in head blocks rendering -->
<head><script src="main.js"></script></head>

<!-- CORRECT — async or defer -->
<script src="main.js" defer></script>
<script src="analytics.js" async></script>
```

> "It is almost never necessary to add synchronous scripts to the `<head>` (except in specific use cases such as loading polyfills or defer/async scripts)."

**SSR / SSG:** Server-side rendering makes images discoverable in HTML source and eliminates JavaScript dependency for LCP content.

### Step 3 — Reduce Resource Load Duration

**Modern image formats:**
```html
<picture>
  <source type="image/avif" srcset="/hero.avif">
  <source type="image/webp" srcset="/hero.webp">
  <img src="/hero.jpg" fetchpriority="high" alt="Hero">
</picture>
```

**Responsive images with correct dimensions:**
```html
<img
  src="/hero-800.webp"
  srcset="/hero-400.webp 400w, /hero-800.webp 800w, /hero-1600.webp 1600w"
  sizes="(max-width: 600px) 400px, (max-width: 1200px) 800px, 1600px"
  fetchpriority="high"
  alt="Hero"
>
```

**Font-display for web fonts:**
```css
@font-face {
  font-family: 'MyFont';
  src: url('/fonts/myfont.woff2') format('woff2');
  font-display: swap; /* text visible during load */
}
```

**CDN + caching:** Serve LCP images from a CDN. Cached resources have ~zero load duration on repeat visits.

### Step 4 — Reduce TTFB

- Minimize redirect chains
- Avoid unique URL parameters (e.g., analytics UTM) on resources — they prevent CDN caching
- Use a CDN close to the user

---

## CLS Optimization

Target: ≤ 0.1 for 75% of page visits.

### Rule 1 — Always Set `width` and `height` on Images

```html
<!-- CORRECT — browser reserves space before image loads -->
<img src="hero.jpg" width="1200" height="800" alt="Hero">
```

```css
/* Pair with this CSS for responsive behavior */
img { height: auto; width: 100%; }
```

The browser auto-computes an aspect ratio from the `width` and `height` attributes, reserving correct space before the image loads.

**Responsive images:**
```html
<img
  src="puppy-800.jpg"
  srcset="puppy-400.jpg 400w, puppy-800.jpg 800w, puppy-1600.jpg 1600w"
  width="800" height="600"
  alt="Puppy"
/>
```

**Art direction with `<picture>`:**
```html
<picture>
  <source media="(max-width: 799px)" srcset="mobile-crop.jpg" width="480" height="400" />
  <source media="(min-width: 800px)" srcset="desktop.jpg" width="800" height="400" />
  <img src="desktop.jpg" alt="..." width="800" height="400" />
</picture>
```

### Rule 2 — Reserve Space for Ads, Embeds, Late-Loading Content

```css
/* Reserve minimum space so content doesn't shift when ad loads */
.ad-slot {
  min-height: 250px;
}

/* Or use aspect-ratio */
.video-embed {
  aspect-ratio: 16 / 9;
}

/* Responsive ad slots */
@media (max-width: 480px) { .ad-slot { min-height: 120px; } }
@media (min-width: 481px) { .ad-slot { min-height: 250px; } }
```

**Never collapse reserved space** when no content loads — show a placeholder instead.

### Rule 3 — Manage Dynamic Content Loading

User-initiated loads (within 500ms of interaction) don't count toward CLS.

**Pattern A — Load on user action:**
```html
<button id="load-more">Load more</button>
```
Content inserted within 500ms of the click = no CLS impact.

**Pattern B — Fixed-size container / carousel:**
- Replace old content with new in a fixed-size container
- Disable links during transition
- Remove old content after animation

**Pattern C — Off-screen loading with notification:**
- Load new content off-screen
- Show a "New content available — scroll to top" notification
- User decides when to reveal

### Rule 4 — Web Font Optimization for CLS

Use `font-display: optional` for zero-CLS, or `font-display: swap` with metric overrides (`size-adjust`, `ascent-override`, etc.) to minimize shift. Preload critical fonts to reduce load time.

-> See [fonts-and-assets.md](fonts-and-assets.md) for font-display strategies, metric overrides, and subsetting.

### Rule 5 — Use CSS Transforms for Animations (Never Layout Properties)

Always animate `transform` and `opacity` (compositor-only properties) instead of layout-triggering properties like `top`, `left`, `width`, or `height`. Layout-triggering animations cause CLS and are far more expensive.

-> See [rendering-pipeline.md](rendering-pipeline.md) for the full compositor-only animation guide and pipeline stages.

### Rule 6 — Back/Forward Cache (bfcache)

Pages restored from bfcache show no layout shifts on navigation. Avoid bfcache-blocking APIs (unload event listeners) to maximize bfcache eligibility.

---

## INP Optimization

Target: ≤ 200ms for 75% of page visits.

### Three categories of work to optimize:

**1. Input delay** — reduce blocking tasks before event handlers run
- Break up long tasks with `scheduler.yield()`
- Debounce timers, cancel fetch requests on rapid input
- Use CSS animations instead of JS animations

**2. Processing duration** — reduce work inside event handlers
- Batch DOM reads/writes (avoid layout thrashing)
- Avoid large style recalculations (simplify CSS selectors)
- Reduce DOM size (< 800 nodes ideal, < 1,400 nodes required)

**3. Presentation delay** — reduce time to next frame after handlers run
- Avoid triggering Layout (use transform/opacity)
- Use `content-visibility: auto` on off-screen sections
- Apply `contain: layout style` to complex widgets

-> See [long-tasks.md](long-tasks.md) for the full task-breaking guide with scheduler.yield(), requestIdleCallback, and script optimization.

### Real-world INP improvements (from web.dev case studies):
- QuintoAndar: 80% INP reduction → 36% more conversions
- Disney+ Hotstar: 61% INP reduction → 100% more weekly card views
- Trendyol: 50% INP reduction → 1% CTR uplift
