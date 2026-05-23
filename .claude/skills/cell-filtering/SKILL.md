# Skill: Cell Filtering (Stage 03)

**Script:** `scripts/03_Cell_filtering/03_cell_filtering.R`
**Input (SoupX track):** `scripts/02_scDblFinder_soupx/scDblFinder_output/iSN_doubletstep.rds`
**Input (DecontX track):** `scripts/02.1_scDblFinder_decontX/scDblFinder_output/iSN_decontX_scDblFinder.rds`
**Output directory:** `scripts/03_Cell_filtering/Cell_filtering_output/`
**Libraries:** `Seurat`, `ggplot2`, `dplyr`, `scales`, `patchwork`

---

## Samples

| Sample | Timepoint |
|--------|-----------|
| NR00_Day13_1 | Day 13 |
| NR00_Day13_1_dup | Day 13 |
| NR00_Day13_2 | Day 13 |
| NR00_Day13_2_dup | Day 13 |
| NR00_Day7_1 | Day 7 |
| NR00_Day7_2 | Day 7 |
| NR00_iPSC_1 | iPSC |
| NR00_iPSC_2 | iPSC |

Grouping and faceting always uses `sample_group` — never `orig.ident` (which holds the numeric Cell Ranger suffix, not the human-readable sample name).

---

## Output structure

```
Cell_filtering_output/
├── soupx/
│   ├── violin_by_sample.pdf
│   ├── violin_by_doublet.pdf
│   ├── scatter_mito_vs_gene_doublet.pdf
│   ├── scatter_mito_vs_gene_sample.pdf
│   ├── scatter_mito_vs_gene_umi.pdf
│   ├── scatter_mito_vs_gene_doublet2.pdf
│   ├── scatter_count_vs_gene_mito.pdf
│   ├── scatter_count_vs_gene_doublet.pdf
│   └── overlay_pre_post_filter.pdf
├── decontx/
│   └── (same 9 PDFs)
├── 03_seu_cellfiltered_soupx.rds
├── 03_seu_cellfiltered_decontx.rds
└── 03_session_info.txt
```

---

## Steps

1. **Set working directory and create output directories**
   - Canonical header: `rm(list = ls(all.name = TRUE))`, `dir <- "..."`, `setwd(dir)`
   - `dir.create()` for `Cell_filtering_output/`, `Cell_filtering_output/soupx/`, `Cell_filtering_output/decontx/`

2. **Parse `--track` and load the matching input**
   - `args_track <- .get_arg("--track", "decontx")` — reads the CLI flag; defaults to `"decontx"`
   - Only one RDS is loaded per invocation, chosen by `args_track`:
     - SoupX: `readRDS("./scripts/02_scDblFinder_soupx/scDblFinder_output/iSN_doubletstep.rds")`
     - DecontX: `readRDS("./scripts/02.1_scDblFinder_decontX/scDblFinder_output/iSN_decontX_scDblFinder.rds")`
   - The other track's RDS is never read in the same run

3. **Calculate mitochondrial percentage**
   - `seu_soupx[["percent.mt"]]   <- PercentageFeatureSet(seu_soupx,   pattern = "^MT-")`
   - `seu_decontx[["percent.mt"]] <- PercentageFeatureSet(seu_decontx, pattern = "^MT-")`
   - Always `percent.mt` — never `percent.mito`

4. **Run the selected track's section only** — the script has two clearly marked sections (`## SoupX track ----`, `## DecontX track ----`), each guarded by `if (args_track == "soupx")` / `if (args_track == "decontx")`. Only one block executes per invocation. Nextflow calls the script twice (once per track) when `--track both` is used.

5. **Plot QC metrics (9 plots per track)**
   - `violin1` — VlnPlot of `nFeature_RNA`, `nCount_RNA`, `percent.mt`, grouped by `sample_group`
   - `violin2` — VlnPlot of the same features, grouped by `scDblFinder.class`
   - `g1` — percent.mt vs nFeature_RNA, colored by `scDblFinder.class`, faceted by `sample_group`
   - `g2` — percent.mt vs nFeature_RNA, colored by `sample_group`, faceted by `sample_group`
   - `g3` — percent.mt vs nFeature_RNA, colored by `nCount_RNA` (gold→red gradient), faceted by `sample_group`
   - `g4` — percent.mt vs nFeature_RNA, colored by `scDblFinder.class`, faceted by `sample_group` (ncol=3)
   - `g5` — nCount_RNA vs nFeature_RNA, colored by `percent.mt` (gold→red gradient), faceted by `sample_group` (ncol=3)
   - `g6` — nCount_RNA vs nFeature_RNA, colored by `scDblFinder.class`, faceted by `sample_group` (ncol=3)
   - `g_overlay` — post-filter overlay: grey = all nuclei, red = nuclei passing all filters; faceted `nrow=1`, width=14
   - Each plot is saved immediately after rendering with `ggsave()` to the appropriate track subdirectory

6. **Set QC thresholds**
   - Thresholds are **PRELIMINARY** — never hardcode without user confirmation from the plots:
     - `percent.mt <= 20` (mito filter)
     - `nFeature_RNA > N` (gene filter — user sets after inspecting violin/scatter plots)
     - `nCount_RNA > 500` (UMI filter)
     - `scDblFinder.class == 'singlet'` (doublet filter)
   - Use `WhichCells()` for each filter, then `Reduce(intersect, list(...))` to combine
   - Print `df_summary` to report per-filter cell counts and final pass_all count

7. **Subset and save**
   - `seuKeep <- subset(seu_soupx, cells = keep)` (or `seu_decontx`)
   - `counts <- seuKeep@assays$RNA@counts`
   - `seuNew <- CreateSeuratObject(counts = counts, min.cells = 1)`
   - Seurat v5→v3 shim: `seuNew[["RNA"]] <- CreateAssayObject(counts = seuNew[["RNA"]]$counts)`
   - `saveRDS(seuNew, "./scripts/03_Cell_filtering/Cell_filtering_output/03_seu_cellfiltered_{track}.rds")`

8. **Session info**
   - `capture.output(sessionInfo(), file = "./scripts/03_Cell_filtering/Cell_filtering_output/03_session_info.txt")`
   - Written once, at the very end of the script (after both tracks complete)

---

## Key conventions

- No `View()` calls — script must run non-interactively on SLURM
- All paths relative to project root (never absolute)
- `sample_group` for all grouping/faceting — not `orig.ident`
- `percent.mt` — not `percent.mito`
- Output directory: `Cell_filtering_output/` (capital C) — consistent across all `dir.create()`, `ggsave()`, `saveRDS()`, and `capture.output()` calls
- Thresholds are confirmed by user after inspecting plots — do not set them without explicit user instruction

---

## Remind user

- After any edit: "Run `/simplify` to check for unnecessary complexity."
- Before treating filtered outputs as final: "Run `/review` to confirm thresholds and output structure match Stage 04 expectations."
