# 10 — AI Overviews / Answer-Engine Optimization (AEO/GEO)

Covers: measured citation patterns for Google AI Overviews, Perplexity, ChatGPT Search, and Claude. Structured data and passage optimization for AI citation. llms.txt syntax, current adoption, and whether it matters yet. Trade-offs: zero-click traffic loss vs brand presence.

---

## 10.1 Measured Citation Patterns (May 2026)

Per **BrightEdge Generative Parser data** (February 2025 – February 2026):

- AI Overviews now trigger on **48% of tracked queries** (up from 31% in February 2025).
- Average AIO height: **>1,200 pixels** on desktop (pushes organic below the fold on 900-pixel viewports).
- Industry triggering rates:
  - **Healthcare 88%**
  - **Education 83%** (up from 18% in May 2025)
  - **B2B Tech 82%**
  - **Restaurants 78%**
- **Citation-to-organic-rank overlap dropped from ~76% in July 2025 to between 17% and 38% in February 2026** (BrightEdge ~17%, Ahrefs ~38%). Ranking #1 organically **no longer reliably earns AIO citation**.

### Per Profound's AI Platform Citation Patterns study

- **ChatGPT cites Wikipedia at 47.9% of top-10 citations** ("Wikipedia serves as ChatGPT's most cited source").
- **Perplexity favors Reddit at 46.7%** ("it really favors Reddit at 46.7%").

### Ads in AI Overviews

- **Ads now appear in 25.5% of AI Overview SERPs**, up from ~3% in January 2025.

### Google AI Mode scale

Per **Nick Fox (Google VP of Search)**, confirmed December 2025, reported by Search Engine Journal:

- **Google AI Mode reached 75 million daily active users worldwide.**
- **Alphabet's Q3 2025 earnings materials disclosed the 1 billion monthly queries figure.**

### The fan-out hypothesis (Ahrefs, December 2025)

Google issues **multiple sub-queries internally** when constructing an AIO; cited pages rank well across the **expanded** query set, not just the literal user query. This explains the drop in literal-query overlap.

---

## 10.2 Structured Data and Passage Optimization for AI Citation

- **Direct-answer paragraphs of 40–60 words right under H2s** — AIO extracts these.
- **Tables** for comparative data — easily lifted into AI answers.
- **Numeric specifics** (versions, dates, percentages) — increase citation odds because AI prefers verifiable facts.
- **Schema.org Organization with `sameAs` Wikidata** — establishes the entity in Google's Knowledge Graph, which AIO and Gemini both consult.
- **Author Person markup with `sameAs`** — credentials feed into citation selection for YMYL.

---

## 10.3 llms.txt — Spec and Adoption Status

### The spec

Proposed by **Jeremy Howard (Answer.AI) on September 3, 2024 at llmstxt.org**. Markdown file at `/llms.txt` (and optionally `/llms-full.txt`) listing high-value content for LLM consumption.

```markdown
# Acme Docs

> Acme is a developer platform for X.

## Core
- [Getting Started](https://example.com/docs/start.md): Install and configure.
- [API Reference](https://example.com/docs/api.md): Full endpoint list.

## Optional
- [Changelog](https://example.com/changelog.md)
```

### Adoption reality (May 2026)

- **BuiltWith reported over 844,000 websites** had implemented `llms.txt` as of October 25, 2025.
- **SERanking analysed 300,000 domains in November 2025**: ~10% had `/llms.txt`. An XGBoost model trained on AI-citation data **improved when llms.txt was removed as a feature** — the file did not predict citations.
- **OtterlyAI's 90-day measurement**: out of 62,100 AI-bot requests, **84 hit `/llms.txt`** (**0.1%**).
- **Google's John Mueller (December 2025, Bluesky)**: *"AFAIK, none of the AI services have said they're using LLMs.TXT (and you can tell when you look at your server logs that they don't even check for it)."*
- A `llms.txt` briefly appeared on Google Developer Docs on December 3, 2025 — **and was removed the same day**.

### Conclusion

As of May 2026, **`llms.txt` does not measurably improve AI citation in answer surfaces.**

It **does** help IDE agents (Cursor, Claude Code, Continue) that explicitly fetch documentation.

**If your audience includes developers using AI coding tools, ship one. Otherwise, skip it and invest the engineering time in structured data, original data assets, and entity disambiguation.**

---

## 10.4 Trade-Offs: Zero-Click Loss vs Brand Presence

### CTR impact data

Per **Seer Interactive's September 2025 study** (reported by Search Engine Land):

- Organic CTR for queries with AI Overviews dropped from **1.76% to 0.61% — a 65% decline**.
- Paid CTR for the same queries fell from **19.7% to 6.34%, a 68% drop**.

Per **Ahrefs (December 2025)**:

- AIOs reduce position-one CTR by **58%**.

### But: brands cited in AIOs see lift

Per Averi/BrightEdge synthesis: brands cited in AIOs see **35% more organic clicks and 91% more paid clicks** than uncited brands.

### Tactical conclusion

**Be cited or be invisible. There is no middle position.**
