# Skill: Ambient RNA Removal (SoupX · DecontX)

Two parallel tracks for ambient RNA removal. Track is selected at pipeline launch via `--track soupx` or `--track decontx`.

---

## Track 01 — SoupX

**Stage:** 01
**Script:** `scripts/01_SoupX/SoupX_{SAMPLE}.R` (one script per sample)
**Samples:** NR00_Day13_1, NR00_Day13_1_dup, NR00_Day13_2, NR00_Day13_2_dup, NR00_Day7_1, NR00_Day7_2, NR00_iPSC_1, NR00_iPSC_2
**Output directory:** `scripts/01_SoupX/SoupX_dir_out/{SAMPLE}Counts/`
**Libraries:** `SoupX`, `ggplot2`, `DropletUtils`, `cowplot`

### Steps

1. **Set working directory**
   - Set `dir` to the project root and call `setwd(dir)`
   - Clear environment with `rm(list = ls())` before loading each sample

2. **Load 10X data**
   - Use `load10X('<cellranger_outs_path>')` to create the SoupChannel object (`sc`)
   - Inspect with `typeof(sc)`, `print(sc)`, `str(sc)`

3. **Extract metadata and tSNE coordinates**
   - `sc_metadata <- sc$metaData`
   - Compute cluster label midpoints: `aggregate(cbind(tSNE1, tSNE2) ~ clusters, data = dd, FUN = mean)`

4. **Visualize clusters**
   - Plot all clusters on tSNE coloured by cluster identity using `ggplot2`
   - Title format: `"{SAMPLE} study pre-Soup"`

5. **Plot iSN marker genes**
   - For each marker (`TUBB3`, `PRPH`, `NTRK2`, `CALCA`):
     - Extract expression: `dd${MARKER} = sc$toc["{MARKER}", ]`
     - Scatter plot: `ggplot(dd, aes(tSNE1, tSNE2)) + geom_point(aes(colour = {MARKER} > 0))`
     - Marker map: `plotMarkerMap(sc, "{MARKER}")`
   - **For `NR00_iPSC_1` only** — also plot iPSC pluripotency markers (`POU5F1`, `SOX2`, `NANOG`)

6. **Estimate contamination**
   - `sc <- autoEstCont(sc)`
   - Expected output: `Estimated global rho of 0.01` (flag if rho > 0.05)

7. **Apply correction**
   - `out_{SAMPLE} <- adjustCounts(sc, roundToInt = TRUE)`

8. **Validate correction**
   - Plot before/after for each marker with `plotChangeMap(sc, out_{SAMPLE}, "{MARKER}")`
   - Combine plots with `plot_grid()`

9. **Check most-zeroed genes**
   - `cntSoggy = rowSums(sc$toc > 0)`
   - `cntStrained = rowSums(out_{SAMPLE} > 0)`
   - `mostZeroed = tail(sort((cntSoggy - cntStrained) / cntSoggy), n = 10)`

10. **Check highest soup-fraction genes**
    - `tail(sort(rowSums(sc$toc > out_{SAMPLE}) / rowSums(sc$toc > 0)), n = 20)`
    - Genes with fraction = 1.0 are pure ambient artifacts

11. **Write corrected counts**
    - `DropletUtils:::write10xCounts("./scripts/01_SoupX/SoupX_dir_out/{SAMPLE}Counts", out_{SAMPLE})`

---

## Track 01.2 — DecontX

**Stage:** 01.2
**Script:** `scripts/01.2_DecontX/01.2_DecontX.R` (single script — all 8 samples at once)
**Output directory:** `scripts/01.2_DecontX/DecontX_out/`
**Libraries:** `celda`, `scater`, `Seurat`, `ggplot2`, `patchwork`, `SingleCellExperiment`, `dplyr`

### Key difference from SoupX
DecontX processes all 8 samples in a single script and uses the raw (unfiltered) Cell Ranger matrix as a contamination background. It outputs per-cell contamination scores (`decontX_contamination`) alongside corrected counts (`decontXcounts`), rather than per-sample corrected count matrices.

### Steps

1. **Load filtered counts for all 8 samples**
   - `Read10X(filtered_dirs)` → `CreateSeuratObject()` → convert to `SingleCellExperiment`
   - Expected: 80,645 cells × 36,601 genes

2. **Load raw counts as background**
   - `Read10X(raw_dirs)` → `CreateSeuratObject()` → subset to genes present in filtered data
   - Expected: ~6.3M barcodes (empty droplets included)

3. **Run decontX with background**
   - `sce_decont_with_raw <- decontX(sce, background = sce_raw)`
   - Pull results into Seurat: `seu$decontX_contamination`, `seu$decontX_clusters`

4. **Check contamination distribution**
   - `summary(seu$decontX_contamination)`
   - Flag: `table(seu$decontX_contamination > 0.5)` — cells >50% contaminated
   - Flag: `table(seu$decontX_contamination > 0.8)` — cells >80% contaminated

5. **Assign sample group labels**
   - Map `orig.ident` (1–8) to NR00 sample names via `sample_mapping` data frame
   - `add_sample_group()` function applied to both `seu_decont` and `seu_decont_with_raw`

6. **Create clean decontX Seurat object**
   - `seu_decont <- CreateSeuratObject(counts = decontXcounts(sce_decont_with_raw))`
   - Merge metadata from `seu_decont_with_raw` (contamination scores, clusters, UMAP coords)

7. **Visualize contamination**
   - `plotDecontXContamination(sce_decont_with_raw)` — contamination UMAP
   - `VlnPlot()` — nCount_RNA vs nCount_originalexp per cluster
   - `plotDimReduceCluster()` — decontX UMAP with cluster labels

8. **Plot iSN marker genes (raw vs decontX counts)**
   - Markers: `TUBB3`, `PRPH`, `NTRK2`, `NTRK3`, `CALCA`, `TRPV1`, `MRGPRD`, `POU5F1`, `SOX2`, `NANOG`, `SNAP25`, `MAP2`
   - For each: UMAP coloured by `log2(expression + 1)`, raw counts panel (`originalexp`) vs decontX counts panel
   - Marker groups: PanNeuronal, Peptidergic, NonPeptidergic, TrkB/TrkC, iPSC

9. **Marker percentage and expression plots**
   - `plotDecontXMarkerPercentage()` — % cells expressing each marker, raw vs decontXcounts
   - `plotDecontXMarkerExpression()` — violin plots for counts and lognorm assays
   - Separate plots for SN markers and iPSC markers

10. **Save outputs**
    - `01_contamination_UMAP.png`, `02_nCount_violin.png`
    - `03_markers_raw.png`, `04_markers_decontX.png`
    - `05_marker_percentage.png`
    - `06_marker_expression_counts.png`, `07_marker_expression_lognorm.png`
    - `08_SN_marker_expression_counts.png`, `09_iPSC_marker_expression_counts.png`
    - `10_SN_marker_expression_lognorm.png`, `11_iPSC_marker_expression_lognorm.png`
    - `iSN_decontX.rds` — final decontX Seurat object passed to Stage 02.1
    - `session_info.txt`
