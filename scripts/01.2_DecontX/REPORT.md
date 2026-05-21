# 01.2_DecontX Change Report

---

**Date:** 2026-05-20
**File changed:** `scripts/01.2_DecontX/01.2_DecontX_report.Rmd`
**Change:** YAML `html_document: dev: png` → `dev: ragg_png`. Fixes Cairo SVG device crash on cluster R binary compiled without Cairo/X11 support. `ragg_png` from the `ragg` package works without cairo or X11 and is confirmed installed on the pipeline R binary. R chunk `dev = "png"` in `knitr::opts_chunk$set()` was not changed.
**Triggered by:** Cairo device unavailable on cluster; `ragg_png` confirmed working.

---

---

**Date:** 2026-05-20
**File changed:** `scripts/01.2_DecontX/01.2_DecontX_report.Rmd`
**Change:** Added `dev = "png"` to `knitr::opts_chunk$set()` in the setup chunk. Fixes Cairo SVG device error (`svg: Cairo-based devices are not available for this platform`) that crashed `rmarkdown::render()` in the SLURM node environment. knitr will now use the PNG device for all chunk output.
**Triggered by:** SLURM job 41051153 failure in DECONTX stage.

---

**Date:** 2026-05-20
**File reviewed:** `01.2_DecontX.R`
**Reviewer:** script-review-agent
**Review trigger:** Post-edit verification after `View()` removal for SLURM job 41044279

| Check | Result |
|---|---|
| All 4 `View()` calls removed | PASS |
| No other interactive-only calls (readline, menu, X11, etc.) | PASS |
| Lines surrounding each removed call logically intact | PASS |
| No dangling brackets or syntax breaks | PASS |
| Script ends with saveRDS + capture.output(sessionInfo()) | PASS |
| Pre-existing: `u12_decont` absent from `u_decont` wrap_plots grid | Pre-existing; not caused by this edit; does not affect pipeline outputs |

**Outcome:** Script is safe for headless SLURM execution. No further changes required for this review.

---

**Date:** 2026-05-20
**File changed:** `01.2_DecontX.R`
**Change:** Removed 4 `View()` calls that crash in headless SLURM (X11 not available).

| Line (before) | Change |
|---|---|
| 80 | `View(seu_decont_with_raw@meta.data)` → removed |
| 85 | `View(seu_decont@meta.data)` → removed |
| 128 | `View(seu_decont@meta.data)` → removed |
| 578 | `View(seu_decont@meta.data)` → removed |

**Reason:** Pipeline job 41044279 failed at DECONTX stage with `Error in View(...) : X11 is not available`. `View()` requires an interactive R session; these calls were leftover debug lines with no function in the pipeline.

---

**Date:** 2026-05-15
**File changed:** `01.2_DecontX.R`
**Change:** Customized from PBMC/PRRSV reference script to iSN project.

| What changed | Old value | New value |
|---|---|---|
| Working directory | none | `setwd("/scratch/rmlab/rmlab_shared3/tyron/Rscriptv2/iSN/iSN_claude")` |
| Input (filtered) | single sample `/project/nadc_prrsv/.../filtered_feature_bc_matrix/` | all 8 samples from `./samples/{SAMPLE}/filtered_feature_bc_matrix/` |
| Input (raw/background) | single sample raw | all 8 samples from `./samples/{SAMPLE}/raw_feature_bc_matrix/` |
| Marker genes | PBMC/immune markers (PTPRC, CD2, CD4, CD3E, CD8A, CD8B, CD27, SIRPA, CSF1R, CD14, CD163, GNLY, CD79A, CD79B, PAX5, HBB, PRRSV) | iSN markers (TUBB3, PRPH, NTRK2, NTRK3, CALCA, TRPV1, MRGPRD) |
| Output | SaveH5Seurat + write10xCounts to `/project/nadc_prrsv/...` | saveRDS to `./scripts/01.2_DecontX/DecontX_out/iSN_decontX.rds` |
| Plots saved | commented-out ggsave calls | 4 ggsave calls: contamination UMAP, violin, raw markers grid, decontX markers grid |
| Removed | `library(singleCellTK)`, sample tag/multiplet removal section | — |
**Reason:** Script was from a previous PBMC project. Adapted for all 8 iSN samples combined, with iSN marker genes and correct output paths.

---

**Date:** 2026-05-15
**File changed:** `01.2_DecontX.R`
**Change:** Added iPSC pluripotency markers (POU5F1, SOX2, NANOG) to the genes vector and added raw + decontX UMAP plot blocks (u8–u10, u8_decont–u10_decont). Updated wrap_plots to include all 10 markers.
**Reason:** User requested the same iPSC markers used in the SoupX iPSC scripts be included in DecontX visualization.

