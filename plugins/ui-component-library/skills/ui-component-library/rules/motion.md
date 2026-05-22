# Motion — Directional Easing and Transitions

Sources:
- https://developer.mozilla.org/en-US/docs/Web/CSS/@media/prefers-reduced-motion
- https://developer.mozilla.org/en-US/docs/Web/CSS/transition
- GPU composited properties: → See [rendering-pipeline.md](webdev-performance/rendering-pipeline.md) (within this skill), sourced from web.dev/articles/rendering-performance
- Directional easing: CSS Transitions Level 1 spec, section "Starting of transitions" — https://drafts.csswg.org/css-transitions-1/#starting (not documented by MDN)

---

## Directional Easing — Hover-In vs Hover-Out (CSS spec behavior)

CSS applies the `transition` property from the **destination state** (the spec calls it the "after-change style"), not the source state.

CSS Transitions Level 1 spec:
> "When one of these transition-* properties changes at the same time as a property whose change might transition, it is the new values of the transition-* properties that control the transition."

MDN does not explicitly document this rule. The spec is the authoritative source.

The practical consequence: you can set different easing curves for hover-in vs hover-out with zero JavaScript:

```css
/* Base rule — this is the hover-OUT destination */
/* When mouse leaves, the element transitions back using THIS easing */
:where(.btn) {
  background: var(--btn-bg);
  transition: background 0.2s cubic-bezier(0.55, 0, 1, 0.45); /* exit: accelerate out */
}

/* Hover rule — this is the hover-IN destination */
/* When mouse enters, the element transitions TO this state using THIS easing */
:where(.btn):hover {
  background: var(--btn-hover-bg, var(--btn-bg));
  transition: background 0.2s cubic-bezier(0.22, 1, 0.36, 1); /* enter: decelerate in */
}
```

---

## Recommended Easing Curves (design principle)

| Purpose | Curve | Feel |
|---|---|---|
| Hover-in, open, reveal | `cubic-bezier(0.22, 1, 0.36, 1)` | Decelerates into position |
| Hover-out, close, hide | `cubic-bezier(0.55, 0, 1, 0.45)` | Accelerates away |
| Spring / bounce | `cubic-bezier(0.34, 1.4, 0.64, 1)` | Overshoots then settles |
| Linear (progress bars) | `linear` | No ease |

---

## Token-Driven Motion (design principle)

Store easing curves and durations as CSS custom properties so themes can give a completely different motion feel without touching component code:

```css
:root {
  --ease-enter:  cubic-bezier(0.22, 1, 0.36, 1);
  --ease-exit:   cubic-bezier(0.55, 0, 1, 0.45);
  --ease-spring: cubic-bezier(0.34, 1.4, 0.64, 1);
  --duration-fast: 0.15s;
  --duration-base: 0.22s;
  --duration-slow: 0.35s;
}

:where(.btn) {
  transition: background var(--duration-base) var(--ease-exit);
}
:where(.btn):hover {
  transition: background var(--duration-base) var(--ease-enter);
}

/* A "snappy" theme just overrides the tokens */
[data-theme="snappy"] {
  --duration-base: 0.12s;
  --ease-enter: cubic-bezier(0, 0.85, 0.1, 1);
}
```

---

## `prefers-reduced-motion` (MDN)

MDN: used to detect "if a user has enabled a setting on their device to minimize the amount of non-essential motion."

**Values (MDN):**
- `no-preference` — user has made no preference known
- `reduce` — user has enabled reduced motion on their device

MDN's recommended approach: provide an alternative animation, not just suppress all motion:

```css
/* Default animation */
.animation {
  animation: pulse 1s linear infinite both;
}

/* Provide a different, less intense animation for reduced motion preference */
@media (prefers-reduced-motion: reduce) {
  .animation {
    animation: dissolve 4s linear infinite both;
  }
}
```

For decorative animations that have no accessible alternative, disable them entirely:

```css
@media (prefers-reduced-motion: reduce) {
  :where(.badge-scan)::after { animation: none; }
  :where(.card-glow) { animation: none; filter: none; }
}
```

---

## GPU-Composited Properties

Source: web.dev/articles/rendering-performance — → See [rendering-pipeline.md](webdev-performance/rendering-pipeline.md) (within this skill)

Only `transform` and `opacity` skip both Layout and Paint entirely — they run purely on the compositor thread:

| Property | Pipeline cost | Notes |
|---|---|---|
| `transform` | Composite only | Movement, scale, rotation — zero layout/paint |
| `opacity` | Composite only | Fade in/out — zero layout/paint |
| `filter` | Paint + Composite | GPU-accelerated but still triggers a paint step |
| `clip-path` | Paint + Composite | GPU in most browsers, but triggers paint |
| `background-color` | Paint + Composite | Triggers paint |
| `box-shadow` | Paint + Composite | Triggers paint |
| `width` / `height` | Full pipeline | Triggers layout → paint → composite |

For smooth 60fps, prefer animating `transform` and `opacity` — these run on the compositor thread and can't be blocked by main-thread JavaScript. Other properties trigger layout or paint, risking jank under load.
