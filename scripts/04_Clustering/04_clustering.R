rm(list = ls(all.name = TRUE))
dir <- "/scratch/rmlab/rmlab_shared3/tyron/Rscriptv2/iSN/iSN_claude"
setwd(dir)
pdf(NULL)

library(ggplot2)
library(multtest)
library(presto)
library(dplyr)
library(scales)
library(AUCell)
library(miloR)
library(glmGamPoi)
library(future)
library(Seurat)
library(harmony)
library(tidyr)
library(SingleCellExperiment)
library(patchwork)
library(ggrepel)
library(Matrix)
library(RSpectra)
library(viridis)
library(pheatmap)
library(tictoc)
library(scCustomize)
# library(scSHC)  # commented out — scSHC removed (OOM on 65k cells)

plan("multisession", workers = 4)
options(future.globals.maxSize = 30000 * 1024^2, future.seed = TRUE)

set.seed(123)

# Parse --gene_sets command-line argument (wire format: "name=G1,G2;name2=G3")
.args <- commandArgs(trailingOnly = TRUE)
.get_arg <- function(flag, default = "") {
  i <- which(.args == flag)
  if (length(i) > 0 && i < length(.args)) .args[i + 1L] else default
}
args_gene_sets <- .get_arg("--gene_sets", "")
# RStudio override — uncomment the next line to run Section 8.1 without CLI args:
# args_gene_sets <- "pan_neuronal=TUBB3,PRPH,SNAP25;g2m=ATF5,MKI67"
args_track <- .get_arg("--track", "decontx")
# RStudio override — uncomment to run without CLI args:
# args_track <- "decontx"



out_dir <- "./scripts/04_Clustering/clustering_output"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
track_dir <- file.path(out_dir, args_track)
dir.create(track_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(track_dir, "aucell"), recursive = TRUE, showWarnings = FALSE)

# ---------------------------------------------------------------------------
# 1. Load input
# ---------------------------------------------------------------------------

seu <- readRDS(file.path("./scripts/03_Cell_filtering/Cell_filtering_output",
                         paste0("03_seu_cellfiltered_", args_track, ".rds")))
seu
DefaultAssay(seu)

# Rename assays if necessary

DefaultAssay(seu) <-"RNA"

table(seu$sample_group)

# Derive individual sample ID for Harmony batch correction (strips _dup suffix)
# Pattern NR00_(iPSC|Day7|Day13)_[0-9] matches NR00_Day13_1 etc.; _dup is outside match
seu$orig.ident <- regmatches(seu$sample_group,
  regexpr("NR00_(iPSC|Day7|Day13)_[0-9]", seu$sample_group))

# Derive timepoint column from sample_group
seu$sample <- regmatches(seu$sample_group,
  regexpr("Day7|Day13|iPSC", seu$sample_group))

table(seu$orig.ident)
table(seu$sample)

# Timepoint colours used for all DimPlots coloured by sample
timepoint_colors <- c(Day13 = "#4E8FCA", Day7 = "#D73027", iPSC = "#F5A623")


#check and split layers
class(seu[["RNA"]])
seu[["RNA"]] <- as(seu[["RNA"]], Class = "Assay5")# convert seurat back to v5

Layers(seu[["RNA"]])

seu[["RNA"]] <- JoinLayers(seu[["RNA"]])#join the layers again

Layers(seu[["RNA"]])

seu[["RNA"]] <- split(seu[["RNA"]],
                         f = seu$orig.ident)

# ---------------------------------------------------------------------------
# 2. Normalize (once, outside sweep loop)
# ---------------------------------------------------------------------------

seu <- NormalizeData(seu, normalization.method = "LogNormalize", scale.factor = 1e4)

# ---------------------------------------------------------------------------
# 3. nfeatures = 10000
# *** To run a different value, change nf below and re-run this section ***
# ---------------------------------------------------------------------------

nf <- 10000
# nf <- 5000
# nf <- 3000

sweep_dir <- file.path(track_dir, paste0("nfeatures_", nf))
dir.create(sweep_dir, recursive = TRUE, showWarnings = FALSE)

# ---- Variable features + scaling ----
seu <- FindVariableFeatures(seu, nfeatures = nf)
seu <- ScaleData(seu, features = VariableFeatures(seu), verbose = TRUE)

# ---- Manual SVD PCA ----
var_genes <- VariableFeatures(seu)
sc <- GetAssayData(seu, layer = "scale.data")[var_genes, , drop = FALSE]

X <- t(as.matrix(sc))
X <- scale(X, center = TRUE, scale = FALSE)

k <- min(80, ncol(X) - 1, nrow(X) - 1)
sv  <- RSpectra::svds(X, k = k)

emb   <- sv$u %*% diag(sv$d)
load  <- sv$v
sdev  <- sv$d / sqrt(nrow(X) - 1)

rownames(emb)  <- colnames(sc)
colnames(emb)  <- paste0("PC_", seq_len(ncol(emb)))
rownames(load) <- rownames(sc)
colnames(load) <- paste0("PC_", seq_len(ncol(load)))

seu@reductions$pca <- NULL
seu[["pca"]] <- CreateDimReducObject(
  embeddings = emb,
  loadings   = load,
  stdev      = sdev,
  key        = "PC_",
  assay      = "RNA"
)

# Variance-explained guide
sdev_vals <- Stdev(seu, "pca")
var_expl  <- sdev_vals^2 / sum(sdev_vals^2)
cumve     <- cumsum(var_expl)
var_table <- data.frame(
  PC     = seq_along(sdev_vals),
  SD     = sdev_vals,
  Var    = round(var_expl, 4),
  CumVar = round(cumve, 4)
)
# k_auto: max(10, min(which(cumve >= 0.90)[1], 40))
# Running on 1:80 dims for now

