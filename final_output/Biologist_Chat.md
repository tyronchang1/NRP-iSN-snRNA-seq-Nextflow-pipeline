# Biologist Chat Log — iSN snRNA-seq Pipeline (DecontX track)

---

## Stage 01.2 — Ambient RNA Removal: DecontX (2026-05-21)

### Parameters reviewed

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Ambient RNA method | DecontX | Chosen over SoupX for this run; DecontX uses a Bayesian model on the ambient RNA profile estimated per cluster, appropriate for nuclear preparations where SoupX soup estimation can be less stable |
| Contamination score threshold | Not applied as hard filter | DecontX scores are used for QC visualization only; counts are corrected in-place; nuclei with high scores are retained and may be re-examined at Stage 03 |

### Findings

| Metric / plot | Flag | Notes |
|---------------|------|-------|
| Per-sample nucleus count post-DecontX | [OK] | Total 80,645 nuclei across 8 samples: Day13 (27,084), Day7 (22,013), iPSC (30,548). Counts are consistent with expected 10x recovery per timepoint |
| Contamination score >0.5 — Day13 samples | [ASK] | NR00_Day13_1: 18.0%, NR00_Day13_1_dup: 18.3%, NR00_Day13_2: 15.0%, NR00_Day13_2_dup: 22.8%. Day13 has consistently higher contamination fractions than Day7 or iPSC, which returned no values >0.5 in the report. Day13 iSN cultures contain a mixture of neurons and non-neuronal cells at varying maturity, which can produce higher ambient RNA loads. However, NR00_Day13_2_dup at 22.8% is the highest recorded. This is not immediately disqualifying but warrants attention — clusters from Day13_2_dup should be examined for marker gene contamination artifacts |
| Contamination score >0.5 — Day7 and iPSC | [OK] | No values reported (implying <15% or below reporting threshold); consistent with less-differentiated but more homogeneous cultures generating less ambient RNA |
| Marker gene expression pre- vs post-DecontX | [OK] | DecontX marker plots embedded in report; ambient RNA correction expected to reduce bleed-in of iPSC markers (POU5F1, SOX2) into neuronal clusters |

### User decision

Proceeding. The Day13_2_dup contamination score of 22.8% is noted for follow-up at annotation stage. No hard filter applied on DecontX score.

---

## Stage 02.1 — Doublet Removal: scDblFinder (DecontX track) (2026-05-21)

### Parameters reviewed

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Doublet scoring method | scDblFinder per sample_group | Correct: scDblFinder runs per-sample on the merged object using the `sample_group` column, so each sample's doublet rate is computed on its own expected multiplet frequency |
| nCount_RNA pre-filter in Stage 02.1 | >500 UMI | Applied BEFORE doublet scoring; removes very-low-count barcodes that scDblFinder cannot score reliably |
| Flag threshold | >15% per sample | Per BIOLOGIST definition |

### Findings

| Metric / plot | Flag | Notes |
|---------------|------|-------|
| Pre-filter nCount>500 removes 5,450 nuclei | [ASK] | This filter runs inside Stage 02.1, not Stage 03. It removes 13.0–18.8% of Day13 nuclei and 6.1–6.7% of Day7 nuclei, but 0% of iPSC nuclei. The disproportionate impact on Day13 is biologically plausible — maturing neurons may have lower ambient-corrected counts than proliferating iPSCs — but it also means Day13 cells are more aggressively pre-filtered before doublet scoring. This is not double-counted in Stage 03 because Stage 03 loads the post-Stage-02.1 object. However, the final_report pipeline summary attributes all 13,935 removed nuclei to "Stage 02 — Doublet Removal," obscuring the fact that 5,450 of those are a QC pre-filter, not doublets. Recommend labeling these separately in a future report |
| Day13 doublet rates (calculated) | [OK] | NR00_Day13_1: 6.1%, NR00_Day13_1_dup: 7.8%, NR00_Day13_2: 7.3%, NR00_Day13_2_dup: 8.0%. These are within or below the expected 8–10% range. Day13 samples appear to have lower doublet rates than Day7/iPSC — consistent with lower total cell density at harvest |
| Day7 doublet rates | [OK] | NR00_Day7_1: 11.8%, NR00_Day7_2: 13.1%. Within acceptable range. Approaching the 15% flag threshold, likely reflecting higher cell density in Day7 cultures |
| iPSC doublet rates | [OK] | NR00_iPSC_1: 13.5%, NR00_iPSC_2: 13.8%. Highest of all timepoints, below 15% flag threshold. iPSC cultures are the most proliferative and densely plated, so elevated doublet rates are expected |
| Overall doublet rate | [OK] | 11.3% overall across 75,195 nuclei. Within expected range for a mixed-timepoint, high-density 10x library |
| No samples exceed 15% threshold | [OK] | Report confirms this explicitly |

