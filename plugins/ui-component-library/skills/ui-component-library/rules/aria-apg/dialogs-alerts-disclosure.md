# Dialogs, Alerts & Disclosure Patterns

Reference for WAI-ARIA Authoring Practices Guide (APG) patterns covering modal
dialogs, alert dialogs, inline alerts, tooltips, accordions, and disclosure
widgets. Each section lists keyboard behaviour, required ARIA attributes, and
correct/incorrect markup.

## Sources

- https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/
- https://www.w3.org/WAI/ARIA/apg/patterns/alertdialog/
- https://www.w3.org/WAI/ARIA/apg/patterns/alert/
- https://www.w3.org/WAI/ARIA/apg/patterns/tooltip/
- https://www.w3.org/WAI/ARIA/apg/patterns/accordion/
- https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/

---

## Table of Contents
1. [Dialog (Modal)](#1-dialog-modal)
2. [Alert Dialog](#2-alert-dialog)
3. [Alert](#3-alert)
4. [Tooltip](#4-tooltip)
5. [Accordion](#5-accordion)
6. [Disclosure (Show/Hide)](#6-disclosure-showhide)

---

## 1. Dialog (Modal)

> A dialog is a window overlaid on either the primary window or another dialog
> window. Windows under a modal dialog are inert. That is, users cannot interact
> with content outside an active dialog window.

A modal dialog steals focus from the rest of the page. The tab sequence is
trapped inside the dialog until it is dismissed. When the dialog closes, focus
**must** return to the element that invoked it (unless that element no longer
exists, in which case focus moves to a logical alternative).

### Keyboard Interaction

| Key | Action |
|-----|--------|
| `Tab` | Move focus to the next tabbable element inside the dialog. When focus is on the **last** tabbable element, wrap to the **first**. |
| `Shift + Tab` | Move focus to the previous tabbable element inside the dialog. When focus is on the **first** tabbable element, wrap to the **last**. |
| `Escape` | Close the dialog. |

### Initial Focus Placement Rules

The APG specifies multiple strategies depending on dialog content:

| Scenario | Where to Place Focus |
|----------|---------------------|
| Simple form / few controls | First focusable element in the dialog. |
| Large block of semantic content (paragraphs, lists, tables) | A static container element at the top of the content with `tabindex="-1"`, so the content is announced without scrolling away. |
| Destructive action confirmation | The **least destructive** action (e.g. "Cancel") to prevent accidental confirmation. |
| Informational / single-action dialog | The most frequently used element (e.g. "OK" button). |

### Required ARIA Roles, States & Properties

| Attribute | Element | Value / Notes |
|-----------|---------|---------------|
| `role="dialog"` | Dialog container | Identifies the element as a dialog. |
| `aria-modal="true"` | Dialog container | Tells assistive technologies the underlying page is inert. |
| `aria-labelledby` | Dialog container | References the visible dialog title element's `id`. Use this when a visible heading exists. |
| `aria-label` | Dialog container | Provides an accessible name when no visible heading exists. Use **one** of `aria-labelledby` or `aria-label`, not both. |
| `aria-describedby` | Dialog container | (Optional) References element(s) that describe the dialog's purpose. |

All interactive elements needed to operate the dialog **must** be DOM
descendants of the `role="dialog"` element.

### HTML Example

```html
<!-- CORRECT: modal dialog with focus trap, label, and description -->
<div role="dialog"
     aria-modal="true"
     aria-labelledby="dlg-title"
     aria-describedby="dlg-desc">
  <h2 id="dlg-title">Confirm Deletion</h2>
  <p id="dlg-desc">This action cannot be undone. Delete this item?</p>
  <button type="button">Delete</button>
  <button type="button" autofocus>Cancel</button>
</div>
<!-- Backdrop / inert layer behind the dialog -->
<div class="backdrop" aria-hidden="true"></div>

<!-- WRONG: missing role, no aria-modal, no label, no focus trap -->
<div class="modal-overlay">
  <div class="modal">
    <h2>Confirm Deletion</h2>
    <p>This action cannot be undone. Delete this item?</p>
    <button>Delete</button>
    <button>Cancel</button>
  </div>
</div>

<!-- WRONG: using aria-labelledby AND aria-label together -->
<div role="dialog"
     aria-modal="true"
     aria-label="Confirm"
     aria-labelledby="dlg-title">
  ...
</div>
```

**JavaScript responsibilities** (not handled by ARIA alone):
1. On open: move focus into the dialog per the placement rules above.
2. On `Tab`/`Shift+Tab`: trap focus within dialog descendants.
3. On `Escape`: close the dialog and return focus to the invoking element.
4. On open: set `aria-hidden="true"` on all sibling containers of the dialog
   so assistive technologies skip background content.

It is strongly recommended that the tab sequence of all dialogs include a
visible element with role `button` that closes the dialog, such as a close
icon or cancel button.

---

## 2. Alert Dialog

> An alert dialog is a modal dialog that interrupts the user's workflow to
> communicate an important message and acquire a response.

Alert dialogs are a specialisation of modal dialogs. Assistive technologies may
treat them differently -- for example by playing a system alert sound.

### When to Use

Use `alertdialog` (not plain `dialog`) when:
- The action is **destructive** and needs explicit confirmation (delete, discard
  unsaved changes).
- An **error** requires acknowledgment before the user can continue.
- The message is **urgent** and the user must respond immediately.

If the message is informational and does not require a response, use the
[Alert pattern](#3-alert) instead.

### Keyboard Interaction

Keyboard behaviour is **identical to the Dialog (Modal) pattern**:

| Key | Action |
|-----|--------|
| `Tab` | Move focus to the next tabbable element; wrap at the end. |
| `Shift + Tab` | Move focus to the previous tabbable element; wrap at the start. |
| `Escape` | Close the alert dialog. |

### Focus Placement

Per the dialog pattern, focus should be set on the least destructive action
when the dialog opens.

For a "Delete / Cancel" confirmation, focus the "Cancel" button. If the dialog
has only an "OK" acknowledgment button, focus that button.

### Required ARIA Roles, States & Properties

| Attribute | Element | Value / Notes |
|-----------|---------|---------------|
| `role="alertdialog"` | Dialog container | Identifies this as an alert dialog (not plain `dialog`). |
| `aria-modal="true"` | Dialog container | Background content is inert. |
| `aria-labelledby` | Dialog container | References the visible alert dialog title. |
| `aria-label` | Dialog container | Alternative if no visible title exists. |
| `aria-describedby` | Dialog container | References the element containing the alert message body. **Required** so the message is announced automatically. |

### HTML Example

```html
<!-- CORRECT: alert dialog for destructive confirmation -->
<div role="alertdialog"
     aria-modal="true"
     aria-labelledby="ad-title"
     aria-describedby="ad-msg">
  <h2 id="ad-title">Discard Changes?</h2>
  <p id="ad-msg">
    You have unsaved changes. If you leave now, your changes will be lost.
  </p>
  <div class="ad-actions">
    <button type="button">Discard</button>
    <button type="button" autofocus>Keep Editing</button>
  </div>
</div>

<!-- WRONG: using role="dialog" for a destructive confirmation -->
<div role="dialog" aria-modal="true" aria-labelledby="ad-title">
  <h2 id="ad-title">Discard Changes?</h2>
  <p>You have unsaved changes.</p>
  <button>Discard</button>
  <button>Keep Editing</button>
</div>

<!-- WRONG: missing aria-describedby -- alert message won't be announced -->
<div role="alertdialog" aria-modal="true" aria-labelledby="ad-title">
  <h2 id="ad-title">Discard Changes?</h2>
  <p>You have unsaved changes.</p>
  <button autofocus>Keep Editing</button>
</div>
```

### Dialog vs Alert Dialog -- Quick Comparison

| Aspect | `role="dialog"` | `role="alertdialog"` |
|--------|-----------------|----------------------|
| Purpose | General-purpose overlay (forms, settings, pickers) | Urgent confirmation or error acknowledgment |
| AT behaviour | Standard modal announcement | May trigger system alert sound |
| `aria-describedby` | Optional | Strongly recommended (conveys the alert message) |
| Typical actions | Varied | Confirm / Cancel, OK |

---

## 3. Alert

> An alert is an element that displays a brief, important message in a way that
> attracts the user's attention without interrupting the user's task.

Alerts are **not** modal. They do not steal focus or require user interaction.
They are announced by assistive technologies via an implicit live region.

### Key Characteristics

- `role="alert"` implicitly sets `aria-live="assertive"` and
  `aria-atomic="true"` (per the ARIA spec role definition, not the APG
  pattern page itself).
- Alerts injected into the DOM **after** page load are announced immediately.
- Alerts present in the DOM **at page load** are **not** announced (they are
  treated as static content).
- Alerts **do not affect keyboard focus**. The user stays wherever they were.

### Keyboard Interaction

**None required.** Alerts are passive announcements. No keyboard handling is
needed.

### Required ARIA Roles, States & Properties

| Attribute | Element | Value / Notes |
|-----------|---------|---------------|
| `role="alert"` | Container element | Identifies the element as an alert live region. Implicitly `aria-live="assertive"` + `aria-atomic="true"`. |

No other ARIA attributes are required. Do not add `aria-live="assertive"`
manually -- it is redundant when `role="alert"` is used.

### Alert vs Status -- When to Use Which

| Use `role="alert"` | Use `role="status"` |
|--------------------|---------------------|
| Errors, warnings, urgent information | Non-urgent status updates |
| Time-sensitive messages | Progress indicators, "Saved" confirmations |
| Implicit `aria-live="assertive"` | Implicit `aria-live="polite"` |
| Interrupts current AT announcement | Waits for AT to finish current announcement |

*Editorial comparison -- the APG alert pattern page does not discuss `role="status"`.*

### Design Cautions

Avoid auto-dismissing alerts -- this risks failing WCAG 2.0 Success
Criterion 2.2.3 (No Timing).

Avoid frequent alerts -- excessive interruptions harm usability for people
with cognitive disabilities (WCAG 2.0 Success Criterion 2.2.4).

### HTML Example

```html
<!-- CORRECT: alert injected dynamically after validation fails -->
<div role="alert">
  <p>Email address is required.</p>
</div>

<!-- CORRECT: empty container in DOM, content injected later via JS -->
<div role="alert" id="form-errors"></div>
<script>
  // On validation failure:
  document.getElementById('form-errors').textContent =
    'Please correct the highlighted fields.';
</script>

<!-- WRONG: alert present in DOM at page load -- it will NOT be announced -->
<body>
  <div role="alert">Welcome to the site!</div>
  <!-- Screen readers will not announce this on load -->
</body>

<!-- WRONG: using alert for non-urgent status update -->
<div role="alert">Your preferences have been saved.</div>
<!-- Should be role="status" instead -- this is not urgent -->

<!-- WRONG: adding redundant aria-live on top of role="alert" -->
<div role="alert" aria-live="assertive">Error occurred.</div>
<!-- aria-live is already implicit -- remove it -->
```

---

## 4. Tooltip

> A tooltip is a popup that displays information related to an element when the
> element receives keyboard focus or the mouse hovers over it.

*Note: The APG warns this pattern is work in progress and does not yet have
task force consensus.*

Tooltips provide supplementary descriptions. They appear after a brief delay on
hover/focus and disappear on blur/mouse-leave or `Escape`.

### Critical Constraints

- Tooltips **must not** contain interactive (focusable) content. If you need
  interactive content in a hover popup, use a non-modal dialog instead.
- Tooltips **do not receive focus**. Focus stays on the triggering element.
- The tooltip should remain visible while the cursor hovers over either the
  trigger **or** the tooltip itself.

> Tooltip widgets do not receive focus. A hover that contains focusable elements
> can be made using a non-modal dialog.

### Keyboard Interaction

| Key | Action |
|-----|--------|
| `Escape` | Dismiss the tooltip. |

No other keyboard interaction is required. The tooltip appears automatically
when the trigger element receives focus and disappears on blur.

### Required ARIA Roles, States & Properties

| Attribute | Element | Value / Notes |
|-----------|---------|---------------|
| `role="tooltip"` | Tooltip popup element | Identifies the popup as a tooltip. |
| `aria-describedby` | Trigger element | References the tooltip element's `id`. Links the trigger to its description. |

### Trigger Behaviour Summary

| Trigger | Shows Tooltip | Hides Tooltip |
|---------|---------------|---------------|
| Mouse hover on trigger | Yes (after brief delay) | On mouse leave from trigger **and** tooltip |
| Keyboard focus on trigger | Yes | On blur (focus leaves trigger) |
| `Escape` key | -- | Yes (immediate) |

### HTML Example

```html
<!-- CORRECT: tooltip with aria-describedby linkage -->
<button type="button"
        aria-describedby="tip-save">
  Save
</button>
<div id="tip-save" role="tooltip" class="tooltip">
  Save your current progress (Ctrl+S)
</div>

<!-- CORRECT: tooltip on a non-button element -->
<input type="text"
       aria-describedby="tip-username"
       placeholder="Username" />
<span id="tip-username" role="tooltip" class="tooltip">
  Must be 3-20 characters, letters and numbers only.
</span>

<!-- WRONG: tooltip contains interactive content -->
<button aria-describedby="tip-bad">Settings</button>
<div id="tip-bad" role="tooltip">
  <p>Configure your preferences</p>
  <a href="/settings">Open settings page</a>  <!-- focusable! -->
</div>
<!-- Use a non-modal dialog instead if you need links/buttons inside -->

<!-- WRONG: missing role="tooltip" and aria-describedby -->
<button>
  Save
  <span class="tooltip-text">Save progress</span>
</button>
<!-- AT has no way to associate the tooltip with the button -->

<!-- WRONG: using aria-labelledby instead of aria-describedby -->
<button aria-labelledby="tip-wrong">Save</button>
<div id="tip-wrong" role="tooltip">Save your progress</div>
<!-- aria-labelledby replaces the button's name; use aria-describedby
     to ADD a description while keeping the existing name -->
```

**CSS/JS responsibilities:**
1. Show tooltip on `:hover` and `:focus-visible` of the trigger (with a brief
   delay).
2. Keep tooltip visible while cursor is over the tooltip itself.
3. Hide on `Escape` keydown, blur, and mouse leave.
4. Position the tooltip so it does not overflow the viewport.

---

## 5. Accordion

> An accordion is a vertically stacked set of interactive headings that each
> contain a title, content snippet, or thumbnail representing a section of
> content. The headings function as controls that enable users to reveal or hide
> their associated sections of content.

Accordions reduce scrolling by collapsing content behind heading triggers.

### One Panel vs Multiple Panels

The APG does not restrict accordions to single-panel-open behaviour. Both are
valid:

| Mode | Behaviour |
|------|-----------|
| **Single** | Opening one panel closes any other open panel. |
| **Multiple** | Any number of panels can be open simultaneously. |

If a panel is required to stay open (e.g. the first panel), set
`aria-disabled="true"` on its header button to indicate it cannot be collapsed.

### Keyboard Interaction

| Key | Action |
|-----|--------|
| `Enter` or `Space` | Toggle the expanded/collapsed state of the focused header's panel. In single-open mode, collapse any other open panel. |
| `Tab` | Move focus to the next focusable element in document order (including elements inside open panels). |
| `Shift + Tab` | Move focus to the previous focusable element in document order. |
| `Down Arrow` *(optional)* | Move focus to the next accordion header. If focus is on the last accordion header, either does nothing or wraps to the first accordion header. |
| `Up Arrow` *(optional)* | Move focus to the previous accordion header. If focus is on the first accordion header, either does nothing or wraps to the last accordion header. |
| `Home` *(optional)* | Move focus to the **first** accordion header. |
| `End` *(optional)* | Move focus to the **last** accordion header. |

Arrow, Home, and End keys are **optional** enhancements. If implemented, they
apply only when focus is on an accordion header button.

### Required ARIA Roles, States & Properties

| Attribute | Element | Value / Notes |
|-----------|---------|---------------|
| `<hN>` or `role="heading"` + `aria-level` | Header wrapper | Each accordion header must be wrapped in a heading element at the appropriate level for the page hierarchy. |
| `role="button"` (or `<button>`) | Header trigger | The element inside the heading that the user activates to expand/collapse. A native `<button>` is preferred. |
| `aria-expanded="true\|false"` | Header button | `true` when the associated panel is visible; `false` when hidden. |
| `aria-controls` | Header button | References the `id` of the associated panel element. |
| `aria-disabled="true"` | Header button | (Optional) When an expanded panel cannot be collapsed. |
| `role="region"` | Panel container | (Optional but recommended) Makes the panel a landmark. Avoid if more than ~6 panels, as too many landmarks reduce their usefulness. |
| `aria-labelledby` | Panel container (`role="region"`) | References the `id` of the header button that controls it. |

### HTML Example

```html
<!-- CORRECT: accordion with proper heading/button/panel structure -->
<div class="accordion">
  <!-- Panel 1 (expanded) -->
  <h3>
    <button type="button"
            id="acc-btn-1"
            aria-expanded="true"
            aria-controls="acc-panel-1">
      Shipping Information
    </button>
  </h3>
  <div id="acc-panel-1"
       role="region"
       aria-labelledby="acc-btn-1">
    <p>We ship to all 50 states. Standard delivery takes 5-7 business days.</p>
  </div>

  <!-- Panel 2 (collapsed) -->
  <h3>
    <button type="button"
            id="acc-btn-2"
            aria-expanded="false"
            aria-controls="acc-panel-2">
      Return Policy
    </button>
  </h3>
  <div id="acc-panel-2"
       role="region"
       aria-labelledby="acc-btn-2"
       hidden>
    <p>Returns accepted within 30 days of purchase.</p>
  </div>
</div>

<!-- WRONG: using div instead of heading, no button role -->
<div class="accordion">
  <div class="accordion-header" onclick="toggle(1)">
    Shipping Information
  </div>
  <div class="accordion-panel">
    <p>We ship to all 50 states.</p>
  </div>
</div>
<!-- Missing: heading wrapper, button element, aria-expanded,
     aria-controls, region role, aria-labelledby -->

<!-- WRONG: aria-expanded on the panel instead of the button -->
<h3>
  <button aria-controls="panel-1">Shipping</button>
</h3>
<div id="panel-1" aria-expanded="true" role="region">
  <p>Content here.</p>
</div>
<!-- aria-expanded belongs on the BUTTON, not the panel -->
```

---

## 6. Disclosure (Show/Hide)

> A disclosure is a widget that enables content to be either collapsed (hidden)
> or expanded (visible). It has two elements: a disclosure button and a section
> of content whose visibility is controlled by the button.

Disclosure is the simplest show/hide pattern -- a single button toggling a
single content section.

### Disclosure vs Accordion

| Aspect | Disclosure | Accordion |
|--------|-----------|-----------|
| Structure | Single button + single content section | Multiple heading/panel pairs stacked vertically |
| Heading required | No | Yes -- each trigger must be inside a heading element |
| `role="region"` on panel | Not required | Recommended |
| Linked panels | Independent -- toggling one has no effect on others | In single-open mode, opening one may close another |
| `aria-controls` | Optional | Required |

*Editorial comparison -- the APG disclosure page does not compare these patterns.*

A page with multiple independent disclosure widgets is **not** an accordion.
An accordion is specifically a vertically stacked group with heading semantics
and optionally coordinated open/close behaviour.

### Keyboard Interaction

| Key | Action |
|-----|--------|
| `Enter` | Activate the disclosure button; toggle content visibility. |
| `Space` | Activate the disclosure button; toggle content visibility. |

Both keys produce identical behaviour. No additional keyboard handling is
needed (no arrow keys, no Home/End).

### Required ARIA Roles, States & Properties

| Attribute | Element | Value / Notes |
|-----------|---------|---------------|
| `role="button"` (or `<button>`) | Disclosure trigger | Identifies the trigger as a button. A native `<button>` is preferred. |
| `aria-expanded="true\|false"` | Disclosure button | `true` when the controlled content is visible; `false` when hidden. |
| `aria-controls` | Disclosure button | (Optional) References the `id` of the content element being shown/hidden. |

### HTML Example

```html
<!-- CORRECT: disclosure with native button and aria-expanded -->
<button type="button"
        aria-expanded="false"
        aria-controls="faq-answer-1">
  What is your return policy?
</button>
<div id="faq-answer-1" hidden>
  <p>You can return any item within 30 days for a full refund.</p>
</div>

<!-- CORRECT: navigation menu disclosure -->
<nav>
  <button type="button"
          aria-expanded="false"
          aria-controls="nav-submenu">
    Products
  </button>
  <ul id="nav-submenu" hidden>
    <li><a href="/widgets">Widgets</a></li>
    <li><a href="/gadgets">Gadgets</a></li>
  </ul>
</nav>

<!-- WRONG: using a link instead of a button for the trigger -->
<a href="#" aria-expanded="false" onclick="toggle()">
  Show details
</a>
<div id="details">Details here.</div>
<!-- A disclosure trigger must be a button, not a link.
     Links navigate; buttons perform actions. -->

<!-- WRONG: missing aria-expanded -->
<button onclick="toggle()">Show details</button>
<div id="details" hidden>Details here.</div>
<!-- AT has no way to know the current expanded/collapsed state -->

<!-- WRONG: toggling display with CSS alone, no hidden attribute or
     aria-expanded update -->
<button class="disclosure-btn">More info</button>
<div class="disclosure-content" style="display:none">
  More info here.
</div>
<!-- Even if visually hidden, AT needs aria-expanded on the button
     and the content must be properly hidden from the accessibility tree -->
```

---

## Cross-References

- See also: [Keyboard & Focus](keyboard-and-focus.md) -- focus trapping in modal dialogs, returning focus on close, `tabindex="-1"` for non-interactive focus targets.
- See also: [Landmarks & Structure](landmarks-and-structure.md) -- using `aria-hidden="true"` on background content behind modal dialogs, `role="region"` for accordion panels.
- See also: [Names & Descriptions](names-and-descriptions.md) -- `aria-labelledby` and `aria-label` for naming dialogs, `aria-describedby` for alert dialog messages and tooltip associations.
