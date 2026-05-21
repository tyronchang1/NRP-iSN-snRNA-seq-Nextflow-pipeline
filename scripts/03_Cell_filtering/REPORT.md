# Stage 03 Cell Filtering — Change Log

## 2026-05-21 — Rmd: stale SoupX input path corrected

**File:** `scripts/03_Cell_filtering/03_cell_filtering_report.Rmd`

**Change:** In the SoupX branch of the `load` chunk, the `readRDS` path for the pre-filter object was updated:

- Old: `"scripts/02_Doublets_Removal/scDblFinder_output/iSN_doubletstep.rds"`
- New: `"scripts/02_scDblFinder_soupx/scDblFinder_output/iSN_doubletstep.rds"`

**Reason:** The Stage 02 directory was renamed from `02_Doublets_Removal` to `02_scDblFinder_soupx`. The `.R` script (`03_cell_filtering.R`) was already updated on 2026-05-21; this entry syncs the Rmd reporter to the same path.

---

## 2026-05-20 (second entry)

**File:** `scripts/03_Cell_filtering/03_cell_filtering_report.Rmd`
**Change:** YAML `html_document: dev: png` → `dev: ragg_png`. Fixes Cairo SVG device crash on cluster R binary compiled without Cairo/X11 support. `ragg_png` from the `ragg` package works without cairo or X11. R chunk `dev = "png"` in `knitr::opts_chunk$set()` was not changed.

---

## 2026-05-20

**File:** `scripts/03_Cell_filtering/03_cell_filtering_report.Rmd`
**Change:** Added `dev = "png"` to `knitr::opts_chunk$set()` in the setup chunk. Preventive fix matching the Cairo SVG crash identified in DECONTX stage (SLURM job 41051153). Ensures knitr uses PNG device in SLURM node environment.

## 2026-05-19

**File:** `scripts/03_Cell_filtering/03_cell_filtering.R`
**Change (bug fixes — flagged by script-review-agent):** Removed `View(seuNew@meta.data)` from DecontX block (crashes in non-interactive Nextflow). Fixed SoupX threshold comment from `nFeature_RNA > 800` to `nFeature_RNA > 700` (filter code already used 700; comment was misleading).

**File:** `scripts/03_Cell_filtering/03_cell_filtering.R`
**Change:** Added `--track` CLI argument (`.get_arg` infrastructure). SoupX section wrapped in `if (args_track == "soupx")`, DecontX section wrapped in `if (args_track == "decontx")`. Each conditional now also loads the corresponding pre-filter .rds and computes `percent.mt` (previously loaded unconditionally for both tracks). Default: `"decontx"`.

**File:** `scripts/03_Cell_filtering/03_cell_filtering_report.Rmd`
**Change:** Added `track: "decontx"` param to YAML. Rewrote load chunk to conditionally load only the selected track's pre-filter and post-filter .rds. Removed separate SoupX and DecontX sections; replaced with single unified plot/filter section using `track_label`, `nfeature_threshold`, and `xlim_ncount` variables set per track. Removed combined summary table (no longer applicable for single-track reports). Section headings now display the selected track name via inline R.

---

**Date:** 2026-05-20
**File changed:** `scripts/03_Cell_filtering/03_cell_filtering.R`
**Change:** Added `pdf(NULL)` on the line immediately after `setwd(dir)`.
**Reason:** After `setwd(dir)`, R opens a default graphics device which writes stray plots to `Rplots.pdf` in the project root. `pdf(NULL)` kills the default device so no stray file is created; all explicit `ggsave()`, `jpeg()`, `png()`, `pdf("filename.pdf")` calls are unaffected.

---

## 2026-05-18

**File:** `scripts/03_Cell_filtering/03_cell_filtering.R`

**What changed:** Full customization of the pig PBMC PRRSV script for the iSN snRNA-seq pipeline.

**Changes made:**

1. **Script header** — Replaced the library block with the canonical iSN header (`rm(list = ls())`, `setwd(dir)`, libraries: `Seurat`, `ggplot2`, `dplyr`, `scales`, `patchwork`). Removed `readxl`, `SeuratData`, `SeuratDisk`.

2. **Input loading** — Replaced `LoadH5Seurat()` with `readRDS()` for both tracks:
   - SoupX: `./scripts/02_Doublets_Removal/scDblFinder_output/iSN_doubletstep.rds`
   - DecontX: `./scripts/02.1_scDblFinder_decontX/scDblFinder_output/iSN_decontX_scDblFinder.rds`
   - (Paths corrected post-agent to match actual Stage 02 output filenames on disk)

3. **Mitochondrial gene calculation** — Replaced the pig-specific `annotKey`/`annot`/`mitoGenes` block with `PercentageFeatureSet(pattern = "^MT-")` applied to both objects. Uses `percent.mt` throughout (iSN convention).

4. **QC plots** — Updated all 6 plot types (violin1, violin2, g1–g6) to use `percent.mt` and `orig.ident`. Runs for both SoupX and DecontX tracks independently.

5. **Removed `View()` calls** — All `View(...)` lines deleted (not compatible with SLURM / non-interactive execution).

6. **Removed stray `setwd()`** — Deleted `setwd("/project/nadc_prrsv/...")` line.

