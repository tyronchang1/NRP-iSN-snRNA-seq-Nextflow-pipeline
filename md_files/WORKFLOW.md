# Workflow — Claude Code Skill Mappings

Read this file before implementing any pipeline stage (01–04).
After identifying the relevant skills for your stage, invoke them at the indicated steps.

---

## Pipeline Branch Design

Two ambient RNA removal methods run in parallel throughout the full pipeline:

| Track | Stages | Purpose |
|-------|--------|---------|
| SoupX | 01 → 02 → 03 → 04 | Per-sample contamination removal; feeds Stage 02 |
| DecontX | 01.2 → 02.1 → 03 → 04 | Whole-dataset contamination removal; feeds Stage 02.1 |

**Quality comparison checkpoint:** After Stage 02/02.1, compare doublet rates and QC metrics between tracks before continuing. Both tracks proceed independently through Stages 03–04.

---

## Stage 01 · Ambient RNA Removal (SoupX)

**Goal:** Remove ambient RNA contamination from raw Cell Ranger outputs using SoupX.
**Scripts directory:** `scripts/01_SoupX/` — scripts named `SoupX_{SAMPLE}.R`
**Skill file:** `.claude/skills/ambient-rna-removal/SKILL.md` — read this before writing or editing any Stage 01 script

**Skills to invoke:**

| When | Skill | Reason |
|------|-------|--------|
| After writing or editing any `SoupX_*.R` script | `/simplify` | Enforce consistency across per-sample scripts; scripts are structural templates and should stay identical |
| Before treating corrected count matrices as final | `/review` | Confirm contamination estimates and output paths are correct |

---

## Stage 01.2 · Ambient RNA Removal (DecontX) — parallel track

**Goal:** Remove ambient RNA contamination using DecontX as a comparison alternative to SoupX (Stage 01). Runs in parallel; output feeds Stage 02.1.
**Scripts directory:** `scripts/01.2_DecontX/` — script: `01.2_DecontX.R`
**Output directory:** `scripts/01.2_DecontX/DecontX_out/`
**Skill file:** None — use existing script as reference

---

## Stage 02 · Doublet Removal (SoupX track)

**Goal:** Identify and remove doublets from SoupX-corrected matrices using scDblFinder.
**Scripts directory:** `scripts/02_scDblFinder_soupx/` — script: `02_scDblFinder_soupx.R`
**Skill file:** `.claude/skills/doublet-removal/SKILL.md` — read this before writing or editing the Stage 02 script

**Skills to invoke:**

| When | Skill | Reason |
|------|-------|--------|
| Before writing or editing `02_scDblFinder.R` | `/doublet-removal` | Read workflow steps, sample status, and key gotchas |
| After editing `02_scDblFinder.R` | `/simplify` | Check for unnecessary complexity |
| Before saving filtered outputs as final | `/review` | Confirm output format is consistent with what Stage 03 expects |

---

## Stage 02.1 · Doublet Removal (DecontX track) — parallel to Stage 02

**Goal:** Score and label doublets on the DecontX-corrected object using scDblFinder. Runs in parallel with Stage 02. Compare doublet rates between tracks after this stage before proceeding to Stage 03.
**Scripts directory:** `scripts/02.1_scDblFinder_decontX/` — script: `02.1_scDblFinder_decontX.R`
**Output directory:** `scripts/02.1_scDblFinder_decontX/scDblFinder_output/`
**Skill file:** None — use existing script as reference

---

## Stage 03 · Cell Filtering (QC)

**Goal:** Filter low-quality nuclei using Seurat QC metrics (nFeature_RNA, nCount_RNA, percent.mt). Runs on both SoupX and DecontX tracks independently.
**Scripts directory:** `scripts/03_Cell_filtering/` — script: `03_cell_filtering.R`
**Skill file:** `.claude/skills/cell-filtering/SKILL.md` — read this before writing or editing the Stage 03 script

**Skills to invoke:**

| When | Skill | Reason |
|------|-------|--------|
| Before writing or editing `03_cell_filtering.R` | `/cell-filtering` | Read workflow steps, output paths, and key conventions |
| After editing `03_cell_filtering.R` | `/simplify` | Check for unnecessary complexity |
| Before treating filtered outputs as final | `/review` | Confirm thresholds and output structure match Stage 04 expectations |

---

## Stage 04 · Clustering

**Goal:** PCA → UMAP/tSNE dimensionality reduction and Louvain/Leiden cluster assignment using Seurat.
**Scripts directory:** `04_Clustering/` — scripts named `Clustering_{SAMPLE}.R`

**Skills to invoke:**

| When | Skill | Reason |
|------|-------|--------|
| After writing clustering scripts | `/simplify` | Review parameter choices and plotting code for reuse |
| Before finalising cluster annotations | `/review` | Confirm cluster labels are biologically interpretable |

---

## Reference — Available Claude Code Skills

| Skill | Slash command | What it does |
|-------|--------------|--------------|
| Ambient RNA removal | `/ambient-rna-removal` | Stage 01 workflow, sample list, output paths for SoupX scripts |
| Doublet removal | `/doublet-removal` | Stage 02 workflow, sample status, scDblFinder gotchas |
| Simplify | `/simplify` | Reviews changed code for reuse, quality, and efficiency; fixes issues found |
| Review | `/review` | Reviews a pull request or set of changes for correctness and consistency |
| Security review | `/security-review` | Audits pending changes for security issues (hard-coded paths, credentials, injection) |
| Init | `/init` | Initialises a new CLAUDE.md with codebase documentation |

---

## Running Scripts

Standalone R scripts for interactive execution in RStudio. No build system.

```r
source("scripts/01_SoupX/SoupX_{SAMPLE}.R")
```

Each script takes ~5–10 minutes and produces plots plus corrected count matrices on disk.

---

## Key Conventions

- **Project root:** `/scratch/rmlab/rmlab_shared3/tyron/Rscriptv2/iSN/iSN_claude/`
- **SoupX output:** `./scripts/01_SoupX/SoupX_dir_out/{SAMPLE}Counts/`
- **SoupX doublet output:** `./scripts/02_scDblFinder_soupx/scDblFinder_output/`
- **DecontX output:** `./scripts/01.2_DecontX/DecontX_out/`
- **DecontX doublet output:** `./scripts/02.1_scDblFinder_decontX/scDblFinder_output/`
- **Marker genes (human iSN):** `TUBB3`, `PRPH` (pan-neuronal); `CALCA`, `TRPV1` (peptidergic); `MRGPRD` (non-peptidergic); `NTRK2`/`NTRK3` (TrkB/TrkC); `MT-` prefix for mitochondrial genes
- **Libraries:** `SoupX`, `ggplot2`, `DropletUtils`, `cowplot`, `Seurat`, `scDblFinder`, `harmony`, `SingleCellExperiment`

---

## Data Notes

- Input: Cell Ranger 10x Genomics output (~25,000 genes, ~8,000 cells per sample)
- Scripts include inline comments with expected console output for validation
- Contamination fractions near 1.0 for specific genes indicate pure ambient artifacts
- Biological context is **human iSN** — not the original LGLN source pipeline