# Elbow plot
p_elbow <- ElbowPlot(seu, ndims = ncol(emb)) + theme_bw() +
  ggtitle(paste0("Elbow plot — nfeatures = ", nf))
p_elbow 
ggsave(file.path(sweep_dir, "elbow_plot.pdf"),
       plot = p_elbow, width = 7, height = 5)

DefaultLayer(seu[["RNA"]]) <- "scale.data"

# ---- UMAP on PCA ----
seu <- RunUMAP(seu,
               reduction      = "pca",
               reduction.name = "umap.pca",
               dims           = 1:80,
               umap.method    = "uwot",
               metric         = "cosine")

# ---- Harmony ----
seu <- RunHarmony(seu,
                  group.by.vars  = "orig.ident",
                  reduction      = "pca",
                  reduction.save = "harmony",
                  verbose        = TRUE)

# ---- UMAP on Harmony ----
seu <- RunUMAP(seu,
               reduction      = "harmony",
               reduction.name = "umap.harmony",
               dims           = 1:80,
               umap.method    = "uwot",
               metric         = "cosine")

# ---- Clustering on PCA ----
seu <- FindNeighbors(seu, reduction = "pca", dims = 1:80)
resolutions <- c(0.2, 0.3, 0.5, 0.6, 0.8)
seu <- FindClusters(seu, resolution = resolutions)

for (res in resolutions) {
  old_col <- paste0("RNA_snn_res.", res)
  new_col <- paste0("pca_res.", res)
  if (old_col %in% colnames(seu@meta.data)) {
    seu@meta.data[[new_col]] <- seu@meta.data[[old_col]]
    seu@meta.data[[old_col]] <- NULL
  }
}

# ---- Clustering on Harmony ----
seu <- FindNeighbors(seu, reduction = "harmony", dims = 1:80)
seu <- FindClusters(seu, resolution = resolutions)

for (res in resolutions) {
  old_col <- paste0("RNA_snn_res.", res)
  new_col <- paste0("harmony_res.", res)
  if (old_col %in% colnames(seu@meta.data)) {
    seu@meta.data[[new_col]] <- seu@meta.data[[old_col]]
    seu@meta.data[[old_col]] <- NULL
  }
}

# ---- DimPlots: umap.pca ----


p <- DimPlot(
  seu,
  reduction = "umap.pca",
  group.by = "sample",
  label = FALSE,     # turn off Seurat's default labeling
  pt.size = 0.5
)+ggtitle("WT iSN snRNA-data ") +
  xlab("UMAP 1") +
  ylab("UMAP 2") +
  theme(
    plot.title = element_text(size = 15, face = "bold", hjust = 0.5),
    axis.title = element_text(size = 13, face = "bold"),
    axis.text = element_text(size = 13),
    legend.title = element_text(size = 12),
    legend.text = element_text(size = 12)
  ) +
  scale_color_manual(values = c("iPSC" ="orange","Day7"= "#E41A1C", "Day13" = "#377EB8")) +
  scale_x_continuous(
    limits = c(-18,18),
    breaks = seq(-18,18,3))+
  scale_y_continuous(
    limits = c(-18,18),
    breaks = seq(-18,18,3))

centroids <- as.data.frame(Embeddings(seu, "umap.pca"))
centroids$group <-seu$sample
centroids <- aggregate(. ~ group, centroids, mean)

centroids$umappca_2[centroids$group == "Day7"] <-
  centroids$umappca_2[centroids$group == "Day7"] + 3.0
centroids$umappca_2[centroids$group == "Day13"] <-
  centroids$umappca_2[centroids$group == "Day13"] + 5.0
# Add manually repelled labels
p <- p + 
  geom_text_repel(
    data = centroids,
    aes(x = umappca_1, y = umappca_2, label = group),
    size = 5,
    color = "black",
    segment.color = "grey50"
  ) 
p

DimPlot(seu, reduction = "umap.pca",
        group.by = "sample_group",label = TRUE)
centroids_pca_cl <- as.data.frame(Embeddings(seu, "umap.pca"))
centroids_pca_cl$pca_res.0.2 <- seu$pca_res.0.2
centroids_pca_cl <- aggregate(. ~ pca_res.0.2, centroids_pca_cl, mean)

p_pca_clusters <- DimPlot(seu,
                           reduction = "umap.pca",
                           group.by  = "pca_res.0.2",
                           label     = FALSE,
                           pt.size   = 0.5) +
  ggtitle(paste0("iSN PCA clusters (res 0.2, nf=", nf, ")")) +
  xlab("UMAP 1") + ylab("UMAP 2") +
  theme(
    plot.title   = element_text(size = 15, face = "bold", hjust = 0.5),
    axis.title   = element_text(size = 13, face = "bold"),
    axis.text    = element_text(size = 13),
    legend.title = element_text(size = 12),
    legend.text  = element_text(size = 12)
  ) +
  scale_x_continuous(limits = c(-16, 16), breaks = seq(-16, 16, 4)) +
  scale_y_continuous(limits = c(-16, 16), breaks = seq(-16, 16, 4)) +
  geom_text_repel(
    data = centroids_pca_cl,
    aes(x = umappca_1, y = umappca_2, label = pca_res.0.2),
    size = 5, color = "black", segment.color = "grey50",
    box.padding = 0.8, max.overlaps = Inf
  )
p_pca_clusters
centroids_pca_samp <- as.data.frame(Embeddings(seu, "umap.pca"))
centroids_pca_samp$sample <- seu$sample
centroids_pca_samp <- aggregate(. ~ sample, centroids_pca_samp, mean)

