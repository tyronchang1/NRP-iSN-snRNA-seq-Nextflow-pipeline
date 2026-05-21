rm(list = ls(all.name = TRUE))
dir <- "/scratch/rmlab/rmlab_shared3/tyron/Rscriptv2/iSN/iSN_claude"
setwd(dir)
pdf(NULL)

library(Seurat)
library(ggplot2)
library(dplyr)
library(scales)
library(patchwork)

# Parse --track command-line argument
.args <- commandArgs(trailingOnly = TRUE)
.get_arg <- function(flag, default = "") {
  i <- which(.args == flag)
  if (length(i) > 0 && i < length(.args)) .args[i + 1L] else default
}
args_track <- .get_arg("--track", "decontx")
# RStudio override — uncomment to run without CLI args:
# args_track <- "decontx"

# Create output directory
dir.create("./scripts/03_Cell_filtering/Cell_filtering_output", recursive = TRUE, showWarnings = FALSE)
dir.create("./scripts/03_Cell_filtering/Cell_filtering_output/soupx",   recursive = TRUE, showWarnings = FALSE)
dir.create("./scripts/03_Cell_filtering/Cell_filtering_output/decontx", recursive = TRUE, showWarnings = FALSE)

## SoupX track ----
if (args_track == "soupx") {

seu_soupx <- readRDS("./scripts/02_scDblFinder_soupx/scDblFinder_output/iSN_doubletstep.rds")
seu_soupx[["percent.mt"]] <- PercentageFeatureSet(seu_soupx, pattern = "^MT-")

### Plot QC metrics — SoupX ----
# Violin plots to visualize QC columns:
violin1 <- VlnPlot(seu_soupx,
        features = c("nFeature_RNA", "nCount_RNA", "percent.mt"),
        group.by = 'sample_group',
        pt.size = 0.01,
        ncol = 3)
violin1
ggsave("./scripts/03_Cell_filtering/Cell_filtering_output/soupx/violin_by_sample.pdf",
       plot = violin1, width = 11, height = 8.5, dpi = 300)

# Violin plots to visualize QC columns by doublet vs singlet:
violin2 <- VlnPlot(seu_soupx,
        features = c("nFeature_RNA", "nCount_RNA", "percent.mt"),
        group.by = 'scDblFinder.class',
        pt.size = 0.01,
        ncol = 3)
violin2
ggsave("./scripts/03_Cell_filtering/Cell_filtering_output/soupx/violin_by_doublet.pdf",
       plot = violin2, width = 11, height = 8.5, dpi = 300)

# Look at relationships before filtering
all_seu_meta <- seu_soupx@meta.data

# 1 — Number of genes vs. percent mitochondrial reads (color = doublet classification):
g1 <- ggplot(all_seu_meta, aes(x = percent.mt, y = nFeature_RNA, color = scDblFinder.class)) +
  geom_point(size = 0.01) + geom_vline(aes(xintercept = 20), color = "red", lty = "longdash") +
  geom_hline(aes(yintercept = 800), color = "black", lty = "longdash") +
  facet_wrap(~sample_group) +
  scale_x_continuous(breaks = seq(0, 100, 10), lim = c(0, 100)) +
  scale_y_continuous(breaks = seq(0, 10000, 2000), lim = c(0, 10000)) +
  theme_bw()
g1
ggsave("./scripts/03_Cell_filtering/Cell_filtering_output/soupx/scatter_mito_vs_gene_doublet.pdf",
       plot = g1, width = 11, height = 8.5, dpi = 300)

# 2 — Number of genes vs. percent mitochondrial reads (color = sample):
g2 <- ggplot(all_seu_meta, aes(x = percent.mt, y = nFeature_RNA, color = sample_group)) +
  geom_point(size = 0.01) + geom_vline(aes(xintercept = 20), color = "red", lty = "longdash") +
  geom_hline(aes(yintercept = 5000), color = "black", lty = "longdash") +
  facet_wrap(~sample_group) +
  scale_x_continuous(breaks = seq(0, 100, 10), lim = c(0, 100)) +
  scale_y_continuous(breaks = seq(0, 10000, 2000), lim = c(0, 10000)) +
  theme_bw()
g2
ggsave("./scripts/03_Cell_filtering/Cell_filtering_output/soupx/scatter_mito_vs_gene_sample.pdf",
       plot = g2, width = 11, height = 8.5, dpi = 300)

# 3 — Number of genes vs. percent mitochondrial reads (color = UMI count):
g3 <- ggplot(all_seu_meta, aes(x = percent.mt, y = nFeature_RNA, color = nCount_RNA)) +
  geom_point(size = 0.75) +
  facet_grid(~sample_group) +
  scale_y_continuous(breaks = seq(0, 10000, 500), limits = c(0, 10000)) +
  geom_hline(aes(yintercept = 700), color = "black", lty = "longdash") +
  geom_vline(aes(xintercept = 20), color = "black", lty = "longdash") +
  theme_get() +
  scale_colour_gradient(low = "gold", high = "red", limits = c(0, 8000), oob = squish)
g3
ggsave("./scripts/03_Cell_filtering/Cell_filtering_output/soupx/scatter_mito_vs_gene_umi.pdf",
       plot = g3, width = 11, height = 8.5, dpi = 300)

# 4 — Number of genes vs. percent mitochondrial reads (color = doublet classification):
g4 <- ggplot(all_seu_meta, aes(x = percent.mt, y = nFeature_RNA, color = scDblFinder.class)) +
  geom_point(size = 0.75) +
  facet_wrap(~sample_group, ncol = 3) +
  scale_x_continuous(breaks = seq(0, 100, 10), lim = c(0, 100)) +
  geom_vline(aes(xintercept = 20), color = "black", lty = "longdash") +
  theme_bw()
g4
ggsave("./scripts/03_Cell_filtering/Cell_filtering_output/soupx/scatter_mito_vs_gene_doublet2.pdf",
       plot = g4, width = 11, height = 8.5, dpi = 300)

# 5 — Number of genes vs. number of reads (color = mitochondrial reads):
g5 <- ggplot(all_seu_meta, aes(x = nCount_RNA, y = nFeature_RNA, color = percent.mt)) +
  geom_point(size = 0.75) +
  facet_wrap(~sample_group, ncol = 3) +
  theme_bw() +
  theme(plot.title = element_text(size = 10)) +
  geom_vline(aes(xintercept = 500), color = "black", lty = "longdash") +
  RotatedAxis() +
  xlim(0, 90000) +
  ylim(0, 10000) +
  scale_colour_gradient(low = "gold", high = "red", limits = c(0, 50), oob = squish) +
  ggtitle("nFeature vs nCounts")
g5
ggsave("./scripts/03_Cell_filtering/Cell_filtering_output/soupx/scatter_count_vs_gene_mito.pdf",
       plot = g5, width = 11, height = 8.5, dpi = 300)

# 6 — Number of genes vs. number of reads (color = doublet classification):
g6 <- ggplot(all_seu_meta, aes(x = nCount_RNA, y = nFeature_RNA, color = scDblFinder.class)) +
  geom_point(size = 0.75) +
  geom_vline(aes(xintercept = 500), color = "black", lty = "longdash") +
  geom_hline(aes(yintercept = 800), color = "black", lty = "longdash") +
  facet_wrap(~sample_group, ncol = 3) +
  scale_x_continuous(breaks = seq(0, 20000, 2000), lim = c(0, 20000)) +
  theme_bw() + ylim(0, 10000)
g6
ggsave("./scripts/03_Cell_filtering/Cell_filtering_output/soupx/scatter_count_vs_gene_doublet.pdf",
       plot = g6, width = 11, height = 8.5, dpi = 300)

# QC thresholds — PRELIMINARY; adjust after inspecting plots above:
# Keep nuclei with percent.mt <= 20%
# Keep nuclei with nFeature_RNA > 700
# Keep nuclei with nCount_RNA > 500
# Keep singlets only (scDblFinder.class == 'singlet')

### Filter — SoupX ----
keepMito  <- WhichCells(seu_soupx, expression = percent.mt <= 20)
keepGenes <- WhichCells(seu_soupx, expression = nFeature_RNA > 700)
keepUMI   <- WhichCells(seu_soupx, expression = nCount_RNA > 500)
keepDub   <- WhichCells(seu_soupx, expression = scDblFinder.class == 'singlet')

keep <- Reduce(intersect, list(keepMito, keepGenes, keepUMI, keepDub))
length(keep)

df_summary <- data.frame(total_nuclei = nrow(all_seu_meta), mito_filter = length(keepMito),
                         gene_filter = length(keepGenes), umi_filter = length(keepUMI),
                         singlet_filter = length(keepDub), pass_all = length(keep))
df_summary
rm(keepMito, keepGenes, keepUMI, keepDub)

# Subset to cells passing all QC filters:
seuKeep <- subset(seu_soupx, cells = keep)
dim(seuKeep)
table(seuKeep$sample_group)

# Post-filter overlay plot (grey = all, red = kept):
metaKeep <- seuKeep@meta.data
g_overlay <- ggplot(all_seu_meta, aes(x = percent.mt, y = nFeature_RNA)) +
  geom_point(aes(color = 'all'), size = 0.75) +
  facet_wrap(~sample_group, nrow = 1) +
  theme_bw() +
  geom_point(data = metaKeep, aes(x = percent.mt, y = nFeature_RNA, color = 'kept'), size = 0.75) +
  scale_color_manual(values = c('all' = 'grey90', 'kept' = 'red'))
g_overlay
ggsave("./scripts/03_Cell_filtering/Cell_filtering_output/soupx/overlay_pre_post_filter.pdf",
       plot = g_overlay, width = 14, height = 8.5, dpi = 300)

### Save — SoupX ----
counts <- seuKeep@assays$RNA@counts
seuNew <- CreateSeuratObject(counts = counts, min.cells = 1)
seuNew #33635 genes across 66566 cells within 1 assay

# Seurat v5 -> v3 compatibility shim:
seuNew[["RNA"]] <- CreateAssayObject(counts = seuNew[["RNA"]]$counts)

saveRDS(seuNew, "./scripts/03_Cell_filtering/Cell_filtering_output/03_seu_cellfiltered_soupx.rds")

} ## end soupx track

