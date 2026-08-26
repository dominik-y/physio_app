# Physio App — agent instructions

Flutter showcase app for Poliklinika Tendo. Code lives in `app/`, spec and plans in `docs/superpowers/`, working knowledge in `vault/`.

## Agent skills

### Issue tracker

Issues live as local markdown files under `.scratch/<feature-slug>/` in this repo. See `docs/agents/issue-tracker.md`.

### Triage labels

Default vocabulary — the five canonical roles used verbatim (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `CONTEXT.md` at the repo root plus `docs/adr/` for decisions (created lazily by `/domain-modeling` — absence is fine). See `docs/agents/domain.md`.