p_pca_samples <- DimPlot(seu,
                          reduction = "umap.pca",
                          group.by  = "sample",
                          label     = FALSE,
                          pt.size   = 0.5) +
  ggtitle(paste0("iSN PCA — sample (nf=", nf, ")")) +
  xlab("UMAP 1") + ylab("UMAP 2") +
  theme(
    plot.title   = element_text(size = 15, face = "bold", hjust = 0.5),
    axis.title   = element_text(size = 13, face = "bold"),
    axis.text    = element_text(size = 13),
    legend.title = element_text(size = 12),
    legend.text  = element_text(size = 12)
  ) +
  scale_color_manual(values = timepoint_colors) +
  scale_x_continuous(limits = c(-16, 16), breaks = seq(-16, 16, 4)) +
  scale_y_continuous(limits = c(-16, 16), breaks = seq(-16, 16, 4)) +
  geom_text_repel(
    data = centroids_pca_samp,
    aes(x = umappca_1, y = umappca_2, label = sample),
    size = 5, color = "black", segment.color = "grey50",
    box.padding = 0.8, max.overlaps = Inf
  )

patchwork_pca <- p_pca_clusters | p_pca_samples
patchwork_pca
ggsave(file.path(sweep_dir, paste0("dimplot_pca_nf", nf, ".pdf")),
       plot = patchwork_pca, width = 16, height = 7)

# ---- DimPlots: umap.harmony ----

centroids_harm_cl <- as.data.frame(Embeddings(seu, "umap.harmony"))
centroids_harm_cl$harmony_res.0.2 <- seu$harmony_res.0.2
centroids_harm_cl <- aggregate(. ~ harmony_res.0.2, centroids_harm_cl, mean)

p_harmony_clusters <- DimPlot(seu,
                               reduction = "umap.harmony",
                               group.by  = "harmony_res.0.2",
                               label     = FALSE,
                               pt.size   = 0.5) +
  ggtitle(paste0("iSN Harmony clusters (res 0.2, nf=", nf, ")")) +
  xlab("UMAP 1") + ylab("UMAP 2") +
  theme(
    plot.title   = element_text(size = 15, face = "bold", hjust = 0.5),
    axis.title   = element_text(size = 13, face = "bold"),
    axis.text    = element_text(size = 13),
    legend.title = element_text(size = 12),
    legend.text  = element_text(size = 12)
  ) +
  scale_x_continuous(limits = c(-16, 16), breaks = seq(-16, 16, 4)) +
  scale_y_continuous(limits = c(-16, 16), breaks = seq(-16, 16, 4)) +
  geom_text_repel(
    data = centroids_harm_cl,
    aes(x = umapharmony_1, y = umapharmony_2, label = harmony_res.0.2),
    size = 5, color = "black", segment.color = "grey50",
    box.padding = 0.8, max.overlaps = Inf
  )

centroids_harm_samp <- as.data.frame(Embeddings(seu, "umap.harmony"))
centroids_harm_samp$sample <- seu$sample
centroids_harm_samp <- aggregate(. ~ sample, centroids_harm_samp, mean)

p_harmony_samples <- DimPlot(seu,
                              reduction = "umap.harmony",
                              group.by  = "sample",
                              label     = FALSE,
                              pt.size   = 0.5) +
  ggtitle(paste0("iSN Harmony — sample (nf=", nf, ")")) +
  xlab("UMAP 1") + ylab("UMAP 2") +
  theme(
    plot.title   = element_text(size = 15, face = "bold", hjust = 0.5),
    axis.title   = element_text(size = 13, face = "bold"),
    axis.text    = element_text(size = 13),
    legend.title = element_text(size = 12),
    legend.text  = element_text(size = 12)
  ) +
  scale_color_manual(values = timepoint_colors) +
  scale_x_continuous(limits = c(-16, 16), breaks = seq(-16, 16, 4)) +
  scale_y_continuous(limits = c(-16, 16), breaks = seq(-16, 16, 4)) +
  geom_text_repel(
    data = centroids_harm_samp,
    aes(x = umapharmony_1, y = umapharmony_2, label = sample),
    size = 5, color = "black", segment.color = "grey50",
    box.padding = 0.8, max.overlaps = Inf
  )

patchwork_harmony <- p_harmony_clusters | p_harmony_samples
ggsave(file.path(sweep_dir, paste0("dimplot_harmony_nf", nf, ".pdf")),
       plot = patchwork_harmony, width = 16, height = 7)

# ---------------------------------------------------------------------------
# 3.5. scSHC — COMMENTED OUT (OOM on 65k cells; fixed parameters: nf=10000, res=0.2, PC=80)
# ---------------------------------------------------------------------------

# seu[["RNA"]] <- JoinLayers(seu[["RNA"]])
# counts_mat <- seu[["RNA"]]$counts
# tic()
# scshc_clusters <- scSHC(counts_mat,
#                          cores        = 6,
#                          num_PCs      = 80,
#                          num_features = nf)
# toc()
# seu$scshc_clusters <- scshc_clusters[colnames(seu)]
# p_scshc <- DimPlot_scCustom(seu,
#                              reduction = "umap.harmony",
#                              group.by  = "scshc_clusters",
#                              label     = TRUE,
#                              pt.size   = 0.5) +
#   ggtitle("scSHC clusters") +
#   xlab("UMAP 1") + ylab("UMAP 2") +
#   theme(
#     plot.title   = element_text(size = 15, face = "bold", hjust = 0.5),
#     axis.title   = element_text(size = 13, face = "bold"),
#     axis.text    = element_text(size = 13),
#     legend.title = element_text(size = 12),
#     legend.text  = element_text(size = 12)
#   ) +
#   scale_x_continuous(limits = c(-16, 16), breaks = seq(-16, 16, 4)) +
#   scale_y_continuous(limits = c(-16, 16), breaks = seq(-16, 16, 4))
# p_seurat_res <- DimPlot_scCustom(seu,
#                                   reduction = "umap.harmony",
#                                   group.by  = "harmony_res.0.2",
#                                   label     = TRUE,
#                                   pt.size   = 0.5) +
#   ggtitle("Seurat Harmony clusters (res 0.2)") +
#   xlab("UMAP 1") + ylab("UMAP 2") +
#   theme(
#     plot.title   = element_text(size = 15, face = "bold", hjust = 0.5),
#     axis.title   = element_text(size = 13, face = "bold"),
#     axis.text    = element_text(size = 13),
#     legend.title = element_text(size = 12),
#     legend.text  = element_text(size = 12)
#   ) +
#   scale_x_continuous(limits = c(-16, 16), breaks = seq(-16, 16, 4)) +
#   scale_y_continuous(limits = c(-16, 16), breaks = seq(-16, 16, 4))
# p_compare <- p_scshc | p_seurat_res
# ggsave(file.path(track_dir, "scshc_vs_harmony_res0.2.pdf"),
#        plot = p_compare, width = 16, height = 7)