## DecontX track ----
if (args_track == "decontx") {

seu_decontx <- readRDS("./scripts/02.1_scDblFinder_decontX/scDblFinder_output/iSN_decontX_scDblFinder.rds")
seu_decontx[["percent.mt"]] <- PercentageFeatureSet(seu_decontx, pattern = "^MT-")

### Plot QC metrics — DecontX ----
# Violin plots to visualize QC columns:
violin1 <- VlnPlot(seu_decontx,
        features = c("nFeature_RNA", "nCount_RNA", "percent.mt"),
        group.by = 'sample_group',
        pt.size = 0.01,
        ncol = 3)
violin1
ggsave("./scripts/03_Cell_filtering/Cell_filtering_output/decontx/violin_by_sample.pdf",
       plot = violin1, width = 11, height = 8.5, dpi = 300)

# Violin plots to visualize QC columns by doublet vs singlet:
violin2 <- VlnPlot(seu_decontx,
        features = c("nFeature_RNA", "nCount_RNA", "percent.mt"),
        group.by = 'scDblFinder.class',
        pt.size = 0.01,
        ncol = 3)
violin2
ggsave("./scripts/03_Cell_filtering/Cell_filtering_output/decontx/violin_by_doublet.pdf",
       plot = violin2, width = 11, height = 8.5, dpi = 300)

# Look at relationships before filtering
all_seu_meta <- seu_decontx@meta.data

# 1 — Number of genes vs. percent mitochondrial reads (color = doublet classification):
g1 <- ggplot(all_seu_meta, aes(x = percent.mt, y = nFeature_RNA, color = scDblFinder.class)) +
  geom_point(size = 0.01) + geom_vline(aes(xintercept = 20), color = "red", lty = "longdash") +
  geom_hline(aes(yintercept = 800), color = "black", lty = "longdash") +
  facet_wrap(~sample_group) +
  scale_x_continuous(breaks = seq(0, 100, 10), lim = c(0, 100)) +
  scale_y_continuous(breaks = seq(0, 10000, 2000), lim = c(0, 10000)) +
  theme_bw()
g1
ggsave("./scripts/03_Cell_filtering/Cell_filtering_output/decontx/scatter_mito_vs_gene_doublet.pdf",
       plot = g1, width = 11, height = 8.5, dpi = 300)

# 2 — Number of genes vs. percent mitochondrial reads (color = sample):
g2 <- ggplot(all_seu_meta, aes(x = percent.mt, y = nFeature_RNA, color = sample_group)) +
  geom_point(size = 0.01) + geom_vline(aes(xintercept = 20), color = "red", lty = "longdash") +
  geom_hline(aes(yintercept = 5000), color = "black", lty = "longdash") +
  facet_wrap(~sample_group) +
  scale_x_continuous(breaks = seq(0, 100, 10), lim = c(0, 100)) +
  scale_y_continuous(breaks = seq(0, 10000, 2000), lim = c(0, 10000)) +
  theme_bw()
g2
ggsave("./scripts/03_Cell_filtering/Cell_filtering_output/decontx/scatter_mito_vs_gene_sample.pdf",
       plot = g2, width = 11, height = 8.5, dpi = 300)

# 3 — Number of genes vs. percent mitochondrial reads (color = UMI count):
g3 <- ggplot(all_seu_meta, aes(x = percent.mt, y = nFeature_RNA, color = nCount_RNA)) +
  geom_point(size = 0.75) +
  facet_grid(~sample_group) +
  scale_y_continuous(breaks = seq(0, 10000, 500), limits = c(0, 10000)) +
  geom_hline(aes(yintercept = 800), color = "black", lty = "longdash") +
  geom_vline(aes(xintercept = 20), color = "black", lty = "longdash") +
  theme_get() +
  scale_colour_gradient(low = "gold", high = "red", limits = c(0, 8000), oob = squish)
g3
ggsave("./scripts/03_Cell_filtering/Cell_filtering_output/decontx/scatter_mito_vs_gene_umi.pdf",
       plot = g3, width = 11, height = 8.5, dpi = 300)

# 4 — Number of genes vs. percent mitochondrial reads (color = doublet classification):
g4 <- ggplot(all_seu_meta, aes(x = percent.mt, y = nFeature_RNA, color = scDblFinder.class)) +
  geom_point(size = 0.75) +
  facet_wrap(~sample_group, ncol = 3) +
  scale_x_continuous(breaks = seq(0, 100, 10), lim = c(0, 100)) +
  geom_vline(aes(xintercept = 20), color = "black", lty = "longdash") +
  theme_bw()
g4
ggsave("./scripts/03_Cell_filtering/Cell_filtering_output/decontx/scatter_mito_vs_gene_doublet2.pdf",
       plot = g4, width = 11, height = 8.5, dpi = 300)

# 5 — Number of genes vs. number of reads (color = mitochondrial reads):
g5 <- ggplot(all_seu_meta, aes(x = nCount_RNA, y = nFeature_RNA, color = percent.mt)) +
  geom_point(size = 0.75) +
  facet_wrap(~sample_group, ncol = 3) +
  theme_bw() +
  theme(plot.title = element_text(size = 10)) +
  RotatedAxis() +
  xlim(0, 40000) +
  ylim(0, 10000) +
  scale_colour_gradient(low = "gold", high = "red", limits = c(0, 50), oob = squish) +
  ggtitle("nFeature vs nCounts")
g5
ggsave("./scripts/03_Cell_filtering/Cell_filtering_output/decontx/scatter_count_vs_gene_mito.pdf",
       plot = g5, width = 11, height = 8.5, dpi = 300)

# 6 — Number of genes vs. number of reads (color = doublet classification):
g6 <- ggplot(all_seu_meta, aes(x = nCount_RNA, y = nFeature_RNA, color = scDblFinder.class)) +
  geom_point(size = 0.75) +
  geom_vline(aes(xintercept = 500), color = "black", lty = "longdash") +
  geom_hline(aes(yintercept = 800), color = "black", lty = "longdash") +
  facet_wrap(~sample_group, ncol = 3) +
  scale_x_continuous(breaks = seq(0, 30000, 2000), lim = c(0, 20000)) +
  theme_bw() + ylim(0, 10000)
g6
ggsave("./scripts/03_Cell_filtering/Cell_filtering_output/decontx/scatter_count_vs_gene_doublet.pdf",
       plot = g6, width = 11, height = 8.5, dpi = 300)

# QC thresholds — PRELIMINARY; adjust after inspecting plots above:
# Keep nuclei with percent.mt <= 20%
# Keep nuclei with nFeature_RNA > 800
# Keep nuclei with nCount_RNA > 500
# Keep singlets only (scDblFinder.class == 'singlet')

### Filter — DecontX ----
keepMito  <- WhichCells(seu_decontx, expression = percent.mt <= 20)
keepGenes <- WhichCells(seu_decontx, expression = nFeature_RNA > 800)
keepUMI   <- WhichCells(seu_decontx, expression = nCount_RNA > 500)
keepDub   <- WhichCells(seu_decontx, expression = scDblFinder.class == 'singlet')

keep <- Reduce(intersect, list(keepMito, keepGenes, keepUMI, keepDub))
length(keep)

df_summary <- data.frame(total_nuclei = nrow(all_seu_meta), mito_filter = length(keepMito),
                         gene_filter = length(keepGenes), umi_filter = length(keepUMI),
                         singlet_filter = length(keepDub), pass_all = length(keep))
df_summary
rm(keepMito, keepGenes, keepUMI, keepDub)

# Subset to cells passing all QC filters:
seuKeep <- subset(seu_decontx, cells = keep)
dim(seuKeep)#36601 genes and 65896 cells
table(seuKeep$sample_group)

# Post-filter overlay plot (grey = all, red = kept):
metaKeep <- seuKeep@meta.data
g_overlay <- ggplot(all_seu_meta, aes(x = percent.mt, y = nFeature_RNA)) +
  geom_point(aes(color = 'all'), size = 0.75) +
  facet_wrap(~sample_group, nrow = 1) +
  theme_bw() +
  geom_point(data = metaKeep, aes(x = percent.mt, y = nFeature_RNA, color = 'kept'), size = 0.75) +
  scale_color_manual(values = c('all' = 'grey90', 'kept' = 'red'))
g_overlay
ggsave("./scripts/03_Cell_filtering/Cell_filtering_output/decontx/overlay_pre_post_filter.pdf",
       plot = g_overlay, width = 14, height = 8.5, dpi = 300)

### Save — DecontX ----
counts <- seuKeep@assays$RNA@counts
seuNew <- CreateSeuratObject(counts = counts, min.cells = 1)
seuNew

# Seurat v5 -> v3 compatibility shim:
seuNew[["RNA"]] <- CreateAssayObject(counts = seuNew[["RNA"]]$counts)
seuNew <- AddMetaData(seuNew, metadata = seuKeep@meta.data[colnames(seuNew), , drop = FALSE])
dim(seuNew)
saveRDS(seuNew, "./scripts/03_Cell_filtering/Cell_filtering_output/03_seu_cellfiltered_decontx.rds")

} ## end decontx track

### Session info ----
capture.output(sessionInfo(), file = "./scripts/03_Cell_filtering/Cell_filtering_output/03_session_info.txt")
