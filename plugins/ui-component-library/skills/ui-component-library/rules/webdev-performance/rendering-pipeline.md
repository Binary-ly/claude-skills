# Rendering Pipeline — How Browsers Paint Pixels

Sources:
- https://web.dev/articles/rendering-performance
- https://web.dev/articles/stick-to-compositor-only-properties-and-manage-layer-count
- https://web.dev/articles/animations-guide

---

## The Pixel Pipeline — 5 Stages

The browser renders frames through up to 5 stages. Each property change triggers a different subset:

```
JavaScript/CSS → Style → Layout → Paint → Composite
```

| Stage | What happens |
|---|---|
| **JavaScript / CSS** | Visual changes via DOM manipulation, animations, CSS transitions |
| **Style** | Selector matching + computing which CSS rules apply to each element |
| **Layout** | Calculating geometry — dimensions, positions. Cascades through DOM. |
| **Paint** | Filling pixels: text, colors, images, borders, shadows onto layers |
| **Composite** | Assembling layers onto screen in correct order |

---

## Three Execution Paths (fastest to slowest)

### Path 1 — Full pipeline (slowest)
**Triggered by:** changes to geometry (width, height, top, left, margin, padding, font-size)
```
JS/CSS → Style → Layout → Paint → Composite
```
Examples: `width`, `height`, `margin`, `padding`, `border`, `font-size`, `left`, `top`

### Path 2 — Skip Layout
**Triggered by:** visual-only changes that don't affect geometry
```
JS/CSS → Style → Paint → Composite
```
Examples: `color`, `background-color`, `box-shadow`, `border-color`, `visibility`

### Path 3 — Composite only (fastest, GPU)
**Triggered by:** only two CSS properties
```
JS/CSS → Style → Composite
```
Properties: **`transform`** and **`opacity`** — the ONLY two properties that skip both layout AND paint

---

## Frame Rate Budget

- **Target:** 60 frames per second (most displays)
- **Time per frame:** 16.66ms
- **Available budget after browser overhead:** ~10ms per frame for your work
- **Long task threshold:** 50ms (any task over this blocks the main thread visibly)

---

## Compositor-Only Properties — The Golden Rule

Only animate `transform` and `opacity` for smooth 60fps animations. Everything else risks triggering layout or paint:

```css
/* CORRECT — compositor only, GPU-accelerated, 60fps */
.element { animation: slide 0.3s ease-out; }
@keyframes slide {
  from { transform: translateX(-100px); opacity: 0; }
  to   { transform: translateX(0);      opacity: 1; }
}

/* WRONG — triggers layout on every frame, causes jank */
@keyframes slide-bad {
  from { left: -100px; }
  to   { left: 0; }
}
```

Animating with `transform` stays on the compositor thread (no layout/paint). Animating with `top`/`left` triggers full pipeline on every frame, causing visible jank.

---

## Layer Management — `will-change`

**What it does:** Promotes element to its own compositor layer, pre-allocating GPU resources.

```css
/* Correct — promote only what you'll animate */
.will-animate { will-change: transform; }

/* Legacy fallback for browsers without will-change support */
.will-animate { transform: translateZ(0); }
```

**Critical rules:**
1. **Only promote elements you will actually animate.** Every promoted layer requires CPU→GPU bandwidth and GPU texture memory.
2. **Compositing target: 4–5ms** during scrolling and transitions (keep layer count low to stay within this budget)
3. **Never do this:**
```css
/* WRONG — "layer explosion", wastes GPU memory for every element */
* { will-change: transform; transform: translateZ(0); }
```

**Memory consequence:** Each layer consumes GPU memory. On memory-constrained devices (mobile), excessive layer promotion ("layer explosion") causes worse performance than no promotion.

---

## Transform Operations Reference

All of these stay on the compositor thread:

```css
/* Movement — use transform, never top/left */
transform: translateX(100px);
transform: translateY(-50px);
transform: translate(10px, 20px);

/* Scale — use transform, never width/height */
transform: scale(1.5);
transform: scaleX(2);

/* Rotation */
transform: rotate(45deg);
transform: rotate3d(1, 0, 0, 45deg);

/* Visibility — use opacity */
opacity: 0;
opacity: 1;
```

---

## Debugging Tools

**Chrome DevTools Performance panel:**
- Paint flashing: highlights regions being repainted (should be minimal)
- Layer panel: inspect layer tree and creation reasons
- FPS meter: target 99% frame retention

**Identify layout triggers:**
- Purple events in Timeline = Style/Layout
- Green events = Paint
- Composite only = no color spike