# ---------------------------------------------------------------------------
# 4. JackStraw — COMMENTED OUT (parameters fixed: nf=10000, res=0.2, PC=80)
#    Elbow plot kept in Section 3 above (sweep_dir/elbow_plot.pdf)
# ---------------------------------------------------------------------------

# seu <- JackStraw(seu, num.replicate = 100, dims = 80)
# seu <- ScoreJackStraw(seu, dims = 1:80)
# p_jackstraw <- JackStrawPlot(seu, dims = 1:80)
# ggsave(file.path(track_dir, "jackstraw_plot.pdf"),
#        plot = p_jackstraw, width = 12, height = 6)
# p_elbow_final <- ElbowPlot(seu, ndims = 80) + theme_bw()
# ggsave(file.path(track_dir, "elbow_plot_final.pdf"),
#        plot = p_elbow_final, width = 7, height = 5)

# Re-join layers after split (needed by AUCell, FindAllMarkers, FindConservedMarkers)
seu[["RNA"]] <- JoinLayers(seu[["RNA"]])

# ---------------------------------------------------------------------------
# 5. AUCell — cell cycle and G2M gene sets
# ---------------------------------------------------------------------------

cellcycle_genes <- c(
  "TOP2A",
  "MCM2",
  "MCM3",
  "MCM5",
  "MCM6",
  "MKI67"
)

g2m.genes <- c(
  "ATF5",
  "AURKA",
  "AURKB",
  "BARD1",
  "BIRC5",
  "BRCA2",
  "BUB1",
  "CCNA2",
  "CCNB2",
  "CCND1",
  "CDC20",
  "CDC45",
  "CDC6",
  "CDK1",
  "CDK2",
  "CDK4",
  "CDKN3",
  "CENPA",
  "CENPE",
  "CENPF",
  "CHAF1A",
  "CHEK1",
  "CKS1B",
  "CKS2",
  "E2F1",
  "E2F2",
  "EGF",
  "ESPL1",
  "EXO1",
  "FBXO5",
  "GINS2",
  "HMGN2",
  "HMMR",
  "KIF11",
  "KIF15",
  "KIF20B",
  "KIF23",
  "KIF2C",
  "KIF4A",
  "KNL1",
  "LMNB1",
  "MAD2L1",
  "MAP3K20",
  "MCM2",
  "MCM3",
  "MCM4",
  "MCM5",
  "MCM6",
  "MKI67",
  "MT2A",
  "MYBL2",
  "NDC80",
  "NEK2",
  "NOTCH2",
  "NUSAP1",
  "ORC6",
  "PBK",
  "PCNA",
  "PLK1",
  "PLK4",
  "POLA2",
  "POLQ",
  "PTTG1",
  "RAD54L",
  "SMC4",
  "STIL",
  "TACC3",
  "TOP2A",
  "TPX2",
  "TROAP",
  "TTK",
  "UBE2C"
)

DefaultLayer(seu[["RNA"]]) <- "data"
exprMatrix <- as.matrix(seu[["RNA"]]$data)

cells_rankings <- AUCell_buildRankings(exprMatrix, plotStats = FALSE)

cells_AUC_cellcycle <- AUCell_calcAUC(cellcycle_genes, cells_rankings, aucMaxRank = 20000)
cells_AUC_g2m       <- AUCell_calcAUC(g2m.genes,       cells_rankings, aucMaxRank = 20000)

pdf(file.path(track_dir, "aucell", "aucell_thresholds_cellcycle.pdf"))
cells_assignment_cellcycle <- AUCell_exploreThresholds(cells_AUC_cellcycle,
                                                       plotHist = TRUE,
                                                       assign   = TRUE)
dev.off()

pdf(file.path(track_dir, "aucell", "aucell_thresholds_g2m.pdf"))
cells_assignment_g2m <- AUCell_exploreThresholds(cells_AUC_g2m,
                                                 plotHist = TRUE,
                                                 assign   = TRUE)
dev.off()

