# 04 — On-Page Architecture

Covers: title and meta description generation logic with character/pixel limits, heading hierarchy with ranking-correlation data, internal linking (PageRank flow, anchor distribution, hub-and-spoke), pagination patterns including infinite scroll.

---

## 4.1 Title and Meta-Description Generation

Per Google's *Influencing title links* documentation (`developers.google.com/search/docs/appearance/title-link`, last updated 2025), **Google rewrites titles roughly 61% of the time** (Cyrus Shepard / Zyppy 2022 study, cited in Search Engine Land's title-tag guide).

### Rewrites are most common when

- The title is **keyword-stuffed**
- The title is **too long** (truncated at ~600 px / ~60 chars desktop, ~50 chars mobile)
- The title is **boilerplate** ("Home" or "Untitled")
- The title **disagrees with the H1** — Google often pulls the H1 instead
- The title **front-loads brand** — **63% of Google's title trims remove the brand name** (Zyppy data)

### Title generation logic

```ts
function generateTitle({ pageTitle, brand, separator = ' | ' }: TitleArgs): string {
  const MAX = 60 // characters — pixel-based truncation at ~600px
  const brandSuffix = `${separator}${brand}`
  const available = MAX - brandSuffix.length
  if (pageTitle.length <= available) return `${pageTitle}${brandSuffix}`
  const truncated = pageTitle.slice(0, available).replace(/\s+\S*$/, '')
  return `${truncated}${brandSuffix}`
}
```

### Meta description

- **~155–160 chars desktop**, **~120 chars mobile**.
- Google rewrites descriptions more than **70%** of the time but uses the meta description as a starting hint.
- If your description **matches the query**, Google often keeps it.

```html
<title>Running Shoes for Wide Feet | Acme</title>
<meta name="description" content="Browse 47 running shoes in widths D, 2E, and 4E. Free returns within 60 days. Updated weekly with new arrivals.">
```

---

## 4.2 Heading Hierarchy

Per John Mueller (2020, restated 2024): **"Multiple H1s are fine, just use them for structure."** Ranking studies from Backlinko (Brian Dean, 2020 ranking-factors study, **n=11.8M results**) and Ahrefs nonetheless correlate a **single, keyword-aligned H1 with measurably better rankings**.

### Engineering rules

- **Exactly one `<h1>` per page**, semantically matching the title intent.
- **`<h2>` for major sections** — these are what AI Overviews and featured snippets extract.
- **`<h3>` for sub-sections** — heavily used by Google's passage indexing.
- **Do not skip levels** (no `<h1>` → `<h3>`).

---

## 4.3 Internal Linking

Numerical targets synthesized from Botify case data, Ahrefs analyses, and Search Engine Land coverage:

- Every indexable URL should be **≤ 3 clicks from the homepage**.
- Homepage outbound internal links: **100–200** (Google retired the old 100 limit but >200 dilutes equity).
- PDP/article pages: **3–10 contextual internal links** in body content.
- Category pages: link to the **top 20–40 child PDPs** above the fold.

### Hub-and-spoke (topic cluster) pattern

```
/seo/                              ← hub (pillar)
  /seo/technical/                  ← cluster page, links to /seo/ + siblings
  /seo/onpage/                     ← cluster page
  /seo/technical/crawl-budget/     ← leaf, links up to /seo/technical/
```

Each **leaf links up to its cluster page and up to the hub**; each **cluster page links to its leaves and to sibling clusters**. This produces the densely connected topic graph that correlates with topical authority in the HCU-era ranking environment.

---

## 4.4 Pagination

**`rel=next` / `rel=prev` was deprecated by Google in 2019** (Mueller confirmed Google had not used the markup for years). **It is still respected by Bing.**

### Modern pattern (paginated archive)

```html
<!-- /blog/page/2/ -->
<link rel="canonical" href="https://example.com/blog/page/2/">
<link rel="prev" href="https://example.com/blog/"><!-- Bing only -->
<link rel="next" href="https://example.com/blog/page/3/"><!-- Bing only -->
<meta name="robots" content="index, follow">
```

**Each paginated URL self-canonicalizes.** Do not canonical page 2 → page 1 — you lose the content on page 2.

### Infinite scroll done correctly — History API + paginated URLs underneath

```js
window.addEventListener('scroll', debounce(() => {
  if (nearBottom()) {
    const nextPage = currentPage + 1
    fetch(`/api/posts?page=${nextPage}`).then(r => r.json()).then(append)
    history.pushState({}, '', `/blog/page/${nextPage}/`)
  }
}, 200))
```

**Each "page" must be independently crawlable at its URL.** Test with curl — if `curl https://example.com/blog/page/5/` returns the items for page 5, you're correct.

---

### Common mistakes (on-page)

- **Canonicalizing paginated pages to page 1** — strips the content from the index.
- **Using JS-rendered pagination with no URL change** — Googlebot only sees page 1.
- **Stuffing titles with brand at the front.** As noted, 63% of Google's title trims remove the brand.
