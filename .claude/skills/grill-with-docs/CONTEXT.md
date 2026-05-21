# iSN snRNA-seq Pipeline

Single-nuclei RNA-seq pipeline for human induced sensory neurons (iSNs), spanning ambient RNA removal through clustering (Stages 01–04).

## Language

### Biological units

**iSN** (induced sensory neuron):
Human iPSC-derived sensory neuron; the primary cell type this pipeline is designed to characterize.
_Avoid_: iSNeuron, sensory neuron (too generic)

**iPSC** (induced pluripotent stem cell):
The precursor cell type from which iSNs are differentiated; present in culture and detectable as a contaminating population in marker gene plots.
_Avoid_: stem cell, progenitor

**DRG** (dorsal root ganglion):
The in vivo reference tissue for sensory neurons used as biological context for interpreting iSN cluster identities.
_Avoid_: ganglion, reference tissue

**Nucleus** / **Cell**:
A single barcode recovered from a 10x Genomics capture. This is a single-nuclei protocol (snRNA-seq), so each barcode represents a nucleus.
_Avoid_: cell (when precision matters — prefer "nucleus" or "barcode"; "cell" is acceptable shorthand in code)

**Doublet**:
A droplet containing two nuclei captured together, appearing as a single barcode with artificially elevated counts. Removed in Stage 02.
_Avoid_: multiplet (unless referring to higher-order multiplets specifically)

**Singlet**:
A barcode confirmed to contain a single nucleus. The surviving population after doublet removal.

**Subtype**:
A mature sensory neuron identity (e.g., peptidergic, non-peptidergic, TrkB/TrkC) inferred from marker gene expression in Stage 04 clusters.
_Avoid_: cluster (a cluster is a computational grouping; a subtype is a biological identity)

### Data and QC

**Sample**:
One 10x Genomics single-nuclei capture from a specific condition and replicate (e.g., `NR00_Day13_1`). Eight samples total across Day13, Day7, and iPSC timepoints.
_Avoid_: dataset, experiment, library

**sample_group**:
The human-readable sample identifier stored in cell metadata (e.g., `NR00_Day13_1`), as opposed to the numeric barcode suffix (1–8) assigned by Cell Ranger when samples are merged.
_Avoid_: sample name, orig.ident (that refers to the numeric suffix)

**Cell Ranger output**:
The raw 10x Genomics output for one sample: `filtered_feature_bc_matrix/` (called cells) and `raw_feature_bc_matrix/` (all barcodes including empty droplets). Both are required by Stage 01.
_Avoid_: count matrix (ambiguous — could mean raw or corrected)

**Ambient RNA**:
Free-floating RNA in the droplet suspension captured alongside — but not originating from — the nucleus. Inflates counts for highly expressed genes across the library.
_Avoid_: background RNA, contamination (use "contamination fraction" for the quantified amount)

**Contamination fraction (rho)**:
SoupX's per-sample estimate of the proportion of UMI counts attributable to ambient RNA; ranges 0–1. Higher = more contamination. Estimated automatically from the data; any manual override is chosen by inspecting the rho scatter plot produced by the Stage 01 script, not set in advance.
_Avoid_: rho alone in documentation; contamination rate

**Soup**:
SoupX's term for the ambient RNA expression profile, estimated from empty droplets in the raw Cell Ranger output.
_Avoid_: background, ambient profile

**nCount_RNA**:
Total UMI counts per barcode. Key QC metric. The filter threshold is chosen empirically by inspecting the nCount_RNA density histogram produced by the Stage 03 script — not set in advance.

**nFeature_RNA**:
Number of unique genes detected per barcode. Key QC metric. Filter threshold set empirically from the distribution plot, not predetermined.

**percent.mt**:
Percentage of UMI counts from mitochondrial genes (prefix `MT-`). Elevated values indicate nuclear membrane rupture (low-quality nuclei). Threshold set from the violin/scatter plot produced by the Stage 03 script.

### Pipeline

**Stage**:
One numbered step in the pipeline (01–04), each with its own scripts directory and output directory. Stages run sequentially; 01 and 01.2 are parallel alternative branches.

**Marker genes**:
Genes used to confirm cell type identity in visualization and QC plots:
- Pan-neuronal: `TUBB3`, `PRPH`, `SNAP25`
- Peptidergic: `CALCA`, `TRPV1`
- Non-peptidergic: `MRGPRD`
- TrkB/TrkC: `NTRK2`, `NTRK3`
- iPSC: `POU5F1`, `SOX2`, `NANOG`

**Cluster**:
A computational grouping of nuclei produced by Louvain/Leiden algorithm in Stage 04. Distinct from **Subtype** — a cluster is a computational grouping; a subtype is a biological identity inferred from marker genes.
_Avoid_: subtype (as a synonym for cluster)

## Relationships

- A **Sample** produces one **Cell Ranger output** (filtered + raw directories)
- **SoupX** uses the raw Cell Ranger output to estimate the **Soup** and compute the **Contamination fraction (rho)** per **Sample**
- After Stage 01, each **Nucleus** has ambient-RNA-corrected counts stored as a corrected count matrix
- **scDblFinder** scores each **Nucleus** per **Sample** as a **Singlet** or **Doublet**; doublets are removed before Stage 03
- After Stage 03 Cell Filtering, surviving singlets are clustered in Stage 04
- **Clusters** from Stage 04 are the final pipeline output; **Subtype** identities are inferred from marker gene expression within clusters

## Example dialogue

> **Dev:** "After SoupX, do we merge all **Samples** before doublet removal?"
> **Domain expert:** "No — **scDblFinder** runs per **Sample** using the `sample_group` column. Merging first would confuse doublet scoring across batches."
>
> **Dev:** "So a **Doublet** from `NR00_Day13_1` and one from `NR00_iPSC_1` are scored independently?"
> **Domain expert:** "Exactly. Each **Sample**'s doublet rate is computed separately, then the flagged barcodes are removed before the combined object moves to Stage 03."

## Flagged ambiguities

- "cell" vs "nucleus" — this is snRNA-seq; "nucleus" is precise, "cell" is acceptable shorthand in code and comments
- "cluster" vs "subtype" — resolved: a cluster is a computational grouping (Stage 04 output); a subtype is a biological identity inferred from marker gene expression within that cluster
- "contamination" vs "ambient RNA" — resolved: "ambient RNA" is the phenomenon; "contamination fraction (rho)" is the quantified SoupX estimate
- "sample" vs "sample_group" — resolved: "sample" is the biological replicate; "sample_group" is the specific metadata column name used in code to hold the human-readable sample label
