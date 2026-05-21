# Nextflow Pipeline Status

This file tracks the iSN Nextflow pipeline only. Updated by `nextflow-script-agent` (implementation status) and `nextflow-stage-report-agent` (last run status). Do not use for RStudio-only stages.

---

## Stage implementation status

| Stage | Process name | Module file | Track | Implementation | Notes |
|-------|-------------|-------------|-------|----------------|-------|
| 01 | `SOUPX` | `nextflow/modules/soupx.nf` | SoupX | Implemented | One invocation per sample via channel |
| 01.2 | `DECONTX` | `nextflow/modules/decontx.nf` | DecontX | Implemented | Single process, all samples |
| 02 | `SCDBLFINDER` | `nextflow/modules/scdblfinder.nf` | SoupX | Implemented | Waits for all SoupX outputs |
| 02.1 | `SCDBLFINDER_DECONTX` | `nextflow/modules/scdblfinder_decontx.nf` | DecontX | Implemented | Waits for DecontX output |
| 03 | `CELL_FILTERING` | `nextflow/modules/cell_filtering.nf` | Both | Implemented | Single call; track selected at runtime via `--track` |
| 04 | `CLUSTERING` | `nextflow/modules/clustering.nf` | Both | Implemented | Follows CELL_FILTERING |

Stage 05 (MergePublicDatasets / DRG atlas integration) removed from the pipeline per user decision 2026-05-21. The pipeline ends at Stage 04 (Clustering).

---

## Last run status

Updated by `nextflow-stage-report-agent` at every session start. Blank until first pipeline run.

| Stage | Process name | Track | Status | Exit code | Last run | Notes |
|-------|-------------|-------|--------|-----------|----------|-------|
| 01 | `SOUPX` | SoupX | NOT STARTED | — | 2026-05-21 | DecontX track selected; SoupX not invoked |
| 01.2 | `DECONTX` | DecontX | CACHED | 0 | 2026-05-21 | Output: iSN_decontX.rds, 01.2_DecontX_report.html |
| 02 | `SCDBLFINDER` | SoupX | NOT STARTED | — | 2026-05-21 | DecontX track selected; SoupX not invoked |
| 02.1 | `SCDBLFINDER_DECONTX` | DecontX | CACHED | 0 | 2026-05-21 | Output: iSN_decontX_scDblFinder.rds, 02.1_scDblFinder_report.html |
| 03 | `CELL_FILTERING` | Both | CACHED | 0 | 2026-05-21 | Output: 03_seu_cellfiltered_decontx.rds, 03_cell_filtering_report_decontX.html |
| 04 | `CLUSTERING` | Both | SUCCESS | 0 | 2026-05-21 | Output: 04_seu_clustered_decontx.rds, 04_clustering_report_decontX.html; 55m 12s |

Status values: `SUCCESS` | `FAILED` | `CACHED` | `IN PROGRESS` | `NOT STARTED` | `—` (not yet run)
