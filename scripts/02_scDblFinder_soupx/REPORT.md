# 02_scDblFinder_soupx Change Report

---

**Date:** 2026-05-20
**File changed:** `scripts/02_Doublets_Removal/02_scDblFinder_report.Rmd`
**Change:** YAML `html_document: dev: png` → `dev: ragg_png`. Fixes Cairo SVG device crash on cluster R binary compiled without Cairo/X11 support. `ragg_png` from the `ragg` package works without cairo or X11. R chunk `dev = "png"` in `knitr::opts_chunk$set()` was not changed.

---

---

**Date:** 2026-05-20
**File changed:** `scripts/02_Doublets_Removal/02_scDblFinder_report.Rmd`
**Change:** Added `dev = "png"` to `knitr::opts_chunk$set()` in the setup chunk. Preventive fix matching the Cairo SVG crash identified in DECONTX stage (SLURM job 41051153). Ensures knitr uses PNG device in SLURM node environment.

---

**Date:** 2026-05-14
**File changed:** `02_scDblFinder.R`
**Change:** Customized from LGLN/maize reference pipeline to iSN project.

| What changed | Old value | New value |
|---|---|---|
| Working directory | `/project/nadc_prrsv/Tyron_Chang/...` | `/scratch/rmlab/rmlab_shared3/tyron/Rscriptv2/iSN/iSN_from_scratch` |
| Input dirs | LGLN1–8, JPP5 SoupX outputs | 8 iSN sample SoupX outputs from `01_SoupX/SoupX_dir_out/` |
| Sample names | LGLN1–8, JPP5 | NR00_Day13_1, NR00_Day13_1_dup, NR00_Day13_2, NR00_Day13_2_dup, NR00_Day7_1, NR00_Day7_2, NR00_iPSC_1, NR00_iPSC_2 |
| Output path | `/project/.../scDblfinder_output/` | `./02_Doublets_Removal/scDblFinder_output/` |
| H5Seurat filename | `all_doubletstep.h5Seurat` | `iSN_doubletstep.h5Seurat` |
| Library added | — | `SingleCellExperiment` (explicit import) |
| `dir.create` | not present | added for `scDblFinder_output/` with `showWarnings = FALSE` |

**Note:** NR00_Day7_2 and NR00_iPSC_2 SoupX outputs are not yet available. NR00_Day13_2_dup has since completed SoupX (rho=0.23).

---

**Date:** 2026-05-14
**File changed:** `02_scDblFinder.R`
**Change:** User uncommented `NR00_Day13_2_dup` in `dirs` (SoupX now complete). Added `saveRDS(all_seu, ...)` call alongside `SaveH5Seurat` to write a `.rds` backup. Moved `all_cst_p` render before `ggsave`. Added second `dir.create` guard before `SaveH5Seurat`. Comment out those three dirs until Stage 01 is complete for those samples.

---

**Date:** 2026-05-14
**File changed:** `02_scDblFinder.R`
**Change:** Fixed dirs vector — commented out the 3 pending SoupX samples (NR00_Day13_2_dup, NR00_Day7_2, NR00_iPSC_2) that don't exist on disk yet. Fixed missing comma after NR00_Day7_1Counts. Restored NR00_iPSC_1 which was accidentally commented out. Updated `desired_order` to match the 5 active samples. `Read10X` errors if any directory in dirs is missing.

---

**Date:** 2026-05-15
**File changed:** `02_scDblFinder.R`, `doublet-removal/SKILL.md`
**Change:** Updated all paths in `02_scDblFinder.R` after stage directories moved into `scripts/`. Input dirs: `./01_SoupX/SoupX_dir_out/` → `./scripts/01_SoupX/SoupX_dir_out/`. Output paths: `./02_Doublets_Removal/scDblFinder_output/` → `./scripts/02_Doublets_Removal/scDblFinder_output/`. SKILL.md header paths updated to match.
**Reason:** User moved `01_SoupX/` and `02_Doublets_Removal/` into a new `scripts/` subdirectory.

---

**Date:** 2026-05-15
**File changed:** `02_scDblFinder.R`
**Change:** Updated `dir <- "...iSN_from_scratch"` → `dir <- "...iSN_claude"`.
**Reason:** Project directory renamed from `iSN_from_scratch` to `iSN_claude`.

---

**Date:** 2026-05-15
**File changed:** `02_scDblFinder.R`
**Change:** Uncommented `NR00_Day7_2Counts` and `NR00_iPSC_2Counts` in `dirs`; updated `desired_order` to include all 8 samples. All 8 samples now active.
**Reason:** SoupX completed for NR00_Day7_2 and NR00_iPSC_2; their output directories confirmed on disk.

---

**Date:** 2026-05-19
**File changed:** `scripts/02_Doublets_Removal/02_scDblFinder_report.Rmd`
**Change:** Added `library(tidyr)` to the libraries chunk for explicitness (previously only called via `tidyr::pivot_wider()` namespace). Flagged by script-review-agent.

---

**Date:** 2026-05-19
**File created:** `scripts/02_Doublets_Removal/02_scDblFinder_report.Rmd`
**Change:** Created HTML reporter for Stage 02 (SoupX track). Loads `iSN_doubletstep.rds`, renders: doublet rate table per sample (with flag for > 15%), overall doublet rate inline text, nCount_RNA histograms faceted by sample (x-limit 0–20000, vline at 500), QC violins by doublet class and by sample, and scDblFinder score histogram coloured by singlet/doublet class. Knit output to `scDblFinder_output/`.

---

**Date:** 2026-05-20
**File changed:** `scripts/02_Doublets_Removal/02_scDblFinder.R`
**Change:** Added `pdf(NULL)` on the line immediately after `setwd(dir)`.
**Reason:** After `setwd(dir)`, R opens a default graphics device which writes stray plots to `Rplots.pdf` in the project root. `pdf(NULL)` kills the default device so no stray file is created; all explicit `ggsave()`, `jpeg()`, `png()`, `pdf("filename.pdf")` calls are unaffected.

---

**Date:** 2026-05-21
**File changed:** `scripts/02_scDblFinder_soupx/02_scDblFinder_report.Rmd`
**Change:** `out_dir` definition updated from `scripts/02_Doublets_Removal/scDblFinder_output` to `scripts/02_scDblFinder_soupx/scDblFinder_output`.
**Reason:** Directory renamed from `02_Doublets_Removal` to `02_scDblFinder_soupx`; Rmd reporter was still pointing at the old path and would have failed to load `iSN_doubletstep.rds` at render time.

---

**Date:** 2026-05-21
**File changed:** `scripts/02_scDblFinder_soupx/02_scDblFinder_soupx.R`
**Change:** Replaced all 5 occurrences of `./scripts/02_Doublets_Removal/` with `./scripts/02_scDblFinder_soupx/` (lines 76, 118, 120, 122, 124). Covers `ggsave path=`, two commented `dir.create`/`SaveH5Seurat` lines, `saveRDS()`, and `capture.output()` session_info path.
**Reason:** Directory `scripts/02_Doublets_Removal/` was renamed to `scripts/02_scDblFinder_soupx/` and script was renamed to `02_scDblFinder_soupx.R`. Internal path strings updated to match.

