# binary-skills

Claude Code skills marketplace by [Binary-Ly](https://binary.ly).

## Install the marketplace

```bash
claude plugin marketplace add Binary-ly/claude-skills
```

## Available plugins

| Plugin | Description |
| --- | --- |
| [`vps-hardening`](./plugins/vps-hardening) | Expert Ubuntu 24.04 LTS VPS hardening assistant (CIS / NIST aligned) |

## Install a plugin

```bash
claude plugin install vps-hardening@binary-skills
```

## Update

```bash
claude plugin update --all
```

## Repo layout

```
.claude-plugin/
  marketplace.json              # lists all plugins, one entry per subfolder
plugins/
  vps-hardening/
    .claude-plugin/plugin.json  # plugin metadata + version
    skills/
      vps-hardening/
        SKILL.md
        references/
```

## Adding a new skill

1. Create `plugins/<name>/.claude-plugin/plugin.json` with `name`, `version`, `description`.
2. Add the skill under `plugins/<name>/skills/<name>/SKILL.md`.
3. Append an entry to `.claude-plugin/marketplace.json` with `"source": "./plugins/<name>"`.
4. Commit and push.

## Releasing an update

Bump `version` in the plugin's `plugin.json`, commit, push. Clients see the new version on `claude plugin update`.
