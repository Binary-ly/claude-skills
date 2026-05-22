# 12 — Penalty Recovery & Algorithm-Update Playbook

Covers: diagnosing manual actions vs algorithmic suppression vs HCU classifier, reconsideration request structure, recovery timelines from documented cases.

---

## 12.1 Diagnosing the Cause

| Symptom | Likely cause | Evidence |
|---|---|---|
| GSC Manual Actions panel shows an entry | **Manual action** | Read the panel; the cause is named |
| Site-wide traffic drop on a documented core update date | **Algorithmic (core update)** | Search Engine Land update tracker, Semrush Sensor |
| Site-wide drop with no update date; disproportionately affects info content | **HCU classifier** | Pattern matches HCU-hit profiles (info/affiliate) |
| Section-specific drop affecting third-party content (coupons, reviews on a news domain) | **Site reputation abuse** | Check if subfolder/subdomain has third-party content |
| Drop on a specific keyword cluster, not site-wide | **Query-level relevance shift** | SERP feature analysis; check for AIO trigger |

### Site Reputation Abuse context

- Google's spam policy **launched March 2024**.
- **Manual enforcement began May 2024.**
- The **policy was updated in November 2024** to include first-party involvement/oversight.
- **November 2024 enforcement waves** hit CNN Underscored, Forbes Health/Advisor, USA Today, and LA Times sub-sections.

Per Google: **"Site reputation abuse is the practice of publishing third-party pages on a site in an attempt to abuse search rankings by taking advantage of the host site's ranking signals."**

---

## 12.2 Manual Action Recovery — Reconsideration Request

Per Google's documentation and Marie Haynes / Kristine Schachinger documented patterns:

### Structure

1. **Acknowledge** the specific manual action by name. Don't deflect.
2. **Document the cause** — be specific. *"We identified 347 unnatural backlinks from 89 referring domains acquired during a 2023–2024 PBN campaign."*
3. **Describe remediation step by step** — link to a Google Sheet showing every link contacted, every disavow entry, every page removed.
4. **State what changed structurally** — *"We ended our affiliate program. We removed our SEO vendor. The approval process for new links now requires…"*
5. **Apologize.** Reviewers respond to ownership.

### Timeline

Reviews take **days to weeks**; complex link cases can take **months**. Each rejected resubmission slows the next review.

---

## 12.3 Recovery Timelines (Documented Cases)

- **Manual action — unnatural links**: 2–8 weeks after a successful reconsideration.
- **Core-update demotion**: next core update cycle (90–180 days typical).
- **HCU classifier demotion**: per multiple practitioner cases, **6+ months minimum**; many sites have **not recovered since September 2023** even after substantial overhauls.
- **Site reputation abuse manual action**: section is removed from index immediately; recovery requires removing the third-party content and a reconsideration request. Some publishers (CNN, Forbes Health, LA Times) saw rapid demotion in November 2024 enforcement waves.

---

## Common mistakes (recovery)

- **Submitting reconsideration before the issue is actually fixed** (slows the next review).
- **Disavowing legitimate links in panic.**
- **Deleting "low-quality" content wholesale instead of improving or consolidating.** Per Mueller, mass-deletion is rarely the right HCU recovery move; mass-improvement is.
