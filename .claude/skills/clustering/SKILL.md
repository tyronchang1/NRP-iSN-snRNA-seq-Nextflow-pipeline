# Skill: Clustering (Stage 04)

**Script:** `scripts/04_Clustering/04_clustering.R`
**Rmd report:** `scripts/04_Clustering/04_clustering.Rmd`
**Input:** `scripts/03_Cell_filtering/Cell_filtering_output/03_seu_cellfiltered_{track}.rds`
**Output directory:** `scripts/04_Clustering/clustering_output/`
**CLI args:** `--gene_sets`, `--track`, `--project_root`, `--seed`
**Libraries:** `ggplot2`, `multtest`, `presto`, `dplyr`, `scales`, `AUCell`, `miloR`, `glmGamPoi`, `future`, `Seurat`, `harmony`, `tidyr`, `SingleCellExperiment`, `patchwork`, `ggrepel`, `Matrix`, `RSpectra`, `viridis`, `pheatmap`, `tictoc`, `scCustomize`

---

## Samples

| Sample | Timepoint | orig.ident (Harmony batch) |
|--------|-----------|---------------------------|
| NR00_Day13_1 | Day13 | NR00_Day13_1 |
| NR00_Day13_1_dup | Day13 | NR00_Day13_1 |
| NR00_Day13_2 | Day13 | NR00_Day13_2 |
| NR00_Day13_2_dup | Day13 | NR00_Day13_2 |
| NR00_Day7_1 | Day7 | NR00_Day7_1 |
| NR00_Day7_2 | Day7 | NR00_Day7_2 |
| NR00_iPSC_1 | iPSC | NR00_iPSC_1 |
| NR00_iPSC_2 | iPSC | NR00_iPSC_2 |

`orig.ident` is derived by stripping the `_dup` suffix from `sample_group`.
`sample` is the timepoint label (Day7 / Day13 / iPSC) used for coloring.

---

## Fixed parameters

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| `nf` (nfeatures) | 10000 | More variable features capture rare subtype genes; confirmed by elbow/clustering inspection |
| `dims` | 1:80 | Manual SVD PCA with k=80; keeps all biologically meaningful PCs |
| Primary resolution | 0.2 | Biologically validated for this dataset (15 clusters at harmony_res.0.2) |
| Resolutions computed | 0.2, 0.3, 0.5, 0.6, 0.8 | All stored in metadata; only 0.2 is primary |
| Batch correction | Harmony on `orig.ident` | Per-individual-sample batches; `_dup` replicates batched with their parent |
| PCA method | Manual SVD via `RSpectra::svds` | Faster and more memory-efficient than Seurat's `RunPCA` for 10k features × 65k cells |
| scSHC | Disabled | OOM on 65k cells (>200 GB); `scshc_clusters` column never created |
| JackStraw | Disabled | Parameters fixed; use elbow plot only |
| FindConservedMarkers | Disabled | `metap` package unavailable (`qqconf` dependency missing) |

---

## Output structure

```
clustering_output/
├── decontx/                            (all PDFs/CSVs for decontx run)
│   ├── nfeatures_10000/
│   │   ├── elbow_plot.pdf
│   │   ├── dimplot_pca_nf10000.pdf
│   │   └── dimplot_harmony_nf10000.pdf
│   ├── aucell/
│   │   ├── aucell_thresholds_cellcycle.pdf
│   │   ├── aucell_thresholds_g2m.pdf
│   │   ├── aucell_cellcycle_umap.pdf
│   │   ├── aucell_g2m_umap.pdf
│   │   ├── aucell_cellcycle_cluster_barchart.pdf
│   │   ├── aucell_g2m_cluster_barchart.pdf
│   │   ├── aucell_cellcycle_sample_barchart.pdf
│   │   └── aucell_g2m_sample_barchart.pdf
│   ├── featureplot_markers_pca.pdf
│   ├── featureplot_markers_harmony.pdf
│   ├── dotplot_isN_markers.pdf
│   ├── featureplot_g2m_genes.pdf
│   ├── featureplot_module_scores.pdf
│   ├── module_score_{name}_umap.pdf
│   ├── module_score_{name}_violin.pdf
│   ├── violin_{gene}.pdf
│   ├── piechart_by_sample.pdf
│   ├── 04_all_markers_harmony_res0.2.csv
│   ├── 04_heatmap_top5_markers.pdf
│   └── 04_session_info.txt
├── soupx/                              (same structure, populated on soupx run)
├── 04_seu_clustered_decontx.rds        (top-level; track-suffixed, no overwrite risk)
├── 04_seu_clustered_soupx.rds          (top-level; track-suffixed, no overwrite risk)
└── 04_clustering_report_{track}.html   (top-level; track-suffixed by Nextflow)
```

