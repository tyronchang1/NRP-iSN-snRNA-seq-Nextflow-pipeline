# Nextflow Pipeline — Agent Reference

Read this file before implementing any Nextflow process or editing `main.nf`. This is the canonical reference for `nextflow-script-agent`.

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
**Module file:** `nextflow/modules/soupx.nf`
**Process name:** `SOUPX`
**Input:** Cell Ranger output directory per sample (`samples/{SAMPLE}/`)
**Output:** Corrected count matrices → published to `scripts/01_SoupX/SoupX_dir_out/{SAMPLE}Counts/`
**Parallelism:** One process invocation per sample via channel

---

## Stage 01.2 · Ambient RNA Removal (DecontX) — parallel track

**Goal:** Remove ambient RNA contamination using DecontX as a comparison alternative to SoupX. Output feeds Stage 02.1.
**Module file:** `nextflow/modules/decontx.nf`
**Process name:** `DECONTX`
**Input:** All samples loaded together (single process)
**Output:** DecontX-corrected Seurat object → published to `scripts/01.2_DecontX/DecontX_out/`

---

## Stage 02 · Doublet Removal (SoupX track)

**Goal:** Score and label doublets on SoupX-corrected matrices using scDblFinder.
**Module file:** `nextflow/modules/scdblfinder.nf`
**Process name:** `SCDBLFINDER`
**Input:** SoupX corrected count matrices from Stage 01
**Output:** Seurat object with doublet labels → published to `scripts/02_scDblFinder_soupx/scDblFinder_output/`

---

## Stage 02.1 · Doublet Removal (DecontX track) — parallel to Stage 02

**Goal:** Score and label doublets on the DecontX-corrected object using scDblFinder. Compare doublet rates between tracks after this stage before proceeding to Stage 03.
**Module file:** `nextflow/modules/scdblfinder_decontx.nf`
**Process name:** `SCDBLFINDER_DECONTX`
**Input:** DecontX-corrected Seurat object from Stage 01.2
**Output:** Seurat object with doublet labels → published to `scripts/02.1_scDblFinder_decontX/scDblFinder_output/`

---

## Stage 03 · Cell Filtering (QC)

**Goal:** Filter low-quality cells per sample using Seurat QC metrics (nFeature_RNA, nCount_RNA, percent.mt).
**Module file:** `nextflow/modules/cell_filtering.nf`
**Process name:** `CELL_FILTERING`
**Input:** Doublet-labelled Seurat object from Stage 02 (SoupX track) or Stage 02.1 (DecontX track)
**Output:** Filtered Seurat object per track → published to `scripts/03_Cell_filtering/`
**Note:** QC thresholds (nCount_RNA, nFeature_RNA, percent.mt cutoffs) are set empirically from plots — not hardcoded in the process. Pass as params after user confirms from plots.

---

## Stage 04 · Clustering

**Goal:** PCA → UMAP dimensionality reduction and Louvain/Leiden cluster assignment using Seurat.
**Module file:** `nextflow/modules/clustering.nf`
**Process name:** `CLUSTERING`
**Input:** Filtered Seurat object from Stage 03 (one per track)
**Output:** Clustered Seurat object per track → published to `scripts/04_Clustering/`
**Note:** Resolution parameter is set empirically — passed as a param after user confirms from UMAP plots.

---

## Key Conventions

- **DSL2:** `nextflow.enable.dsl = 2` declared in `nextflow/main.nf`
- **Module structure:** one process per file under `nextflow/modules/`; process names in UPPERCASE
- **params:** all paths and thresholds defined in `nextflow.config` — never hardcoded inside module files
- **Samples:** passed as channels from a samplesheet or `params.samples` — never hardcoded by name inside modules
- **publishDir:** every process declares a `publishDir` directive matching the corresponding R script output path
- **Reproducibility:** `set.seed(123)` inside every R script block; pass as `params.seed` if variable
- **Session info:** each process captures `sessionInfo()` to `session_info.txt` in its publishDir
- **Project root:** `params.project_root = "/scratch/rmlab/rmlab_shared3/tyron/Rscriptv2/iSN/iSN_claude"`
- **R binary (HTCF):** `/ref/rmlab/software/spack-1.1.0/opt/spack/linux-x86_64/r-4.5.2-jga4yt5sdbzfddqszotqf64bn5a6iu2m/bin/Rscript`
- **R library (HTCF):** `R_LIBS=/ref/rmlab/software/tyron/R-libs`

---

## File Layout

```
nextflow/
├── main.nf                  Main workflow — imports modules, defines channels, wires stages
├── nextflow.config          params, executor settings, resource limits
└── modules/
    ├── soupx.nf             Stage 01 — SOUPX
    ├── decontx.nf           Stage 01.2 — DECONTX
    ├── scdblfinder.nf       Stage 02 — SCDBLFINDER (SoupX track)
    ├── scdblfinder_decontx.nf  Stage 02.1 — SCDBLFINDER_DECONTX (DecontX track)
    ├── cell_filtering.nf    Stage 03 — CELL_FILTERING
    └── clustering.nf        Stage 04 — CLUSTERING
```
