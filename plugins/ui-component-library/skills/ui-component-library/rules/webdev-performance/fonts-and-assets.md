# Fonts, Images & Resource Hints

Sources:
- https://web.dev/articles/font-best-practices
- https://web.dev/articles/optimize-lcp (image section)
- https://web.dev/articles/preconnect-and-dns-prefetch
- https://web.dev/articles/preload-critical-assets

---

## Font Performance — Key Numbers

| Property | Threshold |
|---|---|
| Default text block period (Chromium/Firefox) | Up to 3 seconds |
| Default text block period (Safari) | Indefinite |
| `font-display: block` block period | Up to 3 seconds |
| `font-display: swap` block period | 0ms |
| `font-display: fallback` block period | 100ms |
| `font-display: fallback` swap period | 3 seconds |
| `font-display: optional` swap period | 0ms (no swap) |
| WOFF2 vs WOFF compression | Compresses 30% better |
| Latin font glyph count | 100–1,000 |
| CJK font glyph count | 10,000+ |

---

## `@font-face` Best Practices

**Recommended minimal declaration:**
```css
@font-face {
  font-family: 'MyFont';
  src: url('/fonts/myfont.woff2') format('woff2');
  /* WOFF2 only — widest modern browser support, best compression */
}
```

**Unicode range subsetting:**
```css
@font-face {
  font-family: 'MyFont';
  src: url('/fonts/myfont-latin.woff2') format('woff2');
  unicode-range: U+0025-00FF; /* only load for pages using these characters */
}
```
Browser only downloads the file if the page contains characters in the specified range.

---

## `font-display` Strategy Guide

```css
/* Option 1: optional — best for performance, worst for web-font guarantee */
/* Font used only if available before first layout; fallback otherwise. No CLS. */
@font-face {
  font-family: 'MyFont';
  src: url('/fonts/myfont.woff2') format('woff2');
  font-display: optional;
}

/* Option 2: swap — shows fallback text immediately, swaps when font loads */
/* Risk: CLS if fallback and web font differ significantly in size */
@font-face {
  font-family: 'MyFont';
  src: url('/fonts/myfont.woff2') format('woff2');
  font-display: swap;
}

/* Option 3: fallback — 100ms block, 3s swap window, then fallback permanently */
/* Balance between swap and optional */
@font-face {
  font-family: 'MyFont';
  src: url('/fonts/myfont.woff2') format('woff2');
  font-display: fallback;
}
```

**Minimize CLS on `swap` with metric overrides:**
```css
@font-face {
  font-family: 'MyFont';
  src: url('/fonts/myfont.woff2') format('woff2');
  font-display: swap;
  /* Adjust fallback font metrics to match web font size */
  size-adjust: 90%;
  ascent-override: 110%;
  descent-override: 30%;
  line-gap-override: 5%;
}
```

---

## Font Loading — Resource Hints

**Preconnect for third-party font hosts:**
```html
<!-- Establish connection early (DNS + TCP + TLS) -->
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<!-- crossorigin required because fonts use CORS -->
```

**Preload for self-hosted critical fonts:**
```html
<link rel="preload" as="font"
      href="/fonts/myfont.woff2"
      type="font/woff2"
      crossorigin>
```

**Important misconception:**
> "A font downloads when `@font-face` is encountered" — this is WRONG.
Fonts download only when they are referenced by a CSS rule that **matches a visible element**. An `@font-face` declaration alone downloads nothing.

---

## Font Anti-Patterns

| Anti-pattern | Problem | Fix |
|---|---|---|
| No fallback in font stack | Browser defaults to Times New Roman | Always specify `sans-serif` or `monospace` fallback |
| `preload` every font | Bypasses browser's normal prioritization; competes with other critical resources | Preload only the critical above-fold font |
| Icon fonts | Fallback chars convey wrong meaning, accessibility issues | Use inline SVG or SVG sprites instead |
| Multiple weight/style files for variable fonts | Larger total size than one variable font file | Use variable fonts with `font-variation-settings` |
| Self-hosted without CDN/HTTP2 | Slower than third-party providers | Add CDN and ensure HTTP/2 multiplexing |

---

## Image Performance

**Format selection:**
```html
<!-- Modern format with fallback -->
<picture>
  <source type="image/avif" srcset="/image.avif">
  <source type="image/webp" srcset="/image.webp">
  <img src="/image.jpg" alt="Description" width="800" height="600">
</picture>
```

**Lazy loading (for non-LCP images only):**
```html
<!-- WRONG: loading="lazy" delays the LCP image fetch -->
<img src="/below-fold.jpg" loading="lazy" width="400" height="300" alt="...">
```

**Always provide dimensions to prevent CLS:**
```html
<img src="/image.jpg" width="800" height="600" alt="...">
```
```css
img { height: auto; width: 100%; } /* responsive while preserving aspect ratio */
```

**Fetchpriority for LCP image:**
```html
<img src="/hero.webp" fetchpriority="high" width="1200" height="600" alt="Hero">
```

---

## Resource Hints Reference

```html
<!-- dns-prefetch: resolve DNS only (cheapest, widest support) -->
<link rel="dns-prefetch" href="https://cdn.example.com">

<!-- preconnect: DNS + TCP + TLS handshake (for resources you'll use soon) -->
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>

<!-- preload: high-priority fetch, required for current page (LCP image, critical font) -->
<link rel="preload" as="image" href="/hero.webp" fetchpriority="high">
<link rel="preload" as="font" href="/fonts/main.woff2" type="font/woff2" crossorigin>
<link rel="preload" as="style" href="/critical.css">

<!-- prefetch: low-priority fetch for next page navigation -->
<link rel="prefetch" href="/next-page.html">

<!-- modulepreload: preload ES module + its dependencies (avoids request chains) -->
<link rel="modulepreload" href="/modules/feature.js">
```

**When to use each:**
| Hint | Use when | Risk if overused |
|---|---|---|
| `dns-prefetch` | Third-party origins you'll connect to | Minimal |
| `preconnect` | Origins you'll fetch from within 1–2s | Wastes connection if unused |
| `preload` | Resources critical for current page | Competes with other resources, bandwidth waste |
| `prefetch` | Resources for next navigation | Wastes bandwidth if user doesn't navigate there |
| `modulepreload` | ES module entry points | Bandwidth waste if module unused |
