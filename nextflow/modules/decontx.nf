process DECONTX {

    output:
    val true, emit: done

    script:
    """
    export PATH=${params.r_bin}:\$PATH
    export R_LIBS=${params.r_libs}
    Rscript ${params.project_root}/scripts/01.2_DecontX/01.2_DecontX.R
    Rscript -e "rmarkdown::render(
      input          = '${params.project_root}/scripts/01.2_DecontX/01.2_DecontX_report.Rmd',
      output_options = list(dev = 'ragg_png'),
      params         = list(project_root = '${params.project_root}'),
      output_file    = '${params.project_root}/scripts/01.2_DecontX/DecontX_out/01.2_DecontX_report.html',
      envir          = new.env()
    )"
    """
}