---

## Steps

### 1. Setup and input

- `rm(list = ls(all.name = TRUE))`, `setwd(dir)`, `pdf(NULL)`
- `plan("multisession", workers = 4)` + `options(future.globals.maxSize = 30000 * 1024^2, future.seed = TRUE)`
- Parse `--gene_sets` (wire format: `"name=G1,G2;name2=G3"`) and `--track` from `commandArgs(trailingOnly = TRUE)`
- Load: `seu <- readRDS(.../03_seu_cellfiltered_{track}.rds)`
- Derive metadata columns:
  - `orig.ident` ← strip `_dup` from `sample_group` via `regexpr("NR00_(iPSC|Day7|Day13)_[0-9]", ...)`
  - `sample` ← extract timepoint via `regexpr("Day7|Day13|iPSC", ...)`
- Convert RNA assay to Assay5 → JoinLayers → split by `orig.ident`

### 2. Normalization

- `NormalizeData(seu, normalization.method = "LogNormalize", scale.factor = 1e4)`

### 3. Variable features, scaling, and PCA

- `FindVariableFeatures(seu, nfeatures = 10000)`
- `ScaleData(seu, features = VariableFeatures(seu))`
- **Manual SVD PCA** (do not use `RunPCA`):
  - Extract scale.data, transpose, center
  - `RSpectra::svds(X, k = 80)` → embeddings, loadings, sdev
  - `CreateDimReducObject(...)` → `seu[["pca"]]`
- Elbow plot saved to `nfeatures_10000/elbow_plot.pdf`
- `DefaultLayer(seu[["RNA"]]) <- "scale.data"` after PCA

### 4. UMAP on PCA

- `RunUMAP(reduction = "pca", reduction.name = "umap.pca", dims = 1:80, umap.method = "uwot", metric = "cosine")`

### 5. Harmony batch correction

- `RunHarmony(group.by.vars = "orig.ident", reduction = "pca", reduction.save = "harmony")`
- Batches on `orig.ident` (individual sample IDs), NOT `sample` (timepoint)

### 6. UMAP on Harmony

- `RunUMAP(reduction = "harmony", reduction.name = "umap.harmony", dims = 1:80, umap.method = "uwot", metric = "cosine")`

### 7. Clustering (both PCA and Harmony)

- `FindNeighbors(reduction = "pca", dims = 1:80)` → `FindClusters(resolution = c(0.2, 0.3, 0.5, 0.6, 0.8))`
- Rename columns: `RNA_snn_res.{r}` → `pca_res.{r}`
- `FindNeighbors(reduction = "harmony", dims = 1:80)` → `FindClusters(resolution = ...)`
- Rename columns: `RNA_snn_res.{r}` → `harmony_res.{r}`
- `JoinLayers` after clustering (required by AUCell, FindAllMarkers)

### 8. DimPlots

- PCA UMAP: patchwork of `pca_res.0.2 | sample` → `nfeatures_10000/dimplot_pca_nf10000.pdf`
- Harmony UMAP: patchwork of `harmony_res.0.2 | sample` → `nfeatures_10000/dimplot_harmony_nf10000.pdf`
- All DimPlots use `geom_text_repel` for cluster/sample labels (no Seurat default labels)
- UMAP axes fixed to `(-16, 16)` with breaks every 4 units

### 9. AUCell (cell cycle and G2M)

- Gene sets: `cellcycle_genes` (6 genes: TOP2A, MCM2–6, MKI67) and `g2m.genes` (70 genes)
- `aucMaxRank = 20000` for both
- Outputs per gene set: threshold histogram, UMAP scatter (all/passing/failing), cluster barchart with Fisher's test stars, timepoint barchart
- AUCell helper functions: `plot_aucell_simple()` and `plot_aucell_cluster_counts()` and `make_aucell_timepoint_barchart()`

### 10. iSN marker FeaturePlots + DotPlot

- `isN_markers`: TUBB3, PRPH, SNAP25, CALCA, TRPV1, MRGPRD, NTRK2, NTRK3, POU5F1, SOX2, NANOG
- FeaturePlot on `umap.pca` and `umap.harmony` (ncol=4, viridis plasma)
- DotPlot grouped by `harmony_res.0.2`, red gradient with `squish` at limits `(-1, 3)`

### 11. Module scores (Section 8 — hardcoded iSN gene sets)