### User decision

Proceeding. Stage 02.1 nCount>500 pre-filter noted as a reporting clarity issue — not a biological problem. Day13 sample loss at this step is biologically plausible.

---

## Stage 03 — Cell Filtering (DecontX track) (2026-05-21)

### Parameters reviewed

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| nFeature_RNA threshold (DecontX) | >800 genes | Higher than the SoupX track threshold of 700. For snRNA-seq, nuclei typically express 1,000–4,000 genes in mature iSNs. A minimum of 800 excludes very-low-complexity barcodes (debris, empty droplets that escaped ambient filtering) while retaining the lower tail of genuine nuclei. DecontX may further reduce apparent gene counts in some nuclei after ambient correction, so 800 is more conservative than 700 |
| nCount_RNA threshold | >500 UMI | Conservative lower bound. For snRNA-seq (nuclei), UMI counts are lower than whole-cell protocols; 500 captures most genuine nuclear captures while excluding empty droplets |
| percent.mt threshold | <=20% | Standard for snRNA-seq. Nuclear preparations should have low mitochondrial content because mitochondria are cytoplasmic and not efficiently captured in nuclear isolation. Values >20% after ambient correction indicate rupture or low-quality nuclei |
| Singlets only | scDblFinder.class == 'singlet' | Doublets identified in Stage 02.1 are removed here |

### Findings

| Metric / plot | Flag | Notes |
|---------------|------|-------|
| nFeature_RNA filter impact | [OK] | Only 15 nuclei (75,195 → 75,180) removed by nFeature_RNA >800 filter. This is extremely low and suggests the distribution peak sits well above 800; the threshold is not cutting into a major population. However, because only 15 nuclei were removed, there is no strong evidence the threshold is optimally placed — it may be set conservatively below a natural valley |
| nCount_RNA filter impact | [OK] | Zero nuclei removed by nCount>500 filter at Stage 03. This is expected because Stage 02.1 already pre-filtered on this criterion |
| percent.mt filter impact | [OK] | 1,488 nuclei (75,195 → 73,707) removed by percent.mt <=20%. 2.0% removal is modest and consistent with nuclear isolation: most nuclei should have low mitochondrial content; the minority exceeding 20% are damaged or represent cytoplasmic contamination |
| Singlet filter impact | [OK] | 8,485 doublets removed (66,710 singlets retained from 75,195). Consistent with the doublet rates in Stage 02.1 |
| Total nuclei retained | [OK] | 65,235 nuclei pass all filters from 75,195 input (13.2% removed total). Acceptable. No single filter dominates |
| Stage 03 filter summary vs pipeline summary | [ASK] | The pipeline summary states 9,960 cells removed in Stage 03 (75,195 → 65,235). However, the Stage 03 filter table shows: percent.mt removes 1,488, nFeature removes 15, nCount removes 0, singlets removes 8,485. These four filters applied as intersection (Reduce(intersect)) mean 9,960 ≠ sum of individual filters due to overlap. This is expected behavior from set intersection — not a bug — but the pipeline summary caption "Nuclei removed by QC filtering" does not clarify that doublet removal is included. A future report should show doublet removal separately from QC metric filtering for interpretability |

