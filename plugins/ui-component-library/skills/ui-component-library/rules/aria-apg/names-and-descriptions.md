# Accessible Names & Descriptions

Sources:
- https://www.w3.org/WAI/ARIA/apg/practices/names-and-descriptions/
- https://www.w3.org/TR/wai-aria-1.2/#namecalculation
- https://www.w3.org/TR/wai-aria-1.2/#aria-description
- https://www.w3.org/TR/accname-1.2/

---

## Table of Contents
1. [Accessible Name Computation -- Priority Order](#accessible-name-computation----priority-order)
2. [`aria-label`](#aria-label)
3. [`aria-labelledby`](#aria-labelledby)
4. [`aria-describedby`](#aria-describedby)
5. [`aria-description`](#aria-description)
6. [Accessible Description Computation -- Priority Order](#accessible-description-computation----priority-order)
7. [Naming Requirements by Role](#naming-requirements-by-role)
8. [Common Mistakes in Naming](#common-mistakes-in-naming)
9. [Naming Form Controls](#naming-form-controls)
10. [Naming Landmarks](#naming-landmarks)
11. [Naming Images](#naming-images)
12. [Naming Tables](#naming-tables)
13. [Five Cardinal Rules](#five-cardinal-rules)

---

## Accessible Name Computation -- Priority Order

The browser walks this sequence top-to-bottom and uses the **first match**. Once a name is found, later steps are skipped.

| Priority | Source | Example |
|----------|--------|---------|
| 1 (highest) | `aria-labelledby` | `<input aria-labelledby="lbl1 lbl2">` |
| 2 | `aria-label` | `<button aria-label="Close">X</button>` |
| 3 | Native HTML label mechanism | `<label>`, `<caption>`, `<legend>`, `<figcaption>`, `alt`, `value` |
| 4 | Content from descendants (content-naming roles only) | `<button>Save</button>` |
| 5 (lowest / fallback) | `title` attribute, then `placeholder` | `<input title="Search">` |

The `aria-labelledby` property has the highest precedence when browsers calculate accessible names — it overrides names from child content and all other naming attributes, including `aria-label`.

### Detailed Step-by-Step

**Step 1 -- `aria-labelledby`**: If present, concatenate text content of all referenced elements (space-separated). Stops here.

**Step 2 -- `aria-label`**: If step 1 produced nothing and `aria-label` is present, use its string value. Stops here.

**Step 3 -- Host-language (HTML) mechanisms**:
- Input `type="button|submit|reset"`: `value` attribute
- `<img>`, `<area>`, input `type="image"`: `alt` attribute
- `<fieldset>`: first child `<legend>`
- Form controls (`<input>`, `<select>`, `<textarea>`): associated `<label>` element(s)
- `<figure>`: first child `<figcaption>`
- `<table>`: first child `<caption>`

**Step 4 -- Descendant content** (only for roles that support naming from content):
- Recursively walks child nodes and concatenates text
- Excludes certain subtrees: child `group` in `treeitem`, child `menu` in `menuitem`

**Step 5 -- Fallback attributes**:
- Text/search/tel/url inputs and `<textarea>`: `title`, then `placeholder`
- `<input type="submit">`: localized "Submit" string
- `<input type="reset">`: localized "Reset" string
- `<input type="image">`: `title`, then "Submit Query"
- `<summary>`: "Details"
- Everything else: `title`

---

## `aria-label`

Provides an accessible name as an inline string. No visual rendering.

```html
<!-- CORRECT -- icon-only button with no visible text -->
<button type="button" aria-label="Close">
  <svg aria-hidden="true"><!-- X icon --></svg>
</button>

<!-- CORRECT -- landmark disambiguation -->
<nav aria-label="Product">
  <!-- navigation links -->
</nav>
```

### When to Use

- The element has **no visible text** that can serve as its name
- An icon-only button or link needs a text equivalent
- A landmark needs disambiguation from other landmarks of the same type

### Pitfalls

> "If `aria-label` is applied to an element with one of the roles that supports naming from child content, content contained in the element and its descendants is hidden from assistive technology users."

**Content-naming roles** include: `button`, `link`, `checkbox`, `radio`, `switch`, `tab`, `menuitem`, `menuitemcheckbox`, `menuitemradio`, `option`, `treeitem`, `heading`, `cell`, `columnheader`, `gridcell`, `row`, `rowheader`, `tooltip`.

On these roles, `aria-label` **replaces** all descendant content. The descendants become invisible to assistive technology.

```html
<!-- WRONG -- "Save document" text is hidden; AT only sees "Persist" -->
<button aria-label="Persist">
  <svg aria-hidden="true"><!-- save icon --></svg>
  Save document
</button>

<!-- CORRECT -- visible text IS the name -->
<button>
  <svg aria-hidden="true"><!-- save icon --></svg>
  Save document
</button>
```

Other pitfalls:

| Pitfall | Detail |
|---------|--------|
| Not translated | `aria-label` values are invisible to auto-translation tools and must be manually translated for multilingual UIs |
| Not visually testable | The value never renders on screen; you must test with a screen reader or browser accessibility inspector |
| Prohibited on some roles | Cannot be used on `paragraph`, `code`, `emphasis`, `strong`, `generic`, `caption`, `deletion`, `insertion`, `mark`, `subscript`, `superscript`, `none`, `presentation` |

---

## `aria-labelledby`

References one or more elements by ID to compose an accessible name from their text content.

```html
<!-- CORRECT -- referencing a visible heading -->
<h2 id="billing">Billing address</h2>
<div role="group" aria-labelledby="billing">
  <!-- form fields -->
</div>
```

### Referencing Multiple IDs

IDs are space-separated. Content is concatenated in the specified order with a single space between each.

```html
<!-- CORRECT -- concatenates "Download" + "PDF, 2.4 MB" -->
<button id="dl-btn" aria-labelledby="dl-btn dl-details">Download</button>
<span id="dl-details">PDF, 2.4 MB</span>
<!-- Accessible name: "Download PDF, 2.4 MB" -->
```

### Self-Referencing

An element can include its own ID in the `aria-labelledby` list to combine its own content with external content.

```html
<!-- CORRECT -- "Read more..." link disambiguated with heading context -->
<h2 id="bees-heading">7 ways you can help save the bees</h2>
<p>Bees are disappearing rapidly. Here are seven things you can do.</p>
<p>
  <a id="bees-link" aria-labelledby="bees-link bees-heading">
    Read more...
  </a>
</p>
<!-- Accessible name: "Read more... 7 ways you can help save the bees" -->
```

### Can Reference Hidden Elements

`aria-labelledby` incorporates content from elements regardless of their visibility, including elements with the HTML `hidden` attribute, CSS `display: none`, or CSS `visibility: hidden` in the calculated name string.

```html
<!-- CORRECT -- hidden element used only for AT -->
<span id="switch-lbl" hidden>Night mode</span>
<input type="checkbox" role="switch" aria-labelledby="switch-lbl">
```

### Critical Warnings

**Cannot be chained.** If a referenced element itself has `aria-labelledby`, that second-level `aria-labelledby` is ignored.

```html
<!-- WRONG -- chaining does not work -->
<span id="a" aria-labelledby="b">First</span>
<span id="b" aria-labelledby="c">Second</span>
<span id="c">Third</span>
<input aria-labelledby="a">
<!-- Name is "First", NOT "First Second Third" -->
```

**Duplicate references ignored.** If the same ID appears twice, only the first occurrence is processed.

**Hides descendant content on content-naming roles** (same as `aria-label`) unless descendants are also referenced in the `aria-labelledby` list.

---

## `aria-describedby`

Provides supplemental information **beyond** the accessible name. Works the same as `aria-labelledby` mechanically (ID references, concatenation, hidden element support) but populates the accessible **description** instead of the name.

Screen readers typically announce the name and role of an element first. Because descriptions are optional strings that are usually significantly longer than names, they are presented last, sometimes after a slight delay.

```html
<!-- CORRECT -- button has a name ("Move to trash") and a description -->
<button aria-describedby="trash-desc">Move to trash</button>
<p id="trash-desc">
  Items in the trash will be permanently removed after 30 days.
</p>
```

### Name vs. Description

| Aspect | Name (`aria-label` / `aria-labelledby`) | Description (`aria-describedby`) |
|--------|-----------------------------------------|----------------------------------|
| Purpose | Identifies the element | Provides supplemental detail |
| Announcement order | First (with role) | Last, sometimes after a delay |
| Required? | Often required by role | Always optional |
| Typical length | 1-3 words | One or more sentences |
| Omission impact | Element may be inaccessible | Less context, but still usable |

### Hidden Descriptions

Descriptions can reference hidden elements. This is useful for help text that is only visible on demand.

```html
<!-- CORRECT -- description content hidden until user clicks "?" -->
<label for="username">Username</label>
<input id="username" name="username" aria-describedby="username-desc">
<button aria-expanded="false" aria-controls="username-desc"
        aria-label="Help about username">?</button>
<p id="username-desc" hidden>
  Your username is the name that you use to log in to this service.
</p>
```

### Images Inside Descriptions

When a description references an element containing images, the images' `alt` text is included in the computed description string.

```html
<button aria-describedby="trash-desc">
  Move to <img src="bin.svg" alt="trash">
</button>
<p id="trash-desc">
  Items in <img src="bin.svg" alt="the trash"> will be permanently
  removed after 30 days.
</p>
<!-- Description: "Items in the trash will be permanently removed after 30 days." -->
```

---

## `aria-description`

*Note: `aria-description` is defined in the ARIA spec (not covered in the APG practices page). It has limited browser support.*

The `aria-description` attribute provides an accessible description as an **inline string** directly on the element, similar to how `aria-label` works for names.

| Attribute | Mechanism | Status |
|-----------|-----------|--------|
| `aria-describedby` | References other elements by ID | Stable, well-supported |
| `aria-description` | Inline string value on the element | ARIA 1.3 draft; partial support |

**Recommendation:** Use `aria-describedby` as the primary mechanism. Only use `aria-description` when there is no suitable element to reference AND you have verified browser/AT support in your target matrix.

```html
<!-- Preferred -- aria-describedby with existing element -->
<button aria-describedby="help-text">Submit</button>
<p id="help-text">This will finalize your order.</p>

<!-- Alternative -- aria-description inline (check support first) -->
<button aria-description="This will finalize your order.">Submit</button>
```

---

## Accessible Description Computation -- Priority Order

The description algorithm mirrors the name algorithm but uses different sources:

| Priority | Source |
|----------|--------|
| 1 (highest) | `aria-describedby` |
| 2 | `aria-description` (where supported; defined in ARIA spec, not the APG page) |
| 3 | Host-language attributes not already consumed as name (e.g., `title`) |
| 4 (lowest) | Nothing -- description is empty |

The `title` attribute serves as a fallback description only if it was not already used as the accessible name. If `title` was consumed as the name (because no `<label>`, `aria-label`, or `aria-labelledby` was present), it will not also serve as the description.

---

## Naming Requirements by Role

### MUST Have a Name

These roles are **required** to have an accessible name. Missing names are WCAG failures.

| Role | Recommended technique | Notes |
|------|----------------------|-------|
| `alertdialog` | `aria-labelledby` (visible title) or `aria-label` | |
| `application` | `aria-labelledby` or `aria-label` | |
| `combobox` | HTML `<label>` if native; else `aria-labelledby` / `aria-label` | |
| `dialog` | `aria-labelledby` (visible title) or `aria-label` | |
| `grid` | HTML `<caption>` if `<table>`; else `aria-labelledby` / `aria-label` | |
| `img` | HTML `alt` if `<img>`; else `aria-labelledby` / `aria-label` | |
| `listbox` | HTML `<label>` if `<select>`; else `aria-labelledby` / `aria-label` | |
| `meter` | HTML `<label>` if `<meter>`; else `aria-labelledby` / `aria-label` | |
| `progressbar` | HTML `<label>` if `<progress>`; else `aria-labelledby` / `aria-label` | |
| `radiogroup` | `aria-labelledby` (visible label) or `aria-label` | |
| `region` | `aria-labelledby` (visible label) or `aria-label` | Unnamed `region` is a landmark without identity |
| `searchbox` | HTML `<label>` if `<input>`; else `aria-labelledby` / `aria-label` | |
| `slider` | HTML `<label>` if `<input[type=range]>`; else `aria-labelledby` / `aria-label` | |
| `spinbutton` | HTML `<label>` if `<input[type=number]>`; else `aria-labelledby` / `aria-label` | |
| `table` | HTML `<caption>` if `<table>`; else `aria-labelledby` / `aria-label` | |
| `tabpanel` | `aria-labelledby` pointing to its controlling `tab` element | |
| `textbox` | HTML `<label>` if `<input>`/`<textarea>`; else `aria-labelledby` / `aria-label` | |
| `tree` | `aria-labelledby` (visible label) or `aria-label` | |
| `treegrid` | HTML `<caption>` if `<table>`; else `aria-labelledby` / `aria-label` | |

### SHOULD Have a Name (Content-Derived, Override Only If Insufficient)

These roles derive their name from **visible descendant content**. Use `aria-label` or `aria-labelledby` only when descendant content is insufficient. Both attributes **hide** descendant content from AT on these roles.

| Role | Notes |
|------|-------|
| `button` | Name from visible text content. Icon-only buttons need `aria-label`. |
| `cell` | Name is cell content. Headers are complementary, not naming. Empty cells = empty name (expected). |
| `checkbox` | HTML `<label>` if native; else content or `aria-labelledby` |
| `columnheader` | Content-derived. `abbr` attribute can abbreviate for repeated announcements. |
| `gridcell` | Same as `cell`. |
| `heading` | Content-derived. |
| `link` | Content-derived. Images inside links contribute `alt` text. |
| `menuitem` | Content-derived. Child `menu` content excluded from calculation automatically. |
| `menuitemcheckbox` | Content-derived. |
| `menuitemradio` | Content-derived. |
| `option` | Content-derived. |
| `radio` | HTML `<label>` if native; else content or `aria-labelledby` |
| `row` | Name only needed if focusable in a `treegrid` AND descendant content is insufficient. |
| `rowheader` | Content-derived. `abbr` attribute can abbreviate. |
| `switch` | HTML `<label>` if native; else content or `aria-labelledby` |
| `tab` | Content-derived. |
| `tooltip` | Content-derived. |
| `treeitem` | Content-derived. Child `group` content excluded from calculation automatically. |

### RECOMMENDED (Discretionary but Beneficial)

| Role | When required | Technique |
|------|--------------|-----------|
| `article` | When multiple articles exist | `aria-labelledby` or `aria-label` |
| `complementary` | When multiple; recommended even with one | `aria-labelledby` or `aria-label` |
| `definition` | To associate with `term` | `aria-labelledby` referencing `role="term"` element |
| `feed` | To help users understand context | `aria-labelledby` or `aria-label` |
| `figure` | For HTML use `<figcaption>`; else `aria-labelledby` | |
| `form` | To help users understand purpose | `aria-labelledby` or `aria-label` |
| `math` | `aria-label` for expression text or `aria-labelledby` for visible label | |
| `menu` | `aria-labelledby` to refer to controlling button/menuitem | |
| `menubar` | To help users understand purpose | `aria-labelledby` or `aria-label` |
| `navigation` | When multiple; recommended even with one | `aria-labelledby` or `aria-label` |
| `search` | To help users understand purpose | `aria-labelledby` or `aria-label` |
| `tablist` | To help users understand purpose | `aria-labelledby` or `aria-label` |
| `toolbar` | Required if multiple toolbars; recommended otherwise | `aria-labelledby` or `aria-label` |

### MAY Have a Name (Discretionary)

| Role | Notes |
|------|-------|
| `alert` | `aria-label` prefaces content before announcement |
| `banner` | Required only when two or more banner landmarks exist |
| `blockquote` | `aria-labelledby` can associate a visible label |
| `contentinfo` | Required only when two or more contentinfo landmarks exist |
| `directory` | `aria-labelledby` or `aria-label` |
| `document` | Usually contained inside `application` which already has a name |
| `group` | HTML `<fieldset>` uses `<legend>`; HTML `<details>` should NOT be named (name the `<summary>` instead) |
| `list` | Can aid list navigation in some screen readers but may add verbosity |
| `log` | `aria-label` prefaces content before announcement |
| `main` | Helpful for orientation, especially in SPAs |
| `marquee` | `aria-labelledby` or `aria-label` |
| `note` | Can help users understand context |
| `scrollbar` | Can help users understand purpose |
| `separator` (focusable) | Recommended if multiple on page |
| `status` | `aria-label` prefaces content before announcement |
| `timer` | `aria-label` prefaces content before announcement |

### MUST NOT Be Named (Naming Not Supported)

| Role | Reason |
|------|--------|
| `listitem` | Not supported by assistive technologies |
| `rowgroup` | Not supported by assistive technologies |
| `term` | The term IS the name for its associated `definition`; naming it would be confusing |
| `time` | Not supported by assistive technologies |

### Naming PROHIBITED (Spec Violation)

Using `aria-label` or `aria-labelledby` on these roles is a spec violation that validators flag as errors.

| Role |
|------|
| `caption` |
| `code` |
| `deletion` |
| `emphasis` |
| `generic` |
| `insertion` |
| `mark` |
| `none` |
| `paragraph` |
| `presentation` |
| `strong` |
| `subscript` |
| `superscript` |

---

## Common Mistakes in Naming

### 1. Including the Role in the Name

Do not include a WAI-ARIA role name in the accessible name. For example, do not include the word "button" in the name of a button. Doing so would create duplicate screen reader output since screen readers convey the role of an element in addition to its name.

```html
<!-- WRONG -- screen reader announces "Submit button button" -->
<button>Submit button</button>

<!-- CORRECT -->
<button>Submit</button>

<!-- WRONG -- "Image of a sunset" announced as "Image of a sunset, image" -->
<img alt="Image of a sunset" src="sunset.jpg">

<!-- CORRECT -->
<img alt="Golden sunset over the Pacific Ocean" src="sunset.jpg">

<!-- WRONG -- "Navigation menu" announced as "Navigation menu, navigation" -->
<nav aria-label="Navigation menu">

<!-- CORRECT -->
<nav aria-label="Product">
```

### 2. Using ARIA When Native HTML Works

HTML `label` for form elements and `caption` for tables are simpler and more robust than ARIA naming techniques.

```html
<!-- WRONG -- aria-labelledby when <label> works -->
<span id="user-label">Username</span>
<input aria-labelledby="user-label">

<!-- CORRECT -- native <label> also increases click target area -->
<label for="user">Username</label>
<input id="user">
```

### 3. Relying on `title` or `placeholder` as the Name

The `placeholder` attribute disappears visually when the user focuses the form control — use a `<label>` element instead, which remains visible.

```html
<!-- WRONG -- placeholder as sole label -->
<input type="search" placeholder="Search">

<!-- WRONG -- title as sole label -->
<input type="search" title="Search">

<!-- CORRECT -->
<label>Search <input type="search"></label>
```

### 4. Composing Poor Names

| Problem | Example | Fix |
|---------|---------|-----|
| Too long | "Click this button to submit the registration form and create your new account" | "Submit registration" |
| Not distinct | Three links all named "Read more" | "Read more about bees", "Read more about birds" |
| Describes form, not function | "Left sidebar links" | "Product categories" |
| Missing capitalization | "submit" | "Submit" |
| Ends with period | "Submit." | "Submit" |

> "Convey function or purpose, not form. For example, if an icon that looks like the letter X closes a dialog, name it Close, not X."

> "Put the most distinguishing and important words first."

> "Start names with a capital letter; it helps some screen readers speak them with appropriate inflection. Do not end names with a period; they are not sentences."

### 5. Hiding Content Unintentionally

```html
<!-- WRONG -- "Save" and the icon are hidden from AT; name becomes "Persist" -->
<button aria-label="Persist">
  <svg aria-hidden="true"><!-- save icon --></svg>
  Save
</button>

<!-- CORRECT -- let content provide the name -->
<button>
  <svg aria-hidden="true"><!-- save icon --></svg>
  Save
</button>
```

### 6. Chaining `aria-labelledby`

```html
<!-- WRONG -- chaining is not supported; second reference's aria-labelledby is ignored -->
<span id="a" aria-labelledby="b">Alpha</span>
<span id="b">Beta</span>
<input aria-labelledby="a">
<!-- Name: "Alpha" (NOT "Beta") -->
```

### 7. Naming Elements That Must Not Be Named

```html
<!-- WRONG -- paragraph cannot have an accessible name -->
<p aria-label="Important notice">The store closes at 5 PM.</p>

<!-- WRONG -- list items should not be named -->
<li aria-label="First item">Apples</li>

<!-- CORRECT -- let content speak for itself -->
<p>The store closes at 5 PM.</p>
<li>Apples</li>
```

---

## Naming Form Controls

### Preferred: `<label>` Element

```html
<!-- CORRECT -- implicit association (wrapping) -->
<label>
  Email address
  <input type="email" name="email">
</label>

<!-- CORRECT -- explicit association (for/id) -->
<label for="email">Email address</label>
<input type="email" id="email" name="email">
```

The `<label>` element is preferred because:
- It is the native HTML mechanism (no ARIA needed)
- Clicking the label focuses/activates the control (larger hit target)
- It is visible to all users, not just AT users

### Grouping Related Controls: `<fieldset>` + `<legend>`

```html
<!-- CORRECT -- legend provides group context to each radio -->
<fieldset>
  <legend>Shipping method</legend>
  <label><input type="radio" name="ship" value="std"> Standard</label>
  <label><input type="radio" name="ship" value="exp"> Express</label>
  <label><input type="radio" name="ship" value="over"> Overnight</label>
</fieldset>
```

Screen readers announce: "Shipping method, group" then "Standard, radio button, 1 of 3".

```html
<!-- CORRECT -- grouping address fields that repeat -->
<fieldset>
  <legend>Shipping address</legend>
  <p><label>Full name <input name="ship-name" required></label></p>
  <p><label>Address line 1 <input name="ship-addr1" required></label></p>
  <p><label>Address line 2 <input name="ship-addr2"></label></p>
</fieldset>
<fieldset>
  <legend>Billing address</legend>
  <p><label>Full name <input name="bill-name" required></label></p>
  <p><label>Address line 1 <input name="bill-addr1" required></label></p>
  <p><label>Address line 2 <input name="bill-addr2"></label></p>
</fieldset>
```

> When using HTML `<details>`, do NOT name the `group`; name the `<summary>` instead (it derives its accessible name from its content).

---

## Naming Landmarks

When a page has **multiple landmarks of the same type**, each must be given a distinct name. Even with a single instance, naming is recommended for `navigation`, `complementary`, `search`, and `form`.

```html
<!-- CORRECT -- two nav landmarks distinguished -->
<nav aria-label="Main">
  <ul><!-- primary site links --></ul>
</nav>

<nav aria-label="Related articles">
  <ul><!-- contextual links --></ul>
</nav>

<!-- CORRECT -- aria-labelledby when a visible heading exists -->
<nav aria-labelledby="related-heading">
  <h2 id="related-heading">Related articles</h2>
  <ul><!-- links --></ul>
</nav>
```

| Landmark role | When name is required |
|--------------|----------------------|
| `banner` | Only when 2+ banner landmarks on the page |
| `complementary` | Recommended always; required when 2+ |
| `contentinfo` | Only when 2+ contentinfo landmarks on the page |
| `form` | Recommended always |
| `main` | Recommended always; especially in SPAs |
| `navigation` | Recommended always; required when 2+ |
| `region` | Always required (unnamed region has no identity) |
| `search` | Recommended always |

---

## Naming Images

### Informative Images

```html
<!-- CORRECT -- describes what the image conveys -->
<img alt="Bar chart showing 40% revenue growth in Q3" src="chart.png">
```

### Decorative Images

```html
<!-- CORRECT -- empty alt removes from accessibility tree -->
<img alt="" src="decorative-border.png">
```

### Images Using ARIA `img` Role

```html
<!-- CORRECT -- non-<img> element with img role -->
<div role="img" aria-label="Pie chart: 60% desktop, 30% mobile, 10% tablet">
  <!-- CSS background image or SVG -->
</div>
```

### Figures with Captions

```html
<!-- CORRECT -- figcaption names the figure -->
<figure>
  <img alt="Painting of a person walking in a desert."
       src="desert.jpg">
  <figcaption>
    Jesus entering the desert as imagined by William Hole, 1908
  </figcaption>
</figure>
```

When you need a **separate name and description** for a figure:

```html
<!-- CORRECT -- heading as name, figcaption as description -->
<h2 id="neutron">Neutron</h2>
<figure aria-labelledby="neutron" aria-describedby="neutron-caption">
  <img alt="Within the neutron are three quarks interconnected by gluons."
       src="neutron.svg">
  <figcaption id="neutron-caption">
    The quark content of the neutron. The color assignment of individual
    quarks is arbitrary, but all three colors must be present.
  </figcaption>
</figure>
```

---

## Naming Tables

### Preferred: `<caption>` Element

```html
<!-- CORRECT -->
<table>
  <caption>Special opening hours</caption>
  <tr><td>30 May</td><td>Closed</td></tr>
  <tr><td>6 June</td><td>11:00 - 16:00</td></tr>
</table>
```

### When `aria-labelledby` Is Used, `<caption>` Becomes the Description

If a table is named using `aria-label` or `aria-labelledby`, then a `caption` element, if present, becomes an accessible description rather than the name.

```html
<!-- CORRECT -- heading is the name, caption is the description -->
<h2 id="events-heading">Upcoming events</h2>
<table aria-labelledby="events-heading">
  <caption>
    Calendar of upcoming events, weeks 27 through 31, with each week
    starting with Monday. The first column is the week number.
  </caption>
  <thead>
    <tr><th>Week</th><th>Monday</th><th>Tuesday</th></tr>
  </thead>
  <tbody>
    <tr><td>27</td><td>Team sync</td><td>--</td></tr>
  </tbody>
</table>
```

### Table Cell Naming

> "Note that a name is not required; assistive technologies expect an empty cell in a table to be represented by an empty name. Note that associated row or column headers do not name a `cell`; the name of a cell in a table is its content. Headers are complementary information."

---

## Five Cardinal Rules

These rules summarize the APG's guidance into a decision framework:

**Rule 1: Heed Warnings and Test Thoroughly.**
Names computed from `aria-labelledby` or `aria-label` are not visually rendered. Always verify with a screen reader or the browser accessibility tree inspector.

**Rule 2: Prefer visible text.**
Visible labels benefit all users -- sighted users who do not use AT, users with cognitive disabilities, and speech-input users who activate controls by speaking their visible label.

**Rule 3: Prefer Native Techniques.**
`<label>` over `aria-labelledby`. `<caption>` over `aria-label`. `<legend>` over `aria-label` on a group. Native techniques are simpler, more robust, and provide interaction benefits (click-to-focus).

**Rule 4: Avoid Browser Fallback.**
`title` and `placeholder` are last-resort mechanisms. They have poor discoverability, disappear on focus (placeholder), or require hover (title).

**Rule 5: Compose Brief, Useful Names.**
Start with a capital letter. Put the verb/action first. Keep it to 1-3 words. Do not include the role. Do not end with a period. Make every name unique unless elements are truly identical.

---

> See also: [Landmarks & Structure](landmarks-and-structure.md)

> See also: [Form Controls](form-controls.md)
