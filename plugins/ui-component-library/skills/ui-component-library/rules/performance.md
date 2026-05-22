# Performance — Rendering, Containment, GPU

Sources:
- https://developer.mozilla.org/en-US/docs/Web/CSS/contain
- https://developer.mozilla.org/en-US/docs/Web/CSS/content-visibility
- https://developer.mozilla.org/en-US/docs/Web/CSS/will-change
- https://developer.mozilla.org/en-US/docs/Web/CSS/clip-path
- https://developer.mozilla.org/en-US/docs/Web/CSS/filter-function/drop-shadow
- https://developer.mozilla.org/en-US/docs/Web/CSS/Containing_block

---

## `contain` — Scope Browser Recalculations (MDN)

**`contain: layout`** (MDN):
> "The internal layout of the element is isolated from the rest of the page. This means nothing outside the element affects its internal layout, and vice versa."

**`contain: style`** (MDN):
> "For properties that can affect more than just an element and its descendants, the effects don't escape the containing element. Counters and quotes are scoped to the element and its contents."

**`contain: paint`** (MDN):
> "Descendants of the element don't display outside its bounds... If a descendant overflows the containing element's bounds, then that descendant will be clipped to the containing element's border-box."

```css
.card {
  contain: layout style;
  /* NOT contain: paint — see warning below */
}
```

Avoid `contain: paint` on components with pseudo-elements or decorations that draw outside the border-box — MDN confirms `paint` containment clips all overflow to the padding edge, making corner brackets and overflow decorations invisible.

---

## `content-visibility: auto` (MDN)

> "Off-screen content within a `content-visibility: auto` property remains in the document object model and the accessibility tree. This allows improving page performance with `content-visibility: auto` without negatively impacting accessibility."

Unlike `display: none`, `content-visibility: auto` keeps off-screen content in the accessibility tree and available for find-in-page, tab-order navigation, and focus.

```css
.card {
  content-visibility: auto;
  contain-intrinsic-size: auto 200px; /* placeholder height hint */
}
```

`contain-intrinsic-size` provides a placeholder size hint so the browser can reserve space before rendering the actual content, preventing scroll-bar jank.

Apply to any heavy component that may appear in long lists: cards, list items, accordion panels.

---

## `will-change` — Use with Caution (MDN)

> "Warning: `will-change` is intended to be used as a last resort, in order to try to deal with existing performance problems. It should not be used to anticipate performance problems."

On using `will-change` directly in stylesheets, MDN says:
> "But use caution with the `will-change` property directly in stylesheets. It may cause the browser to keep the optimization in memory for much longer than it is needed."

MDN's recommended approach — toggle via JavaScript only around the animation:

```javascript
el.addEventListener('mouseenter', () => { el.style.willChange = 'filter' })
el.addEventListener('animationend', () => { el.style.willChange = 'auto' })
```

---

## `clip-path` vs `overflow: hidden`

This comparison is based on CSS spec behavior. MDN does not directly compare these two properties.

`clip-path` (MDN): "A computed value other than `none` results in the creation of a new stacking context." MDN's Containing Block page confirms `clip-path` does **not** create a containing block for `position: fixed` elements.

`overflow: hidden` (MDN): "Specifying a value other than `visible` (the default) or `clip` for `overflow` creates a new block formatting context." Note: a block formatting context is **not** the same as a containing block for fixed positioning.

| | `clip-path` | `overflow: hidden` |
|---|---|---|
| Creates containing block for fixed children | No (per MDN Containing Block page) | No (creates a BFC, not a containing block) |
| Creates stacking context | Yes (when non-none, per MDN) | Yes |
| Responsive with CSS variables | Yes via `calc()` in `polygon()` | N/A |

Use `polygon()` with `calc()` and CSS variables for shapes that adapt to any size:
```css
clip-path: polygon(
  0 0,
  calc(100% - var(--radius)) 0,
  100% var(--radius),
  100% 100%,
  var(--radius) 100%,
  0 calc(100% - var(--radius))
);
```

---

## `filter: drop-shadow()` vs `box-shadow`

MDN on `drop-shadow()`:
> "A drop shadow is effectively a blurred, offset version of the input image's alpha mask, drawn in a specific color and composited below the image."

> "This function is somewhat similar to the `box-shadow` property. The `box-shadow` property creates a rectangular shadow behind an element's entire box, while the `drop-shadow()` filter function creates a shadow that conforms to the shape (alpha channel) of the image itself."

MDN does not explicitly document the interaction between `box-shadow` and `clip-path`. In practice, `box-shadow` is part of the box model and gets clipped by `clip-path`, while `drop-shadow()` traces the element's alpha mask (the visible shape after clipping).

```css
/* WRONG — box-shadow is clipped, draws a rectangular shadow on a diagonal button */
.btn:hover { box-shadow: 0 0 20px gold; }

/* CORRECT — drop-shadow traces the clip-path outline */
.btn:hover { filter: drop-shadow(0 0 12px gold); }
```

Chaining multiple filters is legitimate but can be expensive on low-end GPUs. For 3+ chained filters on hover, consider a reduced fallback:
```css
@media (prefers-reduced-motion: reduce) {
  .btn:hover { filter: brightness(1.1); }
}
```

