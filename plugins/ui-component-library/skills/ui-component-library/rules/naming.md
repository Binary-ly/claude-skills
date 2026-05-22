# Naming Conventions

Sources:
- https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Reference/Attributes/aria-pressed
- https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Reference/Attributes/aria-busy
- https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Attributes/disabled
- Sections on component naming, variable naming, and shape names are design principles — no single spec mandates these conventions.

---

## Component Classes — Semantic, Not Visual (design principle)

Names should describe **what a thing is**, not **what it looks like**. Visual names break when the design changes.

```css
/* CORRECT — semantic */
.btn           .btn-primary    .btn-danger
.card          .card-header    .card-body
.badge         .badge-success  .badge-outline
.alert         .alert-warning

/* WRONG — visual, breaks on redesign */
.blue-button   .round-box      .gold-text    .big-card
```

---

## CSS Variable Naming — `--[component]-[property]` (design principle)

No CSS spec mandates variable naming conventions. The following pattern is widely adopted for clarity:

### Public API variables (document these)
```css
--btn-bg          /* button background */
--btn-color       /* button text color */
--btn-radius      /* button corner radius */
--card-shadow     /* card box/drop shadow */
--badge-color     /* badge text + glow color */
```

### Global brand tokens (user sets these to rebrand)
```css
--color-primary   /* brand accent color */
--color-danger    /* destructive action color */
--radius-base     /* base corner radius */
--duration-base   /* base animation duration */
--font-mono       /* monospace font stack */
```

### Internal variables (never document)
```css
--_scan-color     /* internal scan animation color */
--_interior       /* internal pseudo-element fill */
--_bracket-color  /* internal decoration color */
```

### Rules
- Use kebab-case (`--btn-bg`, not `--btnBg`) — CSS custom properties are case-sensitive and kebab-case aligns with native CSS property naming
- Component prefix before property (`--btn-bg` not `--bg-btn`) — grouping by component makes autocomplete and search more useful than grouping by property
- Semantic intent over visual value (`--color-danger` not `--color-red`) — visual names break when the palette changes; semantic names survive redesigns
- `_` prefix for internals (`--_scan-color`) signals "not public API" — no browser enforces this, but it prevents consumers from depending on values that may change without notice

---

## Shape Modifier Names — Descriptive, Not Alphabetic (design principle)

Shape variants must be self-documenting. Letters or numbers require memorization and defeat discoverability.

```css
/* WRONG — cryptic, unguessable */
.btn-alpha   .btn-beta   .btn-gamma   .btn-delta

/* CORRECT — self-documenting */
.btn-cut      /* diagonal chamfered corner */
.btn-bevel    /* octagonal / 8-corner bevel */
.btn-round    /* fully rounded / pill */
.btn-square   /* rectangular, no clip */

.badge-slant  /* parallelogram slant */
.badge-bevel  /* octagonal bevel */
.badge-pill   /* fully rounded */
.badge-rect   /* rectangular */
```

---

## Size Modifiers — Consistent Pattern Across All Components (design principle)

```css
.btn-sm    .btn-lg
.badge-sm  .badge-lg
.card-sm   .card-lg
.alert-sm  .alert-lg
```

Mixing naming patterns (`-small` vs `-sm` vs `-xs`) across components forces consumers to memorize per-component conventions, increasing cognitive load and error rate. Pick one pattern and use it everywhere.

---

## State Classes — Prefer Standard HTML/ARIA Attributes (MDN/W3C ARIA spec)

ARIA attributes are standardized by the W3C and documented by MDN. Prefer them over custom state classes:

```css
/* CORRECT — uses standard HTML/ARIA attributes */
.btn[disabled]             { opacity: 0.5; }
.btn[aria-pressed="true"]  { background: var(--btn-active-bg); }
.btn[aria-busy="true"]     { cursor: wait; }

/* AVOID — custom state classes require extra JS and aren't understood by assistive tech */
.btn.is-disabled {}
.btn.is-active {}
.btn.is-loading {}
```

`aria-pressed` (MDN): Accepts four values — `true`, `false`, `mixed`, and `undefined` (default). Used with the `button` role to turn a button into a toggle button and communicate pressed state to assistive technologies.

`aria-busy` (MDN): Indicates an element is being modified and assistive technologies should wait until the changes are complete before exposing them.

`disabled` (HTML spec): Native HTML attribute. Removes the element from tab order and blocks interaction without needing JavaScript.
