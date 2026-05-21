process CELL_FILTERING {
    tag "both_tracks"

    input:
    val ready

    output:
    val true, emit: done

    script:
    def track_display = params.track == "decontx" ? "decontX" : "soupX"
    """
    export PATH=${params.r_bin}:\$PATH
    export R_LIBS=${params.r_libs}
    Rscript ${params.project_root}/scripts/03_Cell_filtering/03_cell_filtering.R \
        --track ${params.track}
    Rscript -e "rmarkdown::render(
      input          = '${params.project_root}/scripts/03_Cell_filtering/03_cell_filtering_report.Rmd',
      output_options = list(dev = 'ragg_png'),
      params         = list(project_root = '${params.project_root}', track = '${params.track}'),
      output_file    = '${params.project_root}/scripts/03_Cell_filtering/Cell_filtering_output/03_cell_filtering_report_${track_display}.html',
      envir          = new.env()
    )"
    """
}