---

**Date:** 2026-05-15
**File changed:** `01.2_DecontX.R`
**Change:** Added SNAP25 (synaptic marker) to the genes vector and added raw + decontX UMAP plot blocks (u11, u11_decont). Updated both wrap_plots calls to include all 11 markers.
**Reason:** User requested SNAP25 be included alongside the iSN and iPSC markers for visualization.

---

**Date:** 2026-05-15
**File changed:** `01.2_DecontX.R`
**Change:** Added `plotDecontXMarkerPercentage` bar graph block. Defined `markers` as a named list grouping the 11 genes by cell type (PanNeuronal, Peptidergic, NonPeptidergic, TrkB_TrkC, iPSC). Defined `cellTypeMappings <- NULL` with a comment explaining how to fill in cluster-to-group mappings after inspecting the UMAP. Added `ggsave` call saving to `DecontX_out/05_marker_percentage.png`.
**Reason:** User requested a bar graph showing % cells expressing each marker in raw vs decontX counts, per cluster.

---

**Date:** 2026-05-15
**File changed:** `01.2_DecontX.R`
**Change:** Added two `plotDecontXMarkerExpression` blocks and a `logNormCounts` step between them.
- `e1`: violin plots using raw counts vs decontXcounts (all 11 markers, ncol=3); saved to `06_marker_expression_counts.png`
- `logNormCounts(sce_decont_with_raw, exprs_values = "decontXcounts", name = "decontXlogcounts")`: adds log-normalized decontX counts as a new assay
- `e2`: violin plots using logcounts vs decontXlogcounts; saved to `07_marker_expression_lognorm.png`
**Reason:** User requested marker expression violin plots before and after log normalization, comparing raw vs decontX counts.

---

**Date:** 2026-05-15
**File changed:** `01.2_DecontX.R`
**Change:** Added separate `plotDecontXMarkerExpression` calls for SN markers and iPSC markers alongside the existing all-gene calls. SN markers use `unlist(markers[c("PanNeuronal","Peptidergic","NonPeptidergic","TrkB_TrkC")], use.names=FALSE)`; iPSC markers use `markers[["iPSC"]]`. Both before (`e1_SN`, `e1_iPSC`) and after log normalization (`e2_SN`, `e2_iPSC`). 4 new ggsave files: 08–11.
**Reason:** User requested SN and iPSC marker expression plotted separately, preserving the subgroup structure from the `markers` list.

---

**Date:** 2026-05-19
**File created:** `scripts/01.2_DecontX/01.2_DecontX_report.Rmd`
**Change:** Created HTML reporter for Stage 01.2. Loads `iSN_decontX.rds`, renders: cell counts per sample (kable), contamination score summary table (% cells > 0.5 and > 0.8 per sample) plus histogram, three UMAP panels (contamination score, decontX clusters, sample identity), nCount before-vs-after violin (conditional on `nCount_originalexp` being present), and all 6 saved celda PNGs embedded via `include_graphics`. Knit output to `DecontX_out/`.

---

**Date:** 2026-05-20
**File changed:** `scripts/01.2_DecontX/01.2_DecontX_report.Rmd`
**Change:** Added `options(knitr.graphics.rel_path = FALSE)` to the `setup` chunk, after `opts_knit$set(root.dir = ...)`.
**Reason:** `knitr::include_graphics()` relativizes the absolute `out_dir` path against the Rmd document directory (`scripts/01.2_DecontX/`), producing `DecontX_out/01_contamination_UMAP.png`. Because `opts_knit$set(root.dir = params$project_root)` makes knitr resolve relative paths from the project root, it then looks for `iSN_claude/DecontX_out/...` which does not exist. Setting `knitr.graphics.rel_path = FALSE` forces `include_graphics()` to use absolute paths unchanged. SLURM job 41057026 failed at chunk 22/34 [fig-01] for this reason.
**Triggered by:** SLURM job 41057026 failure, pipeline resubmitted as job 41057698.

---

**Date:** 2026-05-20
**File changed:** `scripts/01.2_DecontX/01.2_DecontX.R`
**Change:** Added `pdf(NULL)` on the line immediately after `setwd(dir)`.
**Reason:** After `setwd(dir)`, R opens a default graphics device which writes stray plots to `Rplots.pdf` in the project root. `pdf(NULL)` kills the default device so no stray file is created; all explicit `ggsave()`, `jpeg()`, `png()`, `pdf("filename.pdf")` calls are unaffected.