# Helper: scatter plot of AUCell passing/failing cells on UMAP
plot_aucell_simple <- function(seurat_obj, cells_AUC, cells_assignment,
                               gene_set_name, reduction = "umap.harmony",
                               only_passing = FALSE,
                               only_failing  = FALSE) {

  cellUmap <- seurat_obj@reductions[[reduction]]@cell.embeddings
  selectedThreshold <- unname(cells_assignment[[1]]$aucThr$selected)
  auc_scores        <- getAUC(cells_AUC)[1, ]
  passThreshold     <- auc_scores > selectedThreshold

  n_passed     <- sum(passThreshold)
  passing_cells <- names(passThreshold)[passThreshold]
  failing_cells <- names(passThreshold)[!passThreshold]

  old_par <- par(mar = c(5, 4, 4, 10))
  on.exit(par(old_par))

  if (only_passing) {
    plot(cellUmap[passing_cells, ],
         main = paste0(gene_set_name, " (", n_passed, "g)"),
         sub  = "Pink cells pass the threshold",
         col  = "deeppink", pch = 16, cex = 0.8,
         xlab = "UMAP_1", ylab = "UMAP_2",
         xlim = c(-16, 16), ylim = c(-16, 16), axes = FALSE)

  } else if (only_failing) {
    plot(cellUmap[failing_cells, ],
         main = paste0(gene_set_name, " (", n_passed, "g)"),
         sub  = "Gray cells below threshold",
         col  = "gray80", pch = 16, cex = 0.8,
         xlab = "UMAP_1", ylab = "UMAP_2",
         xlim = c(-16, 16), ylim = c(-16, 16), axes = FALSE)

  } else {
    plot(cellUmap[failing_cells, ],
         main = paste0(gene_set_name, " (", n_passed, "g)"),
         sub  = "Pink cells pass the threshold",
         col  = "gray80", pch = 16, cex = 0.8,
         xlab = "UMAP_1", ylab = "UMAP_2",
         xlim = c(-16, 16), ylim = c(-16, 16), axes = FALSE)
    points(cellUmap[passing_cells, ], col = "deeppink", pch = 16, cex = 0.8)
  }

  axis(1, at = seq(-16, 16, by = 4))
  axis(2, at = seq(-16, 16, by = 4))
  box(lwd = 2)

  legend(x     = par("usr")[2],
         y     = par("usr")[4],
         legend = c("Below threshold", "Above threshold"),
         col   = c("gray80", "deeppink"),
         pch   = 16, pt.cex = 0.8, cex = 0.8, bty = "n",
         title = "AUC Threshold",
         xpd   = NA, xjust = 0, yjust = 1)
}

# Helper: bar chart of cells above/below AUC threshold per cluster
plot_aucell_cluster_counts <- function(seurat_obj, cells_AUC, cells_assignment,
                                       gene_set_name,
                                       cluster_col = "harmony_res.0.2") {

  selectedThreshold <- unname(cells_assignment[[1]]$aucThr$selected)
  auc_scores        <- getAUC(cells_AUC)[1, ]
  passThreshold     <- auc_scores > selectedThreshold

  df <- data.frame(
    cell    = names(auc_scores),
    cluster = seurat_obj@meta.data[[cluster_col]][
      match(names(auc_scores), rownames(seurat_obj@meta.data))
    ],
    status  = ifelse(passThreshold, "Above threshold", "Below threshold"),
    stringsAsFactors = FALSE
  ) %>%
    filter(!is.na(cluster)) %>%
    mutate(cluster = factor(cluster))

  counts_df <- df %>%
    group_by(cluster, status) %>%
    summarise(n = n(), .groups = "drop")

  fisher_results <- df %>%
    group_by(cluster) %>%
    do({
      current_cluster <- unique(.$cluster)
      a <- sum(.$status == "Above threshold")
      b <- sum(.$status == "Below threshold")
      others <- df %>% filter(cluster != current_cluster)
      c <- sum(others$status == "Above threshold")
      d <- sum(others$status == "Below threshold")
      mat  <- matrix(c(a, b, c, d), nrow = 2)
      pval <- fisher.test(mat)$p.value
      data.frame(p = pval)
    }) %>%
    ungroup()

  fisher_results$p_adj <- p.adjust(fisher_results$p, method = "BH")
  fisher_results$stars <- cut(
    fisher_results$p_adj,
    breaks = c(-Inf, 0.001, 0.01, 0.05, Inf),
    labels = c("***", "**", "*", "ns")
  )

  max_counts <- counts_df %>%
    group_by(cluster) %>%
    summarise(max_n = max(n), .groups = "drop")

  fisher_results <- left_join(fisher_results, max_counts, by = "cluster")

  global_max       <- max(counts_df$n)
  counts_df$y_label        <- counts_df$n + global_max * 0.015
  fisher_results$y_pos     <- fisher_results$max_n + global_max * 0.12

  dodge <- position_dodge(width = 1)

  p <- ggplot(counts_df, aes(x = cluster, y = n, fill = status)) +
    geom_bar(stat = "identity", position = dodge, width = 0.8, alpha = 0.85) +
    geom_text(aes(y = y_label, label = n),
              position = dodge, size = 3, fontface = "bold") +
    geom_text(data = fisher_results %>% filter(stars != "ns"),
              aes(x = cluster, y = y_pos, label = stars),
              inherit.aes = FALSE, size = 5, fontface = "bold") +
    geom_text(data = fisher_results %>% filter(stars == "ns"),
              aes(x = cluster, y = y_pos, label = stars),
              inherit.aes = FALSE, size = 3.5, color = "gray40") +
    scale_fill_manual(values = c("Above threshold" = "deeppink",
                                 "Below threshold"  = "gray70")) +
    scale_y_continuous(limits = c(0, global_max * 1.4),
                       expand = expansion(mult = c(0, 0))) +
    labs(title = paste0(gene_set_name,
                        " — Cells Above/Below AUC Threshold per Cluster"),
         x    = "Cluster", y = "Number of Cells", fill = "AUC Status") +
    theme_classic() +
    theme(axis.text.x     = element_text(angle = 45, hjust = 1),
          legend.position  = "top",
          plot.title       = element_text(face = "bold", hjust = 0.5))

  return(p)
}

# Save AUCell scatter plots (umap.harmony)
pdf(file.path(track_dir, "aucell", "aucell_cellcycle_umap.pdf"), width = 10, height = 8)
plot_aucell_simple(seu, cells_AUC_cellcycle, cells_assignment_cellcycle,
                   "CellCycle", reduction = "umap.harmony")
plot_aucell_simple(seu, cells_AUC_cellcycle, cells_assignment_cellcycle,
                   "CellCycle", reduction = "umap.harmony", only_passing = TRUE)
plot_aucell_simple(seu, cells_AUC_cellcycle, cells_assignment_cellcycle,
                   "CellCycle", reduction = "umap.harmony", only_failing  = TRUE)
