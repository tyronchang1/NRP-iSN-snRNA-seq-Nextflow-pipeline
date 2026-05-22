# Pipeline Stages

Both tracks run in parallel. Stages 03–04 accept either track's output.

| Stage | Tool | Track | Script |
|-------|------|-------|--------|
| 01 — Ambient RNA removal | SoupX | SoupX | `scripts/01_SoupX/SoupX_{SAMPLE}.R` |
| 01.2 — Ambient RNA removal | DecontX | DecontX | `scripts/01.2_DecontX/01.2_DecontX.R` |
| 02 — Doublet removal | scDblFinder | SoupX | `scripts/02_scDblFinder_soupx/02_scDblFinder_soupx.R` |
| 02.1 — Doublet removal | scDblFinder | DecontX | `scripts/02.1_scDblFinder_decontX/02.1_scDblFinder_decontX.R` |
| 03 — Cell filtering | Seurat | Both | `scripts/03_Cell_filtering/03_cell_filtering.R` |
| 04 — Clustering | Seurat + Harmony | Both | `scripts/04_Clustering/04_clustering.R` |
