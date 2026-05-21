# Skill: Doublet Removal (scDblFinder)

**Script:** `scripts/02_scDblFinder_soupx/02_scDblFinder_soupx.R`
**Input:** SoupX-corrected count matrices from `scripts/01_SoupX/SoupX_dir_out/{SAMPLE}Counts/`
**Output directory:** `scripts/02_scDblFinder_soupx/scDblFinder_output/`
**Libraries:** `Seurat`, `scDblFinder`, `SingleCellExperiment`, `ggplot2`, `cowplot`, `dplyr`, `SeuratDisk`

---

## Samples

| Sample | SoupX output available |
|--------|------------------------|
| NR00_Day13_1 | Yes |
| NR00_Day13_1_dup | Yes |
| NR00_Day13_2 | Yes |
| NR00_Day13_2_dup | Yes |
| NR00_Day7_1 | Yes |
| NR00_Day7_2 | Yes |
| NR00_iPSC_1 | Yes |
| NR00_iPSC_2 | Yes |

Only include samples in `dirs` whose SoupX output directory exists on disk. `Read10X` errors immediately if any path is missing.

---

## Steps

1. **Set working directory**
   - `dir <- "/scratch/rmlab/rmlab_shared3/tyron/Rscriptv2/iSN/iSN_claude"`
   - `setwd(dir)`; clear environment with `rm(list = ls(all.name = TRUE))`

2. **Define input paths**
   - `dirs` is a character vector of paths to available `{SAMPLE}Counts/` directories
   - Comment out any sample whose SoupX output does not exist yet
   - `desired_order` must stay in sync with the active (uncommented) entries in `dirs` — positional mapping is used to assign sample names to `orig.ident`

3. **Load and create Seurat object**
   - `cts <- Read10X(data.dir = dirs)` — reads all samples; assigns `orig.ident` as `"1"`, `"2"`, `"3"`... by position
   - `all_seu <- CreateSeuratObject(counts = cts)`
   - `View(all_seu@meta.data)` to confirm orig.ident counts match expected cells per sample

4. **Map orig.ident to sample names**
   - Build `sample_mapping` data frame: `orig_ident` (factor 1:n) → `sample_group` (sample names)
   - Join with `all_cts_meta` via `left_join`
   - `View(all_cts_meta)` after join to confirm labels are correct

5. **Pre-QC histogram**
   - Plot `nCount_RNA` density per sample using `facet_wrap(~sample_group)`
   - Red dashed line at `nCount_RNA = 500` marks the minimum count threshold
   - Save with `ggsave()` to `scDblFinder_output/01_totalcounts_preQC_all.png`

6. **Pre-filter**
   - Remove cells with `nCount_RNA ≤ 500` before doublet scoring
   - `select <- WhichCells(all_seu, expression = nCount_RNA > 500)`
   - `all_seu <- subset(all_seu, cells = select)`

7. **Convert to SingleCellExperiment**
   - `all_sce <- as.SingleCellExperiment(all_seu)`
   - Warnings about empty `data` and `scale.data` layers are expected and harmless

8. **Score doublets**
   - `set.seed(123)` for reproducibility
   - `all_sce <- scDblFinder(all_sce, samples = "orig.ident", clusters = TRUE)`
   - `samples = "orig.ident"` scores each sample independently (correct for multi-sample objects)
   - `clusters = TRUE` pre-clusters cells to improve doublet detection sensitivity
   - Expected doublet rate: ~8–10% per sample

9. **Summarise doublet calls**
   - `db_table <- table(all_sce$scDblFinder.class, all_sce$orig.ident)`
   - `percent_db <- db_table[2,] / colSums(db_table) * 100`
   - Review per-sample doublet percentages; flag anything above 15%

10. **Convert back to Seurat**
    - `logcounts(all_sce) <- assay(all_sce, "counts")` — required placeholder for `as.Seurat()`; not true log counts
    - `all_seu <- as.Seurat(all_sce)`
    - `table(all_seu$scDblFinder.class)` to confirm singlet/doublet counts

11. **Save output**
    - `saveRDS(all_seu, "./scripts/02_scDblFinder_soupx/scDblFinder_output/iSN_doubletstep.rds")`
    - `capture.output(sessionInfo(), file = "./scripts/02_scDblFinder_soupx/scDblFinder_output/session_info.txt")`
    - Actual doublet filtering (removing doublet-labelled cells) happens in Stage 03

12. **Remind user to run `/simplify`**
    - After completing the edit, tell the user: "Run `/simplify` to check for unnecessary complexity."

13. **Remind user to run `/review`**
    - Before treating output as final, tell the user: "Run `/review` to confirm doublet rates and output format match Stage 03 expectations."
