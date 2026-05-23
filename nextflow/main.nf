nextflow.enable.dsl = 2

include { SOUPX                                      } from './modules/soupx'
include { SOUPX_REPORT                               } from './modules/soupx'
include { DECONTX                                    } from './modules/decontx'
include { SCDBLFINDER                                } from './modules/scdblfinder'
include { SCDBLFINDER_DECONTX                        } from './modules/scdblfinder_decontx'
include { CELL_FILTERING as CELL_FILTERING_SOUPX     } from './modules/cell_filtering'
include { CELL_FILTERING as CELL_FILTERING_DECONTX   } from './modules/cell_filtering'
include { CLUSTERING     as CLUSTERING_SOUPX         } from './modules/clustering'
include { CLUSTERING     as CLUSTERING_DECONTX       } from './modules/clustering'
include { MERGE_REPORT   as MERGE_REPORT_SOUPX       } from './modules/merge_report'
include { MERGE_REPORT   as MERGE_REPORT_DECONTX     } from './modules/merge_report'

workflow {

    samples_ch = Channel.from(params.samples)

    // ── SoupX track: 01 → 02 → 03 → 04 → report ─────────────────────
    if (params.track == 'soupx' || params.track == 'both') {
        SOUPX(samples_ch)
        SOUPX_REPORT(SOUPX.out.done.collect())
        SCDBLFINDER(SOUPX_REPORT.out.done)
        CELL_FILTERING_SOUPX(SCDBLFINDER.out.done, 'soupx')
        CLUSTERING_SOUPX(CELL_FILTERING_SOUPX.out.done, 'soupx')
        MERGE_REPORT_SOUPX(CLUSTERING_SOUPX.out.done, 'soupx')
    }

    // ── DecontX track: 01.2 → 02.1 → 03 → 04 → report ───────────────
    if (params.track == 'decontx' || params.track == 'both') {
        DECONTX()
        SCDBLFINDER_DECONTX(DECONTX.out.done)
        CELL_FILTERING_DECONTX(SCDBLFINDER_DECONTX.out.done, 'decontx')
        CLUSTERING_DECONTX(CELL_FILTERING_DECONTX.out.done, 'decontx')
        MERGE_REPORT_DECONTX(CLUSTERING_DECONTX.out.done, 'decontx')
    }
}
