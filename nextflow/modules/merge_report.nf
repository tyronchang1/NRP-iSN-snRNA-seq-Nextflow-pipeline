process MERGE_REPORT {

    tag "${track}"

    publishDir "${params.project_root}/final_output", mode: 'copy'

    input:
    val ready
    val track

    output:
    val true, emit: done

    script:
    def track_display = track == "decontx" ? "decontX" : "soupX"
    """
    export PATH=${params.r_bin}:\$PATH
    export R_LIBS=${params.r_libs}
    export GENE_SETS='${params.gene_sets}'
    mkdir -p ${params.project_root}/final_output
    Rscript -e "rmarkdown::render(
      input          = '${params.project_root}/final_output/final_report.Rmd',
      output_options = list(dev = 'ragg_png'),
      params         = list(
        project_root = '${params.project_root}',
        track        = '${track}',
        gene_sets    = Sys.getenv('GENE_SETS')
      ),
      output_file    = '${params.project_root}/final_output/final_report_${track_display}.html',
      envir          = new.env()
    )"
    """
}
