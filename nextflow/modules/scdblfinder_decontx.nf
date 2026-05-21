process SCDBLFINDER_DECONTX {

    input:
    val ready

    output:
    val true, emit: done

    script:
    """
    export PATH=${params.r_bin}:\$PATH
    export R_LIBS=${params.r_libs}
    Rscript ${params.project_root}/scripts/02.1_scDblFinder_decontX/02.1_scDblFinder_decontX.R
    Rscript -e "rmarkdown::render(
      input          = '${params.project_root}/scripts/02.1_scDblFinder_decontX/02.1_scDblFinder_report.Rmd',
      output_options = list(dev = 'ragg_png'),
      params         = list(project_root = '${params.project_root}'),
      output_file    = '${params.project_root}/scripts/02.1_scDblFinder_decontX/scDblFinder_output/02.1_scDblFinder_report.html',
      envir          = new.env()
    )"
    """
}
