# File Organization

Sources:
- This file contains design principles only — no CSS or HTML spec mandates a particular file structure.
- The `:root` vs component scoping guidance derives from MDN CSS Custom Properties: https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_cascading_variables/Using_CSS_custom_properties

---

## Directory Structure

```
src/
  tokens/
    brand.css           ← 5–10 global brand variables on :root
    themes/
      default.css       ← default theme (may be empty if brand.css is the default)
      dark.css          ← dark theme token overrides
      [name].css        ← additional themes — each is a plain CSS file
  components/
    btn/
      btn.css           ← all .btn styles
      btn.js            ← Tailwind plugin registration (if applicable)
    badge/
      badge.css
      badge.js
    card/
      card.css
      card.js
    alert/
      alert.css
      alert.js
  utils/
    shapes.js           ← clip-path geometry factories (if complex shapes are used)
    keyframes.css       ← shared @keyframes animations
  index.js              ← library entry point — imports and registers all components
```

---

## One File Per Component

Each component lives in its own directory. Users can import only what they need:

```js
// Import everything
import 'my-lib'

// Import only button (tree-shakeable)
import 'my-lib/components/btn/btn.css'
```

Keep each component in its own file — monolithic source files prevent tree-shaking, create merge conflicts when multiple contributors edit simultaneously, and make it harder to find and maintain individual components. The bundler can produce a combined output for convenience, but the source must be modular.

---

## Separation of Concerns

| File | Contains | Does NOT contain |
|---|---|---|
| `brand.css` | `:root { --color-primary: ...; }` | Component-level vars |
| `btn.css` | `.btn { ... }` rules, component vars on `.btn` | Brand tokens |
| `themes/dark.css` | `:root { --color-primary: ...; }` overrides | Component structure |
| `keyframes.css` | `@keyframes` definitions | Component selectors |
| `shapes.js` | Geometry factory functions | CSS output |
| `index.js` | Plugin registration, imports | Actual CSS values |

---

## What Goes on `:root` vs on the Component

```css
/* brand.css — :root only */
:root {
  --color-primary: #C9A84C;
  --radius-base:   10px;
  --duration-base: 0.22s;
}

/* btn.css — component vars on .btn, not :root */
:where(.btn) {
  --btn-bg:     var(--color-primary); /* reads from :root brand token */
  --btn-radius: var(--radius-base);
  /* never: :root { --btn-bg: ...; } */
}
```

---

## Compiled Output vs Source

The source is modular. The build step may produce:
- A combined `library.css` for convenience (CDN / quick start)
- Individual `components/btn.css` for tree-shaking
- A Tailwind plugin `library.js` that registers all component classes

Keep compiled output out of the source tree — committed dist files cause merge conflicts, go stale when the build step is skipped, and bloat the repository. Keep source and dist separate.
