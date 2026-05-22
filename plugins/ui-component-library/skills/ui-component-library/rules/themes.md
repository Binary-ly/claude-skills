# Theme / Genre Swapping

Sources:
- https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_cascading_variables/Using_CSS_custom_properties
- https://developer.mozilla.org/en-US/docs/Web/CSS/Attribute_selectors
- This file contains design principles only. No CSS spec mandates CSS-files-over-JS-objects for theme systems.

---

## Themes Are CSS Files, Not JavaScript Objects (design principle)

A theme is a plain CSS file that overrides brand tokens. Swap it by swapping a `<link>` tag or a CSS `@import`. Zero JavaScript, browser-cached:

```css
/* themes/cyberpunk.css */
:root {
  --color-primary: #39FF14;
  --radius-base:   0px;
  --duration-base: 0.15s;
  --font-mono:     'Share Tech Mono', monospace;
}
```

```html
<!-- Swap by changing this one tag -->
<link rel="stylesheet" href="/themes/cyberpunk.css">
```

This is simpler and more cacheable than a JavaScript `setProperty` loop. The component layer never changes — only brand token values change.

---

## Scoped Theme Overrides with Data Attributes

CSS attribute selectors (MDN) target `data-*` attributes — this is standard CSS, no JavaScript required for the matching:

```css
/* default */
:root {
  --color-primary: #C9A84C;
}

/* cyberpunk theme — scoped to data-theme attribute */
[data-theme="cyberpunk"] {
  --color-primary:     #39FF14;
  --card-bracket-size: 22px;
}
```

```html
<html data-theme="cyberpunk">
```

Toggle in JS:
```js
document.documentElement.dataset.theme = 'cyberpunk'
```

---

## Theme Scope Rules (design principle)

| What changes | Where to put it |
|---|---|
| Brand colors, radius, duration | `:root` (or `[data-theme]`) |
| Component structural differences | `[data-theme]` scoped overrides |
| Component class-level overrides | `[data-theme] .badge { ... }` |
| Animations, keyframes | Separate `@keyframes` file |

---

## What NOT to Do

```js
// WRONG — JS token loop: not cacheable, runs on every load, not tree-shakeable
const cyberpunk = {
  '--color-primary': '#39FF14',
  '--radius-base': '0px',
}
Object.entries(cyberpunk).forEach(([k, v]) => root.style.setProperty(k, v))
```

The JS approach is only justified when themes must be dynamically composed at runtime from user input (e.g., a theme builder). For static themes, always use CSS files.

---

## Theme File Template

```css
/* themes/[name].css */
/* Override only what differs from the default theme */
:root {
  /* Brand */
  --color-primary: ...;
  --color-success: ...;
  --color-danger:  ...;

  /* Shape */
  --radius-base: ...;

  /* Motion */
  --duration-base:  ...;
  --ease-enter:     ...;
  --ease-exit:      ...;

  /* Typography */
  --font-mono: ...;
}
```

Omit any token that should stay at the default value — CSS cascade handles it.
