# 01_SoupX Script Update Report

**Date:** 2026-05-11

## Summary

Replaced 8 legacy LGLN sample scripts with 4 new scripts matching the actual samples in `samples/`. Updated all paths, variable names, plot titles, and marker genes to match the iSN project.

---

## Scripts Deleted

| File | Reason |
|------|--------|
| `SoupX_LGLN1.R` | No corresponding sample in `samples/` |
| `SoupX_LGLN2.R` | No corresponding sample in `samples/` |
| `SoupX_LGLN3.R` | No corresponding sample in `samples/` |
| `SoupX_LGLN4.R` | No corresponding sample in `samples/` |
| `SoupX_LGLN5.R` | No corresponding sample in `samples/` |
| `SoupX_LGLN6.R` | No corresponding sample in `samples/` |
| `SoupX_LGLN7.R` | No corresponding sample in `samples/` |
| `SoupX_LGLN8.R` | No corresponding sample in `samples/` |

## Scripts Created

| File | Sample directory |
|------|-----------------|
| `SoupX_NR00_Day13_1.R` | `samples/NR00_Day13_1` |
| `SoupX_NR00_Day13_2.R` | `samples/NR00_Day13_2` |
| `SoupX_NR00_Day7_1.R` | `samples/NR00_Day7_1` |
| `SoupX_NR00_iPSC_1.R` | `samples/NR00_iPSC_1` |
| `SoupX_NR00_Day13_1_dup.R` | `samples/NR00_Day13_1_dup` |
| `SoupX_NR00_Day13_2_dup.R` | `samples/NR00_Day13_2_dup` |
| `SoupX_NR00_Day7_2.R` | `samples/NR00_Day7_2` |
| `SoupX_NR00_iPSC_2.R` | `samples/NR00_iPSC_2` |

## Changes Applied to All New Scripts

| What changed | Old value | New value |
|-------------|-----------|-----------|
| Working directory (`dir`) | `/project/nadc_prrsv/Tyron_Chang/...` | `/scratch/rmlab/rmlab_shared3/tyron/Rscriptv2/iSN_claude` |
| `load10X()` path | `/project/.../LGLN{N}/outs` | `./samples/{SAMPLE}` |
| Marker genes | `PEDV`, `CD4`, `PAX5`, `CD163` | `TUBB3`, `PRPH`, `NTRK2`, `CALCA` (iSN markers) |
| Output variable | `out_LGLN{N}` | `out_{SAMPLE}` |
| Output path | `./SoupX_dir/LGLN{N}Counts` | `./SoupX_dir/{SAMPLE}Counts` |
| Plot titles | `"LGLN{N} study pre-Soup"` | `"{SAMPLE} study pre-Soup"` |

---

## Estimated Contamination Fractions (rho)

Values recorded from inline comments in each script after running `autoEstCont()`.

| Sample | rho | Note |
|--------|-----|------|
| NR00_Day13_1 | 0.21 | Elevated; above typical 0.05 threshold |
| NR00_Day13_1_dup | 0.21 | Elevated |
| NR00_Day13_2 | 0.25 | Elevated |
| NR00_Day13_2_dup | 0.23 | Elevated |
| NR00_Day7_1 | 0.42 | High contamination |
| NR00_Day7_2 | — | Pending |
| NR00_iPSC_1 | 0.65 | Very high; `forceAccept = TRUE` required |
| NR00_iPSC_2 | — | Pending |

All iSN samples show substantially higher ambient contamination than the typical rho ≈ 0.01 benchmark, likely reflecting the complexity of differentiating cultures. `NR00_iPSC_1` required `forceAccept = TRUE` to proceed.

---

## Path Corrections — 2026-05-14

**Files changed:** `SoupX_NR00_Day13_2_dup.R`, `SoupX_NR00_Day7_2.R`, `SoupX_NR00_iPSC_2.R`

**Change:** Corrected `write10xCounts` output path from `./SoupX_dir_out/` to `./01_SoupX/SoupX_dir_out/` in all three scripts. Also removed the `dir.create("./SoupX_dir_out")` call since the directory already exists at `01_SoupX/SoupX_dir_out/`.

**Reason:** `SoupX_dir_out` was moved into `01_SoupX/` after the original scripts ran. Scripts `setwd` to the project root, so the correct relative path is `./01_SoupX/SoupX_dir_out/`. Confirmed by the presence of `NR00_Day13_1_dupCounts` at `01_SoupX/SoupX_dir_out/` from the user-corrected `SoupX_NR00_Day13_1_dup.R`.