### User decision

Proceeding. Filter thresholds are biologically appropriate. The nFeature_RNA >800 threshold removed only 15 nuclei — this is worth examining in the next run to ensure the distribution is not accumulating just below 800.

---

## Stage 04 — Clustering: Harmony + Louvain (2026-05-21)

### Parameters reviewed

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| nfeatures (variable genes) | 10,000 | High number of variable features used for PCA. Standard Seurat pipelines use 2,000–5,000. Using 10,000 captures more biology-relevant variance across highly heterogeneous samples (iPSC, Day7, Day13 span a wide developmental trajectory) but increases compute load and the risk of including technical noise genes. Justified here because cross-timepoint integration requires resolving developmentally distinct populations |
| PCA dimensions used | 80 | All 80 SVD components used for both UMAP and neighbor graph construction. For a 65k-cell dataset spanning 3 developmental timepoints, using all 80 PCs retains fine-grained variance. The elbow plot should be consulted to confirm whether informative PCs plateau before 80; using excess PCs adds noise but is typically less harmful than underdimensioning for Harmony integration |
| Harmony batch variable | orig.ident (per-sample) | Correct: Harmony corrects by individual sample (8 samples), not by timepoint. Using timepoint as the batch variable would over-correct and collapse biologically meaningful differences between Day7, Day13, and iPSC |
| Clustering reduction | Harmony embedding | Correct: clusters are built from Harmony-corrected space, not raw PCA. This ensures sample mixing informs the neighbor graph |
| Resolution sweep | 0.2, 0.3, 0.5, 0.6, 0.8 (PCA); 0.2, 0.3, 0.5, 0.6, 0.8 (Harmony) | Multiple resolutions explored; primary analysis uses harmony_res.0.2 |
| Harmony clusters at res=0.2 | 15 communities | Louvain on Harmony graph at res=0.2. NOTE: the spawn prompt stated "25 clusters" — this was the PCA resolution=0.8 result (25 communities). The Harmony resolution=0.2 result, which is the primary analysis and the source of the FindAllMarkers CSV, produced 15 clusters (0–14) |
| PCA clusters at res=0.2 | 17 communities | For reference; not used as primary analysis |

### Findings

