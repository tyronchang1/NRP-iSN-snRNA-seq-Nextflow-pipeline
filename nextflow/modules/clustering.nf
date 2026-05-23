process CLUSTERING {

    tag "${track}"

    input:
    val ready
    val track

    output:
    val track, emit: done

    script:
    def track_display = track == "decontx" ? "decontX" : "soupX"
    """
    export PATH=${params.r_bin}:\$PATH
    export R_LIBS=${params.r_libs}
    export GENE_SETS='${params.gene_sets}'
    Rscript ${params.project_root}/scripts/04_Clustering/04_clustering.R \
        --gene_sets        "\$GENE_SETS" \
        --track            ${track} \
        --seed             ${params.seed} \
        --project_root     ${params.project_root}
    Rscript -e "rmarkdown::render(
      input          = '${params.project_root}/scripts/04_Clustering/04_clustering.Rmd',
      output_options = list(dev = 'ragg_png'),
      params         = list(
        project_root = '${params.project_root}',
        gene_sets    = Sys.getenv('GENE_SETS'),
        seed         = ${params.seed},
        track        = '${track}'
      ),
      output_file    = '${params.project_root}/scripts/04_Clustering/clustering_output/04_clustering_report_${track_display}.html',
      envir          = new.env()
    )"
    """
}
