# Form Control Patterns

Reference for WAI-ARIA Authoring Practices Guide (APG) form control patterns.
Covers buttons, links, checkboxes, radios, switches, comboboxes, listboxes,
spinbuttons, sliders, and multi-thumb sliders.

## Sources:

- https://www.w3.org/WAI/ARIA/apg/patterns/button/
- https://www.w3.org/WAI/ARIA/apg/patterns/link/
- https://www.w3.org/WAI/ARIA/apg/patterns/checkbox/
- https://www.w3.org/WAI/ARIA/apg/patterns/radio/
- https://www.w3.org/WAI/ARIA/apg/patterns/switch/
- https://www.w3.org/WAI/ARIA/apg/patterns/combobox/
- https://www.w3.org/WAI/ARIA/apg/patterns/listbox/
- https://www.w3.org/WAI/ARIA/apg/patterns/spinbutton/
- https://www.w3.org/WAI/ARIA/apg/patterns/slider/
- https://www.w3.org/WAI/ARIA/apg/patterns/slider-multithumb/

---

## Table of Contents
1. [Button](#1-button)
2. [Link](#2-link)
3. [Checkbox](#3-checkbox)
4. [Radio Group](#4-radio-group)
5. [Switch](#5-switch)
6. [Combobox](#6-combobox)
7. [Listbox](#7-listbox)
8. [Spinbutton](#8-spinbutton)
9. [Slider](#9-slider)
10. [Multi-Thumb Slider](#10-multi-thumb-slider)

---

## 1. Button

A button triggers an action or event such as submitting a form, opening a
dialog, canceling an operation, or performing a delete. The APG defines three
button types:

- **Standard button** -- standard action trigger.
- **Toggle button** -- two-state button using `aria-pressed` (`true`/`false`).
- **Menu button** -- opens a menu via `aria-haspopup="menu"`.

> It is critical the label on a toggle does not change when its state changes.

### Keyboard Interaction

| Key | Action |
|---|---|
| `Enter` | Activates the button. |
| `Space` | Activates the button. |

After activation, focus placement depends on context: dialog-opening buttons
move focus into the dialog; dialog-closing buttons return focus to the trigger;
otherwise focus stays on the button.

### ARIA Roles, States & Properties

| Attribute | Usage |
|---|---|
| `role="button"` | Required on non-`<button>` elements. Native `<button>` has this implicitly. |
| Accessible name | Via text content, `aria-labelledby`, or `aria-label`. Required. |
| `aria-describedby` | Optional. References an element describing the button. |
| `aria-disabled="true"` | When the action is unavailable. |
| `aria-pressed="true\|false"` | Toggle buttons only. Indicates current pressed state. |

### Code Example

```html
<!-- CORRECT: native <button> with toggle state -->
<button type="button" aria-pressed="false" onclick="toggle(this)">
  Mute
</button>

<!-- CORRECT: custom element with role -->
<div role="button" tabindex="0" aria-pressed="false">
  Mute
</div>

<!-- WRONG: missing role and tabindex on non-native element -->
<div onclick="toggle(this)">Mute</div>

<!-- WRONG: label changes with state instead of staying constant -->
<button aria-pressed="false" onclick="this.textContent = this.textContent === 'Mute' ? 'Unmute' : 'Mute'">
  Mute
</button>
```

---

## 2. Link

A link is an interactive reference to a resource. It navigates the user to that
resource when activated.

> Authors are strongly encouraged to use a native host language link element,
> such as an HTML `<a>` element with an `href` attribute.

Applying `role="link"` to a non-anchor element does **not** provide standard
browser link behaviors (context menu, middle-click open in new tab, etc.).
The author must reimplement all of them.

### Keyboard Interaction

| Key | Action |
|---|---|
| `Enter` | Activates the link, navigates to the target. |
| `Shift + F10` | (Optional) Opens context menu for the link. |

Note: Unlike buttons, `Space` does **not** activate a link.

### ARIA Roles, States & Properties

| Attribute | Usage |
|---|---|
| `role="link"` | Required on non-`<a>` elements. Native `<a href>` has this implicitly. |
| Accessible name | Via text content, `aria-labelledby`, or `aria-label`. Required. |
| `tabindex="0"` | Required on non-native elements to make them focusable. |

### Code Example

```html
<!-- CORRECT: native anchor element -->
<a href="/settings">Settings</a>

<!-- CORRECT: custom link with role, tabindex, and keyboard handler -->
<span role="link" tabindex="0"
      onclick="navigate('/settings')"
      onkeydown="if(event.key==='Enter') navigate('/settings')">
  Settings
</span>

<!-- WRONG: missing href makes <a> non-focusable and removes implicit role -->
<a onclick="navigate('/settings')">Settings</a>

<!-- WRONG: div without role or tabindex -->
<div onclick="navigate('/settings')">Settings</div>
```

---

## 3. Checkbox

A checkbox toggles between checked and unchecked. A **tri-state** (mixed)
checkbox adds a third partially-checked state, commonly used as a parent
control that reflects the aggregate state of a group of child checkboxes.

> When the checkbox has focus, pressing the Space key changes the state of
> the checkbox.

### Tri-State Behavior

| Child States | Parent Displays |
|---|---|
| All checked | Checked (`aria-checked="true"`) |
| Some checked | Mixed (`aria-checked="mixed"`) |
| None checked | Unchecked (`aria-checked="false"`) |

Activating the parent checkbox checks or unchecks all children. Some
implementations restore the prior mixed selection on a second toggle.

### Keyboard Interaction

| Key | Action |
|---|---|
| `Space` | Toggles the checkbox state. |

### ARIA Roles, States & Properties

| Attribute | Usage |
|---|---|
| `role="checkbox"` | Required on non-`<input type="checkbox">` elements. |
| `aria-checked="true\|false\|mixed"` | Required. Current state. |
| Accessible name | Via text content, `aria-labelledby`, or `aria-label`. Required. |
| `role="group"` | Wraps a set of related checkboxes. |
| `aria-labelledby` on group | Labels the group with a visible heading. |
| `aria-describedby` | Optional. Additional description. |
| `tabindex="0"` | Required on non-native elements. |

### Code Example

```html
<!-- CORRECT: native checkbox -->
<label>
  <input type="checkbox" name="agree" />
  I agree to the terms
</label>

<!-- CORRECT: custom tri-state checkbox -->
<div role="group" aria-labelledby="toppings-label">
  <h3 id="toppings-label">Toppings</h3>

  <div role="checkbox" tabindex="0"
       aria-checked="mixed" aria-labelledby="all-label">
    <span id="all-label">All toppings</span>
  </div>

  <div role="checkbox" tabindex="0"
       aria-checked="true" aria-labelledby="cheese-label">
    <span id="cheese-label">Cheese</span>
  </div>

  <div role="checkbox" tabindex="0"
       aria-checked="false" aria-labelledby="olives-label">
    <span id="olives-label">Olives</span>
  </div>
</div>

<!-- WRONG: missing aria-checked -->
<div role="checkbox" tabindex="0">Accept</div>

<!-- WRONG: using aria-selected instead of aria-checked -->
<div role="checkbox" tabindex="0" aria-selected="true">Accept</div>
```

---

## 4. Radio Group

> A radio group is a set of checkable buttons, known as radio buttons, where
> no more than one of the buttons can be checked at a time.

Arrow keys move focus **and** selection together (roving tabindex). Only one
radio in the group is in the tab order at a time.

### Keyboard Interaction

| Key | Action |
|---|---|
| `Tab` | Moves focus into the group (to the checked radio, or the first if none checked). |
| `Shift + Tab` | Moves focus out of the group. |
| `Space` | Checks the focused radio if not already checked. |
| `Right Arrow` / `Down Arrow` | Focus to next radio, checks it. Wraps from last to first. |
| `Left Arrow` / `Up Arrow` | Focus to previous radio, checks it. Wraps from first to last. |

**In a toolbar**, `Enter` (Optional) and `Space` check the focused radio (focus movement
does not auto-check). Arrow keys also navigate to sibling toolbar items when
reaching the edge of the group.

### ARIA Roles, States & Properties

| Attribute | Usage |
|---|---|
| `role="radiogroup"` | Container holding all radio buttons. Required. |
| `role="radio"` | Each individual radio button. Required. |
| `aria-checked="true\|false"` | Required. Exactly one radio has `true` (or none if initially unchecked). |
| Accessible name on group | Via `aria-labelledby` or `aria-label`. Required. |
| Accessible name on each radio | Via text content, `aria-labelledby`, or `aria-label`. Required. |
| `aria-describedby` | Optional. Additional description for the group or individual radios. |
| `tabindex="0"` | On the checked radio (or first radio). All others `tabindex="-1"`. |

### Code Example

```html
<!-- CORRECT: custom radio group with roving tabindex -->
<div role="radiogroup" aria-labelledby="drink-label">
  <h3 id="drink-label">Drink size</h3>

  <div role="radio" tabindex="0" aria-checked="true">Small</div>
  <div role="radio" tabindex="-1" aria-checked="false">Medium</div>
  <div role="radio" tabindex="-1" aria-checked="false">Large</div>
</div>

<!-- CORRECT: native fieldset with radio inputs -->
<fieldset>
  <legend>Drink size</legend>
  <label><input type="radio" name="size" value="s" checked /> Small</label>
  <label><input type="radio" name="size" value="m" /> Medium</label>
  <label><input type="radio" name="size" value="l" /> Large</label>
</fieldset>

<!-- WRONG: missing radiogroup container -->
<div>
  <div role="radio" aria-checked="true">Small</div>
  <div role="radio" aria-checked="false">Medium</div>
</div>

<!-- WRONG: multiple radios with aria-checked="true" -->
<div role="radiogroup" aria-label="Size">
  <div role="radio" aria-checked="true">Small</div>
  <div role="radio" aria-checked="true">Medium</div>
</div>
```

---

## 5. Switch

A switch is a binary on/off toggle. It differs from a checkbox in that a switch
has **exactly two states** (on/off) with no third "mixed" state. The semantic
framing matters: "Lights switch on" is more natural than "Lights checkbox
checked."

> It is critical the label on a switch does not change when its state changes.

### Keyboard Interaction

| Key | Action |
|---|---|
| `Space` | Toggles the switch between on and off. |
| `Enter` | (Optional) Toggles the switch between on and off. |

### ARIA Roles, States & Properties

| Attribute | Usage |
|---|---|
| `role="switch"` | Required. Identifies the element as a switch. |
| `aria-checked="true\|false"` | Required. `true` = on, `false` = off. |
| Accessible name | Via text content, `aria-labelledby`, or `aria-label`. Required. |
| `role="group"` or `<fieldset>` | Groups related switches with a shared label. |
| `aria-describedby` | Optional. Additional description. |
| `tabindex="0"` | Required on non-native elements. |

When using `<input type="checkbox" role="switch">`, the native `checked`
property maps to the on state; `aria-checked` is not required (the browser
maps it automatically).

### Code Example

```html
<!-- CORRECT: button-based switch -->
<button role="switch" aria-checked="false">
  Dark mode
</button>

<!-- CORRECT: checkbox-based switch -->
<label>
  <input type="checkbox" role="switch" />
  Dark mode
</label>

<!-- CORRECT: div-based switch with full ARIA -->
<div role="switch" tabindex="0" aria-checked="true"
     aria-labelledby="wifi-label">
  <span id="wifi-label">Wi-Fi</span>
</div>

<!-- WRONG: label changes with state -->
<button role="switch" aria-checked="false"
        onclick="this.textContent = this.getAttribute('aria-checked') === 'true' ? 'Enable' : 'Disable'">
  Enable
</button>

<!-- WRONG: using aria-pressed instead of aria-checked -->
<button role="switch" aria-pressed="false">Dark mode</button>
```

---

## 6. Combobox

> A combobox is an input widget that has an associated popup enabling users to
> choose values from a collection.

The popup can be a **listbox**, **grid**, **tree**, or **dialog**. The combobox
may be editable (text input + suggestions) or select-only (no typing, only
choosing).

### Autocomplete Types

| `aria-autocomplete` | Behavior |
|---|---|
| `none` | Popup shows all options regardless of input text. |
| `list` | Popup filters to options matching input text. |
| `both` | Filters like `list`, plus auto-completes the input with the best match (inline text selected). |

### Keyboard Interaction -- Combobox Input

| Key | Action |
|---|---|
| `Down Arrow` | Opens popup (if closed). Moves focus to first or auto-selected option. |
| `Up Arrow` | (Optional) Opens popup. Moves focus to last option. |
| `Escape` | Closes popup. Optionally clears input. |
| `Enter` | Accepts the currently selected/active option and closes popup. |
| `Alt + Down Arrow` | (Optional) Opens popup without moving focus into it. |
| `Alt + Up Arrow` | (Optional) Closes popup, returns focus to input. |
| Printable characters | Editable: types in the field. Select-only: optionally jumps to matching option. |

### Keyboard Interaction -- Listbox Popup

| Key | Action |
|---|---|
| `Enter` | Accepts focused option, closes popup. |
| `Escape` | Closes popup without accepting, returns focus to input. |
| `Down Arrow` | Moves focus to next option. |
| `Up Arrow` | Moves focus to previous option. |
| `Home` | (Optional) Moves focus to first option. |
| `End` | (Optional) Moves focus to last option. |
| `Right Arrow` | Returns focus to combobox and moves cursor one character right (editable comboboxes). |
| `Left Arrow` | Returns focus to combobox and moves cursor one character left (editable comboboxes). |
| `Backspace` | (Optional) Returns focus to combobox, deletes the character before the cursor. |
| `Delete` | (Optional) Returns focus to combobox, removes the selected state. |
| Printable characters | Editable: returns focus to input to type. Select-only: jumps to matching option. |

### Keyboard Interaction -- Grid Popup

| Key | Action |
|---|---|
| `Arrow keys` | Cell-by-cell navigation with optional wrapping. |
| `Page Up / Page Down` | (Optional) Move by multiple rows. |
| `Home / End` | (Optional) Jump to first/last cell in row. |
| `Ctrl + Home / Ctrl + End` | (Optional) Jump to first/last cell in grid. |

### Keyboard Interaction -- Tree Popup

| Key | Action |
|---|---|
| `Right Arrow` | Expands closed node; moves to first child of open node. |
| `Left Arrow` | Collapses open node; moves to parent of closed node. |
| `Down Arrow` | Moves to next visible node. |
| `Up Arrow` | Moves to previous visible node. |
| `Home / End` | First/last visible node. |

### ARIA Roles, States & Properties

| Attribute | Usage |
|---|---|
| `role="combobox"` | On the input element. Required. |
| `aria-expanded="true\|false"` | Required. Whether the popup is visible. |
| `aria-controls` | Required (when expanded). References the popup element's `id`. |
| `aria-haspopup` | `"listbox"` (default), `"grid"`, `"tree"`, or `"dialog"`. |
| `aria-activedescendant` | Points to the `id` of the focused option within the popup. DOM focus stays on combobox. |
| `aria-autocomplete` | `"none"`, `"list"`, or `"both"`. Required on editable comboboxes. |
| `aria-selected="true"` | On the currently highlighted option in the popup. |
| Accessible name | Via `aria-labelledby` or `aria-label`. Required. |

### Code Example

```html
<!-- CORRECT: editable combobox with listbox popup -->
<label id="state-label" for="state-input">State</label>
<div class="combobox-wrapper">
  <input id="state-input" type="text"
         role="combobox"
         aria-expanded="false"
         aria-autocomplete="list"
         aria-controls="state-listbox"
         aria-labelledby="state-label" />
  <ul id="state-listbox" role="listbox" hidden>
    <li role="option" id="opt-al">Alabama</li>
    <li role="option" id="opt-ak">Alaska</li>
    <li role="option" id="opt-az">Arizona</li>
  </ul>
</div>

<!-- CORRECT: select-only combobox (no text input) -->
<div role="combobox" tabindex="0"
     aria-expanded="false"
     aria-haspopup="listbox"
     aria-controls="color-listbox"
     aria-labelledby="color-label">
  <span id="color-label">Color</span>: <span>Red</span>
</div>
<ul id="color-listbox" role="listbox" hidden>
  <li role="option" aria-selected="true">Red</li>
  <li role="option">Green</li>
  <li role="option">Blue</li>
</ul>

<!-- WRONG: missing aria-expanded -->
<input role="combobox" aria-controls="list1" />

<!-- WRONG: aria-controls references nonexistent id -->
<input role="combobox" aria-expanded="false" aria-controls="nope" />
```

---

## 7. Listbox

A listbox presents a list of selectable options. Unlike a combobox popup, a
standalone listbox is always visible. Options cannot contain interactive
elements (links, buttons, etc.); use the grid pattern for that.

> Names starting with identical words or phrases significantly degrade
> usability -- consider hierarchical listboxes instead.

### Keyboard Interaction -- Single-Select

| Key | Action |
|---|---|
| `Down Arrow` | Moves focus to next option. |
| `Up Arrow` | Moves focus to previous option. |
| `Home` | (Optional) Moves focus to first option (strongly recommended for lists with more than five options). |
| `End` | (Optional) Moves focus to last option (strongly recommended for lists with more than five options). |
| Type-ahead | Moves focus to next option starting with the typed character(s). |

On focus: if an option is selected, that option receives focus; otherwise the
first option receives focus. In single-select, selection typically follows
focus.

### Keyboard Interaction -- Multi-Select (Recommended Model)

All single-select keys apply, plus:

| Key | Action |
|---|---|
| `Space` | Toggles selection of focused option. |
| `Shift + Down Arrow` | (Optional) Moves focus and toggles selection state of next option. |
| `Shift + Up Arrow` | (Optional) Moves focus and toggles selection state of previous option. |
| `Shift + Space` | (Optional) Selects contiguous options from last selected to focused. |
| `Ctrl + Shift + Home` | (Optional) Selects from focused option to first option. |
| `Ctrl + Shift + End` | (Optional) Selects from focused option to last option. |
| `Ctrl + A` | (Optional) Selects all. If all selected, deselects all. |

### Keyboard Interaction -- Multi-Select (Alternative Model)

Moving focus without modifier keys deselects others (like single-select), plus:

| Key | Action |
|---|---|
| `Ctrl + Down / Up Arrow` | Moves focus without changing selection. |
| `Ctrl + Space` | Toggles selection of focused option. |
| `Shift + Down / Up Arrow` | Moves focus and extends selection. |
| `Shift + Space` | Selects range from anchor to focused option. |

### ARIA Roles, States & Properties

| Attribute | Usage |
|---|---|
| `role="listbox"` | Container. Required. |
| `role="option"` | Each selectable item. Required. |
| `role="group"` | Optional. Groups related options under a label. |
| `aria-multiselectable="true"` | On listbox when multi-select is enabled. |
| `aria-selected="true\|false"` | Required on each option. Reflects selection state. Alternatively, `aria-checked` may be used instead of `aria-selected` (never use both on the same option). |
| Accessible name on listbox | Via `aria-labelledby` or `aria-label`. Required. |
| `aria-activedescendant` | Alternative to roving tabindex. Points to the focused option's `id`. |
| `aria-orientation` | `"horizontal"` if horizontal. Default is `"vertical"`. |
| `aria-setsize` / `aria-posinset` | For virtualized lists where not all options are in the DOM. |

### Code Example

```html
<!-- CORRECT: single-select listbox -->
<label id="font-label">Font family</label>
<ul role="listbox" aria-labelledby="font-label" tabindex="0">
  <li role="option" id="opt-sans" aria-selected="true">Sans-serif</li>
  <li role="option" id="opt-serif" aria-selected="false">Serif</li>
  <li role="option" id="opt-mono" aria-selected="false">Monospace</li>
</ul>

<!-- CORRECT: multi-select listbox -->
<label id="topping-label">Toppings</label>
<ul role="listbox" aria-labelledby="topping-label"
    aria-multiselectable="true" tabindex="0">
  <li role="option" aria-selected="false">Cheese</li>
  <li role="option" aria-selected="true">Pepperoni</li>
  <li role="option" aria-selected="true">Mushrooms</li>
</ul>

<!-- WRONG: option missing aria-selected -->
<ul role="listbox" aria-label="Colors">
  <li role="option">Red</li>
</ul>

<!-- WRONG: interactive content inside an option -->
<ul role="listbox" aria-label="Files">
  <li role="option"><a href="/file.pdf">Download</a></li>
</ul>
```

---

## 8. Spinbutton

A spinbutton restricts input to a discrete set of allowed values within a
range. It typically shows a text field (the focusable element) with increment
and decrement buttons. Arrow keys on the text field handle stepping, so the
+/- buttons are supplementary and usually not in the tab order.

### Keyboard Interaction

| Key | Action |
|---|---|
| `Up Arrow` | Increments the value by one step. |
| `Down Arrow` | Decrements the value by one step. |
| `Home` | Sets value to `aria-valuemin` (if defined). |
| `End` | Sets value to `aria-valuemax` (if defined). |
| `Page Up` | (Optional) Increments by a larger step. |
| `Page Down` | (Optional) Decrements by a larger step. |
| Printable characters | Standard text editing within the field. |

### ARIA Roles, States & Properties

| Attribute | Usage |
|---|---|
| `role="spinbutton"` | On the focusable text field. Required. |
| `aria-valuenow` | Required. Current numeric value. |
| `aria-valuemin` | Minimum allowed value. Required when a minimum exists. |
| `aria-valuemax` | Maximum allowed value. Required when a maximum exists. |
| `aria-valuetext` | Human-readable alternative (e.g. `"Monday"` instead of `1`). |
| Accessible name | Via `aria-labelledby` or `aria-label`. Required. |
| `aria-invalid="true"` | Applied when the current value is outside the valid range. |

### Code Example

```html
<!-- CORRECT: spinbutton for quantity -->
<label id="qty-label">Quantity</label>
<div class="spinbutton-wrapper">
  <button tabindex="-1" aria-label="Decrease">-</button>
  <div role="spinbutton" tabindex="0"
       aria-labelledby="qty-label"
       aria-valuenow="1"
       aria-valuemin="0"
       aria-valuemax="99">
    1
  </div>
  <button tabindex="-1" aria-label="Increase">+</button>
</div>

<!-- CORRECT: native number input (preferred when sufficient) -->
<label for="qty">Quantity</label>
<input id="qty" type="number" min="0" max="99" value="1" />

<!-- WRONG: missing aria-valuenow -->
<div role="spinbutton" tabindex="0"
     aria-valuemin="0" aria-valuemax="10">
  5
</div>

<!-- WRONG: using aria-valuetext without aria-valuenow -->
<div role="spinbutton" tabindex="0"
     aria-valuetext="Monday">
  Monday
</div>
```

---

## 9. Slider

A slider lets the user pick a value from a range by dragging a thumb along a
track or using keyboard keys. Default orientation is horizontal.

### Keyboard Interaction

| Key | Action |
|---|---|
| `Right Arrow` | Increases value by one step. |
| `Up Arrow` | Increases value by one step. |
| `Left Arrow` | Decreases value by one step. |
| `Down Arrow` | Decreases value by one step. |
| `Home` | Sets value to `aria-valuemin`. |
| `End` | Sets value to `aria-valuemax`. |
| `Page Up` | (Optional) Increases value by a larger step. |
| `Page Down` | (Optional) Decreases value by a larger step. |

Focus is placed on the slider thumb. For vertical sliders, `Up Arrow`
increases and `Down Arrow` decreases regardless of visual direction.

### ARIA Roles, States & Properties

| Attribute | Usage |
|---|---|
| `role="slider"` | On the focusable thumb element. Required. |
| `aria-valuenow` | Required. Current numeric value. |
| `aria-valuemin` | Required. Minimum value of the range. |
| `aria-valuemax` | Required. Maximum value of the range. |
| `aria-valuetext` | Human-readable alternative when the number alone is not meaningful. |
| `aria-orientation` | `"horizontal"` (default) or `"vertical"`. |
| Accessible name | Via `aria-labelledby` or `aria-label`. Required. |

### Code Example

```html
<!-- CORRECT: horizontal slider -->
<label id="vol-label">Volume</label>
<div class="slider-track">
  <div role="slider" tabindex="0"
       aria-labelledby="vol-label"
       aria-valuenow="50"
       aria-valuemin="0"
       aria-valuemax="100">
  </div>
</div>

<!-- CORRECT: vertical slider with aria-orientation -->
<label id="temp-label">Temperature</label>
<div class="slider-track vertical">
  <div role="slider" tabindex="0"
       aria-labelledby="temp-label"
       aria-orientation="vertical"
       aria-valuenow="72"
       aria-valuemin="60"
       aria-valuemax="90"
       aria-valuetext="72 degrees">
  </div>
</div>

<!-- CORRECT: native range input (preferred when sufficient) -->
<label for="brightness">Brightness</label>
<input id="brightness" type="range" min="0" max="100" value="50" />

<!-- WRONG: missing aria-valuemin and aria-valuemax -->
<div role="slider" tabindex="0" aria-valuenow="50">50</div>

<!-- WRONG: thumb is not focusable -->
<div role="slider" aria-valuenow="50"
     aria-valuemin="0" aria-valuemax="100">
</div>
```

---

## 10. Multi-Thumb Slider

A multi-thumb slider places two or more thumbs on a single track. Each thumb
sets one value in a related set, such as a price range (min/max). Each thumb
is an independent `role="slider"` element.

> In many two-thumb sliders, the thumbs are not allowed to pass one another.

When thumbs are dependent, the `aria-valuemin` of the upper thumb updates to
the lower thumb's current value, and the `aria-valuemax` of the lower thumb
updates to the upper thumb's current value. This prevents overlap.

> The values of aria-valuemin or aria-valuemax of the dependent sliders are
> updated when the value changes.

### Keyboard Interaction

Each thumb is in the tab order and supports the same keys as a single slider:

| Key | Action |
|---|---|
| `Right Arrow` | Increases thumb value by one step. |
| `Up Arrow` | Increases thumb value by one step. |
| `Left Arrow` | Decreases thumb value by one step. |
| `Down Arrow` | Decreases thumb value by one step. |
| `Home` | Sets thumb to its `aria-valuemin` (may be constrained by other thumb). |
| `End` | Sets thumb to its `aria-valuemax` (may be constrained by other thumb). |
| `Page Up` | (Optional) Increases by a larger step. |
| `Page Down` | (Optional) Decreases by a larger step. |
| `Tab` | Moves between thumbs and other focusable elements. Tab order is constant regardless of thumb position. |

### ARIA Roles, States & Properties

| Attribute | Usage |
|---|---|
| `role="slider"` | On each focusable thumb. Required. |
| `aria-valuenow` | Required. Current value of this thumb. |
| `aria-valuemin` | Required. Minimum value (dynamically updated for dependent thumbs). |
| `aria-valuemax` | Required. Maximum value (dynamically updated for dependent thumbs). |
| `aria-valuetext` | Human-readable alternative when numeric value is not meaningful. |
| `aria-orientation` | `"horizontal"` (default) or `"vertical"`. |
| Accessible name per thumb | Via `aria-labelledby` or `aria-label`. Required. Each thumb needs a distinct name (e.g. "Minimum price", "Maximum price"). |

### Preventing Thumb Overlap

When thumb A (min) has value 200 and thumb B (max) has value 800 on a
0--1000 range:

- Thumb A: `aria-valuemin="0"`, `aria-valuemax="800"` (clamped to thumb B).
- Thumb B: `aria-valuemin="200"` (clamped to thumb A), `aria-valuemax="1000"`.

When thumb A moves to 350, update thumb B's `aria-valuemin` to `"350"`.

### Code Example

```html
<!-- CORRECT: multi-thumb price range slider -->
<div class="slider-group" aria-label="Price range">
  <div class="slider-track">
    <!-- Lower thumb -->
    <div role="slider" tabindex="0"
         aria-label="Minimum price"
         aria-valuenow="200"
         aria-valuemin="0"
         aria-valuemax="800">
    </div>
    <!-- Upper thumb -->
    <div role="slider" tabindex="0"
         aria-label="Maximum price"
         aria-valuenow="800"
         aria-valuemin="200"
         aria-valuemax="1000">
    </div>
  </div>
</div>

<!-- WRONG: both thumbs share the same label -->
<div class="slider-track">
  <div role="slider" tabindex="0" aria-label="Price"
       aria-valuenow="200" aria-valuemin="0" aria-valuemax="1000"></div>
  <div role="slider" tabindex="0" aria-label="Price"
       aria-valuenow="800" aria-valuemin="0" aria-valuemax="1000"></div>
</div>

<!-- WRONG: aria-valuemin/max not updated dynamically -->
<div class="slider-track">
  <div role="slider" tabindex="0" aria-label="Min price"
       aria-valuenow="500" aria-valuemin="0" aria-valuemax="1000"></div>
  <div role="slider" tabindex="0" aria-label="Max price"
       aria-valuenow="300" aria-valuemin="0" aria-valuemax="1000"></div>
  <!-- BUG: max thumb (300) is less than min thumb (500) -->
</div>
```

### Accessibility Warning

> Touch-based assistive technologies may struggle with multi-thumb sliders,
> as synthesizing keyboard events from touch gestures is not universally
> supported.

Consider providing alternative input mechanisms (e.g., paired spinbuttons)
alongside multi-thumb sliders for maximum compatibility.

---

## Cross-References

- See also: [Keyboard & Focus](keyboard-and-focus.md) -- roving tabindex (radio groups, listboxes), `aria-activedescendant` (combobox, listbox), focus management after button activation.
- See also: [Names & Descriptions](names-and-descriptions.md) -- `aria-labelledby`, `aria-label`, `aria-describedby` for labeling all form controls.
- See also: [Grid, Table & Range](grid-table-range.md) -- range properties (`aria-valuenow`, `aria-valuemin`, `aria-valuemax`), grid popup for combobox.
