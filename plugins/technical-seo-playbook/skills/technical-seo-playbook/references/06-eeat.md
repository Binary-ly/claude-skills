# 06 — E-E-A-T at Engineering Level

Covers: author markup with author pages and sameAs patterns, first-hand experience signals (original images with EXIF, original data, embedded video), Helpful Content System audit (signals to remove vs add), YMYL content requirements.

---

## 6.1 Author Markup

**Article-level author + dedicated author page = the minimum viable E-E-A-T architecture.**

```html
<!-- /authors/jane-doe -->
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "ProfilePage",
  "mainEntity": {
    "@type": "Person",
    "name": "Jane Doe",
    "url": "https://example.com/authors/jane-doe",
    "image": "https://example.com/authors/jane-doe.jpg",
    "jobTitle": "Senior Technical SEO",
    "worksFor": { "@type": "Organization", "name": "Acme", "@id": "https://example.com/#org" },
    "alumniOf": { "@type": "CollegeOrUniversity", "name": "University of Example" },
    "sameAs": [
      "https://www.linkedin.com/in/janedoe",
      "https://x.com/janedoe",
      "https://www.wikidata.org/wiki/Q...",
      "https://orcid.org/0000-0000-0000-0000"
    ],
    "knowsAbout": ["Technical SEO", "JavaScript rendering", "Core Web Vitals"]
  }
}
</script>
```

**Link from every article byline to `/authors/{slug}`.**

Per practitioner analysis of the December 2025 HCU update (DEV Community write-up by Synergist Digital Media, n≈200 sites):

> "Having an author bio isn't enough anymore. Google's looking at citation patterns, whether other authoritative sites reference your content, and how often your authors appear in industry contexts."

*Note: this is third-party analysis, not an official Google statement.*

---

## 6.2 First-Hand Experience Signals (the "E" in E-E-A-T)

- **Original images** with preserved EXIF (camera model, GPS where appropriate). **Do NOT strip EXIF on upload.**
- **Original data**: charts/tables with your own measurements, not embeds of others'.
- **Embedded video** of the actual process/product (VideoObject markup; see § 5.5).
- **First-person language** in copy: "I tested," "we measured," "our 2026 dataset."

---

## 6.3 Helpful Content Audit

Per Google's documented HCU guidance and Danny Sullivan's clarifications (2023–2024, restated December 2025):

### Signals to remove

- Pages that exist only to rank (low- or zero-traffic affiliate posts, doorway pages).
- AI-generated content with no human review or unique value-add.
- "How tall is X celebrity"-style filler if you're not a celebrity site.
- Multi-niche scope creep (a coding blog suddenly publishing health content).
- Outdated content that hasn't been touched in 3+ years.

### Signals to add

- Author bios with verifiable credentials.
- "Last reviewed by [expert] on [date]" timestamps on YMYL content.
- Methodology pages explaining how you produce content.
- Internal expert review process documented publicly.

### Documented HCU impact data

- Per **James Brockbank's Digitaloft analysis of 671 travel publishers** (published 2024): **32% (213 sites) lost more than 90% of their organic traffic after HCU** — "Sites that used to enjoy millions of sessions every month being reduced to pretty much nothing."
- Per **Mediavine's analysis of 10,302 sites**: only **11.4% (1,170 sites)** saw positive increases in Google referral traffic after HCU.

---

## 6.4 YMYL Requirements

For Your Money or Your Life topics (health, finance, legal, safety):

- Author credentials displayed inline AND linked.
- **"Medically reviewed by Dr. X" / "Financially reviewed by CPA Y"** labels.
- Cited primary sources (PubMed, SEC filings, official statistics) — not aggregator sites.
- **Review/update cycle ≤ 12 months**, documented.
