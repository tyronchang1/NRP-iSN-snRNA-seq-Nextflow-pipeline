---
name: grill-with-docs
description: Grilling session that challenges your plan against the existing domain model, sharpens terminology, and updates documentation (CONTEXT.md, ADRs) inline as decisions crystallise. Use when user wants to stress-test a plan against their project's language and documented decisions.
---

<what-to-do>

Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.

Ask the questions one at a time, waiting for feedback on each question before continuing.

If a question can be answered by exploring the codebase, explore the codebase instead — start with `md_files/WORKFLOW.md` and `md_files/STATUS.md`.

</what-to-do>

<supporting-info>

## Domain context

This is a **single-nuclei RNA-seq (snRNA-seq) pipeline** for **human induced sensory neurons (iSNs)**. Eight samples from the NR00 experiment (Day13, Day7, iPSC timepoints) run through five sequential stages:

| Stage | Tool | Purpose |
|---|---|---|
| 01 | SoupX | Ambient RNA removal |
| 01.2 | DecontX | Alternative ambient RNA removal |
| 02 | scDblFinder (SoupX input) | Doublet removal |
| 02.1 | scDblFinder (DecontX input) | Doublet removal |
| 03 | Seurat | Cell QC filtering |
| 04 | Seurat + Harmony | Clustering |
| 05 | Seurat | Public DRG atlas integration + subtype annotation |

**Planned Nextflow migration:** This pipeline will eventually be rewritten as a Nextflow pipeline. Tool choices and parameter thresholds made now will become hardcoded Nextflow process inputs — they are hard to revisit after the pipeline is productionised. Flag these as ADR candidates.

## Documentation to read before starting

- `md_files/WORKFLOW.md` — stage goals, script locations, skill mappings
- `md_files/STATUS.md` — which stages are implemented vs planned. Gitignored; if missing, pipeline has not run yet

## File structure

CONTEXT.md and ADRs for this skill live inside the skill directory itself:

```
.claude/skills/grill-with-docs/
├── CONTEXT.md          ← domain glossary (pre-seeded with project terms)
├── adr/
│   ├── 0001-slug.md
│   └── 0002-slug.md
├── SKILL.md
├── ADR-FORMAT.md
└── CONTEXT-FORMAT.md
```

Create `adr/` lazily — only when the first ADR is needed.

## During the session

### Challenge against the glossary

When the user uses a term that conflicts with `CONTEXT.md`, call it out immediately. "Your glossary defines 'contamination fraction' as the SoupX rho estimate, but you're using it to mean the DecontX score — which is it?"

### Sharpen fuzzy language

When the user uses vague or overloaded terms, propose a precise canonical term. "You're saying 'sample' — do you mean the Cell Ranger output directory, the `sample_group` label in cell metadata, or the biological replicate?"

### Discuss concrete scenarios

Stress-test domain relationships with specific scenarios drawn from the actual data. "If `NR00_Day13_1` has a contamination fraction of 0.25, does that change how scDblFinder scores doublets in Stage 02?"

### Cross-reference with code

When the user states how something works, check whether the scripts agree. If you find a contradiction, surface it. "You said doublet removal runs on the merged object, but `02_scDblFinder.R` passes `samples = 'sample_group'` — that means per-sample scoring on a merged object. Is that what you intended?"

### Nextflow migration awareness

When a tool choice comes up, ask whether it will become a fixed Nextflow process parameter. If yes and it meets the ADR criteria below, offer an ADR.

**Parameter thresholds are different.** They are not predetermined — they are set empirically by running the R script, inspecting the resulting plot, and choosing a cutoff from the visual. Do not treat a threshold as an ADR candidate until the user has finalised it from a plot. Once finalised, it qualifies if it deviates from the conventional default in a non-obvious way.

### Update CONTEXT.md inline

When a term is resolved, update `.claude/skills/grill-with-docs/CONTEXT.md` right there. Don't batch — capture as they happen. Use the format in [CONTEXT-FORMAT.md](./CONTEXT-FORMAT.md).

`CONTEXT.md` is a glossary only — no implementation details, no specs, no parameter values.

### Offer ADRs sparingly

Only offer to create an ADR when all three are true:

1. **Hard to reverse** — the cost of changing your mind later is meaningful (especially true for Nextflow process parameters)
2. **Surprising without context** — a future reader will wonder "why did they do it this way?"
3. **The result of a real trade-off** — there were genuine alternatives and you picked one for specific reasons

If any of the three is missing, skip the ADR. Use the format in [ADR-FORMAT.md](./ADR-FORMAT.md).

</supporting-info>
