# Layout Thrashing & Style Calculations

Sources:
- https://web.dev/articles/avoid-large-complex-layouts-and-layout-thrashing
- https://web.dev/articles/reduce-the-scope-and-complexity-of-style-calculations
- https://web.dev/articles/dom-size-and-interactivity

---

## Layout Thrashing — Definition

Layout thrashing occurs when JavaScript repeatedly **reads and then writes** style/geometry values in a loop. Each read after a write forces the browser to run layout synchronously ("forced synchronous layout") before continuing. This breaks the browser's ability to batch layout work.

---

## The Anti-Pattern

```javascript
// WRONG — thrashing: reads offsetWidth AFTER writing width each iteration
function resizeAllParagraphsToMatchBlockWidth() {
  for (let i = 0; i < paragraphs.length; i++) {
    paragraphs[i].style.width = `${box.offsetWidth}px`; // read triggers layout, then write
  }
}
```

Each `box.offsetWidth` read after a style write forces the browser to synchronously recalculate layout before moving to the next iteration.

## The Fix — Batch Reads First, Then Writes

```javascript
// CORRECT — read once outside the loop, then write in the loop
const width = box.offsetWidth; // single read

function resizeAllParagraphsToMatchBlockWidth() {
  for (let i = 0; i < paragraphs.length; i++) {
    paragraphs[i].style.width = `${width}px`; // write only
  }
}
```

**Rule:** Always batch all style reads first (browser uses previous frame's values), then batch all writes.

---

## Forced Synchronous Layout Example

```javascript
// Forced synchronous layout — reads layout value immediately after write
box.classList.add('super-big');
console.log(box.offsetHeight); // forces browser to calculate layout NOW before continuing
```

Reading any of these layout properties after a DOM write forces synchronous layout:
`offsetTop`, `offsetLeft`, `offsetWidth`, `offsetHeight`, `scrollTop`, `scrollLeft`, `scrollWidth`, `scrollHeight`, `clientTop`, `clientLeft`, `clientWidth`, `clientHeight`, `getComputedStyle()`, `getBoundingClientRect()`

Note: The full list of properties that trigger forced layout is maintained in a [community gist](https://gist.github.com/paulirish/5d52fb081b3570c81e3a) referenced from the web.dev article.

---

## Style Calculation Cost Model

**Selector matching: ~50%** of style calculation time
**Computed style construction: ~50%** of style calculation time

**Worst case cost:**
```
cost = number_of_elements × number_of_selectors
```

**Practical example:** A single CSS change affecting 900+ elements triggers 900 style recalculations. Keep style recalculation events as short as possible.

### Selector Optimization

```css
/* WRONG — compound selector: browser must traverse up 3 levels for every element */
.box:nth-last-child(-n+1) .title { color: red; }

/* CORRECT — single class match: O(1) lookup */
.box-title-highlighted { color: red; }
```

**Rule:** Prefer simple class-based selectors. Complex pseudo-class chains and sibling/parent traversal multiply style calculation cost.

---

## DOM Size Thresholds

| State | DOM Node Count | Impact |
|---|---|---|
| Warning | 800+ nodes | Lighthouse warning |
| Excessive | 1,400+ nodes | Lighthouse audit failure |

**Measure DOM size in console:**
```javascript
document.querySelectorAll('*').length;
```

### Strategies for Large DOMs

**1. Fragment wrappers (React, Vue, Svelte)**
```jsx
// WRONG — adds unnecessary wrapper div to DOM
function MyComponent() {
  return (
    <div>
      <Item />
      <Item />
    </div>
  );
}

// CORRECT — fragment adds no DOM node
function MyComponent() {
  return (
    <>
      <Item />
      <Item />
    </>
  );
}
```

**2. Lazy-load HTML sections**
Omit DOM sections on startup. Add them only when the user scrolls to or interacts with that area.

**3. `content-visibility: auto`**
```css
.card { content-visibility: auto; contain-intrinsic-size: auto 200px; }
```
Skips layout/paint for off-screen elements. Reduces effective DOM cost even if the nodes exist.

**4. CSS containment**
```css
.widget { contain: layout style; }
```
Isolates rendering work. Changes inside the widget do not force recalculation of the rest of the page.

---

## Detecting Layout Thrashing

**Chrome DevTools Timeline:**
- Purple events = Style/Layout recalculation
- "Forced reflow" annotations on task entries
- `forcedStyleAndLayoutDuration` property via Long Animation Frames API

**Field measurement:**
```javascript
// Long Animation Frames API
new PerformanceObserver((list) => {
  for (const entry of list.getEntries()) {
    console.log('Forced style/layout:', entry.forcedStyleAndLayoutDuration);
  }
}).observe({ type: 'long-animation-frame', buffered: true });
```
