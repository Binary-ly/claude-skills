# 08 — International SEO

Covers: hreflang in HTML, HTTP header, and sitemap form with bidirectional validation logic; common hreflang failure modes; ccTLD vs subdomain vs subfolder decision matrix with hosting/CDN implications.

---

## 8.1 hreflang — Three Implementation Methods

### Method 1: HTML `<link>` tags (page-level)

```html
<link rel="alternate" hreflang="en-us" href="https://example.com/us/page">
<link rel="alternate" hreflang="en-gb" href="https://example.com/uk/page">
<link rel="alternate" hreflang="es-mx" href="https://example.com/mx/page">
<link rel="alternate" hreflang="x-default" href="https://example.com/us/page">
```

### Method 2: HTTP headers (for non-HTML files like PDFs)

```
Link: <https://example.com/us/file.pdf>; rel="alternate"; hreflang="en-us",
      <https://example.com/uk/file.pdf>; rel="alternate"; hreflang="en-gb"
```

### Method 3: Sitemap (best for large sites)

```xml
<url>
  <loc>https://example.com/us/page</loc>
  <xhtml:link rel="alternate" hreflang="en-us" href="https://example.com/us/page"/>
  <xhtml:link rel="alternate" hreflang="en-gb" href="https://example.com/uk/page"/>
  <xhtml:link rel="alternate" hreflang="x-default" href="https://example.com/us/page"/>
</url>
```

### Language and region codes

- **ISO 639-1** for language (`en`, `es`)
- **ISO 3166-1 alpha-2** for region (`US`, `GB`, `MX`)

**Common mistake**: `en-uk` is invalid — use `en-gb`.

---

## 8.2 Bidirectional Validation Logic

**Every hreflang declaration must be reciprocated.** If `/us/page` references `/uk/page` as `en-gb`, `/uk/page` MUST reference `/us/page` as `en-us`.

```python
# Validate hreflang reciprocity across a crawled site
from collections import defaultdict
links = defaultdict(dict)  # url -> {lang: target_url}

# Populate from your crawler...
errors = []
for url, alternates in links.items():
    for lang, target in alternates.items():
        if target not in links:
            errors.append(f"NO-RETURN: {url} → {target} (target not crawled)")
            continue
        target_alts = links[target]
        if url not in target_alts.values():
            errors.append(f"NO-RETURN: {url} ↔ {target}")
    if 'x-default' not in alternates:
        errors.append(f"MISSING-XDEFAULT: {url}")
```

---

## 8.3 Common hreflang Failure Modes

Per Aleyda Solís's documented hreflang guide and the Take It Offline analysis:

| Mistake | Effect | Fix |
|---|---|---|
| **Missing `x-default`** | No default for unmatched locales | Add `x-default` (usually points to English/global page) |
| **Non-reciprocal tags** | Google ignores the hreflang entirely | Bi-directional generation in code, not by hand |
| **Wrong region codes** (`en-uk`, `en-eu`) | Invalid; ignored | Use `en-gb`; "EU" is not a country code, and `eu` as a language = Basque! |
| **hreflang on noindexed/canonicalized-away URLs** | Ignored | Only declare hreflang on indexable canonical URLs |
| **Mixed `_` and `-` separators** | Google accepts both; other engines may not | Stick with `-` (the spec) |
| **HTML `lang` attr disagrees with hreflang** | Conflicting signals | Align them |

---

## 8.4 ccTLD vs Subdomain vs Subfolder

| Structure | SEO equity | Geo signal | Hosting/CDN cost | Best for |
|---|---|---|---|---|
| **ccTLD** (`example.de`) | Each domain builds equity separately | Strongest | Highest (separate certs, separate WAF, separate analytics) | Brands with country teams + local payments |
| **Subdomain** (`de.example.com`) | Often treated as a separate site by Google (Mueller has wavered on this) | Medium | Medium | Localization with shared backend |
| **Subfolder** (`example.com/de/`) | Inherits root-domain authority | Weakest (compensate with hreflang + GSC international targeting) | Lowest | Most sites — recommended default |

**Recommendation: default to subfolders** unless you have a specific reason (acquired local brand, separate legal entity, payment compliance) to fragment authority.
