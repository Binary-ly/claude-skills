# Core Web Vitals — Definitions, Thresholds, Measurement

Sources:
- https://web.dev/articles/lcp
- https://web.dev/articles/cls
- https://web.dev/articles/inp

---

## The Three Core Web Vitals

| Metric | Good | Needs Improvement | Poor | Percentile |
|---|---|---|---|---|
| **LCP** — Largest Contentful Paint | ≤ 2.5s | 2.5s – 4.0s | > 4.0s | 75th |
| **CLS** — Cumulative Layout Shift | ≤ 0.1 | 0.1 – 0.25 | > 0.25 | 75th |
| **INP** — Interaction to Next Paint | ≤ 200ms | 200ms – 500ms | > 500ms | 75th |

All three are measured at the **75th percentile** of page loads, segmented by mobile and desktop.

---

## LCP — Largest Contentful Paint

**What it measures:** Render time of the largest visible image, text block, or video in the viewport, from when the user first navigated.

**Elements considered:**
- `<img>` elements (first frame for animated content)
- `<image>` inside `<svg>`
- `<video>` (poster image or first frame, whichever is earlier)
- Elements with `background-image: url()`
- Block-level elements containing text nodes

**Elements excluded:**
- Elements with `opacity: 0`
- Elements covering the full viewport (background elements)
- Placeholder/low-entropy images

**How size is calculated:**
- Uses visible size within viewport only (clipped/overflowing portions excluded)
- For images: smaller of visible size or intrinsic size
- For text: smallest rectangle containing all text nodes
- CSS margins, padding, and borders excluded

**LCP timing breakdown (4 sub-parts):**
- Time to First Byte (TTFB)
- Resource Load Delay
- Resource Load Duration
- Element Render Delay

The relative proportion of each sub-part varies by page. The web.dev optimization guide recommends optimizing all four.

**Measurement:**
```javascript
// Raw API
new PerformanceObserver((entryList) => {
  for (const entry of entryList.getEntries()) {
    console.log('LCP candidate:', entry.startTime, entry);
  }
}).observe({ type: 'largest-contentful-paint', buffered: true });

// Recommended — web-vitals library
import { onLCP } from 'web-vitals';
onLCP(console.log);
```

**Important caveats:**
- LCP reporting stops after user interaction (tap, scroll, keypress) — report only the most recent entry
- Render timestamps coarsened from Chrome 133 without `Timing-Allow-Origin` header
- Prerendered pages: measure from `activationStart` instead of navigation start
- Back/forward cache restorations: the Largest Contentful Paint API does not report LCP entries on bfcache restores

---

## CLS — Cumulative Layout Shift

**What it measures:** Largest burst of layout shift scores for every unexpected layout shift during the entire page lifecycle.

**Formula:**
```
Layout Shift Score = Impact Fraction × Distance Fraction
```

- **Impact Fraction:** Fraction of the viewport affected by unstable elements between frames
- **Distance Fraction:** Greatest horizontal or vertical distance any unstable element moved, divided by the viewport's largest dimension

**What triggers a layout shift:**
- Images/videos with unknown dimensions loading async
- Dynamically added DOM elements
- Fonts rendering larger/smaller than their fallback
- Third-party ads/widgets that resize themselves
- Asynchronously loaded resources

**What does NOT trigger a layout shift:**
- Adding a new element to the DOM
- An existing element changing size (only position changes count)

**User-interaction grace period:**
Shifts within **500ms of a user interaction** (tap, click, keypress) are excluded from CLS. Continuous interactions (scroll, drag, pinch) do NOT grant this grace period.

**Measurement:**
```javascript
// Raw API
new PerformanceObserver((entryList) => {
  for (const entry of entryList.getEntries()) {
    console.log('Layout shift:', entry);
  }
}).observe({ type: 'layout-shift', buffered: true });

// Recommended
import { onCLS } from 'web-vitals';
onCLS(console.log);
```

**Important caveats:**
- CLS resets to zero on back/forward cache restore
- For pages kept open indefinitely, report CLS when backgrounded (`visibilitychange` event)
- Layout Instability API does NOT report shifts within iframes (but they affect user experience)

---

## INP — Interaction to Next Paint

**What it measures:** Latency of the single worst interaction observed throughout the entire page lifecycle (with outlier removal).

**Counted interaction types:**
1. Mouse clicks
2. Touchscreen taps
3. Keyboard presses

**NOT counted:**
- Scrolling
- Hovering
- Zooming

**Three phases of every interaction:**
1. **Input delay** — time before event handlers begin (caused by blocking tasks)
2. **Processing duration** — time for all event callbacks to run
3. **Presentation delay** — time until the next frame renders

**Percentile calculation:**
- Reports 75th percentile of page views
- Ignores 1 highest interaction per 50 interactions (outlier removal)
- Most pages end up reporting their worst interaction as INP

**Measurement:**
```javascript
import { onINP } from 'web-vitals';
onINP(console.log);
```

**No INP reported when:**
- User never clicks, taps, or presses keys
- User only scrolls or hovers
- Page accessed by bots

**INP vs FID (predecessor):**
- FID measured input delay only on the first interaction
- INP observes ALL interactions throughout the page lifecycle — far more comprehensive
