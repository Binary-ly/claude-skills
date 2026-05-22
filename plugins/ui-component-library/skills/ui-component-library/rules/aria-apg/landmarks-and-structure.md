# Landmarks & Structural Roles

Reference for ARIA landmark regions, structural roles, and techniques for hiding or removing semantics from the accessibility tree.

## Sources:

- https://www.w3.org/WAI/ARIA/apg/practices/landmark-regions/
- https://www.w3.org/WAI/ARIA/apg/practices/structural-roles/
- https://www.w3.org/WAI/ARIA/apg/practices/hiding-semantics/
- https://www.w3.org/TR/wai-aria-1.2/#aria-hidden (ARIA spec)
- https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Attributes/aria-hidden (MDN)

---

## Table of Contents
1. [1. Landmark Regions](#1-landmark-regions)
2. [2. Structural Roles](#2-structural-roles)
3. [3. Hiding & Removing Semantics](#3-hiding--removing-semantics)
4. [4. Quick-Reference Checklist](#4-quick-reference-checklist)

---

## 1. Landmark Regions

Landmarks classify and label sections of a page so that structural information conveyed visually through layout is represented programmatically. Screen readers use landmark roles to provide keyboard navigation to important sections.

> By classifying and labelling sections of a page, they enable structural information that is conveyed visually through layout to be represented programmatically. Screen readers exploit landmark roles to provide keyboard navigation to important sections of a page.

### 1.1 Landmark Role Reference

| Landmark Role    | HTML Equivalent           | Conditions / Notes                                                                 |
|------------------|---------------------------|------------------------------------------------------------------------------------|
| `banner`         | `<header>`                | Only when `<header>` is a direct child of `<body>` (not nested in `article`, `aside`, `main`, `nav`, `section`) |
| `navigation`     | `<nav>`                   | Always maps implicitly                                                             |
| `main`           | `<main>`                  | Always maps implicitly                                                             |
| `complementary`  | `<aside>`                 | Always maps implicitly                                                             |
| `contentinfo`    | `<footer>`                | Only when `<footer>` is a direct child of `<body>` (not nested in `article`, `aside`, `main`, `nav`, `section`) |
| `form`           | `<form>`                  | **Only when the `<form>` has an accessible name** (via `aria-label`, `aria-labelledby`, or `title`) |
| `search`         | `<search>`                | Always maps implicitly                                                             |
| `region`         | `<section>`               | **Only when the `<section>` has an accessible name** (via `aria-label`, `aria-labelledby`, or `title`) |

### 1.2 Page-Level Requirements

Every page must have at a minimum:

| Required Landmark | Count   | Notes                                              |
|--------------------|---------|----------------------------------------------------|
| `banner`           | Exactly 1 | Site-oriented content: logo, identity, site search |
| `main`             | Exactly 1 | Primary content of the page                        |
| `contentinfo`      | Exactly 1 | Site-wide footer content                           |

Multiple instances of `navigation`, `complementary`, `form`, `search`, and `region` are permitted.

Include all perceivable content on a page in one of its landmark regions -- this is one of the most effective ways of ensuring assistive technology users will not overlook information.

**Exception -- modal dialogs:**

Wrapping the content of a modal dialog in a landmark region is unnecessary. A landmark that wraps modal content cannot provide any benefit to users because it is not perceivable unless the modal is open.

Do not wrap modal dialog content in a landmark.

### 1.3 Nesting Rules

- `banner`, `main`, `complementary`, and `contentinfo` must be **top-level** landmarks (not nested inside other landmarks, except the page's own document).
- Landmark roles can be nested to identify parent/child relationships (e.g., a `navigation` inside `banner`).
- Nested documents or applications (iframes) may each have their own `banner`, `main`, and `contentinfo`.

```html
<!-- CORRECT: top-level landmarks -->
<body>
  <header>  <!-- banner -->
    <nav aria-label="Main">...</nav>  <!-- navigation nested in banner: OK -->
  </header>
  <main>...</main>
  <aside>...</aside>  <!-- complementary: top-level -->
  <footer>...</footer>  <!-- contentinfo -->
</body>

<!-- WRONG: main nested inside complementary -->
<body>
  <header>...</header>
  <aside>
    <main>...</main>  <!-- main must be top-level -->
  </aside>
  <footer>...</footer>
</body>
```

### 1.4 Labeling Landmarks

When **multiple instances** of the same landmark role appear on a page, each must have a unique label so users can distinguish them.

> If a specific landmark role is used more than once on a page, provide each instance of that landmark with a unique label.

**Exception:** identical content serving the same purpose (e.g., pagination above and below a table) may share the same label.

**Methods:**

1. **`aria-labelledby`** -- preferred when the landmark already contains a visible heading.
2. **`aria-label`** -- use when no visible heading exists.

**Do not include the role name in the label:**

> A navigation landmark with a label "Site Navigation" will be announced by a screen reader as "Site Navigation Navigation."

```html
<!-- CORRECT: label does not repeat the role -->
<nav aria-label="Products">
  <ul>...</ul>
</nav>
<nav aria-label="Corporate">
  <ul>...</ul>
</nav>

<!-- CORRECT: using aria-labelledby with a visible heading -->
<nav aria-labelledby="nav-heading">
  <h2 id="nav-heading">Products</h2>
  <ul>...</ul>
</nav>

<!-- WRONG: label repeats the implicit role -->
<nav aria-label="Product Navigation">
  <!-- screen reader announces: "Product Navigation navigation" -->
  <ul>...</ul>
</nav>
```

If a landmark is the only instance of its role on the page, a label is not strictly required (the role itself is sufficient).

### 1.5 Context-Dependent Implicit Roles

`<header>` and `<footer>` lose their landmark roles when nested inside sectioning elements:

| Element     | Landmark When...                                        | NOT a Landmark When Nested In...                          |
|-------------|---------------------------------------------------------|-----------------------------------------------------------|
| `<header>`  | Direct child of `<body>` or top-level context           | `<article>`, `<aside>`, `<main>`, `<nav>`, `<section>`   |
| `<footer>`  | Direct child of `<body>` or top-level context           | `<article>`, `<aside>`, `<main>`, `<nav>`, `<section>`   |
| `<form>`    | Has an accessible name (`aria-label` / `aria-labelledby` / `title`) | Missing accessible name (no landmark role)               |
| `<section>` | Has an accessible name (`aria-label` / `aria-labelledby` / `title`) | Missing accessible name (no landmark role)               |

```html
<!-- CORRECT: <header> is banner because it's a direct child of body -->
<body>
  <header>
    <h1>My Site</h1>
  </header>
  <main>
    <article>
      <header>
        <!-- This is NOT a banner landmark, just a plain header -->
        <h2>Article Title</h2>
      </header>
    </article>
  </main>
  <footer>Site info</footer>
</body>
```

### 1.6 Landmark Design Process

The APG recommends a three-step process:

1. **Identify logical structure:** break the page into perceivable areas of content using visual alignment, spacing, and grouping; define sub-areas as needed.
2. **Assign landmark roles:** match roles to content purpose; establish parent/child relationships through nesting.
3. **Label areas:** provide unique labels for multiple instances; use visible headings where possible.

---

## 2. Structural Roles

Structural roles convey the organization of content (headings, lists, tables, etc.). The first rule of ARIA applies:

> Do not use an ARIA role or property if it is possible to use an HTML element that has equivalent semantics.

### 2.1 Structural Role Reference

**Roles with direct HTML equivalents (prefer the HTML element):**

| ARIA Role        | HTML Equivalent      |
|------------------|----------------------|
| `article`        | `<article>`          |
| `blockquote`     | `<blockquote>`       |
| `caption`        | `<caption>`          |
| `cell`           | `<td>`               |
| `code`           | `<code>`             |
| `columnheader`   | `<th>` (in column)   |
| `definition`     | `<dd>`               |
| `deletion`       | `<del>`              |
| `emphasis`       | `<em>`               |
| `figure`         | `<figure>`           |
| `generic`        | `<div>` / `<span>`   |
| `heading`        | `<h1>` -- `<h6>`     |
| `img`            | `<img>`              |
| `insertion`      | `<ins>`              |
| `list`           | `<ul>` / `<ol>`      |
| `listitem`       | `<li>`               |
| `mark`           | `<mark>`             |
| `paragraph`      | `<p>`                |
| `row`            | `<tr>`               |
| `rowgroup`       | `<tbody>` / `<thead>` / `<tfoot>` |
| `rowheader`      | `<th>` (in row)      |
| `separator` (non-focusable) | `<hr>`               |
| `strong`         | `<strong>`            |
| `subscript`      | `<sub>`              |
| `superscript`    | `<sup>`              |
| `table`          | `<table>`            |
| `term`           | `<dfn>`              |
| `time`           | `<time>`             |

**Roles without HTML equivalents (ARIA is the only option):**

| ARIA Role      | Purpose                                                  |
|----------------|----------------------------------------------------------|
| `application`  | Declares a region as a web application (disables browse-mode keys) |
| `directory`    | A list of references to group members (deprecated in ARIA 1.2; note: deprecation per ARIA spec, not the APG structural roles page) |
| `document`     | Content treated as a document by assistive tech          |
| `feed`         | Scrollable list of articles where new articles load as user scrolls |
| `group`        | A set of related UI objects not intended for page TOC    |
| `math`         | Mathematical expression                                 |
| `none`         | Synonym for `presentation` (see Section 3)               |
| `note`         | Parenthetical or ancillary content                       |
| `presentation` | Removes implicit role semantics (see Section 3)          |
| `toolbar`      | A collection of commonly used function buttons/controls  |
| `tooltip`      | Contextual popup displaying a description for an element |

### 2.2 When to Use ARIA Structural Roles Instead of HTML

Use ARIA structural roles **only** when:

1. The HTML element cannot achieve the required visual design without excessive CSS workarounds.
2. Testing demonstrates that browsers or assistive tech support the ARIA approach better than the HTML equivalent.
3. Retrofitting legacy content where changing the DOM structure is cost-prohibitive.
4. Building web components whose shadow DOM provides insufficient native semantics.

```html
<!-- CORRECT: native HTML for a heading -->
<h2>Product Features</h2>

<!-- WRONG: using ARIA when native HTML would work -->
<div role="heading" aria-level="2">Product Features</div>

<!-- ACCEPTABLE: ARIA heading in a legacy system where
     changing the element is not feasible -->
<span role="heading" aria-level="2">Product Features</span>
```

```html
<!-- CORRECT: native HTML table -->
<table>
  <thead>
    <tr><th>Name</th><th>Price</th></tr>
  </thead>
  <tbody>
    <tr><td>Widget</td><td>$5</td></tr>
  </tbody>
</table>

<!-- WRONG: ARIA table roles when native HTML would suffice -->
<div role="table">
  <div role="rowgroup">
    <div role="row">
      <div role="columnheader">Name</div>
      <div role="columnheader">Price</div>
    </div>
  </div>
  <div role="rowgroup">
    <div role="row">
      <div role="cell">Widget</div>
      <div role="cell">$5</div>
    </div>
  </div>
</div>
```

---

## 3. Hiding & Removing Semantics

Three distinct mechanisms exist for hiding content or removing semantics from the accessibility tree. They are **not interchangeable**.

### 3.1 `role="presentation"` / `role="none"`

These are synonyms (introduced as aliases in ARIA 1.1). They declare that an element is used only for visual presentation and has no accessibility semantics.

An element whose role is `presentation` is not represented as having any role in the accessibility API. It has no role mapping.

**What they do:**

- Remove the element's **implicit ARIA role** and its associated states/properties from the accessibility tree.
- **Do not** hide the element's text content or descendant elements. Children remain visible to assistive tech unless independently hidden.

**Required owned elements inherit presentation:**

When `presentation` is applied to an element with required child roles, those children also become presentational:

| Parent Element    | Children That Inherit `presentation`                        |
|-------------------|-------------------------------------------------------------|
| `<ul>` / `<ol>`  | `<li>` elements (because `listitem` requires parent `list`) |
| `<table>`         | `<caption>`, `<thead>`, `<tbody>`, `<tfoot>`, `<tr>`, `<th>`, `<td>` |

Content nested deeper than the required children retains its semantics:

```html
<!-- CORRECT: presentation on list removes list+listitem semantics,
     but links inside remain accessible -->
<ul role="presentation">
  <li><a href="/home">Home</a></li>
  <li><a href="/about">About</a></li>
</ul>
<!-- Equivalent to: -->
<div>
  <div><a href="/home">Home</a></div>
  <div><a href="/about">About</a></div>
</div>
```

```html
<!-- CORRECT: tabs widget using list markup with presentation to
     suppress list/listitem semantics -->
<ul role="tablist">
  <li role="presentation">
    <a role="tab" href="#panel1">Tab 1</a>
  </li>
  <li role="presentation">
    <a role="tab" href="#panel2">Tab 2</a>
  </li>
</ul>
```

```html
<!-- Layout table: suppress table semantics entirely -->
<table role="presentation">
  <tr>
    <td>Left column content</td>
    <td>Right column content</td>
  </tr>
</table>
```

**Presentation is ignored on focusable elements:**

> Browsers ignore `role="presentation"`, and it therefore has no effect, if either of the following are true about the element to which it is applied:
> 1. The element is focusable, e.g. it is natively focusable like an HTML link or input, or it has a `tabindex` attribute.
> 2. The element has any global ARIA states and properties (e.g., `aria-label`).

```html
<!-- WRONG: presentation on a focusable element is ignored -->
<button role="presentation">Click Me</button>
<!-- This is still announced as a button by screen readers -->

<!-- WRONG: presentation on element with tabindex is ignored -->
<div role="presentation" tabindex="0">Focusable div</div>
<!-- Still exposed to accessibility tree -->
```

### 3.2 Roles With Presentational Children

Certain roles **automatically** make all their descendants presentational because the accessibility APIs have no mechanism to represent semantic elements contained within them. The text content of descendants is still accessible, but their roles are stripped.

> Accessibility APIs do not have a way of representing semantic elements contained in a button.

**Roles that require presentational children:**

`button`, `checkbox`, `img`, `meter`, `menuitemcheckbox`, `menuitemradio`, `option`, `progressbar`, `radio`, `scrollbar`, `separator`, `slider`, `switch`, `tab`

```html
<!-- The heading semantics are automatically hidden inside a tab -->
<li role="tab"><h2>Title of My Tab</h2></li>
<!-- Equivalent to: -->
<li role="tab">Title of My Tab</li>
<!-- Screen readers will NOT announce "heading level 2" -->
```

### 3.3 `aria-hidden="true"`

*Sources: [ARIA 1.2 spec -- `aria-hidden`](https://www.w3.org/TR/wai-aria-1.2/#aria-hidden), [MDN -- `aria-hidden`](https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Attributes/aria-hidden)*

`aria-hidden="true"` removes an element **and all of its descendants** from the accessibility tree entirely. Unlike `role="presentation"`, it hides text content, child elements, and everything within.

**Key behaviors:**

- **Inherited by all descendants.** Once set on a parent, no child can opt back in. There is no way to set `aria-hidden="false"` on a descendant to override a parent's `aria-hidden="true"`.
- **Does not affect visual rendering.** The element remains visually visible; only assistive tech is affected.
- **Does not remove focusability.** A focusable element inside an `aria-hidden` subtree can still receive keyboard focus, creating a broken experience where a screen reader user focuses an element they cannot perceive.

```html
<!-- CORRECT: decorative icon hidden from assistive tech -->
<button>
  <svg aria-hidden="true" focusable="false">
    <use href="#icon-save"/>
  </svg>
  Save
</button>

<!-- CORRECT: hiding a decorative background element -->
<div class="hero">
  <div class="hero-decoration" aria-hidden="true"></div>
  <h1>Welcome</h1>
</div>
```

```html
<!-- WRONG: aria-hidden on a focusable element -->
<button aria-hidden="true">Submit</button>
<!-- The button is still focusable via Tab but invisible to screen readers.
     This creates an inaccessible ghost focus trap. -->

<!-- WRONG: aria-hidden on parent containing focusable children -->
<div aria-hidden="true">
  <p>Some text</p>
  <a href="/help">Help</a>  <!-- Still focusable! -->
</div>
<!-- The link receives focus but the screen reader cannot perceive it. -->
```

**Rule:** Never apply `aria-hidden="true"` to an element (or ancestor of an element) that is focusable, unless you also ensure it cannot receive focus (e.g., `tabindex="-1"` and no native focusability, or the element is also hidden with `display: none`).

### 3.4 CSS `display: none` and `visibility: hidden`

Both CSS properties remove content from the accessibility tree **and** hide it visually.

> Text that is explicitly hidden, e.g., styled with `display: none` or has `aria-hidden="true"`, is not visible to assistive technologies.

| Property              | Visually Hidden? | Removed from Accessibility Tree? | Occupies Layout Space? | Focusable? |
|-----------------------|------------------|----------------------------------|------------------------|------------|
| `display: none`       | Yes              | Yes                              | No                     | No         |
| `visibility: hidden`  | Yes              | Yes                              | Yes (space reserved)   | No         |
| `aria-hidden="true"`  | **No** (still visible) | Yes                         | Yes                    | **Yes** (danger!) |
| `role="presentation"` | **No** (still visible) | Role removed, content remains | Yes                   | Ignored on focusable |

### 3.5 Comparison Summary

| Mechanism             | Hides Role? | Hides Text Content? | Hides Descendants? | Visually Hidden? | Safe on Focusable? |
|-----------------------|-------------|----------------------|--------------------|------------------|---------------------|
| `role="presentation"` / `role="none"` | Yes | No | Only required owned children roles | No | Ignored (no effect) |
| `aria-hidden="true"`  | Yes         | Yes                  | Yes (all)          | No               | **No** -- dangerous  |
| `display: none`       | Yes         | Yes                  | Yes (all)          | Yes              | Yes (not focusable)  |
| `visibility: hidden`  | Yes         | Yes                  | Yes (all)          | Yes              | Yes (not focusable)  |

### 3.6 Common Use Cases

| Technique             | Use When...                                                            |
|-----------------------|------------------------------------------------------------------------|
| `role="presentation"` | Suppressing semantics of layout tables, list scaffolding in widgets, decorative images |
| `aria-hidden="true"`  | Decorative icons alongside visible text labels, duplicated content for visual effect, off-screen cloned elements |
| `display: none`       | Content that should be completely hidden from all users (collapsed sections, inactive tabs) |
| `visibility: hidden`  | Content that should be hidden but still occupy space (animation staging, placeholder sizing) |

---

## 4. Quick-Reference Checklist

- [ ] Every page has exactly one `banner`, one `main`, and one `contentinfo` landmark.
- [ ] All perceivable content lives inside a landmark region.
- [ ] `banner`, `main`, `complementary`, `contentinfo` are top-level (not nested in other landmarks).
- [ ] `<form>` elements that should be landmarks have an accessible name.
- [ ] `<section>` elements that should be landmarks have an accessible name.
- [ ] Multiple landmarks of the same role each have a unique label.
- [ ] Labels do not redundantly include the role name.
- [ ] Native HTML elements are used instead of ARIA structural roles wherever possible.
- [ ] `role="presentation"` is not applied to focusable elements.
- [ ] `aria-hidden="true"` is never applied to focusable elements or ancestors of focusable elements.
- [ ] Layout tables use `role="presentation"` to suppress table semantics.
- [ ] Decorative images use either `alt=""` or `role="presentation"`.

---

## Cross-References

- See also: [Names & Descriptions](names-and-descriptions.md)
- See also: [Dialogs, Alerts & Disclosure](dialogs-alerts-disclosure.md)
