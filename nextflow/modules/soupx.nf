process SOUPX {
    tag "${sample}"

    input:
    val sample

    output:
    val true, emit: done

    script:
    """
    export PATH=${params.r_bin}:\$PATH
    export R_LIBS=${params.r_libs}
    Rscript ${params.project_root}/scripts/01_SoupX/SoupX_${sample}.R
    """
}

process SOUPX_REPORT {
    input:
    val ready

    output:
    val true, emit: done

    script:
    """
    export PATH=${params.r_bin}:\$PATH
    export R_LIBS=${params.r_libs}
    Rscript -e "rmarkdown::render(
        '${params.project_root}/scripts/01_SoupX/01_SoupX_report.Rmd',
        output_file = '${params.project_root}/scripts/01_SoupX/SoupX_dir_out/01_SoupX_report.html',
        params = list(project_root = '${params.project_root}')
    )"
    """
}
