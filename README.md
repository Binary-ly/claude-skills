# binary-skills

Claude Code skills marketplace by [Binary-Ly](https://binary.ly).

Browse the showcase at **[binary.ly/skills](https://binary.ly/skills)**.

## Install the marketplace

Add it once. Every plugin in this repo becomes installable.

```bash
claude plugin marketplace add Binary-ly/claude-skills
```

## Available plugins

| # | Plugin | Category | Description |
| --- | --- | --- | --- |
| 01 | [`vps-hardening`](./plugins/vps-hardening) | security | Expert Ubuntu 24.04 LTS hardening assistant — CIS / NIST aligned, 15 categories from SSH to kernel sysctls. |
| 02 | [`technical-seo-playbook`](./plugins/technical-seo-playbook) | seo | Implementation-ready technical SEO playbook with code, exact thresholds, and decision trees for crawl, Core Web Vitals, structured data, JS SEO, and AI Overviews. |
| 03 | [`ui-component-library`](./plugins/ui-component-library) | frontend | Best practices for world-class CSS UI component libraries — tokens, custom properties, ARIA patterns, focus management, WCAG compliance, and performance. |

## Install a plugin

```bash
claude plugin install vps-hardening@binary-skills
claude plugin install technical-seo-playbook@binary-skills
claude plugin install ui-component-library@binary-skills
```

## Update

```bash
claude plugin update --all
```

## Repo layout

```
.claude-plugin/
  marketplace.json                  # lists every plugin, one entry per subfolder
plugins/
  vps-hardening/
    .claude-plugin/plugin.json      # plugin metadata + version
    skills/
      vps-hardening/
        SKILL.md
        references/
  technical-seo-playbook/
    .claude-plugin/plugin.json
    skills/
      technical-seo-playbook/
        SKILL.md
        references/
        templates/
  ui-component-library/
    .claude-plugin/plugin.json
    skills/
      ui-component-library/
        SKILL.md
        rules/
```

## Adding a new skill

1. Create `plugins/<name>/.claude-plugin/plugin.json` with `name`, `version`, `description`, `author`.
2. Add the skill under `plugins/<name>/skills/<name>/SKILL.md` (plus optional `references/`, `scripts/`, `assets/`).
3. Append an entry to `.claude-plugin/marketplace.json` with `"source": "./plugins/<name>"` and a `category`.
4. Commit and push. The next `claude plugin marketplace update binary-skills` picks it up.

## Releasing an update

Bump `version` in the plugin's `plugin.json`, commit, push. Clients see the new version after `claude plugin update <name>` (or `--all`).

## Trademarks

Claude and Claude Code are trademarks of Anthropic, PBC. This repository is an
independent open-source project and is not affiliated with, endorsed by, or
sponsored by Anthropic.