dev.off()

pdf(file.path(track_dir, "aucell", "aucell_g2m_umap.pdf"), width = 10, height = 8)
plot_aucell_simple(seu, cells_AUC_g2m, cells_assignment_g2m,
                   "G2M", reduction = "umap.harmony")
plot_aucell_simple(seu, cells_AUC_g2m, cells_assignment_g2m,
                   "G2M", reduction = "umap.harmony", only_passing = TRUE)
plot_aucell_simple(seu, cells_AUC_g2m, cells_assignment_g2m,
                   "G2M", reduction = "umap.harmony", only_failing  = TRUE)
dev.off()

# Cluster bar charts
p_cc_clusters <- plot_aucell_cluster_counts(seu, cells_AUC_cellcycle,
                                             cells_assignment_cellcycle,
                                             gene_set_name = "CellCycle",
                                             cluster_col   = "harmony_res.0.2")
ggsave(file.path(track_dir, "aucell", "aucell_cellcycle_cluster_barchart.pdf"),
       plot = p_cc_clusters, width = 10, height = 6)

p_g2m_clusters <- plot_aucell_cluster_counts(seu, cells_AUC_g2m,
                                              cells_assignment_g2m,
                                              gene_set_name = "G2M",
                                              cluster_col   = "harmony_res.0.2")
ggsave(file.path(track_dir, "aucell", "aucell_g2m_cluster_barchart.pdf"),
       plot = p_g2m_clusters, width = 10, height = 6)

# --- Bar charts by sample (Day7 / Day13 / iPSC) ---

timepoints   <- c("Day13", "Day7", "iPSC")
tp_colors    <- timepoint_colors

make_aucell_timepoint_barchart <- function(cells_AUC, cells_assignment,
                                            seurat_obj, timepoints, tp_colors,
                                            title_label) {

  auc_scores        <- getAUC(cells_AUC)[1, ]
  selectedThreshold <- unname(cells_assignment[[1]]$aucThr$selected)

  df_all <- data.frame(
    cell      = names(auc_scores),
    timepoint = seurat_obj@meta.data[
      match(names(auc_scores), rownames(seurat_obj@meta.data)), "sample"
    ],
    status = ifelse(auc_scores > selectedThreshold, "Above threshold", "Below threshold"),
    stringsAsFactors = FALSE
  ) %>%
    filter(timepoint %in% timepoints) %>%
    mutate(timepoint = factor(timepoint, levels = timepoints))

  counts_df <- df_all %>%
    group_by(timepoint, status) %>%
    summarise(n = n(), .groups = "drop")

  fisher_results <- lapply(timepoints, function(tp) {
    a <- sum(df_all$timepoint == tp & df_all$status == "Above threshold")
    b <- sum(df_all$timepoint == tp & df_all$status == "Below threshold")
    others <- df_all %>% filter(timepoint != tp)
    c <- sum(others$status == "Above threshold")
    d <- sum(others$status == "Below threshold")
    mat  <- matrix(c(a, b, c, d), nrow = 2)
    pval <- fisher.test(mat)$p.value
    data.frame(timepoint = tp, p = pval)
  }) %>% bind_rows()

  fisher_results$p_adj <- p.adjust(fisher_results$p, method = "BH")
  fisher_results$stars <- cut(
    fisher_results$p_adj,
    breaks = c(-Inf, 0.001, 0.01, 0.05, Inf),
    labels = c("***", "**", "*", "ns")
  )

  global_max <- max(counts_df$n)

  max_per_tp <- counts_df %>%
    group_by(timepoint) %>%
    summarise(max_n = max(n), .groups = "drop")

  fisher_results <- left_join(fisher_results, max_per_tp, by = "timepoint")
  fisher_results$y_pos <- fisher_results$max_n + global_max * 0.08
  counts_df$y_label    <- counts_df$n + global_max * 0.01

  dodge <- position_dodge(width = 0.8)

  p <- ggplot(counts_df, aes(x = timepoint, y = n, fill = status)) +
    geom_bar(stat = "identity", position = dodge, width = 0.7, alpha = 0.85) +
    geom_text(aes(y = y_label, label = n),
              position = dodge, size = 3, fontface = "bold") +
    geom_text(data = fisher_results %>% filter(stars != "ns"),
              aes(x = timepoint, y = y_pos, label = stars),
              inherit.aes = FALSE, size = 5, fontface = "bold") +
    geom_text(data = fisher_results %>% filter(stars == "ns"),
              aes(x = timepoint, y = y_pos, label = stars),
              inherit.aes = FALSE, size = 3.5, color = "gray40") +
    scale_fill_manual(values = c("Above threshold" = "deeppink",
                                 "Below threshold"  = "gray70")) +
    scale_y_continuous(limits = c(0, global_max * 1.3),
                       expand = expansion(mult = c(0, 0))) +
    labs(title = title_label, x = "Timepoint",
         y = "Number of Cells", fill = "AUC Status") +
    theme_classic() +
    theme(plot.title       = element_text(face = "bold", hjust = 0.5),
          legend.position  = "top",
          axis.text.x      = element_text(size = 12, face = "bold",
                                          color = tp_colors[levels(counts_df$timepoint)]))

  return(p)
}

p_cc_tp <- make_aucell_timepoint_barchart(
  cells_AUC_cellcycle, cells_assignment_cellcycle, seu, timepoints, tp_colors,
  "Cell Cycle Gene Set — Cells Above/Below AUC Threshold by Timepoint"
)
ggsave(file.path(track_dir, "aucell", "aucell_cellcycle_sample_barchart.pdf"),
       plot = p_cc_tp, width = 8, height = 6)

