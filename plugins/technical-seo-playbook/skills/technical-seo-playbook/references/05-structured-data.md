# 05 — Structured Data

Covers: JSON-LD examples for Article, Product, Recipe, Event, VideoObject, LocalBusiness, BreadcrumbList, Organization, Review/AggregateRating. SameAs entity disambiguation via Wikidata. CI validation. 2026 deprecations (FAQ, HowTo) and review-snippet restrictions.

All examples are **JSON-LD (Google's recommended format)**. Place in `<head>` or end of `<body>`. Validate with the **Rich Results Test** (`search.google.com/test/rich-results`) for Google rich-result eligibility, and the **Schema Markup Validator** (`validator.schema.org`) for generic schema.org validity.

Per Google's docs: "Google recommends that you start with the Rich Results Test to see what Google rich results can be generated for your page."

---

## 5.1 Article / NewsArticle / BlogPosting

Per Google's docs (Article structured data, last updated 2025): **"There are no required properties; instead, add the properties that apply to your content."**

Google-recognized **recommended** properties: `author`, `dateModified`, `datePublished`, `headline`, `image`, `publisher`, `thumbnailUrl`.

```json
{
  "@context": "https://schema.org",
  "@type": "Article",
  "headline": "Technical SEO Playbook 2026",
  "image": ["https://example.com/img-16x9.jpg", "https://example.com/img-4x3.jpg", "https://example.com/img-1x1.jpg"],
  "datePublished": "2026-05-18T08:00:00+00:00",
  "dateModified": "2026-05-18T08:00:00+00:00",
  "author": [{
    "@type": "Person",
    "name": "Jane Doe",
    "jobTitle": "Technical SEO Lead",
    "url": "https://example.com/authors/jane-doe",
    "sameAs": ["https://www.linkedin.com/in/janedoe", "https://www.wikidata.org/wiki/Q123456"]
  }],
  "publisher": {
    "@type": "Organization",
    "name": "Example",
    "logo": { "@type": "ImageObject", "url": "https://example.com/logo.png" }
  }
}
```

---

## 5.2 Product (Merchant Listing)

Per Google's Product Snippet and Merchant Listing docs there are two classes:

- **Merchant Listing** is for pages where customers can purchase.
- **Product Snippet** is for pages that review or aggregate products.

**Required for Merchant Listing**: `name`, `image`, and an `offers` block containing `price` + `priceCurrency` (or `priceSpecification`). **`Offer.availability` must use the schema.org URL value** (e.g. `https://schema.org/InStock`), **not the bare string**.

```json
{
  "@context": "https://schema.org",
  "@type": "Product",
  "name": "Trail Runner GTX",
  "image": ["https://example.com/shoe-1x1.jpg"],
  "description": "Waterproof trail running shoe.",
  "sku": "TRG-2026-01",
  "gtin13": "0123456789012",
  "brand": { "@type": "Brand", "name": "Acme" },
  "aggregateRating": { "@type": "AggregateRating", "ratingValue": "4.6", "reviewCount": "287" },
  "offers": {
    "@type": "Offer",
    "url": "https://example.com/p/trail-runner-gtx",
    "priceCurrency": "USD",
    "price": "149.00",
    "priceValidUntil": "2026-12-31",
    "availability": "https://schema.org/InStock",
    "itemCondition": "https://schema.org/NewCondition",
    "shippingDetails": {
      "@type": "OfferShippingDetails",
      "shippingRate": { "@type": "MonetaryAmount", "value": "0", "currency": "USD" },
      "shippingDestination": { "@type": "DefinedRegion", "addressCountry": "US" },
      "deliveryTime": {
        "@type": "ShippingDeliveryTime",
        "handlingTime": { "@type": "QuantitativeValue", "minValue": 0, "maxValue": 1, "unitCode": "DAY" },
        "transitTime":  { "@type": "QuantitativeValue", "minValue": 2, "maxValue": 5, "unitCode": "DAY" }
      }
    },
    "hasMerchantReturnPolicy": {
      "@type": "MerchantReturnPolicy",
      "applicableCountry": "US",
      "returnPolicyCategory": "https://schema.org/MerchantReturnFiniteReturnWindow",
      "merchantReturnDays": 60,
      "returnMethod": "https://schema.org/ReturnByMail",
      "returnFees": "https://schema.org/FreeReturn"
    }
  }
}
```

### Variants

For variants, use **`ProductGroup` with `productGroupID`, `variesBy`, and `hasVariant`**. Google's docs explicitly say: **"Don't use AggregateOffer to describe a set of product variants."**

---

## 5.3 Recipe

**Required**: `name`, `image`.

**Strongly recommended for the full rich result**: `author`, `datePublished`, `description`, `prepTime`, `cookTime`, `totalTime`, `recipeYield`, `recipeIngredient`, `recipeInstructions`, `nutrition`, `aggregateRating`.

**Time properties must be single ISO-8601 durations — ranges are no longer supported.**

```json
{
  "@context": "https://schema.org",
  "@type": "Recipe",
  "name": "Sourdough Boule",
  "image": ["https://example.com/boule.jpg"],
  "author": { "@type": "Person", "name": "Jane Doe" },
  "datePublished": "2026-05-01",
  "prepTime": "PT30M",
  "cookTime": "PT45M",
  "totalTime": "PT24H",
  "recipeYield": "1 loaf",
  "recipeIngredient": ["500g bread flour", "10g salt", "350g water", "100g active starter"],
  "recipeInstructions": [
    { "@type": "HowToStep", "text": "Mix flour and water; autolyse 1 hour." },
    { "@type": "HowToStep", "text": "Add starter and salt; bulk ferment 4 hours." }
  ],
  "nutrition": { "@type": "NutritionInformation", "calories": "1800 cal" },
  "aggregateRating": { "@type": "AggregateRating", "ratingValue": "4.8", "ratingCount": "42" }
}
```

---

## 5.4 Event

Per Google's docs change log: **"removed the online event properties."** Events now must be **bookable by the general public and held at a physical location** — pure virtual events are no longer eligible for the event experience.

**Required**: `name`, `startDate`, `location` (`Place` with `name` + `address`).

```json
{
  "@context": "https://schema.org",
  "@type": "Event",
  "name": "BrightonSEO Spring 2026",
  "startDate": "2026-04-25T09:00:00+01:00",
  "endDate": "2026-04-25T17:00:00+01:00",
  "eventAttendanceMode": "https://schema.org/OfflineEventAttendanceMode",
  "eventStatus": "https://schema.org/EventScheduled",
  "location": {
    "@type": "Place",
    "name": "Brighton Centre",
    "address": {
      "@type": "PostalAddress",
      "streetAddress": "Kings Road",
      "addressLocality": "Brighton",
      "postalCode": "BN1 2GR",
      "addressCountry": "GB"
    }
  },
  "image": "https://example.com/event.jpg",
  "offers": {
    "@type": "Offer", "url": "https://example.com/tickets",
    "price": "199", "priceCurrency": "GBP",
    "availability": "https://schema.org/InStock",
    "validFrom": "2026-01-01T00:00:00+00:00"
  },
  "organizer": { "@type": "Organization", "name": "BrightonSEO", "url": "https://brightonseo.com" }
}
```

---

## 5.5 VideoObject

**Required**: `name`, `description`, `thumbnailUrl`, `uploadDate`. **Effectively required for most features**: `contentUrl` OR `embedUrl`, `duration`. **Minimum video duration for eligibility: 30 seconds.**

```json
{
  "@context": "https://schema.org",
  "@type": "VideoObject",
  "name": "How to Fix INP",
  "description": "10-minute tutorial on Interaction to Next Paint optimization.",
  "thumbnailUrl": ["https://example.com/thumb.jpg"],
  "uploadDate": "2026-05-10T08:00:00+00:00",
  "duration": "PT10M",
  "contentUrl": "https://example.com/inp.mp4",
  "embedUrl": "https://example.com/embed/inp",
  "hasPart": [
    { "@type": "Clip", "name": "Intro", "startOffset": 0, "endOffset": 30, "url": "https://example.com/inp#t=0" },
    { "@type": "Clip", "name": "Profiling", "startOffset": 30, "endOffset": 180, "url": "https://example.com/inp#t=30" }
  ]
}
```

---

## 5.6 LocalBusiness

**Required**: `@type` (**use the most specific subtype**, e.g. `Restaurant`, not generic `LocalBusiness`), `name`, `address`.

```json
{
  "@context": "https://schema.org",
  "@type": "Restaurant",
  "name": "Acme Pizza",
  "image": "https://example.com/storefront.jpg",
  "@id": "https://example.com/#restaurant",
  "url": "https://example.com",
  "telephone": "+1-555-123-4567",
  "priceRange": "$$",
  "servesCuisine": "Italian",
  "address": {
    "@type": "PostalAddress",
    "streetAddress": "123 Main St",
    "addressLocality": "Brooklyn",
    "addressRegion": "NY",
    "postalCode": "11201",
    "addressCountry": "US"
  },
  "geo": { "@type": "GeoCoordinates", "latitude": 40.6951, "longitude": -73.9909 },
  "openingHoursSpecification": [
    { "@type": "OpeningHoursSpecification",
      "dayOfWeek": ["Monday","Tuesday","Wednesday","Thursday","Friday"],
      "opens": "11:00", "closes": "22:00" }
  ]
}
```

---

## 5.7 BreadcrumbList

Per Google's docs: **"Define a BreadcrumbList that contains at least two ListItems."** Position is 1-based and sequential.

```json
{
  "@context": "https://schema.org",
  "@type": "BreadcrumbList",
  "itemListElement": [
    { "@type": "ListItem", "position": 1, "name": "Home", "item": "https://example.com/" },
    { "@type": "ListItem", "position": 2, "name": "Shoes", "item": "https://example.com/shoes/" },
    { "@type": "ListItem", "position": 3, "name": "Running", "item": "https://example.com/shoes/running/" }
  ]
}
```

---

## 5.8 Organization (Entity Disambiguation)

Per Google's Organization docs (last updated 2026-04-15): **"There are no required properties."**

Use `sameAs` to point at Wikidata, Wikipedia, LinkedIn, X — this is how the Knowledge Graph disambiguates your entity.

```json
{
  "@context": "https://schema.org",
  "@type": "Organization",
  "name": "Acme",
  "url": "https://example.com",
  "logo": "https://example.com/logo.png",
  "sameAs": [
    "https://www.wikidata.org/wiki/Q12345678",
    "https://en.wikipedia.org/wiki/Acme",
    "https://www.linkedin.com/company/acme",
    "https://x.com/acme"
  ],
  "contactPoint": [{
    "@type": "ContactPoint",
    "contactType": "Customer Service",
    "telephone": "+1-555-123-4567",
    "email": "help@example.com",
    "areaServed": "US",
    "availableLanguage": ["English", "Spanish"]
  }]
}
```

**The single highest-leverage signal**: a **Wikidata Q-number** in `sameAs`. Create one at `wikidata.org` if your brand qualifies.

---

## 5.9 Review / AggregateRating

Per Google's review-snippet docs, the schema types that still trigger review snippets in 2026 are:

**Book, Course, CreativeWorkSeason/Series, Episode, Event, Game, MediaObject, Movie, Music, Product, Recipe, SoftwareApplication, LocalBusiness** (only when reviewing other businesses), **Organization** (only when reviewing other orgs).

### Self-serving review restriction (still policy in 2026)

Per Google's September 2019 blog post:

> "We're not going to display review rich results anymore for the schema types LocalBusiness and Organization (and their subtypes) in cases when the entity being reviewed controls the reviews themselves."

### Author and decimal rules

- `author.name` must be **< 100 chars** (October 2021 doc update).
- Use **dot decimal separators** (Google recommendation, November 2022 update).

---

## 5.10 FAQ and HowTo — Deprecation Status (May 2026)

### HowTo: fully deprecated in September 2023

Per Google's docs:

> "Removed the How-to structured data documentation, as this rich result is no longer shown in search results."

Across desktop and mobile. **Markup is not penalized; it just produces no rich result.**

### FAQ: deprecation completes May–August 2026

Per the **May 7, 2026 deprecation banner** on Google's FAQ structured-data page:

> "Upcoming deprecation: As of May 7, 2026, FAQ rich results are no longer appearing in Google Search. We will be dropping the FAQ search appearance, rich result report, and support in the Rich results test in June 2026. To allow time for adjusting your API calls, support for the FAQ rich result in the Search Console API will be removed in August 2026."

This removes FAQ rich results for **all** sites, including the government/health verticals that retained them after the August 2023 restriction. **FAQPage as a schema.org type is not deprecated** — Google continues to use it for understanding pages, just not for rich-result display.

---

## 5.11 Validation Pipeline (CI)

```yaml
# .github/workflows/structured-data.yml
name: Structured Data Validation
on: [pull_request]
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20 }
      - run: npm i -g structured-data-testing-tool
      - name: Validate
        run: |
          for url in $(cat urls.txt); do
            sdtt --url "$url" --presets Google Schema || exit 1
          done
```

---

## Common mistakes (structured data)

- **Marking up content invisible to users** (Google policy violation).
- **Mixing JSON-LD `@type` with mismatched property names** (using `Product` properties on `Article`).
- **Forgetting that `availability` and `itemCondition` must be schema.org URLs**, not bare strings.
