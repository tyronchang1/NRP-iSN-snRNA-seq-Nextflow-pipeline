# 02.1_scDblFinder_decontX Change Report

---

**Date:** 2026-05-20
**File changed:** `scripts/02.1_scDblFinder_decontX/02.1_scDblFinder_report.Rmd`
**Change:** YAML `html_document: dev: png` → `dev: ragg_png`. Fixes Cairo SVG device crash on cluster R binary compiled without Cairo/X11 support. `ragg_png` from the `ragg` package works without cairo or X11. R chunk `dev = "png"` in `knitr::opts_chunk$set()` was not changed.

---

---

**Date:** 2026-05-20
**File changed:** `scripts/02.1_scDblFinder_decontX/02.1_scDblFinder_report.Rmd`
**Change:** Added `dev = "png"` to `knitr::opts_chunk$set()` in the setup chunk. Preventive fix matching the Cairo SVG crash identified in DECONTX stage (SLURM job 41051153). Ensures knitr uses PNG device in SLURM node environment.

---

**Date:** 2026-05-15
**File created:** `02.1_scDblFinder_decontX.R`
**Change:** Created new scDblFinder script taking DecontX output as input.

| What | Detail |
|---|---|
| Input | `scripts/01.2_DecontX/DecontX_out/iSN_decontX.rds` |
| Sample identity | Derived from barcode suffix (`-1`–`-8`) mapped to `sample_group` via `desired_order` |
| `scDblFinder` samples arg | `samples = "sample_group"` |
| Output RDS | `scDblFinder_output/iSN_decontX_scDblFinder.rds` |
| Removed vs reference | `LoadH5Seurat`, sample tag CSV, `SaveH5Seurat`, `SeuratDisk`, `SeuratData` |

**Reason:** User requested a scDblFinder script suitable for DecontX output, parallel to the existing `02_scDblFinder.R` which uses SoupX output.

---

**Date:** 2026-05-15
**File changed:** `02.1_scDblFinder_decontX.R`
**Change:** Removed the entire `sample_group` derivation block (lines 16–42: `desired_order`, `sample_mapping`, `barcode_suffix`, `left_join`, `AddMetaData`). Also removed all three `View()` calls. `sample_group` is already present in the RDS metadata saved by `01.2_DecontX.R`, so derivation was unnecessary and caused a runtime error.
**Reason:** User confirmed `sample_group` already exists in `iSN_decontX.rds` metadata; `left_join` block was redundant and raised `undefined columns selected` error.

---

**Date:** 2026-05-19
**File created:** `scripts/02.1_scDblFinder_decontX/02.1_scDblFinder_report.Rmd`
**Change:** Created HTML reporter for Stage 02.1 (DecontX track). Structure is identical to `02_scDblFinder_report.Rmd`: loads `iSN_decontX_scDblFinder.rds`, renders doublet rate table (with > 15% flag), overall rate inline text, nCount histograms, QC violins by class and by sample, and scDblFinder score histogram. Knit output to `scDblFinder_output/`.

---

**Date:** 2026-05-20
**File changed:** `scripts/02.1_scDblFinder_decontX/02.1_scDblFinder_decontX.R`
**Change:** Added `pdf(NULL)` on the line immediately after `setwd(dir)`.
**Reason:** After `setwd(dir)`, R opens a default graphics device which writes stray plots to `Rplots.pdf` in the project root. `pdf(NULL)` kills the default device so no stray file is created; all explicit `ggsave()`, `jpeg()`, `png()`, `pdf("filename.pdf")` calls are unaffected.
