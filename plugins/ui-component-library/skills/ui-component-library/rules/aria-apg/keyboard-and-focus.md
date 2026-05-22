# Keyboard & Focus Management

Sources:
- https://www.w3.org/WAI/ARIA/apg/practices/keyboard-interface/

---

## Table of Contents
1. [1. Fundamental Keyboard Navigation Model](#1-fundamental-keyboard-navigation-model)
2. [2. Roving `tabindex` Pattern](#2-roving-tabindex-pattern)
3. [3. `aria-activedescendant` Pattern](#3-aria-activedescendant-pattern)
4. [4. Focus Visibility Requirements](#4-focus-visibility-requirements)
5. [5. Keyboard Shortcut Conventions and Rules](#5-keyboard-shortcut-conventions-and-rules)
6. [6. Focus Persistence Across Dynamic Content Updates](#6-focus-persistence-across-dynamic-content-updates)
7. [7. Grid Navigation Pattern (2D Arrow Key Movement)](#7-grid-navigation-pattern-2d-arrow-key-movement)
8. [8. Composite Widget Key Conventions Summary](#8-composite-widget-key-conventions-summary)
9. [9. The Tab Sequence (`tabindex` Values)](#9-the-tab-sequence-tabindex-values)
10. [10. Focus vs. Selection](#10-focus-vs-selection)
11. [11. Pointer and Keyboard Alignment](#11-pointer-and-keyboard-alignment)
12. [12. Predictable Focus Movement Guidelines](#12-predictable-focus-movement-guidelines)

---

## 1. Fundamental Keyboard Navigation Model

The APG defines a two-tier navigation system that separates movement **between** components from movement **within** components.

> The tab and shift + tab keys move focus from one UI component to another while other keys, primarily the arrow keys, move focus inside of components that include multiple focusable elements.

The set of focusable components reachable by Tab/Shift+Tab is called **the tab sequence** (or tab ring). The critical rule for composite widgets is:

**Only one element per composite widget should be in the tab sequence. Internal navigation uses arrow keys.**

This mirrors how native OS GUIs work: Tab moves between a toolbar and a listbox; arrow keys move between buttons inside the toolbar.

### Composite Widgets (widgets that contain multiple focusable elements)

*Note: Navigation keys below are summarized from each pattern's individual APG page.*

| Widget Role       | Internal Navigation Keys   |
|-------------------|---------------------------|
| `combobox`        | Arrow keys (vertical)      |
| `grid`            | Arrow keys (2D)            |
| `listbox`         | Arrow keys (vertical)      |
| `menu` / `menubar`| Arrow keys (horizontal + vertical) |
| `radiogroup`      | Arrow keys                 |
| `tablist`         | Arrow keys (horizontal or vertical) |
| `toolbar`         | Arrow keys (horizontal)    |
| `treegrid`        | Arrow keys (2D)            |
| `tree`            | Arrow keys (vertical + expand/collapse) |

### Non-composite widgets

Non-composite widgets (buttons, links, single inputs) each occupy one stop in the tab sequence. There is no internal arrow-key navigation.

---

## 2. Roving `tabindex` Pattern

Roving tabindex is the primary technique for managing which element inside a composite widget is the tab stop.

### How it works

> When using roving tabindex to manage focus in a composite UI component, the element that is to be included in the tab sequence has `tabindex="0"` and all other focusable elements contained in the composite have `tabindex="-1"`.

### Algorithm

**Step 1 -- Initialization:**

> When the component container is loaded or created, set `tabindex="0"` on the element that will initially be included in the tab sequence and set `tabindex="-1"` on all other focusable elements it contains.

**Step 2 -- On navigation key press (e.g., arrow key):**

> - Set `tabindex="-1"` on the element that has `tabindex="0"`.
> - Set `tabindex="0"` on the element that will become focused as a result of the key event.
> - Set focus, `element.focus()`, on the element that has `tabindex="0"`.

**Step 3 -- On composite losing focus:**

> If the design calls for a specific element to be focused the next time the user moves focus into the composite with Tab or Shift + Tab, check if that target element has `tabindex="0"` when the composite loses focus. If it does not, set `tabindex="0"` on the target element and set `tabindex="-1"` on the element that previously had `tabindex="0"`.

### Code example

```html
<!-- CORRECT: roving tabindex in a toolbar -->
<div role="toolbar" aria-label="Text Formatting">
  <button tabindex="0" aria-pressed="false">Bold</button>
  <button tabindex="-1" aria-pressed="false">Italic</button>
  <button tabindex="-1" aria-pressed="false">Underline</button>
</div>

<script>
const toolbar = document.querySelector('[role="toolbar"]');
const buttons = toolbar.querySelectorAll('button');

toolbar.addEventListener('keydown', (e) => {
  const current = document.activeElement;
  let next;

  if (e.key === 'ArrowRight') {
    const idx = [...buttons].indexOf(current);
    next = buttons[(idx + 1) % buttons.length];
  } else if (e.key === 'ArrowLeft') {
    const idx = [...buttons].indexOf(current);
    next = buttons[(idx - 1 + buttons.length) % buttons.length];
  } else if (e.key === 'Home') {
    next = buttons[0];
  } else if (e.key === 'End') {
    next = buttons[buttons.length - 1];
  }

  if (next) {
    e.preventDefault();
    current.setAttribute('tabindex', '-1');
    next.setAttribute('tabindex', '0');
    next.focus();
  }
});
</script>
```

```html
<!-- WRONG: all items have tabindex="0" -->
<div role="toolbar" aria-label="Text Formatting">
  <button tabindex="0">Bold</button>
  <button tabindex="0">Italic</button>
  <button tabindex="0">Underline</button>
</div>
<!-- This forces the user to Tab through every button
     instead of arrowing, defeating the composite pattern -->
```

### Key benefit

> One benefit of using roving tabindex rather than aria-activedescendant to manage focus is that the user agent will scroll the newly focused element into view.

### When to use roving tabindex

- When the composite widget needs native browser scroll-into-view behavior.
- When the focusable elements are real interactive elements (buttons, inputs, links).
- When you need native focus events (`:focus`, `:focus-visible`) on each item.

---

## 3. `aria-activedescendant` Pattern

An alternative to roving tabindex where **DOM focus stays on the container** and a property tells assistive technology which child is "active."

### How it works

> If a component container has an ARIA role that supports the aria-activedescendant property, it is not necessary to manipulate the tabindex attribute and move DOM focus among focusable elements within the container. Instead, only the container element needs to be included in the tab sequence.

> When the container has DOM focus, the value of aria-activedescendant on the container tells assistive technologies which element is active within the widget. Assistive technologies will consider the element referred to as active to be the focused element even though DOM focus is on the element that has the aria-activedescendant property.

### Algorithm

**Step 1 -- Initialization:**

> Ensure that the container element is included in the tab sequence [...] and that it has `aria-activedescendant="IDREF"` where IDREF is the id of the element within the container that should be identified as active when the widget receives focus.

**Step 2 -- On container receiving DOM focus:**

> Draw a visual focus indicator on the active element and ensure the active element is scrolled into view.

**Step 3 -- On navigation key press (e.g., arrow key):**

> - Change the value of aria-activedescendant on the container to refer to the element that should be reported to assistive technologies as active.
> - Move the visual focus indicator and, if necessary, scroll the active element into view.

**Step 4 -- On focus loss:**

> If the design calls for a specific element to be focused the next time a user moves focus into the composite with Tab or Shift+Tab, check if aria-activedescendant is referring to that target element when the container loses focus. If it is not, set aria-activedescendant to refer to the target element.

### DOM relationship requirements

The APG places strict restrictions on the DOM relationship between the container (which has DOM focus and the `aria-activedescendant` attribute) and the referenced active element. **One of three conditions must be true:**

1. The active element is a **DOM descendant** of the focused container.
2. The container has an `aria-owns` property that includes the active element's ID.
3. The container is a `combobox`, `textbox`, or `searchbox` with `aria-controls` pointing to an element whose role supports `aria-activedescendant`, and the active element is either a descendant of that controlled element or included in its `aria-owns`.

### Code example

```html
<!-- CORRECT: aria-activedescendant on a listbox -->
<ul role="listbox"
    tabindex="0"
    aria-activedescendant="opt-2"
    aria-label="Choose a color">
  <li role="option" id="opt-1">Red</li>
  <li role="option" id="opt-2">Green</li>   <!-- visually focused -->
  <li role="option" id="opt-3">Blue</li>
</ul>

<style>
  /* You must manually style the active descendant --
     the browser does NOT apply :focus styles to it */
  [role="listbox"]:focus [role="option"][id="opt-2"],
  [role="listbox"]:focus-within .is-active {
    outline: 2px solid var(--focus-color);
    outline-offset: -2px;
  }
</style>

<script>
const listbox = document.querySelector('[role="listbox"]');
const options = listbox.querySelectorAll('[role="option"]');

listbox.addEventListener('keydown', (e) => {
  const currentId = listbox.getAttribute('aria-activedescendant');
  const currentEl = document.getElementById(currentId);
  const idx = [...options].indexOf(currentEl);
  let nextIdx = idx;

  if (e.key === 'ArrowDown') {
    nextIdx = Math.min(idx + 1, options.length - 1);
  } else if (e.key === 'ArrowUp') {
    nextIdx = Math.max(idx - 1, 0);
  } else if (e.key === 'Home') {
    nextIdx = 0;
  } else if (e.key === 'End') {
    nextIdx = options.length - 1;
  }

  if (nextIdx !== idx) {
    e.preventDefault();
    // Remove visual indicator from old
    currentEl.classList.remove('is-active');
    // Set new active descendant
    const next = options[nextIdx];
    next.classList.add('is-active');
    listbox.setAttribute('aria-activedescendant', next.id);
    // Scroll into view manually (browser will NOT do this)
    next.scrollIntoView({ block: 'nearest' });
  }
});
</script>
```

```html
<!-- WRONG: aria-activedescendant pointing to element outside DOM hierarchy
     without aria-owns or aria-controls relationship -->
<div role="listbox" tabindex="0" aria-activedescendant="external-opt">
  <div role="option" id="opt-a">A</div>
</div>
<div id="external-opt" role="option">External</div>
<!-- The active element is NOT a descendant and there is no
     aria-owns -- assistive tech will ignore the reference -->
```

### Comparison: roving tabindex vs. aria-activedescendant

*Editorial comparison — the APG discusses both techniques but does not provide this side-by-side table.*

| Aspect | Roving `tabindex` | `aria-activedescendant` |
|--------|-------------------|------------------------|
| DOM focus moves to each item | Yes | No -- stays on container |
| Browser scrolls item into view | Yes (automatic) | No (manual `scrollIntoView` needed) |
| `:focus` / `:focus-visible` on item | Yes (native) | No (must style manually) |
| `tabindex` attribute manipulation | Yes, on every navigation | No |
| Container must support the property | No requirement | Yes -- role must support `aria-activedescendant` |
| Works with items outside container DOM | No | Yes (via `aria-owns` or `aria-controls`) |
| Pointer + keyboard sync | Each item is separately focusable | Click handler must update `aria-activedescendant` |
| Performance with many items | Each item needs attribute update | Only one attribute update on container |

---

## 4. Focus Visibility Requirements

### Two Essentials

> When operating with a keyboard, two essentials of a good experience are the abilities to easily discern the location of the keyboard focus and to discover where focus landed after a navigation key has been pressed.

**4a. Discernibility (visibility):**

> Users need to be able to easily distinguish the keyboard focus indicator from other features of the visual design. Just as a mouse user may move the mouse to help find the mouse pointer, a keyboard user may press a navigation key to watch for movement. If visual changes in response to focus movement are subtle, many users will lose track of focus and be unable to operate.

**4b. Persistence:**

> It is essential that there is always a component within the user interface that is active (document.activeElement is not null or is not the body element) and that the active element has a visual focus indicator. Authors need to manage events that affect the currently active element so focus remains visible and moves logically. For example, if the user closes a dialog or performs a destructive operation like deleting an item from a list, the active element may be hidden or removed from the DOM. If such events are not managed to set focus on the button that triggered the dialog or on the list item following the deleted item, browsers move focus to the body element, effectively causing a loss of focus within the user interface.

**4c. Predictability:**

> Usability of a keyboard interface is heavily influenced by how readily users can guess where focus will land after a navigation key is pressed.

### Implementation guidance

- Rely on default browser focus indicators as a baseline; enhance, do not remove.
- Avoid subtle color or gradient changes for focus indicators -- they disappear in Windows High Contrast Mode.
- Focus indicator must be visually distinct from the selection indicator.
- Do not auto-focus an element on page load unless the page serves a single primary function (e.g., a search page focusing the search box).

```css
/* CORRECT: enhanced focus indicator that works in high contrast */
:focus-visible {
  outline: 2px solid var(--z-color-focus, #005fcc);
  outline-offset: 2px;
}

/* Also provide for aria-activedescendant containers */
[role="listbox"]:focus [aria-selected="true"],
[role="listbox"]:focus .is-active-descendant {
  outline: 2px solid var(--z-color-focus, #005fcc);
  outline-offset: -2px;
}
```

```css
/* WRONG: removing outline without replacement */
:focus {
  outline: none;
}
/* Keyboard users can no longer see where they are */
```

---

## 5. Keyboard Shortcut Conventions and Rules

### Design philosophy

> The first goal when designing a keyboard interface is simple, efficient, and intuitive operation with only basic keyboard navigation support. If basic operation of a keyboard interface is inefficient, attempting to compensate for fundamental design issues, such as suboptimal layout or command structure, by implementing keyboard shortcuts will not likely reduce user frustration.

### Prerequisite rule

> Before assigning keyboard shortcuts, it is essential to ensure the features and functions to which shortcuts may be assigned are keyboard accessible without a keyboard shortcut.

> If people who rely on the keyboard have to read documentation to learn which keys are required to use an interface, the interface may technically meet some accessibility standards but in practice is only accessible to the small subset of them who have the knowledge that such documentation exists, have the extra time available, and the ability to retain the necessary information.

### Shortcut behavior types

| Behavior | Description | Example |
|----------|-------------|---------|
| **Navigation** | Move focus to an element | Focus a search box, jump to a toolbar |
| **Activation** | Perform action without moving focus | Copy, paste, save (context stays where focus is) |
| **Navigation + Activation** | Move focus AND trigger action | Button that opens a dialog, checkbox toggle, link navigation |

### Standard key assignments

| Function | Windows / Linux | macOS |
|----------|-----------------|-------|
| Open context menu | Shift + F10 | -- |
| Copy | Control + C | Command + C |
| Paste | Control + V | Command + V |
| Cut | Control + X | Command + X |
| Undo | Control + Z | Command + Z |
| Redo | Control + Y | Command + Shift + Z |

### Mnemonic strategy

Use letter associations for shortcuts, e.g., Control + S for "Save," Control + B for "Bold." This reduces the learning curve.

### Conflicts to avoid

**Operating system reserved:**
- Modifier + Tab, Enter, Space, Escape
- Meta key (Windows key / Command) + any single printable key
- Alt + function keys
- System zoom, copy/paste combos

**Assistive technology reserved:**
- Caps Lock + any combination
- Insert + any combination
- Scroll Lock + any combination
- macOS: Control + Option + any combination

**Browser shortcuts to avoid (high-frequency user operations):**
- Address bar focus (Ctrl+L / Cmd+L)
- Page refresh (Ctrl+R / Cmd+R, F5)
- Find on page (Ctrl+F / Cmd+F)
- Bookmarks (Ctrl+D / Cmd+D)
- History (Ctrl+H / Cmd+Y)
- New tab (Ctrl+T / Cmd+T)
- Close tab (Ctrl+W / Cmd+W)

**When intentional conflicts are acceptable:**

A web app may intentionally override a browser shortcut when:
1. The app has a frequently-used function similar to the browser function.
2. Users commonly want the app function, not the browser function.
3. Users rarely need the browser function in this context.
4. An efficient alternative path to the browser function exists.

---

## 6. Focus Persistence Across Dynamic Content Updates

### The core problem

When an element that has focus is removed from the DOM or hidden, browsers move focus to `<body>`, which is effectively a total loss of focus position. The user has to Tab from the beginning of the page.

### Rules for managing focus during DOM mutations

*Note: The APG specifically discusses dialog-close and list-item-delete scenarios; other scenarios below are editorial best practices, not from this specific APG page.*

| Scenario | Where to move focus |
|----------|-------------------|
| Dialog closes | The button/element that opened the dialog |
| Item deleted from a list | The next item in the list (or previous if last was deleted) |
| Inline edit completes | The element that triggered the edit |
| Toast/notification dismissed | Do not move focus (it should not have been on the toast unless it was an `alertdialog`) |
| Tab panel removed | The nearest remaining tab |
| Accordion section collapses | The accordion header that was toggled |
| Content loaded asynchronously | Do not move focus unless the user explicitly triggered it; announce with `aria-live` instead |

### Code example

```html
<!-- CORRECT: focus management after list item deletion -->
<ul role="listbox" aria-label="Tasks" tabindex="0"
    aria-activedescendant="task-2">
  <li role="option" id="task-1">Buy groceries</li>
  <li role="option" id="task-2">Write report</li>   <!-- currently active -->
  <li role="option" id="task-3">Call dentist</li>
</ul>

<script>
function deleteTask(taskId) {
  const listbox = document.querySelector('[role="listbox"]');
  const item = document.getElementById(taskId);
  const options = [...listbox.querySelectorAll('[role="option"]')];
  const idx = options.indexOf(item);

  // Determine next focus target BEFORE removing
  const nextTarget = options[idx + 1] || options[idx - 1];

  item.remove();

  if (nextTarget) {
    listbox.setAttribute('aria-activedescendant', nextTarget.id);
    nextTarget.classList.add('is-active');
  }
  // Focus remains on the listbox container -- no jump to body
}
</script>
```

```html
<!-- WRONG: removing focused element without focus management -->
<script>
function deleteTask(taskId) {
  document.getElementById(taskId).remove();
  // Focus silently moves to <body>
  // Keyboard user is now lost
}
</script>
```

### Focusability of disabled controls

**Default convention:** Remove disabled elements from the tab sequence.

**Exceptions -- keep focusable even when disabled:**

| Widget | Keep disabled items focusable? | Rationale |
|--------|-------------------------------|-----------|
| Listbox options | Yes | Users need to discover all options |
| Menu / menubar items | Yes | Users expect to arrow through all items |
| Tab elements | Yes | Users need to know all tabs exist |
| Tree items | Yes | Users need to discover full tree structure |
| Toolbar buttons | Situational | If discoverability is a concern |

> Allowing keyboard users to skip disabled elements usually reduces the number of key presses required to complete a task. However, preventing focus from moving to disabled elements can hide their presence from screen reader users who "see" by moving the focus.

```html
<!-- CORRECT: disabled menu item is still focusable, announced as disabled -->
<ul role="menu">
  <li role="menuitem" tabindex="-1">Cut</li>
  <li role="menuitem" tabindex="-1" aria-disabled="true">Paste</li>
  <li role="menuitem" tabindex="-1">Delete</li>
</ul>
<!-- Note: use aria-disabled="true" NOT the native disabled attribute,
     because native disabled removes the element from focus order entirely -->
```

```html
<!-- WRONG: using native disabled on menu items hides them from keyboard -->
<ul role="menu">
  <li role="menuitem" tabindex="-1">Cut</li>
  <li><button role="menuitem" disabled>Paste</button></li>
  <li role="menuitem" tabindex="-1">Delete</li>
</ul>
<!-- Keyboard user arrows past "Paste" and never knows it exists -->
```

---

## 7. Grid Navigation Pattern (2D Arrow Key Movement)

Grids and treegrids use a two-dimensional arrow key navigation model. The keyboard model treats the grid as rows and cells, allowing movement along both axes.

### Grid keyboard interactions

| Key | Action |
|-----|--------|
| `ArrowRight` | Move focus one cell to the right. If at the last cell in a row, optionally wrap to first cell of next row or do nothing. |
| `ArrowLeft` | Move focus one cell to the left. If at the first cell in a row, optionally wrap to last cell of previous row or do nothing. |
| `ArrowDown` | Move focus one cell down in the same column. If at the last row, do nothing. |
| `ArrowUp` | Move focus one cell up in the same column. If at the first row, do nothing. |
| `Home` | Move focus to the first cell in the current row. |
| `End` | Move focus to the last cell in the current row. |
| `Ctrl + Home` | Move focus to the first cell in the first row. |
| `Ctrl + End` | Move focus to the last cell in the last row. |
| `Page Down` | Move focus down a page-determined number of rows (or to last row). |
| `Page Up` | Move focus up a page-determined number of rows (or to first row). |
| `Enter` | Activate the cell or enter edit mode if the cell is editable. |
| `Escape` | Exit edit mode, return focus to the cell. |
| `Tab` | Move focus to the next focusable element **outside** the grid (exits the composite). |

### Code example

```html
<!-- CORRECT: grid with roving tabindex for 2D navigation -->
<table role="grid" aria-label="Employee Directory">
  <thead>
    <tr>
      <th role="columnheader">Name</th>
      <th role="columnheader">Role</th>
      <th role="columnheader">Action</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td role="gridcell" tabindex="0">Alice</td>
      <td role="gridcell" tabindex="-1">Engineer</td>
      <td role="gridcell" tabindex="-1">
        <button tabindex="-1">Edit</button>
      </td>
    </tr>
    <tr>
      <td role="gridcell" tabindex="-1">Bob</td>
      <td role="gridcell" tabindex="-1">Designer</td>
      <td role="gridcell" tabindex="-1">
        <button tabindex="-1">Edit</button>
      </td>
    </tr>
  </tbody>
</table>
```

```html
<!-- WRONG: every cell and button in tab order -->
<table role="grid">
  <tr>
    <td role="gridcell" tabindex="0">Alice</td>
    <td role="gridcell" tabindex="0">Engineer</td>
    <td role="gridcell"><button>Edit</button></td>  <!-- button in tab order -->
  </tr>
</table>
<!-- User must Tab through every cell of every row to exit the grid -->
```

---

## 8. Composite Widget Key Conventions Summary

*Compiled from individual APG pattern pages.*

### Common keys across all composites

| Key | Behavior |
|-----|----------|
| `Tab` | Enter the composite (land on active element), then exit to next component |
| `Shift + Tab` | Enter the composite from the other direction, then exit to previous component |
| `Arrow keys` | Navigate between focusable items within the composite |
| `Home` | Move to first item |
| `End` | Move to last item |
| `Enter` / `Space` | Activate the current item (role-dependent) |
| `Escape` | Close/cancel (menus, dialogs, combobox popups) |

### Per-widget specifics

| Widget | Navigation direction | Enter/Space behavior | Escape behavior | Initial focus |
|--------|---------------------|----------------------|-----------------|---------------|
| `toolbar` | Horizontal arrows | Activate button | -- | First element |
| `menubar` | Horizontal arrows (top-level), vertical (submenus) | Open submenu or activate | Close submenu, return to parent | First element |
| `menu` | Vertical arrows | Activate item | Close menu, return to trigger | First element |
| `tablist` | Horizontal (or vertical) arrows | Select tab (or automatic) | -- | Selected tab, or first |
| `listbox` | Vertical arrows | Select option | -- | Selected option, or first |
| `radiogroup` | Arrow keys (all directions) | Select radio (selection follows focus) | -- | Selected radio, or first |
| `tree` | Vertical arrows; Right expands, Left collapses | Activate node | -- | Selected node, or first |
| `grid` | 2D arrows | Activate/edit cell | Exit edit mode | Last focused cell, or first |
| `combobox` | Vertical arrows (in popup) | Select and close popup | Close popup | -- |

---

## 9. The Tab Sequence (`tabindex` Values)

| `tabindex` value | Effect |
|------------------|--------|
| Not set / invalid | Default platform behavior (focusable only if natively interactive) |
| `tabindex="0"` | Included in tab sequence at DOM position |
| `tabindex="-1"` | **Not** in tab sequence but focusable via `element.focus()` |
| `tabindex="1"` through `tabindex="32767"` | **Do not use.** Overrides DOM order, causes unpredictable focus. |

> The most robust method of manipulating the order of the tab sequence while also maintaining alignment with the reading order that is currently available in all browsers is rearranging elements in the DOM.

```html
<!-- CORRECT: DOM order matches visual/reading order -->
<nav>
  <a href="/home">Home</a>
  <a href="/about">About</a>
  <a href="/contact">Contact</a>
</nav>

<!-- WRONG: positive tabindex overrides DOM order -->
<nav>
  <a href="/home" tabindex="3">Home</a>
  <a href="/about" tabindex="1">About</a>
  <a href="/contact" tabindex="2">Contact</a>
</nav>
<!-- Tab order is now About -> Contact -> Home, confusing and fragile -->
```

---

## 10. Focus vs. Selection

> From the keyboard user's perspective, focus is a pointer, like a mouse pointer; it tracks the path of navigation. There is only one point of focus at any time and all operations take place at the point of focus.

> From the developer's perspective, the difference is simple -- the focused element is the active element (document.activeElement). Selected elements are elements that have `aria-selected="true"`.

This distinction matters especially in multi-select widgets where the user can move focus independently of selection.

### Selection following focus

> In composite widgets where only one element may be selected, such as a tablist or single-select listbox, moving the focus may also cause the focused element to become the selected element. This is called having selection follow focus.

**Use selection-follows-focus when:**
- Content is already in the DOM (no network requests).
- Switching is instantaneous and low-cost.
- Example: tab panels whose content is pre-rendered.

**Do NOT use selection-follows-focus when:**
- Changing selection triggers a network request or page refresh.
- There is significant latency or side effects.

> If displaying a new tab refreshes the page, then the user not only has to wait for the new page to load but also return focus to the tab list.

> When selection does not follow focus, the user changes which element is selected by pressing the Enter or Space key.

---

## 11. Pointer and Keyboard Alignment

> When a component is clicked/tapped, authors should take the same steps to set the correct tabindex or aria-activedescendant for the element, in the same way that they would for keyboard navigation. Otherwise, this could lead to a confusing experience for users that switch between pointer and keyboard navigation.

This means every `click` handler on a composite widget item must also update the roving tabindex or `aria-activedescendant` so that a subsequent Tab/Shift+Tab or arrow key press starts from the correct position.

```html
<!-- CORRECT: click handler syncs roving tabindex -->
<script>
toolbar.addEventListener('click', (e) => {
  const btn = e.target.closest('button');
  if (!btn) return;

  // Same logic as arrow key handler
  const prev = toolbar.querySelector('[tabindex="0"]');
  if (prev) prev.setAttribute('tabindex', '-1');
  btn.setAttribute('tabindex', '0');
  btn.focus();
});
</script>
```

```html
<!-- WRONG: click handler does not update tabindex -->
<script>
toolbar.addEventListener('click', (e) => {
  const btn = e.target.closest('button');
  if (!btn) return;
  btn.focus(); // Focus moves, but tabindex still on old element
  // Next Tab press returns to wrong button
});
</script>
```

---

## 12. Predictable Focus Movement Guidelines

Design the tab sequence and focus order so users can predict where focus moves:

1. **Match reading order.** Left-to-right, top-to-bottom for LTR languages.
2. **Complete sections before moving on.** Tab through all elements in a toolbar before moving to the next landmark.
3. **Avoid backward jumps.** Do not move focus from bottom-right to top-left sidebar.
4. **Be consistent across pages.** Same layout should produce the same focus order.
5. **Do not auto-focus on page load** unless the page has a single primary function (e.g., login form, search page).

### Initial focus in composites

| Composite type | Initial focus convention |
|----------------|------------------------|
| Grid, Treegrid | Last focused element (or first cell if never focused) |
| Radio group, Tabs, Listbox, Tree | Selected element (or first if none selected) |
| Menubar, Toolbar | First element |

---

## Cross-references

- See also: [Form Controls](form-controls.md)
- See also: [Navigation & Menus](navigation-and-menus.md)
- See also: [Data Display Widgets](data-display-widgets.md)
