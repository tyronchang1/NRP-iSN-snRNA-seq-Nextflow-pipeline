---
paths:
  - "/scratch/rmlab/rmlab_shared3/tyron/Rscriptv2/iSN/iSN_claude/**"
  - "scripts/01_SoupX/**/*.R"
  - "scripts/01.2_DecontX/**/*.R"
  - "scripts/02_scDblFinder_soupx/**/*.R"
  - "scripts/02.1_scDblFinder_decontX/**/*.R"
  - "scripts/03_Cell_filtering/**/*.R"
  - "scripts/04_Clustering/**/*.R"
  - "md_files/**"
  - "nextflow/**"
---

# Update REPORT.md After Every Change

This rule is autonomous — never wait for the user to ask.

## Triggers

**At the start of every conversation**, detect recently modified scripts and md files:

```bash
find /scratch/rmlab/rmlab_shared3/tyron/Rscriptv2/iSN/iSN_claude \
  \( -path '*/scripts/0*/*.R' -o -path '*/nextflow/*.nf' -o -name 'nextflow.config' -o \( -name '*.md' -not -name 'REPORT.md' \) \) \
  -newer /scratch/rmlab/rmlab_shared3/tyron/Rscriptv2/iSN/iSN_claude/.claude/rules/update-report-on-change.md
```

For each modified file found, read it and append an entry to the `REPORT.md` in the same directory.

**After any edit or write**, append an entry to the corresponding `REPORT.md`:

| Changed file path | Update this REPORT.md |
|---|---|
| `scripts/01_SoupX/**/*.R` | `scripts/01_SoupX/REPORT.md` |
| `scripts/01_SoupX/**/*.md` (not REPORT.md) | `scripts/01_SoupX/REPORT.md` |
| `scripts/01.2_DecontX/**/*.R` | `scripts/01.2_DecontX/REPORT.md` |
| `scripts/01.2_DecontX/**/*.md` (not REPORT.md) | `scripts/01.2_DecontX/REPORT.md` |
| `scripts/02_scDblFinder_soupx/**/*.R` | `scripts/02_scDblFinder_soupx/REPORT.md` |
| `scripts/02_scDblFinder_soupx/**/*.md` (not REPORT.md) | `scripts/02_scDblFinder_soupx/REPORT.md` |
| `scripts/02.1_scDblFinder_decontX/**/*.R` | `scripts/02.1_scDblFinder_decontX/REPORT.md` |
| `scripts/02.1_scDblFinder_decontX/**/*.md` (not REPORT.md) | `scripts/02.1_scDblFinder_decontX/REPORT.md` |
| `scripts/03_Cell_filtering/**/*.R` | `scripts/03_Cell_filtering/REPORT.md` |
| `scripts/03_Cell_filtering/**/*.md` (not REPORT.md) | `scripts/03_Cell_filtering/REPORT.md` |
| `scripts/04_Clustering/**/*.R` | `scripts/04_Clustering/REPORT.md` |
| `scripts/04_Clustering/**/*.md` (not REPORT.md) | `scripts/04_Clustering/REPORT.md` |
| `nextflow/**/*.nf` | `md_files/REPORT.md` |
| `nextflow/nextflow.config` | `md_files/REPORT.md` |
| `nextflow/REPORT.md` | — (this file is the log; do not log it again) |
| `md_files/**/*.md` (not REPORT.md) | `md_files/REPORT.md` |
| `.claude/rules/*.md` | `md_files/REPORT.md` |
| `.claude/skills/**/*.md` | `md_files/REPORT.md` |
| `.claude/agents/**/*.md` | `md_files/REPORT.md` |

## Each Entry Must Include
- Full path of the changed file
- What changed and why
- Date

## Constraints
- Only update `REPORT.md` — never modify scripts without explicit user permission
- The user should never need to ask