7. **Removed PRRSV sample tag CSV block** — Deleted the `Sus-Scrofa-PRRSV_Sample_Tag_Calls.csv` read + join block. Not applicable to iSN.

8. **Output saving** — Replaced `SaveH5Seurat()` with `saveRDS()`:
   - SoupX: `./scripts/03_Cell_filtering/cell_filtering_output/03_seu_cellfiltered_soupx.rds`
   - DecontX: `./scripts/03_Cell_filtering/cell_filtering_output/03_seu_cellfiltered_decontx.rds`

9. **Output directory** — Added `dir.create()` call for `./scripts/03_Cell_filtering/cell_filtering_output/`.

10. **Assay conversion** — Kept `CreateAssayObject(counts = seuNew[["RNA"]]$counts)` Seurat v5->v3 compatibility shim.

11. **QC thresholds** — Kept placeholder thresholds (mito <= 20%, nFeature > 800, nCount > 500, singlet only) with comment that these are preliminary and should be adjusted after inspecting plots.

12. **Session info** — Updated `capture.output()` path to `./scripts/03_Cell_filtering/cell_filtering_output/03_session_info.txt`. Removed `report(sessionInfo())`.

13. **Script structure** — Two clearly marked sections: `## SoupX track ----` and `## DecontX track ----`, each running the full QC -> filter -> save pipeline independently.

**Why:** Adapting from pig PBMC PRRSV project to human iSN snRNA-seq pipeline. Aligns with iSN project conventions (canonical header, `percent.mt`, `saveRDS`, `sample_group`, two-track structure).

---

## 2026-05-21

**File:** `scripts/03_Cell_filtering/03_cell_filtering.R`
**Change:** Replaced 1 occurrence of `./scripts/02_Doublets_Removal/scDblFinder_output/iSN_doubletstep.rds` with `./scripts/02_scDblFinder_soupx/scDblFinder_output/iSN_doubletstep.rds` (line 30, SoupX track `readRDS` call).
**Reason:** Stage 02 directory was renamed from `02_Doublets_Removal` to `02_scDblFinder_soupx`; input path updated to match.

---

## 2026-05-18 (follow-up)

**File:** `scripts/03_Cell_filtering/03_cell_filtering.R`

**What changed:** Replaced all `orig.ident` references with `sample_group` in QC plot grouping, faceting, and `table()` calls (20 occurrences, both tracks).

**Why:** Per `CONTEXT.md`, `orig.ident` holds the numeric barcode suffix (1–8) from Cell Ranger merging; `sample_group` holds the human-readable sample identifier (e.g., `NR00_Day13_1`). Using `orig.ident` would produce plots faceted by number rather than sample name.

---

## 2026-05-18 (figure saving)

**File:** `scripts/03_Cell_filtering/03_cell_filtering.R`

**What changed:** Added `ggsave()` calls to save all QC figures to disk for both tracks. Specifically:

1. **Subdirectory creation** — Added two `dir.create()` calls after the existing output directory setup:
   - `Cell_filtering_output/soupx/`
   - `Cell_filtering_output/decontx/`

2. **SoupX track** — Added `ggsave()` after each of the 8 plot objects:
   - `violin_by_sample.pdf` (violin1)
   - `violin_by_doublet.pdf` (violin2)
   - `scatter_mito_vs_gene_doublet.pdf` (g1)
   - `scatter_mito_vs_gene_sample.pdf` (g2)
   - `scatter_mito_vs_gene_umi.pdf` (g3)
   - `scatter_mito_vs_gene_doublet2.pdf` (g4)
   - `scatter_count_vs_gene_mito.pdf` (g5)
   - `scatter_count_vs_gene_doublet.pdf` (g6)
   - Assigned the previously anonymous overlay `ggplot(...)` to `g_overlay` and saved as `overlay_pre_post_filter.pdf`

3. **DecontX track** — Mirrored the same 9 saves to `Cell_filtering_output/decontx/`. Overlay variable also named `g_overlay` (separate scope, no collision).

**Why:** Plots were previously only rendered interactively. Saving to PDF makes the QC outputs inspectable in non-interactive (SLURM) execution and persistent across sessions — required for threshold review by the BIOLOGIST agent.

---

## 2026-05-19

**File created:** `scripts/03_Cell_filtering/03_cell_filtering_report.Rmd`

**What changed:** Created HTML reporter for Stage 03. Loads pre-filter objects from both tracks (Stage 02 outputs), computes `percent.mt` for both, loads post-filter objects from `Cell_filtering_output/`. Renders:

- **SoupX track:** QC violin plots (by sample, by doublet class), 6 scatter plots (g1–g6) exactly matching `03_cell_filtering.R` lines 51–124, filter summary table (thresholds: `percent.mt <= 20`, `nFeature > 700`, `nCount > 500`, singlets), pre/post overlay plot.
- **DecontX track:** Same structure, g1–g6 matching lines 201–272, filter thresholds: `percent.mt <= 20`, `nFeature > 800`, `nCount > 500`, singlets.
- **Combined summary:** Table comparing pre- vs post-filter cell counts and percentage removed for both tracks.

Knit output to `Cell_filtering_output/`.
