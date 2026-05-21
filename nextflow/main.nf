nextflow.enable.dsl = 2

include { SOUPX                 } from './modules/soupx'
include { DECONTX               } from './modules/decontx'
include { SCDBLFINDER           } from './modules/scdblfinder'
include { SCDBLFINDER_DECONTX  } from './modules/scdblfinder_decontx'
include { CELL_FILTERING        } from './modules/cell_filtering'
include { CLUSTERING            } from './modules/clustering'
include { MERGE_REPORT          } from './modules/merge_report'

workflow {

    samples_ch = Channel.from(params.samples)

    // ── Run only the selected track end-to-end ────────────────────
    if (params.track == "decontx") {
        // Stages 01.2 → 02.1 → 03 → 04
        DECONTX()
        SCDBLFINDER_DECONTX(DECONTX.out.done)
        CELL_FILTERING(SCDBLFINDER_DECONTX.out.done)
    } else {
        // Stages 01 → 02 → 03 → 04
        SOUPX(samples_ch)
        SCDBLFINDER(SOUPX.out.done.collect())
        CELL_FILTERING(SCDBLFINDER.out.done)
    }

    // ── Stage 04 — clustering ──────────────────────────────────────
    CLUSTERING(CELL_FILTERING.out.done)

    // ── Final merged report ────────────────────────────────────────
    MERGE_REPORT(CLUSTERING.out.done)
}