p_g2m_tp <- make_aucell_timepoint_barchart(
  cells_AUC_g2m, cells_assignment_g2m, seu, timepoints, tp_colors,
  "G2M Gene Set — Cells Above/Below AUC Threshold by Timepoint"
)
ggsave(file.path(track_dir, "aucell", "aucell_g2m_sample_barchart.pdf"),
       plot = p_g2m_tp, width = 8, height = 6)

# ---------------------------------------------------------------------------
# 6. iSN marker FeaturePlots + DotPlot
# ---------------------------------------------------------------------------

isN_markers <- c(
  "TUBB3", "PRPH", "SNAP25",
  "CALCA", "TRPV1",
  "MRGPRD",
  "NTRK2", "NTRK3",
  "POU5F1", "SOX2", "NANOG"
)

p_feature_pca <- FeaturePlot(seu, features = isN_markers,
                              reduction = "umap.pca", ncol = 4) &
  scale_color_viridis_c(option = "plasma")
ggsave(file.path(track_dir, "featureplot_markers_pca.pdf"),
       plot = p_feature_pca, width = 16, height = 12)

p_feature_harmony <- FeaturePlot(seu, features = isN_markers,
                                  reduction = "umap.harmony", ncol = 4) &
  scale_color_viridis_c(option = "plasma")
ggsave(file.path(track_dir, "featureplot_markers_harmony.pdf"),
       plot = p_feature_harmony, width = 16, height = 12)

p_dot <- DotPlot(seu, features = isN_markers, group.by = "harmony_res.0.2") +
  RotatedAxis() +
  scale_color_gradient(low = "white", high = "red",
                       limits = c(-1, 3), oob = squish)
ggsave(file.path(track_dir, "dotplot_isN_markers.pdf"),
       plot = p_dot, width = 10, height = 6)

# ---------------------------------------------------------------------------
# 7. G2M gene FeaturePlot (individual genes on umap.harmony)
# ---------------------------------------------------------------------------

g2m_vis_genes <- c("MKI67", "TOP2A", "MCM2", "MCM3", "MCM5", "MCM6")

p_g2m_fp <- FeaturePlot(seu, features = g2m_vis_genes,
                         reduction = "umap.harmony", ncol = 3) &
  scale_color_viridis_c(option = "plasma")
ggsave(file.path(track_dir, "featureplot_g2m_genes.pdf"),
       plot = p_g2m_fp, width = 14, height = 9)

# ---------------------------------------------------------------------------
# 8. Module scores (iSN gene sets)
# ---------------------------------------------------------------------------

safe_module_score <- function(seu, features, name) {
  tryCatch(
    AddModuleScore(seu, features = list(features), name = name),
    error = function(e) { message("Skipping ", name, ": ", conditionMessage(e)); seu }
  )
}

seu <- safe_module_score(seu, c("TUBB3", "MAP2", "RBFOX3", "SNAP25"),           "pan_neuronal_score")
seu <- safe_module_score(seu, c("CALCA", "TRPV1", "TAC1", "NTRK1"),             "peptidergic_score")
seu <- safe_module_score(seu, c("TH", "CDH9"),                                   "cLTMR_score")
seu <- safe_module_score(seu, c("TRPM8"),                                         "Cold_score")
seu <- safe_module_score(seu, c("AR", "C3"),                                      "SN_score")
seu <- safe_module_score(seu, c("MRGPRD"),                                        "non_peptidergic_score")
seu <- safe_module_score(seu, c("NTRK2", "NTRK3"),                               "trkbc_score")
seu <- safe_module_score(seu, c("POU5F1", "SOX2", "NANOG"),                      "ipsc_score")
seu <- safe_module_score(seu, c("MCM2","MCM3","MCM4","MCM5","MCM6","MKI67","TOP2A"), "G2M_proliferation_score")



score_features <- intersect(
  c("pan_neuronal_score1", "peptidergic_score1", "non_peptidergic_score1",
    "trkbc_score1", "ipsc_score1"),
  colnames(seu@meta.data)
)

if (length(score_features) > 0) {
  p_scores <- FeaturePlot(seu, min.cutoff = "q05", max.cutoff = "q95",
                          features = score_features,
                          reduction = "umap.harmony", ncol = 3) &
    scale_color_viridis_c(option = "plasma")
  ggsave(file.path(track_dir, "featureplot_module_scores.pdf"),
         plot = p_scores, width = 14, height = 9)
} else {
  message("No module score columns found — skipping featureplot_module_scores.pdf")
}

# ---------------------------------------------------------------------------
# 8.1. User-specified gene set module scores (from --gene_sets / RStudio override)
# ---------------------------------------------------------------------------

if (!is.null(args_gene_sets) && nchar(args_gene_sets) > 0) {
  sets_raw <- strsplit(args_gene_sets, ";")[[1]]
  gene_set_list <- lapply(sets_raw, function(s) {
    parts <- strsplit(s, "=")[[1]]
    list(name = parts[1], genes = strsplit(parts[2], ",")[[1]])
  })

  for (gs in gene_set_list) {
    set_name  <- gs$name
    set_genes <- gs$genes
    score_col <- paste0("score_", set_name)

    seu_scored <- tryCatch(
      AddModuleScore(seu, features = list(set_genes), name = score_col),
      error = function(e) {
        message("Skipping gene set '", set_name, "': ", conditionMessage(e))
        NULL
      }
    )
    if (is.null(seu_scored)) next
    seu <- seu_scored

    seu[[score_col]] <- seu[[paste0(score_col, "1")]]
    seu[[paste0(score_col, "1")]] <- NULL

    out_prefix <- file.path(track_dir, paste0("module_score_", set_name))

    p_umap <- FeaturePlot(seu, features = score_col,
                          reduction = "umap.harmony", pt.size = 0.3) +
              scale_colour_viridis_c() +
              ggtitle(paste("Module score:", set_name))
    ggsave(paste0(out_prefix, "_umap.pdf"), p_umap, width = 6, height = 5)

    p_vln <- VlnPlot(seu, features = score_col,
                     group.by = "harmony_res.0.2", pt.size = 0) +
             ggtitle(paste("Module score:", set_name)) +
             NoLegend()
    ggsave(paste0(out_prefix, "_violin.pdf"), p_vln, width = 8, height = 4)
  }
}