| Metric / plot | Flag | Notes |
|---------------|------|-------|
| Cluster count: 15 at harmony_res.0.2 | [OK] | For a dataset spanning iPSC, Day7, and Day13 developmental stages with 65,235 nuclei, 15 clusters is biologically reasonable at a conservative resolution. It is not overclustered: all 15 clusters have hundreds of distinguishing marker genes (605–1,797 per cluster in the FindAllMarkers output) indicating each cluster has a distinct transcriptional identity |
| Cluster 0 — iPSC identity confirmed | [OK] | Top markers: AC022140.1, TDGF1, POU5F1, ESRG, GAL. POU5F1 (OCT4) is the canonical iPSC marker. TDGF1 (Cripto/TDGF1) and NANOG also appear in top 50 markers. This cluster is an iPSC/pluripotent population |
| Cluster 4 — iPSC identity | [OK] | Top markers: MAL2, NANOG, RIDA, PIM2; POU5F1 appears as a top marker. A second iPSC-enriched cluster; may represent a distinct iPSC state (e.g., naive vs primed) or actively cycling iPSCs |
| Cluster 5 — iPSC identity | [OK] | Top markers: POU5F1, TDGF1, GAL, SFRP2, EPCAM; SOX2 and NANOG also present. Third iPSC-enriched cluster. Having 3 iPSC-enriched clusters (0, 4, 5) from iPSC samples is expected given iPSC samples represent the largest timepoint group (25,072 nuclei) |
| iPSC markers absent from Day13-specific clusters | [ASK] | Cannot confirm from marker data alone without UMAP colored by sample_group. Clusters 3, 6, 11, 12, 14 show neuronal markers (NTRK2, TUBB3, MAP2, PRPH) and are likely Day13-enriched. Clusters 0, 4, 5 show iPSC markers. Whether iPSC markers bleed into neuronal clusters requires inspection of the UMAP + DotPlot outputs that are rendered as images in the report. Marker gene data from FindAllMarkers shows iPSC markers (POU5F1, SOX2, NANOG) are NOT top markers in any of the neuronal clusters (3, 6, 11, 12, 14) — this is reassuring |
| Pan-neuronal markers present | [OK] | TUBB3 is a top marker in clusters 1, 7, and 12 (pct.1 = 0.99–1.00 in clusters 7 and 12). PRPH appears as a top marker in clusters 3, 6, 10, 11, 12, 14. SNAP25 is a top marker in clusters 1, 3, 8, 12, and 14. Pan-neuronal markers are present and well-expressed — confirming successful neuronal differentiation |
| Mature neuron markers present | [OK] | MAP2 is a top marker in clusters 3, 6, 12, 14 (pct.1 = 0.76–1.00). RBFOX3 appears in clusters 1 and 3. Mature neuronal identity is present in multiple clusters |
| Neuronal progenitor/intermediate markers | [OK] | ISL1 (sensory neuron TF), NEUROD1, and NEUROG1 are top markers in clusters 1, 7, and 8. These likely represent intermediate differentiation states between iPSC and mature iSN — biologically expected in Day7 samples |
| TrkB/TrkC markers present | [OK] | NTRK2 is a highly ranked marker in clusters 3, 11, and 14 (log2FC 2.06–5.83; pct.1 0.65–0.78). NTRK3 also present in clusters 3, 11, and 14. These clusters likely represent TrkB/TrkC-expressing iSN subtypes — consistent with CONTEXT.md expectation |
| Peptidergic markers (CALCA, TRPV1) | [ASK] | Neither CALCA nor TRPV1 appears as a top distinguishing marker for any cluster in FindAllMarkers output. This does not mean they are absent — FindAllMarkers uses a logFC cutoff and only lists significant top markers per cluster. Peptidergic iSN subtype is expected to be present but may represent a small subpopulation not reaching top-marker status. This should be verified by inspecting the DotPlot (dotplot_isN_markers.pdf) and the violin plots (violin_CALCA.pdf, violin_TRPV1.pdf) rendered in the report. Cannot confirm or deny from text data alone |
| Non-peptidergic marker (MRGPRD) | [OK] | MRGPRD was correctly noted as "not in object" and skipped. This is biologically expected: MRGPRD marks mature non-peptidergic nociceptors in adult DRG; iSNs at Day13 may not yet express this marker at detectable levels. Absence is not a red flag |
| Cluster 2 — stromal/fibroblast identity | [FLAG] | Top markers: COL12A1, COL5A1, SEMA3C, AHNAK, COL3A1. This is a collagen-rich gene signature consistent with fibroblasts or stromal cells, not neurons. These cells should not be present in a pure iSN culture. Possible explanations: (1) contaminating fibroblasts or feeder cells from the differentiation protocol; (2) a subset of neural crest-derived non-neuronal cells; (3) a technical artifact (ambient RNA from connective tissue). This cluster should be examined on the UMAP for sample_group distribution — if it is predominantly one sample, it may be a protocol artifact |
| Cluster 9 — unknown identity | [ASK] | Top markers: AC084816.1 (lncRNA), LHX1, DSCAM, CER1. LHX1 is a LIM homeobox TF expressed in spinal interneurons and kidney; CER1 (Cerberus 1) is a Wnt/BMP antagonist expressed in early mesoderm/endoderm. This cluster has an unusual gene signature — not recognizably neuronal or iPSC. Its biological identity is unclear. Needs UMAP context to determine sample_group composition and location |
| Cluster 10 — non-neuronal support cell | [ASK] | Top markers: CXCL14, IGFBP5, COL3A1, IGFBP7, NPPB. CXCL14 and IGFBP markers are associated with stromal/mesenchymal populations. PRPH appears as a lower-ranked marker. May represent a mixed or transitional population. Needs UMAP inspection |
| Cluster 13 — unusual signature | [FLAG] | Top markers: VGLL1 (pct.1=0.20, very low), TNNT2 (cardiac troponin T), XAGE2, MYL4 (myosin light chain 4). TNNT2 and MYL4 are cardiac muscle genes. pct.1=0.20 for the top marker indicates this is a very small or heterogeneous cluster. Cardiac-lineage contamination in an iSN culture would be highly unusual. More likely explanations: (a) a very small cluster of ambiguous doublets that escaped removal; (b) cells from a cardiomyocyte-like fate acquired during early differentiation; (c) ambient RNA contamination signature. This cluster needs urgent UMAP inspection |
| Cluster 7 — neuronal progenitor with SOX10 | [OK] | Top markers: INSM1, NEUROG1, NHLH1, NEUROD1, SIX1; SOX10 also present. SOX10 marks neural crest cells and Schwann cell precursors. This cluster may represent sensory neuron progenitors at an intermediate neural crest stage — appropriate for Day7 cultures. ISL1 also appears |
| Cluster 6 — mature neuron | [OK] | Top markers: MYT1L, MAP2, GRIA4, SEMA6D. MAP2 pct.1=0.93 indicates broad mature neuron identity. GRIA4 (AMPA receptor) suggests excitatory neuron character, but in DRG context may reflect synaptic gene expression in mature sensory neurons |
| AUCell cell cycle activity | [OK] | AUCell cell cycle and G2M gene set modules computed and saved; no anomalous output noted in report text. Cycling cells (G2M-positive) expected mainly in iPSC clusters |
| Module scores (pan_neuronal, peptidergic, trkbc) | [OK] | Module score outputs confirmed saved (UMAP and violin PDFs present in output dir). Text data does not report numerical scores but PDF outputs exist |
| Sample composition piechart | [OK] | Piechart by sample saved (piechart_by_sample.pdf). Text data confirms per-sample nucleus counts are consistent from Stage 03 input to Stage 04 output (no nuclei lost in clustering) |
| scSHC disabled (OOM on 65k cells) | [OK] | scSHC cluster validation was commented out due to out-of-memory on 65,235 cells. This is expected — scSHC has quadratic memory complexity. No impact on clustering results; Louvain clustering on Harmony graph is the operative result |
| Spawn prompt stated "25 clusters" — actual harmony_res.0.2 result is 15 | [FLAG] | The 25-cluster figure in the spawn prompt appears to refer to PCA reduction at resolution 0.8 (confirmed from .command.out: PCA r=0.8 gave 25 communities, Harmony r=0.8 also gave 25 communities). The primary analysis uses harmony_res.0.2 = 15 clusters, which is what FindAllMarkers and all DotPlot/violin outputs use. This is a documentation inconsistency in the spawn prompt, not a pipeline error. Clarify in STATUS.md for future sessions |

