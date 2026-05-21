# repo-standards

Label standard, alias map, and reusable workflows for the
[convergent-systems-co](https://github.com/convergent-systems-co) GitHub org.

## What's here

| File | Purpose |
|---|---|
| `labels.yml` | The 28-label org standard. Source of truth. |
| `label-aliases.yml` | Legacy / non-standard label → canonical name mapping. |
| `docs/label-guide.md` | When to apply each label. |
| `docs/triage-rubric.md` | The rubric the triage agent embeds. |
| `.github/workflows/label-install.yml` | Reusable: install labels into your repo. |
| `.github/workflows/triage.yml` | Reusable: agentic issue triage. _(Plan 2)_ |
| `.github/workflows/label-cleanup.yml` | Reusable: cleanup non-standard labels. _(Plan 3)_ |
| `.github/workflows/label-sync.yml` | Reusable: keep your labels in sync. _(Plan 5)_ |

## Consume from your repo

Add this to your repo's `.github/workflows/bootstrap.yml`:

```yaml
name: Bootstrap

on:
  push:
    branches: [main]

jobs:
  install-labels:
    uses: convergent-systems-co/repo-standards/.github/workflows/label-install.yml@v1
```

That's it. The first push to main installs all 28 labels.

For triage and cleanup, see Plan 2 and Plan 3 docs once landed.

## Versioning

- The floating tag `v1` always points at the latest non-breaking change.
- Immutable tags `v1.0.0`, `v1.0.1`, … exist for audit. Pin to those if you
  need bit-for-bit stability.
- Adding or renaming a label = minor bump. Removing or repurposing a label =
  major bump + announcement issue.

## Contributing

Changes to `labels.yml` or `label-aliases.yml` require CODEOWNERS approval.
CI (`validate.yml`) runs schema tests on every PR.

## License

AGPL-3.0. See `LICENSE` and `COPYRIGHT`.
