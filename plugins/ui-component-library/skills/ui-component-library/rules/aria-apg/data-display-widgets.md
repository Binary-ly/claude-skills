# Data Display Widget Patterns

ARIA Authoring Practices Guide (APG) patterns for components that present, organize, or navigate structured data: static tables, interactive grids, hierarchical trees, infinite-scroll feeds, value meters, slide carousels, and resizable pane splitters. Each pattern specifies the keyboard contract and ARIA semantics assistive technologies depend on.

## Sources:

- https://www.w3.org/WAI/ARIA/apg/patterns/table/
- https://www.w3.org/WAI/ARIA/apg/patterns/grid/
- https://www.w3.org/WAI/ARIA/apg/patterns/treegrid/
- https://www.w3.org/WAI/ARIA/apg/patterns/treeview/
- https://www.w3.org/WAI/ARIA/apg/patterns/feed/
- https://www.w3.org/WAI/ARIA/apg/patterns/meter/
- https://www.w3.org/WAI/ARIA/apg/patterns/carousel/
- https://www.w3.org/WAI/ARIA/apg/patterns/windowsplitter/

---

## Table of Contents
1. [Table](#1-table)
2. [Grid](#2-grid)
3. [Treegrid](#3-treegrid)
4. [Tree View](#4-tree-view)
5. [Feed](#5-feed)
6. [Meter](#6-meter)
7. [Carousel (Slide Show)](#7-carousel-slide-show)
8. [Window Splitter](#8-window-splitter)

---

## 1. Table

> A table is a static tabular structure containing one or more rows that each contain one or more cells; it is not an interactive widget.

A table presents read-only data in rows and columns. Cells are **not** focusable or selectable -- the table itself is purely structural. Interactive widgets (links, buttons, form controls) can live inside cells, but each widget is a separate tab stop, not part of grid-style arrow-key navigation. This is the critical distinction from the Grid pattern: tables present data; grids are composite interactive widgets.

The APG strongly encourages using native HTML `<table>` elements whenever possible.

### Keyboard Interaction

Not applicable. Tables have no keyboard interaction requirements of their own because they are non-interactive containers. Any interactive widgets embedded in cells follow their own keyboard patterns.

### ARIA Roles, States & Properties

| Role / Property | Applies to | Purpose |
|---|---|---|
| `role="table"` | Container | Identifies the table structure |
| `role="row"` | Row element | DOM descendant of `table` or `rowgroup`, or referenced via `aria-owns` |
| `role="rowgroup"` | Row grouping (optional) | Groups rows (analogous to `<thead>`, `<tbody>`, `<tfoot>`) |
| `role="columnheader"` | Header cell | Column title |
| `role="rowheader"` | Header cell | Row title |
| `role="cell"` | Data cell | Standard data cell |
| `aria-labelledby` / `aria-label` | `table` | Required accessible name for the table |
| `aria-describedby` | `table` | References a caption or longer description |
| `aria-sort` | `columnheader`, `rowheader` | Indicates sort direction: `ascending`, `descending`, `other`, `none` |
| `aria-colcount` / `aria-rowcount` | `table` | Total columns/rows when not all are present in the DOM |
| `aria-colindex` / `aria-rowindex` | `row`, `cell`, `columnheader`, `rowheader` | 1-based position within the full column/row count |
| `aria-colspan` / `aria-rowspan` | `cell`, `columnheader`, `rowheader` | Multi-cell spanning (use HTML `colspan`/`rowspan` when using native `<table>`) |

### Code Example

```html
<!-- CORRECT: Native HTML table with proper semantics -->
<table aria-label="Quarterly revenue">
  <caption>Revenue by region, Q1-Q4 2025</caption>
  <thead>
    <tr>
      <th scope="col" aria-sort="none">Region</th>
      <th scope="col" aria-sort="ascending">Q1</th>
      <th scope="col">Q2</th>
      <th scope="col">Q3</th>
      <th scope="col">Q4</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th scope="row">North America</th>
      <td>$1.2M</td>
      <td>$1.4M</td>
      <td>$1.1M</td>
      <td>$1.6M</td>
    </tr>
    <tr>
      <th scope="row">Europe</th>
      <td>$0.8M</td>
      <td>$0.9M</td>
      <td>$0.7M</td>
      <td>$1.0M</td>
    </tr>
  </tbody>
</table>

<!-- WRONG: Using role="grid" for non-interactive tabular data -->
<div role="grid" aria-label="Quarterly revenue">
  <div role="row">
    <div role="gridcell">North America</div>
    <div role="gridcell">$1.2M</div>
  </div>
</div>
<!-- Grid implies interactive cells with arrow-key navigation.
     Use role="table" (or native <table>) for static data. -->

<!-- WRONG: ARIA table missing accessible name -->
<div role="table">
  <div role="row">
    <div role="cell">Data</div>
  </div>
</div>
<!-- Every table needs aria-label or aria-labelledby. -->
```

---

## 2. Grid

> A grid widget is a container that enables users to navigate the information or interactive elements it contains using directional navigation keys, such as arrow keys, Home, and End.

A grid is an interactive tabular widget. Unlike a table, **every cell in a grid contains a focusable element or is itself focusable**. Only one focusable element within the grid is in the page tab sequence at any time (roving tabindex). Two primary use cases:

1. **Data grids** -- present tabular data with editable or interactive cells (spreadsheet-like)
2. **Layout grids** -- group interactive elements (links, buttons) to reduce the total number of tab stops

> For assistive technology users, the quality of experience when navigating a grid heavily depends on both what a cell contains and on where keyboard focus is set.

> Screen readers will typically be in their application reading mode when users are interacting with the grid. While in application mode, a screen reader user hears only focusable elements.

### Keyboard Interaction

#### Data Grid Navigation

| Key | Action |
|---|---|
| `Right Arrow` | Move focus one cell to the right. No action at right edge. |
| `Left Arrow` | Move focus one cell to the left. No action at left edge. |
| `Down Arrow` | Move focus one cell down. No action at bottom edge. |
| `Up Arrow` | Move focus one cell up. No action at top edge. |
| `Page Down` | Move focus down an author-determined number of rows, scrolling so the new row is visible. |
| `Page Up` | Move focus up an author-determined number of rows, scrolling so the new row is visible. |
| `Home` | Move focus to the first cell in the current row. |
| `End` | Move focus to the last cell in the current row. |
| `Control + Home` | Move focus to the first cell in the first row. |
| `Control + End` | Move focus to the last cell in the last row. |

#### Editing / In-Cell Navigation

| Key | Action |
|---|---|
| `Enter` | Disable grid navigation, place focus in cell input or first widget inside the cell. |
| `F2` | Toggle edit mode: first press disables grid navigation for cell editing; second press restores grid navigation. |
| `Alphanumeric keys` | In editable cells, places focus in an input field, such as a textbox. |
| `Escape` | Restore grid navigation. May also undo in-progress edits. |
| `Tab` / `Shift + Tab` | Move focus to the next widget in the grid. Optionally, the focus movement may wrap inside a single cell or within the grid itself. |

#### Selection (Multi-Select Grids)

| Key | Action |
|---|---|
| `Control + Space` | Select the column containing focus. |
| `Shift + Space` | Select the row containing focus. |
| `Control + A` | Select all cells. |
| `Shift + Arrow Keys` | Extend selection one cell in the arrow direction. |

#### Layout Grid Variations

Arrow keys may optionally wrap at row/column boundaries. `Home`/`End` may move to grid start/end if fewer than three cells per row.

### ARIA Roles, States & Properties

| Role / Property | Applies to | Purpose |
|---|---|---|
| `role="grid"` | Container | Identifies the grid widget |
| `role="row"` | Row element | DOM descendant of `grid` or `rowgroup` |
| `role="rowgroup"` | Row grouping (optional) | Groups rows |
| `role="gridcell"` | Data cell | Interactive data cell |
| `role="columnheader"` | Header cell | Column title |
| `role="rowheader"` | Header cell | Row title |
| `aria-labelledby` / `aria-label` | `grid` | Required accessible name |
| `aria-describedby` | `grid` | Optional description/caption |
| `aria-readonly` | `grid` or `gridcell` | `true` when editing is disabled |
| `aria-selected` | `gridcell`, `row` | `true` on selected items; `false` on unselected items in a selectable grid |
| `aria-sort` | `columnheader`, `rowheader` | Sort direction: `ascending`, `descending`, `other`, `none` |
| `aria-colcount` / `aria-rowcount` | `grid` | Total columns/rows when DOM is virtualized |
| `aria-colindex` / `aria-rowindex` | `row`, `gridcell`, `columnheader`, `rowheader` | 1-based position in full dataset |
| `aria-colspan` / `aria-rowspan` | `gridcell`, `columnheader`, `rowheader` | Multi-cell spanning (use HTML attributes when using native `<table>`) |

### Focus Management

Use roving `tabindex`: set `tabindex="0"` on the currently focused cell (or widget inside it) and `tabindex="-1"` on all other focusable elements in the grid. Two recommended strategies:

1. **Cell contains a single widget** (button, link, checkbox) -- focus the widget directly.
2. **Cell contains text or a graphic** -- make the cell itself focusable.

### Code Example

```html
<!-- CORRECT: Interactive data grid with editable cells -->
<table role="grid" aria-label="Employee directory">
  <thead>
    <tr>
      <th scope="col" aria-sort="ascending">Name</th>
      <th scope="col" aria-sort="none">Department</th>
      <th scope="col">Actions</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td tabindex="-1">Alice Johnson</td>
      <td tabindex="-1" aria-readonly="false">Engineering</td>
      <td>
        <button tabindex="-1">Edit</button>
      </td>
    </tr>
    <tr>
      <td tabindex="-1">Bob Smith</td>
      <td tabindex="-1" aria-readonly="false">Design</td>
      <td>
        <button tabindex="-1">Edit</button>
      </td>
    </tr>
  </tbody>
</table>
<!-- JS manages roving tabindex: only one cell/widget has tabindex="0" at a time. -->

<!-- WRONG: Grid where cells are not focusable -->
<div role="grid" aria-label="Data">
  <div role="row">
    <div role="gridcell">Not focusable text</div>
    <div role="gridcell">More text</div>
  </div>
</div>
<!-- Every gridcell MUST be focusable or contain a focusable element.
     Screen reader users in application mode only hear focusable elements. -->

<!-- WRONG: Using grid for non-interactive data -->
<table role="grid" aria-label="Sales report">
  <tr><td tabindex="-1">$500</td><td tabindex="-1">$600</td></tr>
</table>
<!-- If cells are read-only with no interactive purpose, use role="table" instead.
     Grid implies an interactive keyboard contract users will expect. -->
```

---

## 3. Treegrid

A treegrid widget presents a hierarchical data grid consisting of tabular information that is editable or interactive. Rows can have child rows that expand or collapse.

A treegrid combines the two-dimensional cell navigation of a grid with the hierarchical expand/collapse semantics of a tree. Rows act as tree nodes -- parent rows can be expanded or collapsed to show or hide child rows. Both rows and cells are focusable, and screen readers use application mode. It is essentially a grid where rows have a tree structure.

### Keyboard Interaction

#### Navigation

| Key | Action |
|---|---|
| `Right Arrow` | If focus is on a collapsed row, expand the row. If focus is on an expanded row, move focus to the first cell in the row. If focus is on a row that does not have child rows, move focus to the first cell in the row. If focus is on a cell, move one cell to the right. |
| `Left Arrow` | If focus is on an expanded row, collapse the row. If focus is on a collapsed row or a row without children, focus does not move. If focus is on the first cell in a row and row focus is supported, move focus to the row. If focus is on any other cell, move focus one cell to the left. |
| `Down Arrow` | Move focus to the next visible row (or next cell down when navigating cells). |
| `Up Arrow` | Move focus to the previous visible row (or previous cell up when navigating cells). |
| `Home` | Move focus to the first row, or first cell in the current row (context-dependent). |
| `End` | Move focus to the last visible row, or last cell in the current row. |
| `Control + Home` | Move focus to the first row. |
| `Control + End` | Move focus to the last row. |
| `Page Down` | Move focus down an author-determined number of rows with scrolling. |
| `Page Up` | Move focus up an author-determined number of rows with scrolling. |
| `Tab` | Move to next focusable element within the row, then exit the treegrid. |
| `Enter` | If cell-only focus is enabled and focus is on the first cell with the `aria-expanded` property, opens or closes the child rows. Otherwise, performs the default action for the cell. |

#### Selection (Multi-Select)

| Key | Action |
|---|---|
| `Control + Space` | Select column or all cells. |
| `Shift + Space` | Select entire row. |
| `Control + A` | Select all cells. |
| `Shift + Arrow Keys` | Extend selection one cell/row in the arrow direction. |

### ARIA Roles, States & Properties

| Role / Property | Applies to | Purpose |
|---|---|---|
| `role="treegrid"` | Container | Identifies the treegrid widget |
| `role="row"` | Row element | Each row in the treegrid |
| `role="gridcell"` | Data cell | Standard interactive cell |
| `role="columnheader"` | Header cell | Column title |
| `role="rowheader"` | Header cell | Row title |
| `aria-expanded` | `row` (parent rows only) | `true` when children are visible, `false` when collapsed. Absent on leaf rows. |
| `aria-multiselectable` | `treegrid` | `true` if multiple rows/cells can be selected. |
| `aria-selected` | `row`, `gridcell` | `true`/`false` for selection state. |
| `aria-labelledby` / `aria-label` | `treegrid` | Required accessible name. |
| `aria-describedby` | `treegrid` | Optional description. |
| `aria-readonly` | `treegrid` or `gridcell` | `true` when editing is disabled. |
| `aria-colcount` / `aria-rowcount` | `treegrid` | Total columns/rows when DOM is virtualized. |
| `aria-colindex` / `aria-rowindex` | `row`, `gridcell` | 1-based position in full dataset. |

### Code Example

```html
<!-- CORRECT: Treegrid with expandable rows -->
<table role="treegrid" aria-label="File browser">
  <thead>
    <tr>
      <th scope="col">Name</th>
      <th scope="col">Size</th>
      <th scope="col">Modified</th>
    </tr>
  </thead>
  <tbody>
    <!-- Parent row: expanded -->
    <tr role="row" aria-level="1" aria-expanded="true" aria-setsize="2" aria-posinset="1" tabindex="0">
      <td role="gridcell">Documents</td>
      <td role="gridcell">--</td>
      <td role="gridcell">2025-03-10</td>
    </tr>
      <!-- Child row -->
      <tr role="row" aria-level="2" aria-setsize="2" aria-posinset="1" tabindex="-1">
        <td role="gridcell">report.pdf</td>
        <td role="gridcell">2.4 MB</td>
        <td role="gridcell">2025-03-09</td>
      </tr>
      <!-- Child row -->
      <tr role="row" aria-level="2" aria-setsize="2" aria-posinset="2" tabindex="-1">
        <td role="gridcell">notes.txt</td>
        <td role="gridcell">12 KB</td>
        <td role="gridcell">2025-03-08</td>
      </tr>
    <!-- Parent row: collapsed -->
    <tr role="row" aria-level="1" aria-expanded="false" aria-setsize="2" aria-posinset="2" tabindex="-1">
      <td role="gridcell">Photos</td>
      <td role="gridcell">--</td>
      <td role="gridcell">2025-02-15</td>
    </tr>
    <!-- Children of "Photos" are hidden when aria-expanded="false" -->
  </tbody>
</table>

<!-- WRONG: Treegrid row missing aria-expanded on a parent -->
<tr role="row" aria-level="1">
  <td role="gridcell">Folder with children</td>
</tr>
<!-- Parent rows MUST have aria-expanded. Without it, assistive technologies
     cannot communicate expand/collapse state. Leaf rows must NOT have it. -->

<!-- WRONG: Using role="grid" for hierarchical data -->
<table role="grid" aria-label="Files">
  <!-- If rows have parent-child relationships with expand/collapse,
       use role="treegrid", not role="grid". -->
</table>
```

---

## 4. Tree View

> A tree view widget presents a hierarchical list. Any item in the hierarchy may have child nodes, and parent nodes can be expanded or collapsed.

A tree view displays hierarchical data where items (nodes) may be nested. Parent nodes expand to reveal children and collapse to hide them. Trees support single-select or multi-select modes, and include type-ahead character navigation.

**Terminology:**
- **Root node** -- top-level item with no parent
- **Parent node** -- item with child nodes (open or closed)
- **End node** -- item with no children
- **Open node** -- expanded parent showing children
- **Closed node** -- collapsed parent hiding children

### Keyboard Interaction

#### Navigation

| Key | Action |
|---|---|
| `Right Arrow` | On a closed node: open it. On an open node: move focus to first child. On an end node: nothing. |
| `Left Arrow` | On an open node: close it. On a child/end node: move focus to its parent. On a root node: nothing. |
| `Down Arrow` | Move focus to the next visible node without changing expand/collapse state. |
| `Up Arrow` | Move focus to the previous visible node without changing expand/collapse state. |
| `Home` | Move focus to the first node in the tree. |
| `End` | Move focus to the last visible node in the tree. |
| `Enter` | Activates the node. On parent nodes, toggles open/closed. In single-select trees, selects the node. |
| `Type a character` | Focus moves to the next node whose name starts with the typed character (type-ahead). |
| `*` (asterisk) | Expand all sibling nodes at the same level as the focused node (optional). |

#### Selection (Multi-Select Trees)

**Recommended model** (modifier keys not required for basic operations):

| Key | Action |
|---|---|
| `Space` | Toggle selection of the focused node. |
| `Shift + Down Arrow` | Move focus down, toggle selection of the new node. |
| `Shift + Up Arrow` | Move focus up, toggle selection of the new node. |
| `Shift + Space` | Select contiguous nodes from the most recently selected to the focused node (optional). |
| `Control + Shift + Home` | Select from the focused node to the first node (optional). |
| `Control + Shift + End` | Select from the focused node to the last visible node (optional). |
| `Control + A` | Select all nodes (optional). |

**Alternative model** (modifier keys required):

| Key | Action |
|---|---|
| `Shift + Down Arrow` | Move focus and extend/toggle selection. |
| `Shift + Up Arrow` | Move focus and extend/toggle selection. |
| `Control + Down Arrow` | Move focus without changing selection. |
| `Control + Up Arrow` | Move focus without changing selection. |
| `Control + Space` | Toggle selection of the focused node. |

### ARIA Roles, States & Properties

| Role / Property | Applies to | Purpose |
|---|---|---|
| `role="tree"` | Container | Identifies the tree widget |
| `role="treeitem"` | Each node | Identifies individual items in the tree |
| `role="group"` | Subtree container | Wraps child treeitems within a parent treeitem |
| `aria-expanded` | `treeitem` (parent nodes only) | `true` when open, `false` when closed. **Must not be present on end nodes.** |
| `aria-selected` | `treeitem` | Selection state. Use for single-select trees. |
| `aria-checked` | `treeitem` | Selection state. Conventional for multi-select trees (use one of `aria-selected` or `aria-checked` consistently, not both). |
| `aria-multiselectable` | `tree` | `true` for multi-select trees. |
| `aria-level` | `treeitem` | Depth of the node (1-based). Required when nodes load dynamically and DOM nesting does not convey level. |
| `aria-setsize` | `treeitem` | Total sibling nodes at the same level. Required when nodes load dynamically. |
| `aria-posinset` | `treeitem` | 1-based position among siblings. Required when nodes load dynamically. |
| `aria-orientation` | `tree` | Default is `vertical`. Set to `horizontal` for horizontal trees (swaps Up/Down and Left/Right arrow key behavior). |
| `aria-labelledby` / `aria-label` | `tree` | Required accessible name for the tree. |
| `aria-owns` | `tree` or `treeitem` | References nodes that are not DOM children but logically belong to this node. |

### Focus Management

> When a single-select tree receives focus: If none of the nodes are selected before the tree receives focus, focus is set on the first node. If a node is selected before the tree receives focus, focus is set on the selected node.

For multi-select trees: focus goes to the first selected node if any exist, otherwise the first node.

### Code Example

```html
<!-- CORRECT: Single-select tree with nested groups -->
<ul role="tree" aria-label="Project files">
  <li role="treeitem" aria-expanded="true" tabindex="0">
    src
    <ul role="group">
      <li role="treeitem" aria-expanded="false" tabindex="-1">
        components
        <ul role="group">
          <li role="treeitem" tabindex="-1">Button.tsx</li>
          <li role="treeitem" tabindex="-1">Card.tsx</li>
        </ul>
      </li>
      <li role="treeitem" tabindex="-1">index.ts</li>
    </ul>
  </li>
  <li role="treeitem" tabindex="-1">package.json</li>
</ul>
<!-- End nodes (Button.tsx, Card.tsx, index.ts, package.json) have no aria-expanded. -->

<!-- CORRECT: Multi-select tree with aria-checked -->
<ul role="tree" aria-label="Permissions" aria-multiselectable="true">
  <li role="treeitem" aria-checked="true" tabindex="0">Read</li>
  <li role="treeitem" aria-checked="false" tabindex="-1">Write</li>
  <li role="treeitem" aria-checked="true" tabindex="-1">Execute</li>
</ul>

<!-- WRONG: End nodes with aria-expanded -->
<li role="treeitem" aria-expanded="false" tabindex="-1">leaf-file.txt</li>
<!-- End nodes must NOT have aria-expanded. Its presence tells AT
     that the node has children, which is incorrect for leaves. -->

<!-- WRONG: Mixing aria-selected and aria-checked on the same tree -->
<ul role="tree" aria-multiselectable="true">
  <li role="treeitem" aria-selected="true">Node A</li>
  <li role="treeitem" aria-checked="true">Node B</li>
</ul>
<!-- Use one consistently: aria-selected OR aria-checked, never both. -->

<!-- WRONG: Tree items not inside role="group" under parent -->
<ul role="tree">
  <li role="treeitem" aria-expanded="true">
    Parent
    <!-- children must be wrapped in role="group" -->
    <li role="treeitem">Child</li>
  </li>
</ul>
<!-- Child treeitems must be wrapped in a <ul role="group">. -->
```

---

## 5. Feed

> A feed is a section of a page that automatically loads new sections of content as the user scrolls.

A feed is a **structure** (not an interactive widget) composed of dynamically-loaded articles. It enables infinite scrolling while giving assistive technologies a reliable interoperability contract for skim-reading and navigating between articles. Because it is a structure, assistive technologies can operate in reading mode rather than application mode.

The feed pattern is not based on a desktop GUI widget, so it has no established keyboard conventions. Keyboard documentation should be easily discoverable.

### Keyboard Interaction

| Key | Action |
|---|---|
| `Page Down` | Move focus to the next article. |
| `Page Up` | Move focus to the previous article. |
| `Control + End` | Move focus to the first focusable element **after** the feed. |
| `Control + Home` | Move focus to the first focusable element **before** the feed. |

**Note:** When focus is on an interactive widget inside an article that uses `Page Down`/`Page Up` (e.g., a text area), the widget consumes those keys instead of the feed.

### ARIA Roles, States & Properties

| Role / Property | Applies to | Purpose |
|---|---|---|
| `role="feed"` | Container | Identifies the feed structure |
| `role="article"` | Each content unit | Marks individual articles within the feed |
| `aria-labelledby` / `aria-label` | `feed` | Required accessible name for the feed |
| `aria-labelledby` | `article` | References a distinguishing label element (e.g., headline) |
| `aria-describedby` | `article` | References primary article content (recommended) |
| `aria-busy` | `feed` | `true` while loading/updating content; `false` when stable |
| `aria-setsize` | `article` | Total number of articles loaded, or total in the feed if known. Use `-1` if total is unknown. |
| `aria-posinset` | `article` | 1-based position of this article in the feed |

### Interoperability Contract

The feed pattern defines a contract between the web page and assistive technologies:

**Web page responsibilities:**
- Manage visual scrolling behavior based on which article has focus.
- Load or remove articles as needed based on the focused article's position.

**Assistive technology responsibilities:**
- Indicate reading cursor position via DOM focus.
- Provide article-to-article navigation keys.
- Support reading past feed boundaries.

### Code Example

```html
<!-- CORRECT: Feed with articles, loading state, and position data -->
<section role="feed" aria-label="Tech news" aria-busy="false">
  <article
    role="article"
    aria-posinset="1"
    aria-setsize="-1"
    aria-labelledby="headline-1"
    aria-describedby="summary-1"
    tabindex="0"
  >
    <h3 id="headline-1">New CSS Features in 2025</h3>
    <p id="summary-1">A look at the latest additions to CSS...</p>
  </article>

  <article
    role="article"
    aria-posinset="2"
    aria-setsize="-1"
    aria-labelledby="headline-2"
    aria-describedby="summary-2"
    tabindex="-1"
  >
    <h3 id="headline-2">WebAssembly 2.0 Announced</h3>
    <p id="summary-2">Major performance improvements in the new spec...</p>
  </article>

  <!-- More articles loaded dynamically as user scrolls... -->
</section>

<!-- While loading more articles: -->
<section role="feed" aria-label="Tech news" aria-busy="true">
  <!-- existing articles... -->
  <!-- spinner or loading indicator -->
</section>

<!-- WRONG: Feed without aria-setsize/aria-posinset on articles -->
<div role="feed" aria-label="News">
  <article>First article</article>
  <article>Second article</article>
</div>
<!-- Each article MUST have aria-posinset and aria-setsize so
     assistive technologies can communicate position context. -->

<!-- WRONG: Using role="feed" for static, non-scrolling content -->
<div role="feed" aria-label="About us">
  <article>Company info</article>
</div>
<!-- Feed implies dynamic loading. Use a simple landmark or list
     for static content. -->
```

---

## 6. Meter

> A meter is a graphical display of a numeric value that varies within a defined range.

A meter represents a scalar measurement within a known range -- like a battery level, disk usage percentage, or fuel gauge. It is a read-only display element with no user interaction. The key distinction from `progressbar`: a progress bar represents completion of a task; a meter represents a static measurement within a bounded range.

The meter pattern should not be used for values without a meaningful maximum limit.

### Keyboard Interaction

Not applicable. Meters are read-only display elements with no interaction requirements.

### ARIA Roles, States & Properties

| Role / Property | Applies to | Purpose |
|---|---|---|
| `role="meter"` | Container | Identifies the meter widget |
| `aria-valuenow` | `meter` | **Required.** Current numeric value (decimal between min and max). |
| `aria-valuemin` | `meter` | **Required.** Minimum value of the range. |
| `aria-valuemax` | `meter` | **Required.** Maximum value of the range (must be greater than min). |
| `aria-labelledby` / `aria-label` | `meter` | **Required.** Accessible name for the meter. |
| `aria-valuetext` | `meter` | Human-readable value string. Overrides the default percentage announcement. |

### Meter vs Progressbar

| Aspect | `role="meter"` | `role="progressbar"` |
|---|---|---|
| Semantics | Scalar measurement within a known range | Task completion status |
| Use case | Battery level, disk usage, signal strength | File upload, form completion, loading |
| Value meaning | A measurement at a point in time | How much of a task is done |
| Indeterminate state | Not applicable (value always known) | Supported (omit `aria-valuenow`) |

### Code Example

```html
<!-- CORRECT: Battery meter with aria-valuetext -->
<div
  role="meter"
  aria-label="Battery level"
  aria-valuenow="72"
  aria-valuemin="0"
  aria-valuemax="100"
  aria-valuetext="72% (approximately 4 hours remaining)"
>
  <div class="meter-fill" style="width: 72%"></div>
</div>

<!-- CORRECT: Disk usage meter with visible label -->
<span id="disk-label">Disk usage</span>
<div
  role="meter"
  aria-labelledby="disk-label"
  aria-valuenow="450"
  aria-valuemin="0"
  aria-valuemax="512"
  aria-valuetext="450 of 512 GB used (88%)"
>
  <div class="meter-fill" style="width: 88%"></div>
</div>

<!-- CORRECT: Use native <meter> when possible -->
<label for="fuel">Fuel level:</label>
<meter id="fuel" min="0" max="100" value="65">65%</meter>

<!-- WRONG: Using meter for task completion -->
<div role="meter" aria-valuenow="3" aria-valuemin="0" aria-valuemax="5"
     aria-label="Steps completed">
</div>
<!-- Task completion is a progressbar, not a meter. Meter is for
     measurements, not progress through a sequence. -->

<!-- WRONG: Meter missing required value properties -->
<div role="meter" aria-label="CPU temperature">Hot</div>
<!-- aria-valuenow, aria-valuemin, and aria-valuemax are all required. -->
```

---

## 7. Carousel (Slide Show)

> A carousel presents a set of items, referred to as slides, by sequentially displaying a subset of one or more slides. Typically, one slide is displayed at a time, and users can activate a next or previous slide control to display adjacent slides.

A carousel (or slideshow) cycles through a collection of slides. It may auto-rotate on page load. The pattern emphasizes controlling rotation to prevent disorientation and ensuring screen reader users can navigate slides and understand their position.

### Keyboard Interaction

| Key | Action |
|---|---|
| `Tab` / `Shift + Tab` | Move focus through interactive elements within the carousel in page tab order. |
| Rotation control button | Toggle auto-rotation on/off. Does not move focus. |
| Next/Previous buttons | Display adjacent slide. Does not move focus (allows repeated activation). |
| Tab-based slide picker | Follows the Tabs pattern keyboard interaction (arrow keys between tabs). |

**Auto-rotation behavior:**
- Rotation **stops** when any carousel element receives keyboard focus.
- Rotation **pauses** when the mouse hovers over the carousel.
- Rotation does **not resume** unless the user explicitly reactivates it.
- The rotation control must be the **first element** in the Tab sequence within the carousel.

### ARIA Roles, States & Properties

#### Carousel Container

| Role / Property | Purpose |
|---|---|
| `role="region"` (or `role="group"`) | Landmark container. Use `region` when the carousel is a significant page section. |
| `aria-roledescription="carousel"` | Overrides the default role announcement. Assistive technologies say "carousel" instead of "region". |
| `aria-labelledby` / `aria-label` | Required accessible name. Should **not** repeat "carousel" (since `aria-roledescription` already announces it). |

#### Rotation Control

| Property | Purpose |
|---|---|
| `<button>` (native) | Recommended element for the rotation toggle. |
| `aria-label` or inner text | Accessible label that **changes dynamically**: "Stop slide rotation" or "Start slide rotation". |

#### Slides (Basic Carousel)

| Role / Property | Purpose |
|---|---|
| `role="group"` | Each slide is a group. |
| `aria-roledescription="slide"` | Overrides the "group" announcement. |
| `aria-labelledby` / `aria-label` | Accessible name for the slide. May use numbering like "3 of 10" when no unique name exists. |

#### Slides (Tabbed Carousel)

| Role / Property | Purpose |
|---|---|
| `role="tabpanel"` | Each slide is a tabpanel (do **not** use `aria-roledescription="slide"` with tabpanels). |
| `tablist` with `aria-label` | Slide picker labeled with purpose (e.g., "Choose slide to display"). |
| `tab` | Each picker control; accessible name includes slide identification (e.g., "Slide 3"). |

#### Slide Container (Live Region)

| Property | Value | When |
|---|---|---|
| `aria-live` | `"off"` | During auto-rotation (prevents excessive announcements). |
| `aria-live` | `"polite"` | When rotation is stopped (announces slide changes). |
| `aria-atomic` | `"false"` | Always. Only announce changed content, not the entire region. |

### Code Example

```html
<!-- CORRECT: Basic carousel with rotation control -->
<section
  role="region"
  aria-roledescription="carousel"
  aria-label="Featured articles"
>
  <!-- Rotation control is FIRST in tab order -->
  <button aria-label="Stop slide rotation" onclick="toggleRotation()">
    Pause
  </button>

  <button aria-label="Previous slide">Previous</button>
  <button aria-label="Next slide">Next</button>

  <div aria-live="off" aria-atomic="false">
    <!-- Visible slide -->
    <div role="group" aria-roledescription="slide" aria-label="1 of 4">
      <h3>Article Title</h3>
      <p>Article content...</p>
    </div>
  </div>
</section>

<!-- CORRECT: Tabbed carousel with slide picker -->
<section
  role="region"
  aria-roledescription="carousel"
  aria-label="Product highlights"
>
  <button aria-label="Stop slide rotation">Pause</button>

  <div role="tablist" aria-label="Choose slide to display">
    <button role="tab" aria-selected="true" aria-controls="slide-1">Slide 1</button>
    <button role="tab" aria-selected="false" aria-controls="slide-2">Slide 2</button>
    <button role="tab" aria-selected="false" aria-controls="slide-3">Slide 3</button>
  </div>

  <div id="slide-1" role="tabpanel" aria-label="Product A">
    <h3>Product A</h3>
    <p>Description...</p>
  </div>
  <!-- Other tabpanels hidden -->
</section>

<!-- WRONG: Carousel missing rotation control -->
<section role="region" aria-roledescription="carousel" aria-label="News">
  <div aria-live="polite">
    <div role="group" aria-roledescription="slide">Auto-advancing content</div>
  </div>
</section>
<!-- Auto-rotating carousels MUST have an explicit pause/stop control.
     Users with vestibular disorders or screen reader users need to stop motion. -->

<!-- WRONG: aria-roledescription repeating role name -->
<section role="region" aria-roledescription="carousel" aria-label="Image carousel">
  <!--                                                          ^^^^^^^^^^^^^^^
       Don't repeat "carousel" in aria-label -- aria-roledescription already
       causes AT to announce "carousel". This would read as "Image carousel carousel". -->
</section>

<!-- WRONG: Using aria-roledescription="slide" on tabpanel slides -->
<div role="tabpanel" aria-roledescription="slide">...</div>
<!-- When using the tabbed carousel variant, slides are tabpanels.
     Do NOT add aria-roledescription="slide" to tabpanels. -->
```

---

## 8. Window Splitter

> A window splitter is a moveable separator between two sections, or panes, of a window that enables users to change the relative size of the panes.

A window splitter uses a focusable `separator` element that the user drags or nudges with arrow keys to resize adjacent panes. Splitters can be **variable** (any position within a range) or **fixed** (toggle between two positions, such as collapsed and expanded). The value represents the primary pane's size as a percentage, typically 0 to 100.

**Note:** ARIA 1.1 introduced changes to the separator role so it behaves as a widget when focusable. While this pattern has been revised to match the ARIA 1.1 specification, the task force will not complete its review until a functional example is complete.

### Keyboard Interaction

| Key | Action |
|---|---|
| `Left Arrow` | Move a vertical splitter to the left (decrease primary pane width). |
| `Right Arrow` | Move a vertical splitter to the right (increase primary pane width). |
| `Up Arrow` | Move a horizontal splitter up (decrease primary pane height). |
| `Down Arrow` | Move a horizontal splitter down (increase primary pane height). |
| `Enter` | If primary pane is not collapsed, collapse it (set to minimum). If already collapsed, restore to previous position. |
| `Home` (optional) | Move splitter to give primary pane its minimum size. |
| `End` (optional) | Move splitter to give primary pane its maximum size. |
| `F6` (optional) | Cycle focus through window panes. |

**Note:** Fixed splitters (toggle between two positions) do not implement arrow key movement.

### ARIA Roles, States & Properties

| Role / Property | Applies to | Purpose |
|---|---|---|
| `role="separator"` | Splitter element | Identifies the focusable separator. Must have `tabindex="0"` to be focusable and act as a widget. |
| `aria-valuenow` | `separator` | **Required.** Current position as a decimal (typically 0-100). |
| `aria-valuemin` | `separator` | **Required.** Minimum position (typically `0`). |
| `aria-valuemax` | `separator` | **Required.** Maximum position (typically `100`). |
| `aria-controls` | `separator` | **Required.** References the ID of the primary pane being resized. |
| `aria-labelledby` / `aria-label` | `separator` | Required accessible name. If the primary pane has a visible label, reference it with `aria-labelledby`. |
| `aria-orientation` | `separator` | `vertical` (default) or `horizontal`. Determines which arrow keys control movement. **Note:** This property is not listed on the APG window splitter pattern page; included here for completeness as it is part of the separator role specification. |

### Static vs Focusable Separator

The `separator` role has two modes:

| Aspect | Static separator | Focusable separator (splitter) |
|---|---|---|
| Focusable | No (`tabindex` not set) | Yes (`tabindex="0"`) |
| Purpose | Visual/structural divider | Interactive resizing control |
| ARIA value props | Not applicable | `aria-valuenow`, `aria-valuemin`, `aria-valuemax` required |
| Keyboard | None | Arrow keys, Enter, Home/End |

### Code Example

```html
<!-- CORRECT: Vertical window splitter between two panes -->
<div class="split-layout">
  <div id="sidebar" class="pane">
    <h2 id="sidebar-label">Sidebar</h2>
    <nav><!-- sidebar content --></nav>
  </div>

  <div
    role="separator"
    tabindex="0"
    aria-valuenow="30"
    aria-valuemin="0"
    aria-valuemax="100"
    aria-orientation="vertical"
    aria-controls="sidebar"
    aria-label="Resize sidebar"
  ></div>

  <div id="main-content" class="pane">
    <h2>Main Content</h2>
    <p>Page content here...</p>
  </div>
</div>

<!-- CORRECT: Horizontal splitter with visible label reference -->
<div class="split-vertical">
  <div id="editor" class="pane">
    <h2 id="editor-label">Code Editor</h2>
    <textarea>code here</textarea>
  </div>

  <div
    role="separator"
    tabindex="0"
    aria-valuenow="60"
    aria-valuemin="10"
    aria-valuemax="90"
    aria-orientation="horizontal"
    aria-controls="editor"
    aria-labelledby="editor-label"
  ></div>

  <div id="terminal" class="pane">
    <h2>Terminal</h2>
    <pre>$ output here</pre>
  </div>
</div>

<!-- WRONG: Separator without tabindex (not focusable = not a splitter) -->
<div role="separator" aria-valuenow="50" aria-valuemin="0" aria-valuemax="100">
</div>
<!-- Without tabindex="0", the separator is a static structure, not an
     interactive splitter. Value properties have no effect. -->

<!-- WRONG: Splitter missing aria-controls -->
<div role="separator" tabindex="0"
     aria-valuenow="50" aria-valuemin="0" aria-valuemax="100"
     aria-label="Resize">
</div>
<!-- aria-controls is required to identify which pane the splitter controls. -->

<!-- WRONG: Using a generic div with custom role instead of separator -->
<div role="slider" tabindex="0" aria-label="Resize pane"
     aria-valuenow="50" aria-valuemin="0" aria-valuemax="100">
</div>
<!-- A pane resizer uses role="separator", not role="slider".
     Slider implies a form input for selecting a value. -->
```

---

## Cross-References

- See also: [Keyboard & Focus](keyboard-and-focus.md) -- grid arrow-key navigation, roving tabindex, focus management patterns used by Grid, Treegrid, Tree View, and Carousel.
- See also: [Grid, Table & Range](grid-table-range.md) -- detailed ARIA grid/table structural properties (`aria-colcount`, `aria-rowcount`, `aria-colindex`, `aria-rowindex`, `aria-colspan`, `aria-rowspan`), range value properties (`aria-valuenow`, `aria-valuemin`, `aria-valuemax`), and Grid vs Table role comparison.
- See also: [Names & Descriptions](names-and-descriptions.md) -- labeling strategies for tables, grids, feeds, carousels, and other containers (`aria-labelledby`, `aria-label`, `aria-describedby`).