# ---------------------------------------------------------------------------
# 9. Violin plots (IQR-summary style from reference)
# ---------------------------------------------------------------------------

iqr_summary <- function(x) {
  data.frame(
    y    = median(x),
    ymin = quantile(x, 0.25),
    ymax = quantile(x, 0.75)
  )
}

violin_genes <- c(
  "TUBB3", "PRPH", "SNAP25", "CALCA", "TRPV1", "MRGPRD",
  "NTRK2", "NTRK3", "POU5F1", "SOX2", "NANOG",
  "MKI67", "TOP2A", "MCM2"
)

Idents(seu) <- seu$harmony_res.0.2

violin_genes_present <- intersect(violin_genes, rownames(seu[["RNA"]]))
for (gene in violin_genes_present) {
  df_vln <- FetchData(seu, vars = c(gene, "harmony_res.0.2"))
  colnames(df_vln)[1] <- "expr"

  p_vln <- ggplot(df_vln, aes(x = harmony_res.0.2, y = expr,
                               fill = harmony_res.0.2)) +
    geom_violin(scale = "width", trim = TRUE) +
    stat_summary(fun.data = iqr_summary, geom = "crossbar",
                 width = 0.3, color = "black") +
    scale_fill_brewer(palette = "Set3") +
    theme_classic() +
    theme(legend.position = "none",
          plot.title      = element_text(face = "bold", hjust = 0.5),
          axis.text.x     = element_text(angle = 45, hjust = 1)) +
    labs(title = gene, x = "Cluster (harmony_res.0.2)", y = "Expression")

  ggsave(file.path(track_dir, paste0("violin_", gene, ".pdf")),
         plot = p_vln, width = 8, height = 5)
}

# ---------------------------------------------------------------------------
# 10. Pie chart by sample (Day7 / Day13 / iPSC)
# ---------------------------------------------------------------------------

group_df <- seu@meta.data %>%
  group_by(sample) %>%
  summarise(count = n(), .groups = "drop") %>%
  mutate(percentage = count / sum(count) * 100)

group_df$sample <- factor(group_df$sample, levels = c("iPSC", "Day7", "Day13"))

group_df <- group_df %>%
  arrange(sample) %>%
  mutate(
    label = paste0(round(percentage, 1), "%\n(n=", count, ")"),
    csum  = rev(cumsum(rev(percentage))),
    ypos  = percentage / 2 + lead(csum, default = 0)
  )

p_pie <- ggplot(group_df, aes(x = "", y = percentage, fill = sample)) +
  geom_bar(stat = "identity", width = 1, color = "white") +
  coord_polar("y", start = 0) +
  theme_void() +
  geom_text(aes(y = ypos, label = label),
            fontface = "bold", size = 4, color = "black") +
  scale_fill_manual(values = c("iPSC"  = "#F5A623",
                               "Day7"  = "#D73027",
                               "Day13" = "#4E8FCA")) +
  ggtitle("iSN samples — Day7 / Day13 / iPSC") +
  theme(plot.title      = element_text(hjust = 0.5, size = 18, face = "bold"),
        legend.title    = element_blank(),
        legend.text     = element_text(size = 12))

ggsave(file.path(track_dir, "piechart_by_sample.pdf"),
       plot = p_pie, width = 7, height = 7)

# ---------------------------------------------------------------------------
# 11. FindAllMarkers + DoHeatmap
# ---------------------------------------------------------------------------

Idents(seu) <- seu$harmony_res.0.2

all_markers <- FindAllMarkers(seu,
                              only.pos       = TRUE,
                              min.pct        = 0.1,
                              logfc.threshold = 1)

write.csv(all_markers,
          file.path(track_dir, "04_all_markers_harmony_res0.2.csv"),
          row.names = FALSE)

# DoHeatmap — top 5 genes per cluster, downsampled to 100 cells
top5 <- all_markers %>%
  group_by(cluster) %>%
  slice_max(order_by = avg_log2FC, n = 5) %>%
  ungroup()

DefaultLayer(seu[["RNA"]]) <- "data"

set.seed(123)
cells.use <- unlist(
  lapply(split(Cells(seu), Idents(seu)),
         function(x) sample(x, min(length(x), 100)))
)

p_heatmap <- DoHeatmap(seu,
                       features  = unique(top5$gene),
                       cells     = cells.use,
                       group.by  = "harmony_res.0.2",
                       raster    = TRUE) +
  ggtitle("Top 5 Marker Genes per Cluster (Downsampled Heatmap)")

ggsave(file.path(track_dir, "04_heatmap_top5_markers.pdf"),
       plot = p_heatmap, width = 14, height = 10)

# Section 12 commented out — metap package unavailable (qqconf dependency missing on this system)
# ---------------------------------------------------------------------------
# # 12. FindConservedMarkers (cluster "0" as example)
# ---------------------------------------------------------------------------
#
# conserved_markers_cluster0 <- FindConservedMarkers(
#   seu,
#   ident.1     = "0",
#   grouping.var = "sample",
#   only.pos    = TRUE
# )
#
# write.csv(conserved_markers_cluster0,
#           file.path(track_dir, "04_conserved_markers_cluster0.csv"),
#           row.names = TRUE)

# ---------------------------------------------------------------------------
# 13. Save final object + session info
# ---------------------------------------------------------------------------

saveRDS(seu, file.path(out_dir, paste0("04_seu_clustered_", args_track, ".rds")))
capture.output(sessionInfo(), file = file.path(track_dir, "04_session_info.txt"))
