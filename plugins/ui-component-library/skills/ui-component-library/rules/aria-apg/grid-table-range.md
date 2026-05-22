# Grid, Table & Range Properties

ARIA properties for structured data presentation (grids, tables, treegrids) and range-based interactive widgets (sliders, progress bars, meters, spinbuttons, scrollbars). These properties communicate structure, position, and value semantics to assistive technologies, especially when the DOM does not fully represent the underlying data.

## Sources:

- https://www.w3.org/WAI/ARIA/apg/practices/grid-and-table-properties/
- https://www.w3.org/WAI/ARIA/apg/practices/range-related-properties/

---

## Table of Contents
1. [Part 1 — Grid & Table Properties](#part-1--grid--table-properties)
2. [Part 2 — Range-Related Properties](#part-2--range-related-properties)
3. [Quick Decision Reference](#quick-decision-reference)

---

## Part 1 — Grid & Table Properties

### Why These Properties Exist

> Browsers automatically populate their accessibility tree with the number of rows and columns in a grid or table based on the rendered DOM. However, there are many situations where the DOM does not contain the whole grid or table, such as when the data set is too large to fully render.

When you virtualize rows/columns, paginate, or lazy-load table data, assistive technologies lose the ability to navigate and announce position. The ARIA grid/table properties restore that context.

---

### Property Reference

| Property | Applies to | Purpose |
|---|---|---|
| `aria-colcount` | `table`, `grid`, `treegrid` | Declares the **total** number of columns in the full dataset |
| `aria-rowcount` | `table`, `grid`, `treegrid` | Declares the **total** number of rows in the full dataset |
| `aria-colindex` | `row`, `cell`, `gridcell`, `columnheader`, `rowheader` | Identifies a cell's or row's position within the total column count (1-based) |
| `aria-rowindex` | `row`, `cell`, `gridcell`, `columnheader`, `rowheader` | Identifies a row's position within the total row count (1-based) |
| `aria-colspan` | `cell`, `gridcell`, `columnheader`, `rowheader` | Number of columns a cell spans (for non-HTML-table markup) |
| `aria-rowspan` | `cell`, `gridcell`, `columnheader`, `rowheader` | Number of rows a cell spans (for non-HTML-table markup) |
| `aria-sort` | `columnheader`, `rowheader` | Indicates current sort direction of that column or row |

---

### Grid Role vs Table Role

*Editorial summary — compiled from the separate [Grid](https://www.w3.org/WAI/ARIA/apg/patterns/grid/) and [Table](https://www.w3.org/WAI/ARIA/apg/patterns/table/) pattern pages, not from the grid-and-table-properties practice page.*

| Aspect | `role="table"` | `role="grid"` / `role="treegrid"` |
|---|---|---|
| Interaction model | Read-only data presentation | Interactive — cells can be focusable, editable, selectable |
| Keyboard pattern | Screen reader table navigation only | Arrow keys move focus between cells; Enter/Space activate |
| Cell roles | `cell`, `columnheader`, `rowheader` | `gridcell`, `columnheader`, `rowheader` |
| Use case | Static data display, reports | Spreadsheets, editable tables, data grids with inline actions |
| Sort/filter UI | Can use `aria-sort` on headers | Can use `aria-sort` on headers |

Both roles support all six structural properties (`aria-colcount`, `aria-rowcount`, `aria-colindex`, `aria-rowindex`, `aria-colspan`, `aria-rowspan`).

---

### `aria-rowcount` & `aria-rowindex`

> When the number of rows represented by the DOM structure is not the total number of rows available for a table, grid, or treegrid, the `aria-rowcount` property is used to communicate the total number of rows available, and it is accompanied by the `aria-rowindex` property to identify the row indices of the rows that are present in the DOM.

If the total row count is unknown (e.g., infinite scroll with unknown backend size):

> If the total number of rows is unknown, a value of `-1` may be specified. Using a value of `-1` indicates that more rows are available to include in the DOM without specifying the size of the available supply.

**Validation rules for `aria-rowindex`:**
1. Must be greater than or equal to `1`
2. Must be greater than the `aria-rowindex` on any previous row
3. If a cell spans multiple rows, set to the index of the **first** row in the span
4. Must be less than or equal to the total number of rows

> **Warning:** Missing or inconsistent values of `aria-rowindex` could have devastating effects on assistive technology behavior. For example, specifying an invalid value for `aria-rowindex` or setting it on some but not all rows in a table, could cause screen reader table reading functions to skip rows or simply stop functioning.

```html
<!-- CORRECT: Virtualized grid showing rows 51-53 of 463 total -->
<table role="grid" aria-rowcount="463" aria-label="Student roster for history 101">
  <thead>
    <tr aria-rowindex="1">
      <th>Last Name</th>
      <th>First Name</th>
      <th>E-mail</th>
      <th>Major</th>
      <th>Minor</th>
      <th>Standing</th>
    </tr>
  </thead>
  <tbody>
    <tr aria-rowindex="51">
      <td>Henderson</td>
      <td>Alan</td>
      <td>ahenderson56@myuniversity.edu</td>
      <td>Business</td>
      <td>Spanish</td>
      <td>Junior</td>
    </tr>
    <tr aria-rowindex="52">
      <td>Henderson</td>
      <td>Alice</td>
      <td>ahenderson345@myuniversity.edu</td>
      <td>Engineering</td>
      <td>none</td>
      <td>Sophomore</td>
    </tr>
    <tr aria-rowindex="53">
      <td>Henderson</td>
      <td>Andrew</td>
      <td>ahenderson75@myuniversity.edu</td>
      <td>General Studies</td>
      <td>none</td>
      <td>Freshman</td>
    </tr>
  </tbody>
</table>
```

*Note: WRONG examples throughout this document are editorial additions for learning purposes — the APG source provides only correct examples.*

```html
<!-- WRONG: aria-rowindex missing on some rows — AT behavior will break -->
<table role="grid" aria-rowcount="463" aria-label="Student roster">
  <thead>
    <tr>
      <th>Last Name</th>
      <th>First Name</th>
    </tr>
  </thead>
  <tbody>
    <tr aria-rowindex="51">
      <td>Henderson</td>
      <td>Alan</td>
    </tr>
    <tr><!-- Missing aria-rowindex! -->
      <td>Henderson</td>
      <td>Alice</td>
    </tr>
  </tbody>
</table>
```

---

### `aria-colcount` & `aria-colindex`

> When the number of columns represented by the DOM structure is not the total number of columns available for a table, grid, or treegrid, the `aria-colcount` property is used to communicate the total number of columns available.

If the total column count is unknown:

> If the total number of columns is unknown, a value of `-1` may be specified. Using a value of `-1` indicates that more columns are available to include in the DOM without specifying the size of the available supply.

**Validation rules for `aria-colindex`:**
1. Must be greater than or equal to `1`
2. When set on a cell, must be greater than the value on any previous cell in the same row
3. If a cell spans multiple columns, set to the index of the **first** column in the span
4. Must be less than or equal to the total number of columns

> **Warning:** Missing or inconsistent values of `aria-colindex` could have devastating effects on assistive technology behavior. For example, specifying an invalid value for `aria-colindex` or setting it on some but not all cells in a row, could cause screen reader table reading functions to skip cells or simply stop functioning.

#### Contiguous columns — set `aria-colindex` on the row

> When all the cells in a row have column index numbers that are consecutive integers, `aria-colindex` can be set on the row element with a value equal to the index number of the first column in the set. Browsers will then compute a column number for each cell in the row.

```html
<!-- CORRECT: Contiguous columns 2-5 of 16 — aria-colindex on the row -->
<div role="grid" aria-colcount="16">
  <div role="rowgroup">
    <div role="row" aria-colindex="2">
      <span role="columnheader">First Name</span>
      <span role="columnheader">Last Name</span>
      <span role="columnheader">Company</span>
      <span role="columnheader">Address</span>
    </div>
  </div>
  <div role="rowgroup">
    <div role="row" aria-colindex="2">
      <span role="gridcell">Fred</span>
      <span role="gridcell">Jackson</span>
      <span role="gridcell">Acme, Inc.</span>
      <span role="gridcell">123 Broad St.</span>
    </div>
  </div>
</div>
```

#### Non-contiguous columns — set `aria-colindex` on each cell

> When the cells in a row have column index numbers that are not consecutive integers, `aria-colindex` needs to be set on each cell in the row.

```html
<!-- CORRECT: Non-contiguous columns (1,2 then 10-13) of 13 total -->
<table role="grid" aria-rowcount="463" aria-colcount="13"
  aria-label="Student grades for history 101">
  <thead>
    <tr aria-rowindex="1">
      <th aria-colindex="1">Last Name</th>
      <th aria-colindex="2">First Name</th>
      <th aria-colindex="10">Homework 4</th>
      <th aria-colindex="11">Quiz 2</th>
      <th aria-colindex="12">Homework 5</th>
      <th aria-colindex="13">Homework 6</th>
    </tr>
  </thead>
  <tbody>
    <tr aria-rowindex="50">
      <td aria-colindex="1">Henderson</td>
      <td aria-colindex="2">Alan</td>
      <td aria-colindex="10">8</td>
      <td aria-colindex="11">25</td>
      <td aria-colindex="12">9</td>
      <td aria-colindex="13">9</td>
    </tr>
  </tbody>
</table>
```

```html
<!-- WRONG: Non-contiguous columns but aria-colindex only on the row -->
<table role="grid" aria-colcount="13" aria-label="Student grades">
  <thead>
    <tr aria-colindex="1"><!-- Can't represent non-contiguous gap to col 10 this way -->
      <th>Last Name</th>
      <th>First Name</th>
      <th>Homework 4</th><!-- Browser thinks this is col 3, not 10 -->
    </tr>
  </thead>
</table>
```

---

### `aria-colspan` & `aria-rowspan`

> For tables, grids, and treegrids created using elements other than HTML `table` elements, row and column spans are defined with the `aria-rowspan` and `aria-colspan` properties.

**`aria-colspan` rules:**
1. Must be greater than or equal to `1`
2. Must not cause the cell to overlap the next cell in the same row

**`aria-rowspan` rules:**
1. Must be greater than or equal to `0`
2. A value of `0` means the cell spans all remaining rows in its row group
3. Must not cause the cell to overlap the next cell in the same column

```html
<!-- CORRECT: Spanning cells with ARIA roles (non-HTML-table markup) -->
<div role="grid" aria-rowcount="463" aria-label="Student grades for history 101">
  <div role="rowgroup">
    <div role="row" aria-rowindex="1">
      <span role="columnheader" aria-rowspan="2">Last Name</span>
      <span role="columnheader" aria-rowspan="2">First Name</span>
      <span role="columnheader" aria-colspan="2">Test 1</span>
      <span role="columnheader" aria-colspan="2">Test 2</span>
      <span role="columnheader" aria-colspan="2">Final</span>
    </div>
    <div role="row" aria-rowindex="2">
      <span role="columnheader">Score</span>
      <span role="columnheader">Grade</span>
      <span role="columnheader">Score</span>
      <span role="columnheader">Grade</span>
      <span role="columnheader">Total</span>
      <span role="columnheader">Grade</span>
    </div>
  </div>
  <div role="rowgroup">
    <div role="row" aria-rowindex="50">
      <span role="cell">Henderson</span>
      <span role="cell">Alan</span>
      <span role="cell">89</span>
      <span role="cell">B+</span>
      <span role="cell">72</span>
      <span role="cell">C</span>
      <span role="cell">161</span>
      <span role="cell">B-</span>
    </div>
  </div>
</div>
```

#### Native HTML Tables: Use Native Attributes

> When using HTML `table` elements, use the native semantics of the `th` and `td` elements to define row and column spans by using the `rowspan` and `colspan` attributes.

```html
<!-- CORRECT: HTML table — use native colspan/rowspan -->
<table>
  <thead>
    <tr>
      <th rowspan="2">Name</th>
      <th colspan="2">Test 1</th>
      <th colspan="2">Test 2</th>
    </tr>
    <tr>
      <th>Score</th>
      <th>Grade</th>
      <th>Score</th>
      <th>Grade</th>
    </tr>
  </thead>
</table>
```

```html
<!-- WRONG: Using aria-colspan on native HTML table cells -->
<table>
  <thead>
    <tr>
      <th aria-rowspan="2">Name</th><!-- Use native rowspan="2" instead -->
      <th aria-colspan="2">Test 1</th><!-- Use native colspan="2" instead -->
    </tr>
  </thead>
</table>
```

---

### `aria-sort`

> When rows or columns are sorted, the `aria-sort` property can be applied to a column or row header to indicate the sorting method.

| Value | Meaning |
|---|---|
| `ascending` | Data are sorted in ascending order |
| `descending` | Data are sorted in descending order |
| `other` | Data are sorted by an algorithm other than ascending or descending |
| `none` | Default (no sort applied) |

> It is important to note that ARIA does not provide a way to indicate levels of sort for data sets that have multiple sort keys. Thus, there is limited value to applying `aria-sort` with a value other than `none` to more than one column or row.

```html
<!-- CORRECT: One column marked as sorted -->
<table role="grid" aria-rowcount="463" aria-colcount="13"
  aria-label="Student grades for history 101">
  <thead>
    <tr aria-colindex="10" aria-rowindex="1">
      <th>Homework 4</th>
      <th aria-sort="descending">Quiz 2</th>
      <th>Homework 5</th>
      <th>Homework 6</th>
    </tr>
  </thead>
  <tbody>
    <tr aria-colindex="10" aria-rowindex="50">
      <td>8</td>
      <td>30</td>
      <td>9</td>
      <td>9</td>
    </tr>
    <tr aria-colindex="10" aria-rowindex="51">
      <td>10</td>
      <td>29</td>
      <td>10</td>
      <td>8</td>
    </tr>
  </tbody>
</table>
```

```html
<!-- WRONG: Multiple columns marked as sorted — AT cannot convey multi-level sort -->
<thead>
  <tr>
    <th aria-sort="ascending">Last Name</th>
    <th aria-sort="ascending">First Name</th><!-- No multi-sort support -->
    <th aria-sort="descending">Grade</th><!-- Three sorted columns is misleading -->
  </tr>
</thead>
```

---

### When to Use ARIA Table Properties vs Native HTML

*Editorial guidance synthesized from the APG practices.*

| Scenario | Approach |
|---|---|
| Standard HTML `<table>` with all data in DOM | No ARIA needed — native semantics are sufficient |
| HTML `<table>` with virtualized/paginated rows | Add `aria-rowcount` on `<table>`, `aria-rowindex` on each `<tr>` |
| HTML `<table>` with spanning cells | Use native `colspan`/`rowspan` attributes on `<th>`/`<td>` |
| `<div>`-based grid (CSS Grid layout) | Use `role="grid"` + all ARIA structural properties |
| `<div>`-based grid with spanning cells | Use `aria-colspan`/`aria-rowspan` (native attributes are not available) |
| Sortable column headers | Add `aria-sort` to the currently sorted `<th>` or `columnheader` |
| Unknown total rows (infinite scroll) | Set `aria-rowcount="-1"` |

---

## Part 2 — Range-Related Properties

### Why These Properties Exist

Range widgets communicate a value within a bounded (or unbounded) numeric range. Assistive technologies use `aria-valuemin`, `aria-valuemax`, and `aria-valuenow` to announce the current value and its relationship to the range limits.

---

### Property Reference

| Property | Purpose |
|---|---|
| `aria-valuemin` | Defines the minimum value allowed by the range widget |
| `aria-valuemax` | Defines the maximum value allowed by the range widget |
| `aria-valuenow` | Defines the current value — must be >= `aria-valuemin` and <= `aria-valuemax` |
| `aria-valuetext` | Human-readable text alternative for the current value when the number alone is not meaningful |

---

### Roles That Support Range Properties

| Role | `aria-valuemin` | `aria-valuemax` | `aria-valuenow` | Default min | Default max |
|---|---|---|---|---|---|
| `slider` | Supported | Supported | **Required** | 0 | 100 |
| `spinbutton` | Supported | Supported | Optional | None | None |
| `progressbar` | Supported | Supported | Optional | 0 | 100 |
| `meter` | Supported | Supported | **Required** | 0 | 100 |
| `scrollbar` | Supported | Supported | **Required** | 0 | 100 |
| `separator` (focusable) | Supported | Supported | **Required** | 0 | 100 |

Key differences:
- **`spinbutton`** has no default min/max. If `aria-valuemin` and `aria-valuemax` are not specified, range limits will not be exposed to assistive technologies.
- **`progressbar`** and **`spinbutton`** allow omitting `aria-valuenow` for indeterminate states.
- All other roles **require** `aria-valuenow`.

---

### `aria-valuemin` & `aria-valuemax`

These define the bounds of the range. Most roles default to 0-100, but `spinbutton` has no defaults.

```html
<!-- CORRECT: Slider with explicit range -->
<div role="slider"
  aria-label="Volume"
  aria-valuemin="0"
  aria-valuemax="100"
  aria-valuenow="50"
  tabindex="0">
</div>
```

```html
<!-- CORRECT: Spinbutton with custom range — no defaults exist -->
<input role="spinbutton"
  aria-label="Quantity"
  aria-valuemin="1"
  aria-valuemax="99"
  aria-valuenow="1">
```

```html
<!-- WRONG: Spinbutton missing min/max — AT cannot convey range limits -->
<input role="spinbutton"
  aria-label="Quantity"
  aria-valuenow="5">
```

---

### `aria-valuenow`

> Defines the current value of a range widget. This value is a number greater than or equal to `aria-valuemin` and less than or equal to `aria-valuemax` (if they are specified).

For **indeterminate** states (e.g., a loading bar with unknown progress, or a spinbutton with no value yet):

> Omit the `aria-valuenow` attribute to indicate an indeterminate state.

```html
<!-- CORRECT: Determinate progress bar -->
<div role="progressbar"
  aria-label="File upload"
  aria-valuemin="0"
  aria-valuemax="100"
  aria-valuenow="72">
  72%
</div>
```

```html
<!-- CORRECT: Indeterminate progress bar — aria-valuenow omitted -->
<div role="progressbar"
  aria-label="Loading data"
  aria-valuemin="0"
  aria-valuemax="100">
  Loading...
</div>
```

```html
<!-- WRONG: aria-valuenow outside the declared range -->
<div role="slider"
  aria-valuemin="0"
  aria-valuemax="100"
  aria-valuenow="150"
  aria-label="Brightness">
</div>
```

---

### `aria-valuetext`

> If a numeric value is not sufficiently descriptive, this property can define a text description of the current value of a range widget.

> Only use `aria-valuetext` when `aria-valuenow` is not sufficiently meaningful for users because using `aria-valuetext` will prevent assistive technologies from communicating `aria-valuenow`.

Use `aria-valuetext` when:
- The numeric value maps to a named level (e.g., "Low", "Medium", "High")
- The value represents a compound state (e.g., "5%, 18 minutes remaining")
- The value represents a date, time, or other non-numeric concept
- The raw number is meaningless without context

Always **still include** `aria-valuenow` alongside `aria-valuetext` so that AT can fall back to the numeric value if needed.

```html
<!-- CORRECT: Battery meter with descriptive text -->
<div role="meter"
  aria-label="Battery"
  aria-valuemin="0"
  aria-valuemax="100"
  aria-valuenow="5"
  aria-valuetext="5%, 18 minutes remaining">
</div>
```

```html
<!-- CORRECT: Temperature slider with named levels -->
<div role="slider"
  aria-label="Thermostat"
  aria-valuemin="1"
  aria-valuemax="5"
  aria-valuenow="3"
  aria-valuetext="Medium"
  tabindex="0">
</div>
```

```html
<!-- CORRECT: Day-of-week slider -->
<div role="slider"
  aria-label="Day"
  aria-valuemin="1"
  aria-valuemax="7"
  aria-valuenow="4"
  aria-valuetext="Thursday"
  tabindex="0">
</div>
```

```html
<!-- WRONG: aria-valuetext used when the number IS the meaningful value -->
<div role="slider"
  aria-label="Volume"
  aria-valuemin="0"
  aria-valuemax="100"
  aria-valuenow="72"
  aria-valuetext="72"><!-- Redundant — just use aria-valuenow -->
</div>
```

```html
<!-- WRONG: aria-valuetext without aria-valuenow -->
<div role="meter"
  aria-label="Battery"
  aria-valuemin="0"
  aria-valuemax="100"
  aria-valuetext="Low battery"><!-- Missing aria-valuenow — no numeric fallback -->
</div>
```

---

### Role-Specific Guidance

#### `slider`
- `aria-valuenow` is **required**
- Must be keyboard operable (Arrow keys adjust value)
- Use `aria-valuetext` for non-numeric display labels
- Default range: 0-100
- Must have `tabindex="0"` or be a native focusable element

#### `spinbutton`
- `aria-valuenow` is **optional** (omit for empty/indeterminate)
- `aria-valuemin` and `aria-valuemax` have **no defaults** — always set them explicitly
- Typically paired with increment/decrement buttons
- Supports direct text entry of values

#### `progressbar`
- `aria-valuenow` is **optional** (omit for indeterminate progress)
- Default range: 0-100
- Not interactive — no keyboard pattern needed
- Use `aria-valuetext` for complex status (e.g., "Step 3 of 5: Validating")

#### `meter`
- `aria-valuenow` is **required**
- Default range: 0-100
- Not interactive — represents a scalar measurement
- Good candidate for `aria-valuetext` (e.g., battery life, disk usage with context)

#### `scrollbar`
- `aria-valuenow` is **required**
- Default range: 0-100
- Controls a `scrollable` region — link with `aria-controls`
- `aria-orientation` should be set to `vertical` or `horizontal`

#### `separator` (focusable)
- `aria-valuenow` is **required** when the separator is focusable
- Default range: 0-100
- Represents a movable divider (e.g., split pane resizer)
- Non-focusable separators are purely decorative and do not use range properties

---

### Common Mistakes

*Editorial — common mistakes compiled from general ARIA best practices.*

| Mistake | Why it breaks | Fix |
|---|---|---|
| Omitting `aria-valuenow` on `slider` | AT cannot announce current value | Always set `aria-valuenow` on required roles |
| Omitting `aria-valuemin`/`aria-valuemax` on `spinbutton` | No range limits exposed — AT says "no minimum/maximum" | Always declare bounds for `spinbutton` |
| `aria-valuenow` outside min/max bounds | AT behavior undefined; some ignore, some clamp | Validate before setting: `min <= now <= max` |
| Using `aria-valuetext` when the number is the value | Overrides the numeric announcement for no benefit | Only use when text adds meaning beyond the number |
| Using `aria-valuetext` without `aria-valuenow` | No numeric fallback for AT that prefer numbers | Always include both properties together |
| Setting `aria-valuenow` on indeterminate `progressbar` | Conveys a specific % when state is unknown | Omit `aria-valuenow` entirely for indeterminate state |

---

*Editorial quick reference — not from the APG source pages.*

## Quick Decision Reference

### Grid/Table: Do I Need ARIA Properties?

```
Is the full dataset rendered in the DOM?
  YES --> No ARIA row/col properties needed
  NO  --> Is it an HTML <table>?
            YES --> Add aria-rowcount / aria-colcount on <table>
                    Add aria-rowindex on each <tr>
                    Use native colspan/rowspan for spans
            NO  --> Use role="grid" or role="table"
                    Add all structural ARIA properties
                    Use aria-colspan / aria-rowspan for spans
```

### Range: Which Properties Are Required?

```
What role is the widget?
  slider / meter / scrollbar / separator (focusable)
    --> aria-valuenow is REQUIRED
    --> aria-valuemin / aria-valuemax default to 0/100

  progressbar
    --> aria-valuenow is OPTIONAL (omit for indeterminate)
    --> aria-valuemin / aria-valuemax default to 0/100

  spinbutton
    --> aria-valuenow is OPTIONAL (omit for empty)
    --> aria-valuemin / aria-valuemax have NO DEFAULTS — always set them
```

---

## Cross-References

- See also: [Data Display Widgets](data-display-widgets.md) (grid, table, treegrid patterns)
- See also: [Form Controls](form-controls.md) (slider, spinbutton patterns)