---

## SoupX Completion — 2026-05-14

**File:** `SoupX_NR00_Day13_2_dup.R`
**Change:** User added `#rho=0.23` annotation to `autoEstCont()` call; output written to `01_SoupX/SoupX_dir_out/NR00_Day13_2_dupCounts`. Sample is now complete and can be included in Stage 02.

---

## Path Update — 2026-05-15

**Files changed:** All 8 `SoupX_*.R` scripts, `SKILL.md`

**Change:** Updated `write10xCounts` output paths from `./01_SoupX/SoupX_dir_out/` → `./scripts/01_SoupX/SoupX_dir_out/` after stage directories were moved into `scripts/`. Also updated `ambient-rna-removal/SKILL.md` header paths to match.

**Reason:** User moved `01_SoupX/` and `02_Doublets_Removal/` into a new `scripts/` subdirectory. All script paths set relative to project root (`setwd`), so all output paths needed the `scripts/` prefix added.

---

**Date:** 2026-05-15
**File changed:** `SoupX_NR00_Day13_1.R`
**Change:** Fixed `dir.create("./SoupX_dir_out")` → `dir.create("./scripts/01_SoupX/SoupX_dir_out")`. The `write10xCounts` line was already correct; only the `dir.create` was missed in the previous bulk update.
**Reason:** Stale path would have created a spurious empty directory at the project root.

---

**Date:** 2026-05-15
**Files changed:** All 8 `SoupX_*.R` scripts
**Change:** Updated `dir <- "...iSN_from_scratch"` → `dir <- "...iSN_claude"` in all scripts.
**Reason:** Project directory renamed from `iSN_from_scratch` to `iSN_claude`.

---

**Date:** 2026-05-15
**SoupX completion:** `NR00_Day7_2`, `NR00_iPSC_2`
**Change:** Output directories `NR00_Day7_2Counts` and `NR00_iPSC_2Counts` confirmed present in `SoupX_dir_out/`. Both samples now have SoupX output and can be included in Stage 02.
**Reason:** User ran SoupX for these two previously pending samples.

---

**Date:** 2026-05-15
**Files changed:** `SoupX_NR00_Day7_2.R`, `SoupX_NR00_iPSC_2.R`
**Change:** Rho estimates added as inline annotations after running `autoEstCont()`.

| Sample | rho |
|---|---|
| NR00_Day7_2 | 0.39 |
| NR00_iPSC_2 | 0.12 |

**Reason:** User completed SoupX runs for both samples and annotated the estimated contamination fractions in-script.

---

**Date:** 2026-05-19
**File changed:** `scripts/01_SoupX/01_SoupX_report.Rmd`
**Change:** Fixed `sample_mapping` join: `factor(1:8)` → `as.character(1:8)` to match Seurat's character-typed `orig.ident` column. Flagged by script-review-agent.

---

**Date:** 2026-05-19
**File created:** `scripts/01_SoupX/01_SoupX_report.Rmd`
**Change:** Created HTML reporter for Stage 01. Reads all 8 SoupX-corrected output directories via `Read10X`, builds a merged Seurat object, and renders: cell counts per sample (kable), UMI and gene count violins, marker gene expression violins (pan-neuronal, peptidergic, non-peptidergic, TrkB/TrkC, iPSC), and a note explaining that rho values are not stored in saved outputs and must be recovered by re-running the per-sample .R scripts. Knit output to `SoupX_dir_out/`.

---

**Date:** 2026-05-20
**Files changed:** All 8 `SoupX_*.R` scripts (`SoupX_NR00_Day13_1.R`, `SoupX_NR00_Day13_1_dup.R`, `SoupX_NR00_Day13_2.R`, `SoupX_NR00_Day13_2_dup.R`, `SoupX_NR00_Day7_1.R`, `SoupX_NR00_Day7_2.R`, `SoupX_NR00_iPSC_1.R`, `SoupX_NR00_iPSC_2.R`)
**Change:** Added `pdf(NULL)` on the line immediately after `setwd(dir)` in each script.
**Reason:** After `setwd(dir)`, R opens a default graphics device which writes stray plots to `Rplots.pdf` in the project root. `pdf(NULL)` kills the default device so no stray file is created; all explicit `ggsave()`, `jpeg()`, `png()`, `pdf("filename.pdf")` calls are unaffected.
