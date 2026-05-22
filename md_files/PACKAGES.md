# Package Reference

All packages installed by `r_install/submit_all.sh`. The install scripts handle dependencies automatically.

---

## CRAN (`r_install/01_cran.sh`)

| Package | Purpose |
|---------|---------|
| Seurat | scRNA-seq analysis (all stages) |
| SoupX | Ambient RNA removal (Stage 01) |
| scCustomize | Seurat plotting extensions |
| cowplot | Multi-panel plot composition |
| ggplot2 | Plotting |
| ggrepel | Non-overlapping plot labels |
| patchwork | Plot layout |
| viridis | Color scales |
| pheatmap | Heatmaps |
| ggpubr | Publication-ready ggplot2 helpers |
| ggdendro | Dendrogram plotting |
| clustree | Clustering resolution trees |
| magick | Image processing |
| RColorBrewer | Color palettes |
| randomcoloR | Random color generation |
| gt | Table formatting |
| dplyr | Data manipulation |
| tidyr | Data tidying |
| purrr | Functional programming |
| tibble | Modern data frames |
| stringr | String manipulation |
| forcats | Factor manipulation |
| readr | Data import |
| scales | Axis/color scaling |
| lubridate | Date handling |
| broom | Model output tidying |
| Matrix | Sparse matrix support |
| RSpectra | Sparse SVD for PCA (Stage 04) |
| future | Parallel processing |
| data.table | Fast tabular operations |
| magrittr | Pipe operator |
| glue | String interpolation |
| gridExtra | Grid graphics |
| tictoc | Timing |
| R.utils | Utility functions |
| msigdbr | MSigDB gene sets |
| RobustRankAggreg | Robust rank aggregation |
| reticulate | Python interop |
| shiny | Interactive apps |
| DT | Interactive tables |
| knitr | Report rendering |
| rmarkdown | R Markdown documents |
| markdown | Markdown rendering |
| here | Relative paths |
| lintr | Linting |
| styler | Code formatting |
| BiocManager | Bioconductor install manager |
| remotes | GitHub package installer |
| pak | Fast package installer |
| callback | Callback utilities |

---

## Bioconductor (`r_install/02_bioc.sh`)

| Package | Purpose |
|---------|---------|
| DropletUtils | Write corrected 10x count matrices (Stage 01) |
| scDblFinder | Doublet detection (Stages 02, 02.1) |
| AUCell | Gene set activity scoring (Stage 04) |
| glmGamPoi | Fast GLM fitting (Seurat SCTransform) |
| miloR | Differential abundance testing |
| SingleCellExperiment | SCE container (scDblFinder input) |
| SummarizedExperiment | Base Bioc container |
| multtest | Multiple testing correction |
| celda | Decontamination (decontX dependency) |
| scater | Single-cell utilities |
| scran | Single-cell normalization |
| ComplexHeatmap | Advanced heatmaps |
| UCell | Gene set scoring |
| zellkonverter | AnnData ↔ SCE conversion |
| DESeq2 | Differential expression |
| edgeR | Differential expression |
| limma | Linear models for genomics |
| apeglm | Log fold change shrinkage |
| clusterProfiler | Gene ontology enrichment |
| ReactomePA | Reactome pathway analysis |
| AnnotationDbi | Annotation databases |
| org.Hs.eg.db | Human gene annotation |
| org.Mm.eg.db | Mouse gene annotation |
| GSVA | Gene set variance analysis |
| BiocGenerics | Bioc generic functions |
| BiocParallel | Bioc parallel framework |
| S4Vectors | S4 vector classes |
| DelayedArray | Delayed array operations |
| DelayedMatrixStats | Stats on delayed matrices |
| HDF5Array | HDF5-backed arrays |
| batchelor | Batch correction |
| Biobase | Base Bioc classes |
| TOAST | Cell type deconvolution |
| singleCellTK | Single-cell toolkit |
| scry | Null residuals for scRNA-seq |
| Rhtslib | HTSlib for BAM/CRAM |
| monocle | Trajectory analysis (v2) |

---

## GitHub (`r_install/03_github.sh`)

| Package | GitHub repo | Purpose |
|---------|-------------|---------|
| harmony | immunogenomics/harmony | Batch correction (Stage 04) |
| presto | immunogenomics/presto | Fast Wilcoxon / FindAllMarkers |
| SeuratDisk | mojaveazure/seurat-disk | H5Seurat read/write |
| decontX | campbio/decontX | Ambient RNA removal (Stage 01.2) |
| BPCells | bnprks/BPCells/r | Out-of-core matrix operations |
| DoubletFinder | chris-mcginnis-ucsf/DoubletFinder | Alternative doublet detection |
| monocle3 | cole-trapnell-lab/monocle3 | Trajectory analysis (v3) |
| SeuratWrappers | satijalab/seurat-wrappers | Seurat integration wrappers |
| SeuratData | satijalab/seurat-data | Reference datasets |
| scSHC | igrabski/sc-SHC | Statistical cluster validation |
| scclusteval | crazyhottommy/scclusteval | Clustering stability evaluation |
| scGSVA | guokai8/scGSVA | Gene set scoring for scRNA-seq |
| garnett | cole-trapnell-lab/garnett | Cell type classification |
| ShinyCell2 | the-ouyang-lab/ShinyCell2 | Shiny app for scRNA-seq |
| EPIC | GfellerLab/EPIC | Cell type deconvolution |
| MuSiC | xuranw/MuSiC | Bulk deconvolution |
| xbioc | renozao/xbioc | MuSiC dependency |
| MuSiC2 | Jiaxin-Fan/MuSiC2 | Improved bulk deconvolution |

---

## Python (`r_install/04_python.sh`)

| Package | Purpose |
|---------|---------|
| numpy | Numerical arrays |
| pandas | DataFrames |
| scipy | Scientific computing |
| scikit-learn | Machine learning utilities |
| anndata | AnnData container (scverse) |
| scanpy | Python scRNA-seq analysis |
