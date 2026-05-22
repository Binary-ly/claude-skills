# @property Registration Rules

Sources:
- https://developer.mozilla.org/en-US/docs/Web/CSS/@property
- https://developer.mozilla.org/en-US/docs/Web/CSS/@property/initial-value
- https://developer.mozilla.org/en-US/docs/Web/CSS/@property/syntax
- https://developer.mozilla.org/en-US/docs/Web/CSS/@property/inherits

---

## Required Descriptors (MDN)

> "The `@property` rule must include both the `syntax` and `inherits` descriptors. If either is missing, the entire `@property` rule is invalid and ignored."

`initial-value` is **conditionally required** (MDN, paraphrased from bullet points):

- Optional when `syntax: "*"`
- Required for all other syntax values
- If required but missing or invalid, the entire `@property` rule is invalid and ignored

```css
/* WRONG — missing inherits → entire rule silently ignored */
@property --my-color {
  syntax: "<color>";
  initial-value: red;
}

/* CORRECT */
@property --my-color {
  syntax: "<color>";
  inherits: false;
  initial-value: red;
}

/* CORRECT — initial-value optional when syntax is "*" */
@property --any-value {
  syntax: "*";
  inherits: false;
}
```

---

## When @property is Useful (MDN)

MDN lists three primary uses:

1. **Type checking and constraining** — browser rejects values that don't match the declared `syntax`
2. **Setting default values** — via `initial-value`, the property always has a value even when unset
3. **Controlling inheritance** — `inherits: false` prevents the value cascading to descendants

```css
/* Animatable color — browser can interpolate between color values */
@property --btn-bg {
  syntax: "<color>";
  inherits: false;
  initial-value: transparent;
}
```

---

## `initial-value` Must Be Computationally Independent (MDN)

> "If the value of the `syntax` descriptor is not the universal syntax definition, the `initial-value` descriptor has to be a computationally independent value."

MDN lists examples (paraphrased from list format): `10px` is valid (computationally independent); `3em` is NOT valid because `em` depends on the parent's `font-size`.

```css
/* WRONG — 3em depends on font-size context */
@property --spacing {
  syntax: "<length>";
  inherits: false;
  initial-value: 3em; /* invalid — rule is ignored */
}

/* CORRECT */
@property --spacing {
  syntax: "<length>";
  inherits: false;
  initial-value: 12px;
}
```

---

## The Fallback Chain Trap (derived from MDN's initial-value behavior)

This is a consequence of how `initial-value` works — not explicitly called out on MDN, but follows directly from it.

When `initial-value` is set, the property **always has a value** (it never falls through to the `var()` fallback). This breaks fallback chains:

```css
@property --btn-hover-bg {
  syntax: "<color>";
  inherits: false;
  initial-value: transparent; /* property is NEVER unset */
}

/* var(--btn-hover-bg, var(--btn-bg)) now ALWAYS returns transparent */
/* The var(--btn-bg) fallback is never reached */
```

```css
/* CORRECT — leave unregistered so fallback fires when property is unset */
/* No @property for --btn-hover-bg */
.btn { background: var(--btn-hover-bg, var(--btn-bg)); } /* works correctly */
.btn-outline { --btn-hover-bg: transparent; }             /* explicit override */
```

Register with `@property` only variables that should always have a value. If a variable is intentionally unset in some contexts so that a `var()` fallback fires, registration breaks that pattern — `initial-value` ensures the property always has a value, so the fallback never triggers.

---

## Registered vs Unregistered Comparison

| Feature | Registered (`@property`) | Unregistered (`--`) |
|---|---|---|
| Animatable | Yes — browser interpolates typed values | No — discrete only |
| Type checking | Yes — browser validates syntax | No — any value accepted |
| Inheritance control | Yes — `inherits: false/true` | No — always inherits |
| Fallback chains | Broken if `initial-value` is set | Works correctly |
| `calc()` in initial-value | Must be context-free (no `em`) | No restriction |
