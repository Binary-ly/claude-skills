# Long Tasks & Main Thread Optimization

Sources:
- https://web.dev/articles/optimize-long-tasks
- https://web.dev/articles/optimize-input-delay
- https://web.dev/articles/script-evaluation-and-long-tasks

---

## Definitions

- **Task:** Any discrete piece of work the browser does — rendering, parsing, JavaScript execution
- **Main thread:** Where most browser tasks execute. Can only process one task at a time.
- **Long task:** Any task exceeding **50 milliseconds**
- **Blocking period:** The portion of a long task beyond the 50ms threshold (e.g., a 130ms task blocks for 80ms)

A long task blocks the main thread, preventing the browser from responding to user input, updating animations, or rendering the next frame — directly degrading INP.

---

## Breaking Up Long Tasks

### Method 1 — `scheduler.yield()` (recommended, Chrome 129+)

```javascript
async function saveSettings() {
  // User-facing work first — run synchronously
  validateForm();
  showSpinner();
  updateUI();

  await scheduler.yield(); // yield to browser — lets input/rendering proceed

  // Non-critical work after yield
  saveToDatabase();
  sendAnalytics();
}
```

`scheduler.yield()` yields to the main thread and returns control to higher-priority tasks (user input, rendering) before continuing. Unlike `setTimeout(fn, 0)`, it maintains task priority.

### Method 2 — `setTimeout` fallback (all browsers)

```javascript
function saveSettings() {
  validateForm();
  showSpinner();
  updateUI();

  setTimeout(() => {
    saveToDatabase();
    sendAnalytics();
  }, 0);
}
```

### Method 3 — Universal polyfill

```javascript
function yieldToMain() {
  if (globalThis.scheduler?.yield) {
    return scheduler.yield();
  }
  return new Promise(resolve => setTimeout(resolve, 0));
}
```

### Method 4 — Batched job processing with deadline

```javascript
async function runJobs(jobQueue, deadline = 50) {
  let lastYield = performance.now();

  for (const job of jobQueue) {
    job();
    // Yield every 50ms to keep tasks within the long-task threshold
    if (performance.now() - lastYield > deadline) {
      await yieldToMain();
      lastYield = performance.now();
    }
  }
}
```

**50ms batches:** Short enough to prevent long tasks, long enough to minimize yield overhead.

---

## Script Evaluation

Every `<script>` tag creates a task for evaluation. Large bundles = one large blocking task.

### Script Loading Strategies

```html
<!-- WRONG — synchronous script blocks HTML parsing and rendering -->
<head>
  <script src="large-bundle.js"></script>
</head>

<!-- BETTER — async: doesn't block HTML, evaluates when ready -->
<script src="chunk-a.js" async></script>

<!-- BETTER — defer: evaluates after HTML parsed, in order -->
<script src="chunk-b.js" defer></script>
```

**Caution (Chromium):** Multiple `defer` scripts all execute in a single task at `DOMContentLoaded`. For better task splitting, use `async` or dynamic `import()`.

### Dynamic `import()` — best task separation

```javascript
// Each call produces a separate Compile + Evaluate task
const { featureA } = await import('./feature-a.js');
const { featureB } = await import('./feature-b.js');
```

### ES Modules

```html
<!-- type=module defers by default — no explicit defer needed -->
<script type="module" src="app.js"></script>
```

Chromium: produces separate **Compile module** and **Evaluate module** tasks.
Safari/Firefox: each module evaluated in its own task.

### Script size target

**≤ 100 KB per script file** — balances compression efficiency, download time, and evaluation time.

---

## Input Delay Optimization

Input delay = the gap between user interaction and when event handlers begin running. Caused by blocking tasks on the main thread.

### Timer Management

```javascript
// WRONG — setInterval runs perpetually, increasing collision probability with interactions
setInterval(heavyWork, 100);

// BETTER — setTimeout in loop: each iteration schedules the next only after completing
function scheduleWork() {
  doWork();
  setTimeout(scheduleWork, 100);
}
scheduleWork();
```

### Debouncing Autocomplete / Validation

```javascript
let debounceTimer;
input.addEventListener('input', (e) => {
  clearTimeout(debounceTimer);
  debounceTimer = setTimeout(() => {
    validateInput(e.target.value);
  }, 300);
});
```

### Cancelling Fetch on Fast Typing

```javascript
let controller;
input.addEventListener('input', async (e) => {
  controller?.abort(); // cancel previous request
  controller = new AbortController();
  try {
    const results = await fetch(`/api/search?q=${e.target.value}`, {
      signal: controller.signal
    });
  } catch (err) {
    if (err.name !== 'AbortError') throw err;
  }
});
```

### CSS Animations Over JS Animations

```css
/* CORRECT — compositor thread, doesn't block main thread */
.element {
  animation: pulse 1s ease-out infinite;
}

/* WRONG — JavaScript requestAnimationFrame runs on main thread */
/* avoid: requestAnimationFrame-based animations for simple CSS effects */
```

---

## Anti-Patterns Summary

| Anti-pattern | Problem | Fix |
|---|---|---|
| Single monolithic JS bundle | One giant blocking task | Split into ≤100KB chunks |
| `setInterval` with heavy work | Perpetual main thread occupation | Use `setTimeout` in loop |
| Synchronous `<script>` in `<head>` | Blocks HTML parsing | Use `async` or `defer` |
| `Array.forEach` with async callbacks | Callbacks don't await between iterations | Use `for...of` with `await` |
| `isInputPending()` API | web.dev recommends against using it — unreliable | Use `scheduler.yield()` |
| JS animations via `requestAnimationFrame` | Runs on main thread | Use CSS `transform`/`opacity` animations |
