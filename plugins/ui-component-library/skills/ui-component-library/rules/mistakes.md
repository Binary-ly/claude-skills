# Common Mistakes — What NOT to Do

Sources:
- https://developer.mozilla.org/en-US/docs/Web/CSS/:where — `:where()` zero-specificity (Mistake 1)
- https://developer.mozilla.org/en-US/docs/Web/CSS/will-change — `will-change` usage guidance (Mistake 2)
- https://developer.mozilla.org/en-US/docs/Web/CSS/overflow — `overflow` and block formatting context (Mistake 3)
- https://developer.mozilla.org/en-US/docs/Web/CSS/clip-path — `clip-path` clipping behavior (Mistakes 3, 8)
- https://developer.mozilla.org/en-US/docs/Web/CSS/box-shadow — `box-shadow` on clipped elements (Mistake 8)
- https://developer.mozilla.org/en-US/docs/Web/CSS/color_value/color-mix — `color-mix()` and color spaces (Mistake 4)
- https://developer.mozilla.org/en-US/docs/Web/CSS/custom-properties — custom property scoping and `:root` (Mistake 7)
- https://developer.mozilla.org/en-US/docs/Web/CSS/contain — `contain` paint clipping (Mistake 9)
- https://developer.mozilla.org/en-US/docs/Web/CSS/content-visibility — content-visibility and containment (Mistake 9)
- https://developer.mozilla.org/en-US/docs/Web/CSS/@property — `@property` initial-value and fallback chains (Mistake 10)
- Mistakes 5, 6 are design principles with no spec reference.
- Cross-references to sibling files: specificity.md, performance.md, color.md, naming.md, token-architecture.md, at-property.md.

---

## 1. `!important` in Component CSS

**Problem**: Blocks all downstream customization. Developers can't override without also using `!important`.

**Fix**: Use `:where()` for zero-specificity components.

> "`:where()` always has 0 specificity." — MDN

```css
/* WRONG */
.btn { background: blue !important; }

/* CORRECT */
:where(.btn) { background: var(--btn-bg); }
```

See: specificity.md

---

## 2. `will-change` in Stylesheets

**Problem**: Holds GPU resources permanently for every instance, even when idle.

> "It may cause the browser to keep the optimization in memory for much longer than it is needed." — MDN

**Fix**: Apply via JavaScript only after profiling confirms a real bottleneck. Remove it after the animation ends.

```css
/* WRONG — in stylesheet */
.card-glow { will-change: filter; }
```

```js
/* CORRECT — in JavaScript, toggled only when needed */
el.addEventListener('mouseenter', () => { el.style.willChange = 'filter' })
el.addEventListener('animationend',  () => { el.style.willChange = 'auto' })
```

See: performance.md

---

## 3. `overflow: hidden` for Shaped Components

**Problem**: `overflow: hidden` clips all overflowing content to the element's padding box. For shaped components using `clip-path`, `box-shadow` renders as a rectangle behind the box before clipping — it doesn't follow the clipped shape.

> "Specifying a value other than `visible` (the default) or `clip` for `overflow` creates a new block formatting context." — MDN

**Fix**: Use `clip-path` with `filter: drop-shadow()` instead.

```css
/* WRONG */
.btn { border-radius: 8px; overflow: hidden; }

/* CORRECT */
.btn { clip-path: inset(0 round 8px); }
```

See: performance.md

---

## 4. `color-mix(in srgb, ...)` for Alpha Blending

**Problem**: sRGB produces muddy, desaturated midpoints when blending.

> "The sRGB color space is neither linear-light nor perceptually uniform, and produces poorer results such as overly dark or grayish mixes." — MDN

**Fix**: Use `oklch` which preserves chroma throughout the transition.

```css
/* WRONG — muddy, grayish midpoint */
color-mix(in srgb, #C9A84C 45%, transparent)

/* CORRECT — vibrant, perceptually consistent */
color-mix(in oklch, #C9A84C 45%, transparent)
```