Wrapped in `safe_module_score()` (tryCatch — skips silently if no features present):

| Score column | Genes |
|---|---|
| `pan_neuronal_score1` | TUBB3, MAP2, RBFOX3, SNAP25 |
| `peptidergic_score1` | CALCA, TRPV1, TAC1, NTRK1 |
| `cLTMR_score1` | TH, CDH9 |
| `Cold_score1` | TRPM8 |
| `SN_score1` | AR, C3 |
| `non_peptidergic_score1` | MRGPRD |
| `trkbc_score1` | NTRK2, NTRK3 |
| `ipsc_score1` | POU5F1, SOX2, NANOG |
| `G2M_proliferation_score1` | MCM2–6, MKI67, TOP2A |

- `score_features <- intersect(c(...), colnames(seu@meta.data))` before FeaturePlot
- FeaturePlot on `umap.harmony` with `min.cutoff = "q05"`, `max.cutoff = "q95"`

### 12. User-specified gene set module scores (Section 8.1)

- Parsed from `--gene_sets` CLI arg (wire format: `"name=G1,G2;name2=G3"`)
- For each gene set: `AddModuleScore` wrapped in tryCatch (`NULL` sentinel → `next` on failure)
- Column renamed from `score_{name}1` → `score_{name}`
- Outputs: `module_score_{name}_umap.pdf` and `module_score_{name}_violin.pdf`

### 13. Violin plots (Section 9)

- `violin_genes`: TUBB3, PRPH, SNAP25, CALCA, TRPV1, MRGPRD, NTRK2, NTRK3, POU5F1, SOX2, NANOG, MKI67, TOP2A, MCM2
- **Must filter before loop**: `violin_genes_present <- intersect(violin_genes, rownames(seu[["RNA"]]))`
- `FetchData(seu, vars = c(gene, "harmony_res.0.2"))` — `colnames(df_vln)[1] <- "expr"` only safe when gene is present
- IQR-style summary: `stat_summary(fun.data = iqr_summary, geom = "crossbar")` with `scale_fill_brewer("Set3")`

### 14. Pie chart (Section 10)

- Grouped by `sample` (Day7 / Day13 / iPSC) with percentage labels
- Colors: iPSC = "#F5A623", Day7 = "#D73027", Day13 = "#4E8FCA"

### 15. FindAllMarkers + DoHeatmap (Section 11)

- `FindAllMarkers(only.pos = TRUE, min.pct = 0.1, logfc.threshold = 1)`
- CSV saved: `04_all_markers_harmony_res0.2.csv`
- DoHeatmap: top 5 by `avg_log2FC` per cluster, downsampled to 100 cells, `raster = TRUE`

### 16. Save object + session info (Section 13)

- `saveRDS(seu, .../04_seu_clustered_{track}.rds)` — final pipeline output
- `capture.output(sessionInfo(), file = .../04_session_info.txt)`

---

## Key conventions

- No `View()` calls — script runs non-interactively on SLURM
- All paths relative to project root (set via `setwd(dir)`)
- `sample_group` identifies individual samples; `sample` is the timepoint; `orig.ident` is the Harmony batch variable
- **Harmony batches on `orig.ident`**, not `sample_group` — `_dup` replicates are batched together with their parent sample
- `harmony_res.0.2` is the primary cluster column for all downstream plots
- `safe_module_score()` wraps every `AddModuleScore` call — never call `AddModuleScore` directly
- Violin loop must always use `intersect()` to filter `violin_genes` against `rownames(seu[["RNA"]])`
- scSHC, JackStraw, and FindConservedMarkers are disabled — do not re-enable without checking OOM limits and package availability
- `timepoint_colors`: Day13 = "#4E8FCA", Day7 = "#D73027", iPSC = "#F5A623"
- `aucMaxRank = 20000` (not the AUCell default) — set to capture full transcriptome ranking for sparse nuclei data

---

## Disabled sections (do not re-enable without user confirmation)

| Section | Status | Reason |
|---------|--------|--------|
| scSHC (Section 3.5) | Commented out | OOM: requires >200 GB on 65k cells |
| JackStraw (Section 4) | Commented out | Parameters fixed; elbow plot is sufficient |
| FindConservedMarkers (Section 12) | Commented out | `metap` package unavailable; `qqconf` dependency missing on cluster R binary |

---

## Remind user

- After any edit: spawn `script-review-agent` per the auto-review rule in CLAUDE.md before reporting done.
- Before treating clustered output as final: "Run `/review` to confirm cluster count, resolution, and output structure."
- If re-enabling scSHC: check available memory on target node — requires >200 GB.