### User decision

Proceeding. Two clusters require visual follow-up: Cluster 2 (collagen/fibroblast) and Cluster 13 (cardiac-like signature). Cluster 9 identity is unclear. Peptidergic markers (CALCA, TRPV1) could not be confirmed from FindAllMarkers text data alone — violin plots should be reviewed.

---

## Parameter recommendations — 2026-05-21

| Parameter | Current value | Recommended value | What the plot showed | Biological reason |
|-----------|--------------|-------------------|----------------------|-------------------|
| nFeature_RNA threshold (DecontX track, Stage 03) | >800 | Keep at >800 but verify against density plot | Only 15 nuclei removed by this filter (out of 75,195 = 0.02%) | If the distribution shows a clear valley above 800, the threshold is correctly placed. If the distribution is continuously decreasing, the threshold may be arbitrarily low. iSN nuclei at Day13 typically express 1,000–4,000 genes; nuclei below 800 are likely debris or low-quality captures that would dilute neuronal subtype signal. Too permissive retains uninformative barcodes; too strict risks removing rare subtypes with lower transcript complexity. The near-zero removal rate suggests the current threshold is safely below the real distribution minimum — raising to 1,000 may better capture the natural minimum while still preserving rare subtypes |
| nCount_RNA pre-filter in Stage 02.1 | >500 UMI | Keep, but report separately from doublet removal | Stage 02.1 removes 5,450 nuclei (6.8%) before doublet scoring — these are attributed to "doublet removal" in the pipeline summary but are a QC pre-filter | The current pipeline summary conflates QC pre-filtering (nCount>500, applied in Stage 02.1 before scDblFinder) with doublet removal. For iSN nuclei, 500 UMI is a reasonable minimum; most genuine nuclei have >1,000 UMI. The current threshold is not too aggressive. The recommendation is to add a separate line in the pipeline summary table for the Stage 02.1 pre-filter so users can distinguish filter-related vs doublet-related cell loss |
| Clustering resolution | harmony_res.0.2 = 15 clusters | Consider testing harmony_res.0.3 (16 clusters) | At 15 clusters, clusters 0/4/5 are all iPSC-enriched and may represent over-merged iPSC subpopulations; cluster 2 (fibroblast) and cluster 13 (cardiac-like) are small outlier clusters that may fragment further at higher resolution | For a 3-timepoint developmental dataset spanning iPSC to mature iSN, 15 clusters may under-resolve the neuronal subtypes at Day13 while correctly grouping the iPSC population. Resolution 0.3 would add 1–2 communities (16 clusters in Harmony space from the sweep output) with minimal overclustering risk. However, this recommendation should wait until UMAP plots are visually inspected to confirm that neuronal clusters (3, 6, 11, 12, 14) are not already well-separated |
| Harmony theta | Default (not specified) | No change pending UMAP inspection | Sample mixing across clusters cannot be assessed from text data alone | If UMAP (colored by sample_group) shows sample-specific clustering — e.g., Day13 and iPSC nuclei segregating into non-overlapping regions — increasing Harmony theta would enforce stronger mixing. For now, no change recommended without visual confirmation |