See: color.md

---

## 5. Cryptic Shape Names (design principle)

**Problem**: `.btn-alpha`, `.btn-beta` require documentation to use. You cannot guess what shape "alpha" is.

**Fix**: Use self-documenting, descriptive names.

```css
/* WRONG */
.btn-alpha  /* diagonal */
.btn-beta   /* bevel */

/* CORRECT */
.btn-cut    /* diagonal chamfer */
.btn-bevel  /* octagonal bevel */
```

See: naming.md

---

## 6. Exposing Too Many Public CSS Variables Per Component (design principle)

**Problem**: A component with 18+ public CSS variables requires users to read extensive documentation before customizing anything.

**Fix**: Expose only what users genuinely need to override. Everything else is internal (prefixed to signal "not public API").

```css
/* WRONG — too many public vars */
.btn {
  --btn-bg: ...; --btn-color: ...; --btn-filter: ...;
  --btn-hover-bg: ...; --btn-hover-color: ...; --btn-hover-filter: ...;
  --btn-active-bg: ...; --btn-active-scale: ...; --btn-scan-color: ...;
}

/* CORRECT — minimal public surface */
.btn {
  --btn-bg:     blue;        /* PUBLIC */
  --btn-color:  white;       /* PUBLIC */
  --btn-radius: 8px;         /* PUBLIC */
  --_interior:  transparent; /* internal */
  --_scan:      white;       /* internal */
}
```

---

## 7. All Tokens on `:root`

**Problem**: Putting component-level variables on `:root` means every page carries all tokens regardless of which components are used.

> "Declaring a custom property on `:root` is a common practice" for globally referenced properties. — MDN

**Fix**: Brand/global tokens go on `:root`. Component tokens go on the component element.

```css
/* WRONG */
:root { --btn-bg: blue; --card-shadow: ...; --badge-glow: ...; }

/* CORRECT */
:root  { --color-primary: blue; }             /* brand — truly global */
.btn   { --btn-bg: var(--color-primary); }    /* component — scoped */
.card  { --card-shadow: ...; }
.badge { --badge-glow: ...; }
```

See: token-architecture.md

---

## 8. `box-shadow` on `clip-path` Elements

**Problem**: `box-shadow` is applied to the element's bounding box before clip-path clipping — it gets clipped away or draws a rectangle.

**Fix**: Use `filter: drop-shadow()` which applies after clipping and traces the real visible outline.

```css
/* WRONG — shadow draws rectangle, not diagonal button shape */
.btn:hover { box-shadow: 0 0 20px gold; }

/* CORRECT — shadow traces the clip-path outline */
.btn:hover { filter: drop-shadow(0 0 12px gold); }
```

See: performance.md

---

## 9. `contain: paint` on Components with Overflowing Pseudo-Elements

**Problem**: `contain: paint` clips any `::before` or `::after` that draws outside the border-box, silently breaking visual effects.

> `contain: paint` clips "descendants of the element" to the border-box. — MDN

**Fix**: Use `contain: layout style` without `paint`.

```css
/* WRONG — clips corner bracket pseudo-elements */
.card { contain: strict; } /* = size layout paint style */

/* CORRECT — layout/style containment, paint intentionally excluded */
.card { contain: layout style; }
```

See: performance.md

---

## 10. Registering Fallback-Chain Variables with `@property`

**Problem**: `@property` with `initial-value` means the variable always resolves to that value — the CSS fallback (`var(--x, var(--y))`) never fires.

**Fix**: Leave fallback-chain variables unregistered.

```css
/* WRONG — @property breaks the fallback */
@property --btn-hover-bg {
  syntax: "<color>";
  inherits: false;
  initial-value: transparent; /* var(--btn-hover-bg, var(--btn-bg)) always returns transparent */
}

/* CORRECT — unregistered, fallback fires when property is unset */
/* no @property rule */
.btn { background: var(--btn-hover-bg, var(--btn-bg)); }
```

See: at-property.md
