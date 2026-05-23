process SCDBLFINDER {

    input:
    val ready

    output:
    val true, emit: done

    script:
    """
    export PATH=${params.r_bin}:\$PATH
    export R_LIBS=${params.r_libs}
    Rscript ${params.project_root}/scripts/02_scDblFinder_soupx/02_scDblFinder_soupx.R
    Rscript -e "rmarkdown::render(
      input          = '${params.project_root}/scripts/01_SoupX/01_SoupX_report.Rmd',
      output_options = list(dev = 'ragg_png'),
      params         = list(project_root = '${params.project_root}'),
      output_file    = '${params.project_root}/scripts/01_SoupX/SoupX_dir_out/01_SoupX_report.html',
      envir          = new.env()
    )"
    Rscript -e "rmarkdown::render(
      input          = '${params.project_root}/scripts/02_scDblFinder_soupx/02_scDblFinder_report.Rmd',
      output_options = list(dev = 'ragg_png'),
      params         = list(project_root = '${params.project_root}'),
      output_file    = '${params.project_root}/scripts/02_scDblFinder_soupx/scDblFinder_output/02_scDblFinder_report_soupX.html',
      envir          = new.env()
    )"
    """
}
