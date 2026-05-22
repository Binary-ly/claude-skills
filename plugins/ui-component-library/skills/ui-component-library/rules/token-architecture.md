# Token Architecture — CSS Custom Properties

Sources:
- https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_cascading_variables/Using_CSS_custom_properties
- https://developer.mozilla.org/en-US/docs/Web/CSS/var

---

## How Scoping Works (MDN)

> "The selector given to the ruleset defines the scope in which the custom property can be used. For this reason, a common practice is to define custom properties on the `:root` pseudo-class, so that it can be referenced globally."

> "This doesn't always have to be the case: you maybe have a good reason for limiting the scope of your custom properties."

```css
/* :root — globally available */
:root {
  --color-primary: #C9A84C;
}

/* Scoped — only accessible inside .card and its descendants */
.card {
  --card-shadow: 0 4px 24px rgba(0,0,0,0.3);
}
```

**Design principle (not from MDN):** Scope brand/global tokens to `:root`. Scope component tokens to the component element so they don't pollute the global namespace and can be tree-shaken per component.

---

## Fallback Values with `var()` (MDN)

> "Using the `var()` function, you can define multiple fallback values when the given variable is not yet defined; this can be useful when working with Custom Elements and Shadow DOM."

> "The second argument to the function is an optional fallback value, which is used as the substitution value when the referenced custom property is invalid."

```css
.two {
  /* pink if --my-var and --my-background are not defined */
  color: var(--my-var, var(--my-background, pink));
}
```

Fallback chains allow variants to selectively override without repeating code:

```css
/* Solid btn leaves --btn-hover-bg unset → falls back to --btn-bg */
background: var(--btn-hover-bg, var(--btn-bg));

/* Outlined btn sets --btn-hover-bg explicitly → fallback ignored */
.btn-outline { --btn-hover-bg: transparent; }
```

**Critical:** Variables used in fallback chains must stay **unregistered** (no `@property`). See at-property.md.

---

## Inheritance (MDN)

> "A custom property defined using two dashes `--` instead of `@property` always inherits the value of its parent."

> "The `@property` at-rule lets you explicitly state whether the property inherits or not."

```css
/* Unregistered — always inherits */
:root { --color-primary: teal; }
.child { color: var(--color-primary); } /* inherits from :root */

/* @property — inherits: false means NO inheritance */
@property --box-color {
  syntax: "<color>";
  inherits: false;
  initial-value: teal;
}
```

---

## Design Principles (not from MDN)

These are architectural recommendations, not MDN-specified rules:

- **Keep public API small** — fewer tokens = easier to maintain and understand. Large token surfaces increase cognitive load for consumers.
- **Internal tokens** — use a naming convention (e.g. `--_name`) to signal "not part of public API." No browser enforces this; it is a documentation signal only.
- **Avoid `!important` in library source** — it blocks downstream customization. If `!important` is needed, the specificity model is likely broken. Use `:where()` instead (see specificity.md).