_Recommendations are based on `final_report_decontX.html` and `04_clustering_report_decontX.html`. Confirm before any script is changed._

---

## Pipeline run summary — 2026-05-21

| Stage | Report | Overall flag | Key finding |
|-------|--------|-------------|-------------|
| 01.2 DECONTX | 01.2_DecontX_report.html | [OK] | 80,645 nuclei retained post-correction; Day13_2_dup contamination score >0.5 in 22.8% of nuclei — highest of all samples, monitor at annotation |
| 02.1 SCDBLFINDER_DECONTX | 02.1_scDblFinder_report.html | [OK] | Overall doublet rate 11.3%; all samples below 15% threshold; Day13 samples 6–8%, Day7/iPSC 12–14% — biologically consistent with cell density at harvest |
| 03 CELL_FILTERING | 03_cell_filtering_report_decontX.html | [OK] | 13.2% of nuclei removed (nFeature>800, percent.mt<=20%, singlets only); nFeature filter removed only 15 nuclei suggesting threshold is below the natural distribution minimum |
| 04 CLUSTERING | 04_clustering_report_decontX.html | [FLAG] | 15 clusters at harmony_res.0.2; pan-neuronal markers confirmed; TrkB/TrkC clusters present; Cluster 2 (collagen/fibroblast signature) and Cluster 13 (cardiac troponin T) are biologically unexpected and require visual UMAP inspection; peptidergic markers not confirmed from text data |
| Pipeline | final_report_decontX.html | [ASK] | Pipeline summary conflates Stage 02.1 QC pre-filter (5,450 nuclei) with doublet removal (8,485 nuclei) — recommend separating in future report; all stages otherwise complete |

