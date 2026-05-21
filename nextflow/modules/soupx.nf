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
