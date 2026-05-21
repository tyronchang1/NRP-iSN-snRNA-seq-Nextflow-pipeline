# CONTEXT.md Format

## Structure

Terms are grouped under three subheadings that mirror the project's domain:

```md
# {Context Name}

{One or two sentence description of what this context is and why it exists.}

## Language

### Biological units

**Sample**:
One 10x Genomics single-nuclei capture from a specific condition and replicate (e.g., `NR00_Day13_1`).
_Avoid_: dataset, library, experiment

**Doublet**:
A droplet containing two nuclei captured together, appearing as a single barcode with elevated counts.
_Avoid_: multiplet (unless referring to higher-order multiplets specifically)

### Data and QC

**Contamination fraction (rho)**:
SoupX's per-sample estimate of the proportion of UMI counts attributable to ambient RNA; ranges 0–1.
_Avoid_: rho alone in documentation; contamination rate

**nCount_RNA**:
Total UMI counts per barcode. Key QC metric. Threshold is set empirically by inspecting the density histogram produced by the Stage 03 script — not predetermined.

### Pipeline

**Stage**:
One numbered step in the pipeline (01–05), each with its own scripts directory and output.

## Relationships

- A **Sample** produces one **Cell Ranger output** (filtered + raw)
- **SoupX** uses the raw output to estimate the **Contamination fraction (rho)** per **Sample**
- **scDblFinder** scores each barcode per **Sample** as a **Singlet** or **Doublet**

## Example dialogue

> **Dev:** "After SoupX, do we merge all **Samples** before doublet removal?"
> **Domain expert:** "No — **scDblFinder** runs per **Sample** using the `sample_group` column. Merging first would confuse doublet scoring across batches."
>
> **Dev:** "So a **Doublet** from `NR00_Day13_1` and one from `NR00_iPSC_1` are scored independently?"
> **Domain expert:** "Exactly. Each **Sample**'s doublet rate is computed separately, then the flagged barcodes are removed before the combined object moves to Stage 03."

## Flagged ambiguities

- "cell" vs "nucleus" — this is a single-nuclei (snRNA-seq) protocol; "nucleus" is precise, "cell" is acceptable shorthand in code
- "cluster" vs "subtype" — resolved: a cluster is a computational grouping (Stage 04); a subtype is a biological identity inferred from marker gene expression within that cluster
```

## Rules

- **Be opinionated.** When multiple words exist for the same concept, pick the best one and list the others as aliases to avoid.
- **Flag conflicts explicitly.** If a term is used ambiguously, call it out in "Flagged ambiguities" with a clear resolution.
- **Keep definitions tight.** One sentence max. Define what it IS, not what it does.
- **Show relationships.** Use bold term names and express cardinality where obvious.
- **Use the three subheadings.** Group terms under `Biological units`, `Data and QC`, and `Pipeline`. Add a fourth only if a natural cluster falls outside all three.
- **For QC metric terms, name the plot.** If the term's threshold is set from a plot (e.g., nCount_RNA, percent.mt, rho), state which plot and which stage produces it — not the value itself.
- **Only include terms specific to this project.** General bioinformatics concepts (UMAP, PCA, batch correction) and R/Seurat internals (`FindNeighbors`, `ScaleData`) don't belong even if used extensively. Ask: is this a concept unique to this pipeline's design, or a standard method? Only the former belongs. `Doublet` belongs; `FindDoublets` does not.
- **Write an example dialogue.** A conversation between a dev and a domain expert that demonstrates how the terms interact naturally and clarifies boundaries between related concepts.

## Context file location

This project is single-context. `CONTEXT.md` lives in `.claude/skills/grill-with-docs/CONTEXT.md` — not at the repo root.