**Recommendation:** Pipeline complete (Stage 04). The following items are flagged for attention:
1. Cluster 2 (fibroblast/stromal signature) — inspect UMAP for sample composition; consider excluding from final analysis if confirmed non-neuronal and not neural-crest-derived
2. Cluster 13 (TNNT2/MYL4/cardiac-like) — inspect UMAP; very small cluster; if confirmed non-neuronal, exclude from final analysis
3. Cluster 9 (LHX1/CER1 — unknown identity) — inspect UMAP sample_group distribution before annotation
4. Peptidergic markers (CALCA, TRPV1) — inspect DotPlot PDF and violin PDFs to confirm expression; these did not appear in FindAllMarkers top lists but may still be detectable
5. iPSC marker bleed-in — confirm POU5F1/SOX2/NANOG are absent from neuronal clusters (3, 6, 11, 12, 14) in the DotPlot

---

## Updated Review — HTML Report Verification (2026-05-21)

_This section documents a second pass through all 5 HTML reports using extracted text content. It corrects or updates findings from the initial review and adds new information available from the full report data._

### Correction: Cluster 13 TNNT2 pct.1

The initial review flagged Cluster 13 as "very small" based on VGLL1 pct.1=0.20. This was a misread. VGLL1 is the first-ranked marker by log2FC (4.96), but its pct.1=0.20 reflects low prevalence of this specific gene within the cluster. Crucially, TNNT2 (cardiac troponin T) pct.1=0.793 and MYL4 (myosin light chain 4) pct.1=0.421, confirming that the cardiac-muscle gene signature is expressed in the majority of nuclei in Cluster 13, not a minority. This makes the cardiac signature more — not less — concerning. The cluster is not necessarily small in cell number; the VGLL1 pct.1 reflects gene-level expression, not cluster size.

**Revised flag for Cluster 13:** [FLAG] — TNNT2 pct.1=0.793 and MYL4 pct.1=0.421 across Cluster 13 nuclei. This is a strong cardiac muscle signature in an iSN culture. At this pct.1, it is unlikely to be ambient RNA contamination (which would affect all clusters equally). Possible explanations: (a) early cardiomyocyte-like fate decision during directed differentiation — iSN protocols involving BMP signaling can produce off-target mesoderm lineages; (b) a contaminating feeder cell or support cell type. Cluster 13 should be treated as a non-neuronal contaminating population and excluded from neuronal subtype annotation unless sample_group inspection reveals it to be sample-specific.

### Correction: CALCA and TRPV1 absence confirmed

CALCA and TRPV1 are absent from the entire `04_all_markers_harmony_res0.2.csv` output — not merely absent from the top-ranked markers. This means neither gene is a statistically significant differentially expressed marker in any cluster at this resolution. Two interpretations:

1. **Peptidergic iSNs are present but sparse**: CALCA and TRPV1 mark a subpopulation that may be diluted within a larger neuronal cluster (e.g., within Cluster 3, 6, 11, or 14). FindAllMarkers tests for genes that distinguish one cluster from all others — rare subtypes within a cluster will not reach significance. The violin PDFs (violin_CALCA.pdf, violin_TRPV1.pdf) should be reviewed to check for expression in a subset of cells.
2. **Day13 cultures have not yet upregulated peptidergic markers**: Mature peptidergic identity (CGRP/CALCA, TRPV1) requires prolonged culture or NGF stimulation. Day13 may be too early for robust CALCA/TRPV1 expression.

[ASK] — Violin plots (violin_CALCA.pdf, violin_TRPV1.pdf) must be inspected before concluding peptidergic iSNs are absent. The absence from FindAllMarkers does not rule out expression at the cell level.

### iPSC marker segregation confirmed from FindAllMarkers

POU5F1, SOX2, and NANOG are present as significant markers in Clusters 0, 4, and 5 only. None appear in the marker lists for Clusters 1, 3, 6, 7, 8, 9, 10, 11, 12, 13, or 14. This is strong evidence that iPSC identity is correctly segregated to the three iPSC-enriched clusters and does not bleed into neuronal or non-neuronal clusters.

