# Accessibility

Sources:
- https://developer.mozilla.org/en-US/docs/Web/CSS/:focus-visible
- https://developer.mozilla.org/en-US/docs/Web/CSS/content-visibility
- https://developer.mozilla.org/en-US/docs/Web/CSS/@media/prefers-reduced-motion
- https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html (WCAG 2.1 AA — 1.4.3)
- https://www.w3.org/WAI/WCAG21/Understanding/non-text-contrast.html (WCAG 2.1 AA — 1.4.11)
- https://www.w3.org/WAI/WCAG21/Understanding/use-of-color.html (WCAG 2.1 AA — 1.4.1)

---

## Focus Indicators — `:focus-visible` Not `:focus` (MDN)

> "The `:focus` pseudo-class always matches the currently-focused element. The `:focus-visible` pseudo-class also matches the focused element, but only if the user needs to be informed where the focus currently is."

In practice (MDN):
- Does NOT show a focus ring when clicking with a mouse on buttons
- DOES show a focus ring when navigating with the keyboard

```css
/* WRONG — shows ring on mouse click too */
:where(.btn):focus {
  outline: 2px solid var(--color-primary);
}

/* CORRECT — ring only for keyboard navigation */
:where(.btn):focus-visible {
  outline: 2px solid var(--color-primary);
  outline-offset: 3px;
}

/* Removing outline without an alternative leaves keyboard users unable to see focus — violates WCAG 2.4.7 */
:where(.btn):focus { outline: none; } /* Only acceptable when :focus-visible provides the ring */
```

---

## ARIA Role Support

Interactive components should style both the semantic element and its ARIA role equivalent:

```css
/* Button — supports <button> AND <div role="button"> */
:where(.btn),
:where([role="button"]).btn {
  /* styles */
}

/* Alert — supports <div class="alert"> AND <div role="alert"> */
:where(.alert),
:where([role="alert"]) {
  /* styles */
}
```

Non-interactive components (badges, cards) don't need `[role]` selectors — they're purely presentational.

---

## WCAG 2.1 AA Contrast Requirements

### Text contrast — WCAG 2.1 criterion 1.4.3

> "The visual presentation of text and images of text has a contrast ratio of at least 4.5:1, except for the following: Large Text — Large-scale text and images of large-scale text have a contrast ratio of at least 3:1."

| Context | Minimum ratio |
|---|---|
| Normal text (< 18pt non-bold, < 14pt bold) | 4.5 : 1 |
| Large text (≥ 18pt non-bold or ≥ 14pt bold) | 3 : 1 |

### Non-text contrast — WCAG 2.1 criterion 1.4.11

> "The visual presentation of the following have a contrast ratio of at least 3:1 against adjacent color(s): User Interface Components — Visual indicators needed to identify controls and their states, excluding inactive (disabled) components."

WCAG lists two categories:

| Category | Minimum ratio |
|---|---|
| User Interface Components — visual indicators to identify controls and states | 3 : 1 |
| Graphical Objects — parts of graphics essential for understanding content | 3 : 1 |
| Decorative elements | No requirement |
| Inactive / disabled components | Exempt |

Note: focus indicators fall under "states" within the UI Components category (not a separate category).

Check contrast at both rest and hover/active states. A button that passes at rest may fail on hover if the text color changes.

Tools: [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/), browser DevTools accessibility panel.

---

## `content-visibility: auto` Is Accessibility-Safe (MDN)

> "Off-screen content within a `content-visibility: auto` property remains in the document object model and the accessibility tree. This allows improving page performance with `content-visibility: auto` without negatively impacting accessibility."

Unlike `display: none` or `visibility: hidden`, `content-visibility: auto` keeps off-screen content reachable by find-in-page, tab navigation, and screen readers.

---

## Reduced Motion

→ See [motion.md](motion.md) for the full `prefers-reduced-motion` guide — directional easing, reduced-motion fallbacks, and GPU-composited property rules.

Key principle: disable decorative animations but keep state-communicating ones (loading spinners, progress bars). Users with vestibular disorders need reduced motion, but still need to know when the app is working.

---

## Semantic HTML First

```html
<!-- CORRECT — native button, keyboard-accessible by default -->
<button class="btn btn-primary">Submit</button>

<!-- ALSO CORRECT — ARIA role for non-button elements (needs JS for keyboard) -->
<div class="btn btn-primary" role="button" tabindex="0">Submit</div>

<!-- WRONG — no role, not keyboard accessible -->
<div class="btn btn-primary">Submit</div>
```

---

## Color Is Never the Only Indicator (WCAG 2.1 criterion 1.4.1)

WCAG 1.4.1 (Use of Color): color must not be the only visual means of conveying information, indicating an action, prompting a response, or distinguishing a visual element.

```html
<!-- WRONG — only color distinguishes error from success -->
<div class="alert alert-danger">Your form has errors.</div>

<!-- CORRECT — color + icon + descriptive text -->
<div class="alert alert-danger" role="alert">
  <span aria-hidden="true">✕</span>
  Error: Please fix the highlighted fields.
</div>
```
