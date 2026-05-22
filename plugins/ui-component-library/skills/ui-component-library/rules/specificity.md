# Specificity — Zero-Specificity Components with `:where()`

Sources:
- https://developer.mozilla.org/en-US/docs/Web/CSS/:where
- https://developer.mozilla.org/en-US/docs/Web/CSS/:is
- https://drafts.csswg.org/selectors/#where-pseudo

---

## `:where()` Always Has Zero Specificity (MDN)

> "`:where()` always has 0 specificity"

> "The difference between `:where()` and `:is()` is that `:where()` always has 0 specificity, whereas `:is()` takes on the specificity of the most specific selector in its arguments."

This makes `:where()` the correct choice for wrapping all library component selectors — any developer class automatically wins without needing `!important`.

---

## The Problem with Normal Specificity

```css
/* Library: .btn has specificity (0,1,0) */
.btn { background: blue; }

/* Developer override: also (0,1,0) — source order determines winner, unpredictable */
.my-btn { background: purple; } /* may or may not win depending on load order */
```

---

## The Solution: Wrap All Library Selectors in `:where()`

```css
/* Library: specificity = 0,0,0 */
:where(.btn) {
  background: var(--btn-bg);
  color: var(--btn-color);
}

:where(.btn):where(:hover) {
  background: var(--btn-hover-bg, var(--btn-bg));
}

/* Developer override: specificity = 0,1,0 — wins automatically, no !important */
.my-btn {
  --btn-bg: purple;
}

/* Even a single element selector wins over :where() */
button {
  --btn-bg: purple; /* (0,0,1) > (0,0,0) */
}
```

---

## Wrap Variants Too

```css
:where(.btn-primary) {
  --btn-bg: var(--color-primary);
}

:where(.btn-danger) {
  --btn-bg: var(--color-danger);
}

/* Developer can always override without fighting specificity */
.btn-primary.custom { --btn-bg: purple; } /* (0,2,0) > (0,0,0) — wins cleanly */
```

---

## Forgiving Selector List (MDN)

> "The specification defines `:is()` and `:where()` as accepting a forgiving selector list. In CSS when using a selector list, if any of the selectors are invalid then the whole list is deemed invalid. When using `:is()` or `:where()` instead of the whole list of selectors being deemed invalid if one fails to parse, the incorrect or unsupported selector will be ignored and the others used."

This means `:where()` is safe for progressive enhancement — unknown selectors are silently skipped rather than breaking the entire rule.

---

## `:where()` vs `:is()` (MDN)

| | `:where()` | `:is()` |
|---|---|---|
| Specificity contributed | Always 0 | Highest of its arguments |
| Forgiving selector list | Yes | Yes |
| Use in libraries | Always | Only if specificity is intentional |

`:is()` takes the highest specificity of all arguments inside it — not appropriate for zero-override-cost library components.

---

## Result

With `:where()` wrapping all library selectors, any single class, element, or ID selector written by a developer automatically overrides library defaults. `!important` is never needed in either the library code or consumer code.