[OK] — iPSC markers are cleanly confined to Clusters 0, 4, and 5.

### Pan-neuronal and TrkB/TrkC marker summary (from full FindAllMarkers)

| Marker | Clusters | max pct.1 | Notes |
|--------|----------|-----------|-------|
| TUBB3 | 1, 7, 12 | 1.00 (cl7, cl12) | Pan-neuronal; near-universal in clusters 7 and 12 |
| SNAP25 | 1, 3, 8, 12, 14 | 0.929 (cl12) | Synaptic vesicle; strong in cl12 |
| PRPH | 3, 6, 10, 11, 12, 14 | 0.438 (cl14) | Peripheral neuron marker; moderate pct.1 across neuronal clusters |
| MAP2 | 3, 6, 12, 14 | 1.00 (cl12) | Mature neuron; cl12 shows MAP2 pct.1=1.00 |
| NTRK2 | 3, 11, 14 | 0.778 (cl3) | TrkB; strong in cl3 |
| NTRK3 | 3, 11, 14 | 0.531 (cl11) | TrkC; co-expressed with NTRK2 in cl3, 11, 14 |

[OK] — Pan-neuronal and TrkB/TrkC markers confirm mature sensory neuron identity in Clusters 3, 11, and 14 (NTRK2/3 + PRPH + SNAP25). Cluster 12 shows TUBB3 pct.1=1.00 and MAP2 pct.1=1.00, suggesting a highly mature but possibly distinct neuronal population.

### Pipeline summary — cell count accounting (from final_report_decontX.html)

| Stage | Input | Output | Removed | Note |
|-------|-------|--------|---------|------|
| 01.2 DecontX | 80,645 | 80,645 | 0 | Ambient correction in-place; no cells removed |
| 02 Doublet removal | 80,645 | 66,710 | 13,935 | Includes 5,450 pre-filter (nCount>500) + 8,485 doublets |
| 03 Cell filtering | 75,195 | 65,235 | 9,960 | Note: pipeline uses 75,195 as input (post-pre-filter, pre-doublet-label application) |
| 04 Clustering | 65,235 | 65,235 | 0 | No cells removed in clustering |

[ASK] — The pipeline summary table shows Stage 02 input as 80,645 but Stage 03 input as 75,195. This 5,450-nucleus discrepancy is the Stage 02.1 nCount>500 pre-filter. The Stage 03 report starts from 75,195, confirming these nuclei were removed in Stage 02.1. This is correct behavior but the pipeline summary should label Stage 02 output as 75,195 (post-pre-filter singlets) rather than 66,710 (post-doublet-removal), or add a sub-row for the pre-filter step, for clearer accounting.

### User decision

_Awaiting user confirmation before marking any stage final._

> **Do these results look biologically reasonable to proceed to the next stage (annotation/subtype calling)?**
>
> Specific items requiring user input:
> 1. **Cluster 13 (TNNT2 pct.1=0.793)** — do you want to exclude this cluster from annotation, or investigate further with UMAP/sample composition plots?
> 2. **Cluster 2 (COL12A1/COL3A1 — fibroblast/stromal)** — exclude from annotation, or is this a known non-neuronal population to characterize separately?
> 3. **Cluster 9 (LHX1/CER1 — unknown)** — does this population have a biological interpretation in the context of iSN differentiation (e.g., a neural tube-like off-target)?
> 4. **CALCA/TRPV1 absence** — are violin plots (violin_CALCA.pdf, violin_TRPV1.pdf) available for visual inspection? If peptidergic iSNs are expected at Day13, is a longer culture time planned for the next experiment?
> 5. **Pipeline cell count table discrepancy** — should the final_report.Rmd be updated to separate the Stage 02.1 pre-filter row from doublet removal for clearer accounting?
