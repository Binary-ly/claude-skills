# Navigation & Menu Patterns

Sources:
- https://www.w3.org/WAI/ARIA/apg/patterns/menubar/
- https://www.w3.org/WAI/ARIA/apg/patterns/menu-button/
- https://www.w3.org/WAI/ARIA/apg/patterns/tabs/
- https://www.w3.org/WAI/ARIA/apg/patterns/toolbar/
- https://www.w3.org/WAI/ARIA/apg/patterns/breadcrumb/

---

## Table of Contents
1. [Menu Bar](#1-menu-bar)
2. [Menu Button](#2-menu-button)
3. [Tabs](#3-tabs)
4. [Toolbar](#4-toolbar)
5. [Breadcrumb](#5-breadcrumb)

---

## 1. Menu Bar

> "A menu is a widget that offers a list of choices to the user, such as a set of actions or functions. A menubar is typically a horizontal bar that contains a set of commands and provides persistent, visible access near the top of a window."

A menubar mirrors the behavior of desktop application menus. Items in the bar open vertical submenus. Each submenu can contain `menuitem`, `menuitemcheckbox`, or `menuitemradio` elements.

### Keyboard Interaction

| Key | Action |
|---|---|
| `Tab` | Moves focus into the menubar (first item or previously focused item). When inside a menu, moves focus out and closes all open menus. |
| `Enter` | If the menuitem has a submenu, opens it and focuses the first item. Otherwise activates the item and closes all menus. |
| `Space` | (Optional) On `menuitemcheckbox`: toggles checked state without closing. (Optional) On `menuitemradio`: checks the item and unchecks others in the group. (Optional) On `menuitem` with submenu: opens the submenu and moves focus to its first item. (Optional) Otherwise same as `Enter`. |
| `Down Arrow` | In the menubar: opens the submenu and focuses its first item. In a vertical menu: moves focus to the next item (optionally wraps to first). |
| `Up Arrow` | In a vertical menu: moves focus to the previous item (optionally wraps to last). In the menubar (optional): opens submenu and focuses its last item. |
| `Right Arrow` | In the menubar: moves focus to the next top-level item. In a submenu on an item with a child submenu: opens it. In a submenu on an item without a child submenu: closes the current submenu and opens the next top-level menu. |
| `Left Arrow` | In the menubar: moves focus to the previous top-level item. In a submenu: closes it and returns focus to the parent menuitem. If the parent is in the menubar, opens the previous top-level menu. |
| `Home` | If arrow key wrapping is not supported: moves focus to the first item in the current menu or menubar. |
| `End` | If arrow key wrapping is not supported: moves focus to the last item in the current menu or menubar. |
| `Escape` | Closes the currently open menu and returns focus to the invoking menubar item. |
| Printable character (optional) | Moves focus to the next item whose label starts with that character. |

### Required ARIA Roles, States, and Properties

| Attribute | Element | Purpose |
|---|---|---|
| `role="menubar"` | Container `<ul>` or `<div>` | Identifies the horizontal menu bar. |
| `role="menu"` | Submenu container | Identifies a vertical dropdown menu. |
| `role="menuitem"` | Each actionable item | Standard menu choice. |
| `role="menuitemcheckbox"` | Togglable item | A menu item with a checkable state. |
| `role="menuitemradio"` | Exclusive-choice item | A menu item in a mutually-exclusive group. |
| `role="separator"` | Divider element | Visually and semantically separates groups. |
| `aria-haspopup="menu"` | Parent menuitem that opens a submenu | Tells assistive technology a submenu exists. |
| `aria-expanded="true\|false"` | Parent menuitem that opens a submenu | Reflects whether the submenu is currently open. |
| `aria-checked="true\|false"` | `menuitemcheckbox` / `menuitemradio` | Reflects the checked state. |
| `aria-disabled="true"` | Disabled items | Marks an item as non-interactive. |
| `aria-label` or `aria-labelledby` | `menubar` / `menu` | Provides an accessible name for the menu region. |
| `aria-orientation` | `menu` | `"vertical"` (default) or `"horizontal"`. Usually omitted on `menubar` since horizontal is implied. |
| `tabindex="0"` / `tabindex="-1"` | Each menuitem | Roving tabindex: only the currently focused item has `tabindex="0"`. |

### HTML Example

```html
<!-- CORRECT — semantic menubar with proper ARIA -->
<nav aria-label="Application menu">
  <ul role="menubar" aria-label="Formatting">
    <li role="none">
      <a role="menuitem" tabindex="0" aria-haspopup="menu" aria-expanded="false">
        File
      </a>
      <ul role="menu" aria-label="File">
        <li role="none">
          <a role="menuitem" tabindex="-1">New</a>
        </li>
        <li role="none">
          <a role="menuitem" tabindex="-1">Open</a>
        </li>
        <li role="separator"></li>
        <li role="none">
          <a role="menuitem" tabindex="-1">Save</a>
        </li>
      </ul>
    </li>
    <li role="none">
      <a role="menuitem" tabindex="-1" aria-haspopup="menu" aria-expanded="false">
        Edit
      </a>
      <ul role="menu" aria-label="Edit">
        <li role="none">
          <a role="menuitem" tabindex="-1">Undo</a>
        </li>
        <li role="none">
          <a role="menuitemcheckbox" tabindex="-1" aria-checked="false">
            Word Wrap
          </a>
        </li>
      </ul>
    </li>
  </ul>
</nav>

<!-- WRONG — missing roles, no keyboard support, no aria-expanded -->
<nav>
  <ul>
    <li>
      <a href="#">File</a>
      <ul class="dropdown">
        <li><a href="#">New</a></li>
        <li><a href="#">Open</a></li>
      </ul>
    </li>
  </ul>
</nav>

```

> The APG provides both action menu examples (e.g., editor menubars with commands like File > Save) and a "Navigation Menubar Example" that uses `menubar` for site navigation with links. Choose the pattern that matches your use case.

---

## 2. Menu Button

> "A menu button is a button that opens a menu. It is often styled with a downward pointing arrow or triangle to hint that activating the button will display a menu."

Two common patterns exist:
1. **Action menu button** -- opens a `role="menu"` containing `menuitem` elements that trigger commands.
2. **Navigation menu button** -- opens a menu of links (built with `<a>` elements inside `menuitem` roles).

### Keyboard Interaction

| Key | Action |
|---|---|
| `Enter` | Opens the menu and places focus on the first menu item. |
| `Space` | Opens the menu and places focus on the first menu item. |
| `Down Arrow` (optional) | Opens the menu and moves focus to the first menu item. |
| `Up Arrow` (optional) | Opens the menu and moves focus to the last menu item. |
| `Escape` | Closes the menu and returns focus to the button. |

> Once the menu is open, keyboard behavior follows the Menu and Menubar pattern (arrow keys move between items, `Enter`/`Space` activate, `Escape` closes).

### Required ARIA Roles, States, and Properties

| Attribute | Element | Purpose |
|---|---|---|
| `role="button"` (or native `<button>`) | The trigger | Identifies the element as a button. Native `<button>` is preferred. |
| `aria-haspopup="menu"` or `aria-haspopup="true"` | The button | Signals that a menu will appear on activation. |
| `aria-expanded="true\|false"` | The button | Reflects whether the menu is currently visible. |
| `aria-controls="IDREF"` (optional) | The button | References the `id` of the menu element. |
| `role="menu"` | The dropdown container | Identifies the popup as a menu. |
| `role="menuitem"` | Each item in the menu | Identifies each choice. |
| `tabindex="-1"` | Each menuitem | Items are not in the tab order; focus is managed via JS. |

### HTML Example

```html
<!-- CORRECT — action menu button -->
<button
  type="button"
  aria-haspopup="menu"
  aria-expanded="false"
  aria-controls="actions-menu"
>
  Actions
  <svg aria-hidden="true" width="12" height="12"><!-- down arrow icon --></svg>
</button>
<ul role="menu" id="actions-menu" aria-label="Actions" hidden>
  <li role="none">
    <button role="menuitem" tabindex="-1">Duplicate</button>
  </li>
  <li role="none">
    <button role="menuitem" tabindex="-1">Rename</button>
  </li>
  <li role="separator"></li>
  <li role="none">
    <button role="menuitem" tabindex="-1">Delete</button>
  </li>
</ul>

<!-- CORRECT — navigation menu button (links) -->
<button
  type="button"
  aria-haspopup="menu"
  aria-expanded="false"
  aria-controls="nav-menu"
>
  More Pages
</button>
<ul role="menu" id="nav-menu" aria-label="More pages" hidden>
  <li role="none">
    <a role="menuitem" tabindex="-1" href="/settings">Settings</a>
  </li>
  <li role="none">
    <a role="menuitem" tabindex="-1" href="/profile">Profile</a>
  </li>
</ul>

<!-- WRONG — missing aria-haspopup, no role="menu" on the list -->
<button id="menu-btn">Actions</button>
<ul id="dropdown" class="hidden">
  <li><button>Duplicate</button></li>
  <li><button>Delete</button></li>
</ul>

<!-- WRONG — using a <div> with click handler instead of a <button> -->
<div class="btn" onclick="toggleMenu()">Actions</div>
```

---

## 3. Tabs

> "Tabs are a set of layered sections of content, known as tab panels, that display one panel of content at a time. Each tab element is associated with a tab panel; activating a tab displays its panel while hiding others."

### Activation Modes

> **Automatic activation** is recommended "as long as their associated tab panels are displayed without noticeable latency." The tab activates immediately when it receives focus via arrow keys.

> **Manual activation** requires the user to press `Enter` or `Space` after focusing a tab. Use when panel content is expensive to render or fetched asynchronously.

### Keyboard Interaction

| Key | Action |
|---|---|
| `Tab` | When entering the tab list, focuses the active (selected) tab. When focus is on a tab, moves focus to the next element in the page tab sequence outside the tablist, which is typically the tabpanel unless the first element containing meaningful content inside the tabpanel is focusable. |
| `Right Arrow` | Moves focus to the next tab. Wraps from last to first. Optionally, activates the newly focused tab. |
| `Left Arrow` | Moves focus to the previous tab. Wraps from first to last. Optionally, activates the newly focused tab. |
| `Down Arrow` (vertical tabs) | Behaves as `Right Arrow` for vertical orientations. |
| `Up Arrow` (vertical tabs) | Behaves as `Left Arrow` for vertical orientations. |
| `Space` / `Enter` | In manual activation mode, activates the focused tab. |
| `Home` (optional) | Moves focus to the first tab and optionally activates it. |
| `End` (optional) | Moves focus to the last tab and optionally activates it. |
| `Delete` (optional) | If the tab is closable, removes it and moves focus to the next tab (or previous if it was the last). |
| `Shift + F10` | If the tab has an associated popup menu, opens it. |

### Required ARIA Roles, States, and Properties

| Attribute | Element | Purpose |
|---|---|---|
| `role="tablist"` | Container of the tabs | Groups the tab elements. |
| `role="tab"` | Each tab trigger | Identifies the element as a tab. Must be a child (or owned by) `tablist`. |
| `role="tabpanel"` | Each content panel | Identifies the panel associated with a tab. |
| `aria-selected="true"` | Active tab | Indicates the currently displayed tab. |
| `aria-selected="false"` | All inactive tabs | Marks tabs as not selected. |
| `aria-controls="IDREF"` | Each `tab` | Points to the `id` of the associated `tabpanel`. |
| `aria-labelledby="IDREF"` | Each `tabpanel` | Points to the `id` of the associated `tab`, providing the panel's accessible name. |
| `aria-label` or `aria-labelledby` | `tablist` | Provides an accessible name for the tab group. |
| `aria-orientation="vertical"` | `tablist` | Declares vertical orientation. Default is `"horizontal"` (can be omitted for horizontal tabs). |
| `aria-haspopup="menu"` | `tab` (if applicable) | Indicates the tab has a popup menu (uncommon). |
| `tabindex="0"` | Active tab | The selected tab is in the tab order. |
| `tabindex="-1"` | All inactive tabs | Inactive tabs are removed from the tab order (roving tabindex). |

### HTML Example

```html
<!-- CORRECT — proper tabs with roving tabindex and panel association -->
<div aria-label="Code examples" role="tablist">
  <button role="tab" id="tab-html" aria-selected="true" aria-controls="panel-html" tabindex="0">
    HTML
  </button>
  <button role="tab" id="tab-css" aria-selected="false" aria-controls="panel-css" tabindex="-1">
    CSS
  </button>
  <button role="tab" id="tab-js" aria-selected="false" aria-controls="panel-js" tabindex="-1">
    JS
  </button>
</div>

<div role="tabpanel" id="panel-html" aria-labelledby="tab-html" tabindex="0">
  <!-- HTML content -->
</div>
<div role="tabpanel" id="panel-css" aria-labelledby="tab-css" tabindex="0" hidden>
  <!-- CSS content -->
</div>
<div role="tabpanel" id="panel-js" aria-labelledby="tab-js" tabindex="0" hidden>
  <!-- JS content -->
</div>

<!-- WRONG — using links/anchors as tab triggers, missing roles -->
<div class="tabs">
  <a href="#panel1" class="active">HTML</a>
  <a href="#panel2">CSS</a>
  <a href="#panel3">JS</a>
</div>
<div id="panel1">...</div>
<div id="panel2" style="display:none">...</div>

<!-- WRONG — all tabs have tabindex="0" (breaks roving tabindex) -->
<div role="tablist">
  <button role="tab" tabindex="0" aria-selected="true">Tab 1</button>
  <button role="tab" tabindex="0" aria-selected="false">Tab 2</button>
  <button role="tab" tabindex="0" aria-selected="false">Tab 3</button>
</div>

<!-- WRONG — missing aria-controls / aria-labelledby link between tab and panel -->
<div role="tablist">
  <button role="tab" aria-selected="true">Tab 1</button>
</div>
<div role="tabpanel">Content</div>
```

> It is recommended that each `tabpanel` element has `tabindex="0"` when the tabpanel does not contain any focusable elements or the first element with content is not focusable.

---

## 4. Toolbar

> "A toolbar is a container for grouping a set of controls, such as buttons, menubuttons, or checkboxes. When a set of controls is visually presented as a group, the toolbar role can be used to communicate the group to assistive technology."

The toolbar reduces Tab stops: the entire toolbar is a single Tab stop, and arrow keys navigate between the controls inside it (roving tabindex).

> Use `toolbar` only when the group contains **three or more controls**.

### Keyboard Interaction

| Key | Action |
|---|---|
| `Tab` | Moves focus into the toolbar. Focus lands on the first non-disabled control, or the previously focused control. |
| `Shift + Tab` | Moves focus out of the toolbar to the previous focusable element in the page. |
| `Right Arrow` | Moves focus to the next control (horizontal toolbar). Optionally wraps from last to first. |
| `Left Arrow` | Moves focus to the previous control (horizontal toolbar). Optionally wraps from first to last. |
| `Down Arrow` | Moves focus to the next control (vertical toolbar). In a horizontal toolbar, may operate contained controls (e.g., open a menu button, adjust a slider). |
| `Up Arrow` | Moves focus to the previous control (vertical toolbar). In a horizontal toolbar, may operate contained controls. |
| `Home` (optional) | Moves focus to the first control in the toolbar. |
| `End` (optional) | Moves focus to the last control in the toolbar. |

### Required ARIA Roles, States, and Properties

| Attribute | Element | Purpose |
|---|---|---|
| `role="toolbar"` | Container element | Identifies the grouping as a toolbar. |
| `aria-label` or `aria-labelledby` | The toolbar | Provides an accessible name for the toolbar. |
| `aria-orientation="vertical"` | The toolbar (when vertical) | Declares vertical arrangement. Default is `"horizontal"` and can be omitted for horizontal toolbars. |
| `tabindex="0"` / `tabindex="-1"` | Each control inside | Roving tabindex: only the currently focused control has `tabindex="0"`. |
| `aria-disabled="true"` | Disabled controls | Disabled controls should either be non-focusable or focusable but marked disabled. Note: this is a general ARIA attribute, not specifically listed in the APG toolbar pattern. |

### HTML Example

```html
<!-- CORRECT — toolbar with roving tabindex and accessible label -->
<div role="toolbar" aria-label="Text formatting" aria-orientation="horizontal">
  <button type="button" tabindex="0" aria-pressed="false">
    <svg aria-hidden="true"><!-- bold icon --></svg>
    Bold
  </button>
  <button type="button" tabindex="-1" aria-pressed="false">
    <svg aria-hidden="true"><!-- italic icon --></svg>
    Italic
  </button>
  <button type="button" tabindex="-1" aria-pressed="false">
    <svg aria-hidden="true"><!-- underline icon --></svg>
    Underline
  </button>
  <span role="separator" aria-orientation="vertical"></span>
  <button type="button" tabindex="-1" aria-haspopup="menu" aria-expanded="false">
    Font Size
  </button>
</div>

<!-- CORRECT — vertical toolbar -->
<div role="toolbar" aria-label="Drawing tools" aria-orientation="vertical">
  <button type="button" tabindex="0" aria-pressed="true">Brush</button>
  <button type="button" tabindex="-1">Eraser</button>
  <button type="button" tabindex="-1">Fill</button>
  <button type="button" tabindex="-1">Eyedropper</button>
</div>

<!-- WRONG — no role="toolbar", all buttons are tab stops -->
<div class="toolbar">
  <button>Bold</button>
  <button>Italic</button>
  <button>Underline</button>
</div>

<!-- WRONG — toolbar with only 2 controls (use toolbar only for 3+) -->
<div role="toolbar" aria-label="Options">
  <button tabindex="0">Save</button>
  <button tabindex="-1">Cancel</button>
</div>
```

> Avoid placing controls inside a horizontal toolbar that require horizontal arrow keys for their own operation (e.g., a textbox), because the arrow keys will navigate the toolbar instead of operating the control. If unavoidable, include only one such control and make it the last element in the toolbar.

---

## 5. Breadcrumb

> "A breadcrumb trail consists of a list of links to the parent pages of the current page in hierarchical order. It helps users find their place within a website or web application."

Breadcrumbs are purely structural. There is no specific keyboard interaction beyond normal link tabbing.

### Keyboard Interaction

| Key | Action |
|---|---|
| `Tab` / `Shift + Tab` | Standard link navigation. Each breadcrumb link is a normal tab stop. |

> The APG notes keyboard interaction is "Not applicable" beyond standard link behavior.

### Required ARIA Roles, States, and Properties

| Attribute | Element | Purpose |
|---|---|---|
| `<nav>` (or `role="navigation"`) | Wrapper element | The breadcrumb must be inside a navigation landmark. |
| `aria-label="Breadcrumb"` | The `<nav>` element | Labels the navigation region so screen readers distinguish it from other `<nav>` landmarks on the page. |
| `aria-current="page"` | The last link (current page) | Identifies which breadcrumb represents the current page. If the current page element is plain text (not a link), this attribute may be omitted. |

### HTML Example

```html
<!-- CORRECT — semantic breadcrumb with aria-label and aria-current -->
<nav aria-label="Breadcrumb">
  <ol>
    <li><a href="/">Home</a></li>
    <li><a href="/products">Products</a></li>
    <li><a href="/products/widgets">Widgets</a></li>
    <li><a href="/products/widgets/blue" aria-current="page">Blue Widget</a></li>
  </ol>
</nav>

<!-- CORRECT — current page as plain text (no link, no aria-current needed) -->
<nav aria-label="Breadcrumb">
  <ol>
    <li><a href="/">Home</a></li>
    <li><a href="/products">Products</a></li>
    <li>Blue Widget</li>
  </ol>
</nav>

<!-- WRONG — missing nav landmark and aria-label -->
<div class="breadcrumb">
  <a href="/">Home</a> > <a href="/products">Products</a> > Blue Widget
</div>

<!-- WRONG — using aria-current on a non-current-page link -->
<nav aria-label="Breadcrumb">
  <ol>
    <li><a href="/" aria-current="page">Home</a></li>
    <li><a href="/products">Products</a></li>
    <li><a href="/products/widgets">Widgets</a></li>
  </ol>
</nav>

<!-- WRONG — missing aria-label on <nav> (indistinguishable from other nav landmarks) -->
<nav>
  <ol>
    <li><a href="/">Home</a></li>
    <li><a href="/products" aria-current="page">Products</a></li>
  </ol>
</nav>
```

> Visual separators between breadcrumb links (such as `/` or `>`) should be added via CSS `::before` / `::after` pseudo-elements or inserted with `aria-hidden="true"` so screen readers do not announce them as content.

```css
/* Separator via CSS — accessible by default */
nav[aria-label="Breadcrumb"] li + li::before {
  content: "/";
  padding-inline: 0.5ch;
  color: var(--color-text-muted, #666);
}
```

---

## Cross-References

- See also: [Keyboard & Focus](keyboard-and-focus.md) -- roving tabindex pattern used in menubar, tabs, and toolbar; arrow key navigation model; focus management for popups.
- See also: [Landmarks & Structure](landmarks-and-structure.md) -- `<nav>` landmark for breadcrumb and menubar; proper landmark labeling with `aria-label`.
- See also: [Names & Descriptions](names-and-descriptions.md) -- labeling navigation regions, `aria-labelledby` vs `aria-label` on `tablist`, `toolbar`, and `menu`.
