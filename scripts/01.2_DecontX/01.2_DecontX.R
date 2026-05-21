rm(list=ls(all.name=TRUE))
library(celda)
library(scater)
library(Seurat)
library(ggplot2)
library(patchwork)
library(SingleCellExperiment)
options(Seurat.object.assay.version = "v5")

dir <- "/scratch/rmlab/rmlab_shared3/tyron/Rscriptv2/iSN/iSN_claude"
setwd(dir)
pdf(NULL)

# Input: Cell Ranger filtered counts
filtered_dirs <- c(
  './samples/NR00_Day13_1/filtered_feature_bc_matrix',
  './samples/NR00_Day13_1_dup/filtered_feature_bc_matrix',
  './samples/NR00_Day13_2/filtered_feature_bc_matrix',
  './samples/NR00_Day13_2_dup/filtered_feature_bc_matrix',
  './samples/NR00_Day7_1/filtered_feature_bc_matrix',
  './samples/NR00_Day7_2/filtered_feature_bc_matrix',
  './samples/NR00_iPSC_1/filtered_feature_bc_matrix',
  './samples/NR00_iPSC_2/filtered_feature_bc_matrix'
)

sc_data <- Read10X(filtered_dirs)
seu <- CreateSeuratObject(sc_data)
dim(seu)# 80645 cells 36601 genes
# Convert filtered data to SCE — required for decontX
sce <- SingleCellExperiment(list(counts = seu@assays$RNA@layers$counts))

# Input: Cell Ranger raw counts (used as background for decontX)
raw_dirs <- c(
  './samples/NR00_Day13_1/raw_feature_bc_matrix',
  './samples/NR00_Day13_1_dup/raw_feature_bc_matrix',
  './samples/NR00_Day13_2/raw_feature_bc_matrix',
  './samples/NR00_Day13_2_dup/raw_feature_bc_matrix',
  './samples/NR00_Day7_1/raw_feature_bc_matrix',
  './samples/NR00_Day7_2/raw_feature_bc_matrix',
  './samples/NR00_iPSC_1/raw_feature_bc_matrix',
  './samples/NR00_iPSC_2/raw_feature_bc_matrix'
)

sc_data_raw <- Read10X(raw_dirs)
seu_raw <- CreateSeuratObject(sc_data_raw)
dim(seu_raw)#36601 genes 6330707 cells
# Keep only genes present in filtered data — required for decontX background
common_genes <- rownames(seu_raw) %in% rownames(seu)
counts_subset_raw <- seu_raw@assays$RNA@layers$counts[common_genes, ]
sce_raw <- SingleCellExperiment(list(counts = counts_subset_raw))

# Run decontX using raw counts as background
sce_decont_with_raw <- decontX(sce, background = sce_raw)
colData(sce_decont_with_raw)

# Pull results into Seurat
seu$decontX_contamination <- sce_decont_with_raw$decontX_contamination
seu$decontX_clusters <- sce_decont_with_raw$decontX_clusters

# Quick look at contamination distribution
summary(seu$decontX_contamination)

# Visualize
plotDecontXContamination(sce_decont_with_raw)
ggsave("./scripts/01.2_DecontX/DecontX_out/DecontX_contamination_umap_plot.jpg")
# Also check distribution as histogram
hist(seu$decontX_contamination, breaks = 50, 
     main = "DecontX Contamination", xlab = "Contamination Score")

# How many cells are severely contaminated?
table(seu$decontX_contamination > 0.5)  # >50% contaminated 5991 cells
table(seu$decontX_contamination > 0.8)  # >80% contaminated `684 cells`

# Assign gene names and barcodes from filtered object
rownames(sce_decont_with_raw) <- rownames(seu)
colnames(sce_decont_with_raw) <- colnames(seu)
dim(seu)#80645
# Extract decontX counts and convert back to Seurat
logcounts(sce_decont_with_raw) <- assay(sce_decont_with_raw, "decontXcounts")
seu_decont_with_raw <- as.Seurat(sce_decont_with_raw)
Assays(seu_decont_with_raw)

##use decontxcounts
seu_decont <- CreateSeuratObject(counts = decontXcounts(sce_decont_with_raw))
dim(seu_decont_with_raw)
dim(seu_decont)
all(dim(seu_decont_with_raw) == dim(seu_decont))#True


# ── INSERT SAMPLE MAPPING HERE ──────────────────────────────────────────────
desired_order <- c("NR00_Day13_1", "NR00_Day13_1_dup",
                   "NR00_Day13_2",  "NR00_Day13_2_dup",
                   "NR00_Day7_1",   "NR00_Day7_2",
                   "NR00_iPSC_1",   "NR00_iPSC_2")

sample_mapping <- data.frame(
  orig_ident   = factor(1:length(desired_order)),
  sample_group = factor(desired_order, levels = desired_order)
)

library(dplyr)
add_sample_group <- function(seu_obj) {
  meta <- seu_obj@meta.data
  barcodes <- rownames(meta)
  meta <- meta %>%
    left_join(sample_mapping, by = c("orig.ident" = "orig_ident"))
  rownames(meta) <- barcodes
  seu_obj <- AddMetaData(seu_obj, metadata = meta["sample_group"])
  seu_obj
}

seu_decont          <- add_sample_group(seu_decont)
dim(seu_decont)
seu_decont_with_raw <- add_sample_group(seu_decont_with_raw)
table(seu_decont$sample_group, useNA = "always")
table(seu_decont$orig.ident)
# ────────────────────────────────────────────────────────────────────────────

# Merge metadata from both objects
if (all(rownames(seu_decont_with_raw@meta.data) == rownames(seu_decont@meta.data))) {
  seu_decont <- AddMetaData(seu_decont, metadata = seu_decont_with_raw@meta.data)
  head(seu_decont@meta.data)
} else {
  print("error: barcode order mismatch")
}

dim(seu_decont)
# Violin plot: total counts before vs after decontX, per cluster
v1 <- VlnPlot(seu_decont,
               features = c("nCount_RNA", "nCount_originalexp"),
               group.by = "decontX_clusters",
               combine = TRUE)
v1

# UMAP cluster plot from decontX embedding
umap <- reducedDim(sce_decont_with_raw, "decontX_UMAP")
plotDimReduceCluster(x = sce_decont_with_raw$decontX_clusters,
                     dim1 = umap[, 1], dim2 = umap[, 2])

# Contamination UMAP
p1 <- plotDecontXContamination(sce_decont_with_raw)
p1

# Add UMAP coordinates to Seurat objects
seu_decont_with_raw <- AddMetaData(seu_decont_with_raw, umap, col.name = c("UMAP1", "UMAP2"))
dim(seu_decont_with_raw)
seu_decont <- AddMetaData(seu_decont, umap, col.name = c("UMAP1", "UMAP2"))
dim(seu_decont)
# iSN marker genes + iPSC pluripotency markers (POU5F1/OCT4, SOX2, NANOG)
genes <- c("TUBB3", "PRPH", "NTRK2", "NTRK3", "CALCA", "TRPV1", "MRGPRD",
           "POU5F1", "SOX2", "NANOG", "SNAP25","MAP2")

# Raw counts UMAP plots

expr_raw <- GetAssayData(seu_decont_with_raw, assay = "originalexp", layer = "counts")
umap_raw <- seu_decont_with_raw@meta.data[, c("UMAP1", "UMAP2")]
expr_raw <- expr_raw[genes, , drop = FALSE]

# TUBB3
umap_raw$TUBB3_expression <- expr_raw["TUBB3", ]
u1 <- ggplot(umap_raw, aes(x = UMAP1, y = UMAP2, color = log(TUBB3_expression + 1, base = 2))) +
  geom_point(size = 0.1) +
  scale_color_gradient(low = "grey90", high = "blue") +
  theme_minimal() +
  labs(title = "Raw Counts - TUBB3", color = "TUBB3 (log2)") +
  theme(plot.title = element_text(hjust = 0.5, size = 6),
        axis.title = element_text(size = 4), axis.text = element_text(size = 4),
        legend.text = element_text(size = 4), legend.title = element_text(size = 4),
        legend.key.size = unit(0.5, "lines"))

# PRPH
umap_raw$PRPH_expression <- expr_raw["PRPH", ]
u2 <- ggplot(umap_raw, aes(x = UMAP1, y = UMAP2, color = log(PRPH_expression + 1, base = 2))) +
  geom_point(size = 0.1) +
  scale_color_gradient(low = "grey90", high = "blue") +
  theme_minimal() +
  labs(title = "Raw Counts - PRPH", color = "PRPH (log2)") +
  theme(plot.title = element_text(hjust = 0.5, size = 6),
        axis.title = element_text(size = 4), axis.text = element_text(size = 4),
        legend.text = element_text(size = 4), legend.title = element_text(size = 4),
        legend.key.size = unit(0.5, "lines"))

# NTRK2
umap_raw$NTRK2_expression <- expr_raw["NTRK2", ]
u3 <- ggplot(umap_raw, aes(x = UMAP1, y = UMAP2, color = log(NTRK2_expression + 1, base = 2))) +
  geom_point(size = 0.1) +
  scale_color_gradient(low = "grey90", high = "blue") +
  theme_minimal() +
  labs(title = "Raw Counts - NTRK2", color = "NTRK2 (log2)") +
  theme(plot.title = element_text(hjust = 0.5, size = 6),
        axis.title = element_text(size = 4), axis.text = element_text(size = 4),
        legend.text = element_text(size = 4), legend.title = element_text(size = 4),
        legend.key.size = unit(0.5, "lines"))

# NTRK3
umap_raw$NTRK3_expression <- expr_raw["NTRK3", ]
u4 <- ggplot(umap_raw, aes(x = UMAP1, y = UMAP2, color = log(NTRK3_expression + 1, base = 2))) +
  geom_point(size = 0.1) +
  scale_color_gradient(low = "grey90", high = "blue") +
  theme_minimal() +
  labs(title = "Raw Counts - NTRK3", color = "NTRK3 (log2)") +
  theme(plot.title = element_text(hjust = 0.5, size = 6),
        axis.title = element_text(size = 4), axis.text = element_text(size = 4),
        legend.text = element_text(size = 4), legend.title = element_text(size = 4),
        legend.key.size = unit(0.5, "lines"))

# CALCA
umap_raw$CALCA_expression <- expr_raw["CALCA", ]
u5 <- ggplot(umap_raw, aes(x = UMAP1, y = UMAP2, color = log(CALCA_expression + 1, base = 2))) +
  geom_point(size = 0.1) +
  scale_color_gradient(low = "grey90", high = "blue") +
  theme_minimal() +
  labs(title = "Raw Counts - CALCA", color = "CALCA (log2)") +
  theme(plot.title = element_text(hjust = 0.5, size = 6),
        axis.title = element_text(size = 4), axis.text = element_text(size = 4),
        legend.text = element_text(size = 4), legend.title = element_text(size = 4),
        legend.key.size = unit(0.5, "lines"))

# TRPV1
umap_raw$TRPV1_expression <- expr_raw["TRPV1", ]
u6 <- ggplot(umap_raw, aes(x = UMAP1, y = UMAP2, color = log(TRPV1_expression + 1, base = 2))) +
  geom_point(size = 0.1) +
  scale_color_gradient(low = "grey90", high = "blue") +
  theme_minimal() +
  labs(title = "Raw Counts - TRPV1", color = "TRPV1 (log2)") +
  theme(plot.title = element_text(hjust = 0.5, size = 6),
        axis.title = element_text(size = 4), axis.text = element_text(size = 4),
        legend.text = element_text(size = 4), legend.title = element_text(size = 4),
        legend.key.size = unit(0.5, "lines"))

# MRGPRD
umap_raw$MRGPRD_expression <- expr_raw["MRGPRD", ]
u7 <- ggplot(umap_raw, aes(x = UMAP1, y = UMAP2, color = log(MRGPRD_expression + 1, base = 2))) +
  geom_point(size = 0.1) +
  scale_color_gradient(low = "grey90", high = "blue") +
  theme_minimal() +
  labs(title = "Raw Counts - MRGPRD", color = "MRGPRD (log2)") +
  theme(plot.title = element_text(hjust = 0.5, size = 6),
        axis.title = element_text(size = 4), axis.text = element_text(size = 4),
        legend.text = element_text(size = 4), legend.title = element_text(size = 4),
        legend.key.size = unit(0.5, "lines"))

# POU5F1 (OCT4) — master pluripotency factor; high = undifferentiated iPSC
umap_raw$POU5F1_expression <- expr_raw["POU5F1", ]
u8 <- ggplot(umap_raw, aes(x = UMAP1, y = UMAP2, color = log(POU5F1_expression + 1, base = 2))) +
  geom_point(size = 0.1) +
  scale_color_gradient(low = "grey90", high = "blue") +
  theme_minimal() +
  labs(title = "Raw Counts - POU5F1", color = "POU5F1 (log2)") +
  theme(plot.title = element_text(hjust = 0.5, size = 6),
        axis.title = element_text(size = 4), axis.text = element_text(size = 4),
        legend.text = element_text(size = 4), legend.title = element_text(size = 4),
        legend.key.size = unit(0.5, "lines"))

# SOX2 — pluripotency and neural progenitor marker
umap_raw$SOX2_expression <- expr_raw["SOX2", ]
u9 <- ggplot(umap_raw, aes(x = UMAP1, y = UMAP2, color = log(SOX2_expression + 1, base = 2))) +
  geom_point(size = 0.1) +
  scale_color_gradient(low = "grey90", high = "blue") +
  theme_minimal() +
  labs(title = "Raw Counts - SOX2", color = "SOX2 (log2)") +
  theme(plot.title = element_text(hjust = 0.5, size = 6),
        axis.title = element_text(size = 4), axis.text = element_text(size = 4),
        legend.text = element_text(size = 4), legend.title = element_text(size = 4),
        legend.key.size = unit(0.5, "lines"))

# NANOG — core pluripotency network; lost upon differentiation
umap_raw$NANOG_expression <- expr_raw["NANOG", ]
u10 <- ggplot(umap_raw, aes(x = UMAP1, y = UMAP2, color = log(NANOG_expression + 1, base = 2))) +
  geom_point(size = 0.1) +
  scale_color_gradient(low = "grey90", high = "blue") +
  theme_minimal() +
  labs(title = "Raw Counts - NANOG", color = "NANOG (log2)") +
  theme(plot.title = element_text(hjust = 0.5, size = 6),
        axis.title = element_text(size = 4), axis.text = element_text(size = 4),
        legend.text = element_text(size = 4), legend.title = element_text(size = 4),
        legend.key.size = unit(0.5, "lines"))

# SNAP25 — synaptic vesicle marker
umap_raw$SNAP25_expression <- expr_raw["SNAP25", ]
u11 <- ggplot(umap_raw, aes(x = UMAP1, y = UMAP2, color = log(SNAP25_expression + 1, base = 2))) +
  geom_point(size = 0.1) +
  scale_color_gradient(low = "grey90", high = "blue") +
  theme_minimal() +
  labs(title = "Raw Counts - SNAP25", color = "SNAP25 (log2)") +
  theme(plot.title = element_text(hjust = 0.5, size = 6),
        axis.title = element_text(size = 4), axis.text = element_text(size = 4),
        legend.text = element_text(size = 4), legend.title = element_text(size = 4),
        legend.key.size = unit(0.5, "lines"))

# RBFOX3
umap_raw$MAP2_expression <- expr_raw["MAP2", ]
u12<- ggplot(umap_raw, aes(x = UMAP1, y = UMAP2, color = log(MAP2_expression + 1, base = 2))) +
  geom_point(size = 0.1) +
  scale_color_gradient(low = "grey90", high = "blue") +
  theme_minimal() +
  labs(title = "Raw Counts - MAP2", color = "MAP2 (log2)") +
  theme(plot.title = element_text(hjust = 0.5, size = 6),
        axis.title = element_text(size = 4), axis.text = element_text(size = 4),
        legend.text = element_text(size = 4), legend.title = element_text(size = 4),
        legend.key.size = unit(0.5, "lines"))
u12 

u_raw <- wrap_plots(u1, u2, u3, u4, u5, u6, u7, u8, u9, u10, u11, u12, ncol = 3)
u_raw

# DecontX counts UMAP plots
expr_decontX <- GetAssayData(seu_decont, layer = "counts")
umap_decontX <- seu_decont@meta.data[, c("UMAP1", "UMAP2")]
expr_decontX <- expr_decontX[genes, , drop = FALSE]

# TUBB3
umap_decontX$TUBB3_expression <- expr_decontX["TUBB3", ]
u1_decont <- ggplot(umap_decontX, aes(x = UMAP1, y = UMAP2, color = log(TUBB3_expression + 1, base = 2))) +
  geom_point(size = 0.1) +
  scale_color_gradient(low = "grey90", high = "blue") +
  theme_minimal() +
  labs(title = "DecontX Counts - TUBB3", color = "TUBB3 (log2)") +
  theme(plot.title = element_text(hjust = 0.5, size = 6),
        axis.title = element_text(size = 4), axis.text = element_text(size = 4),
        legend.text = element_text(size = 4), legend.title = element_text(size = 4),
        legend.key.size = unit(0.5, "lines"))
u1 | u1_decont

# PRPH
umap_decontX$PRPH_expression <- expr_decontX["PRPH", ]
u2_decont <- ggplot(umap_decontX, aes(x = UMAP1, y = UMAP2, color = log(PRPH_expression + 1, base = 2))) +
  geom_point(size = 0.1) +
  scale_color_gradient(low = "grey90", high = "blue") +
  theme_minimal() +
  labs(title = "DecontX Counts - PRPH", color = "PRPH (log2)") +
  theme(plot.title = element_text(hjust = 0.5, size = 6),
        axis.title = element_text(size = 4), axis.text = element_text(size = 4),
        legend.text = element_text(size = 4), legend.title = element_text(size = 4),
        legend.key.size = unit(0.5, "lines"))
u2 | u2_decont

# NTRK2
umap_decontX$NTRK2_expression <- expr_decontX["NTRK2", ]
u3_decont <- ggplot(umap_decontX, aes(x = UMAP1, y = UMAP2, color = log(NTRK2_expression + 1, base = 2))) +
  geom_point(size = 0.1) +
  scale_color_gradient(low = "grey90", high = "blue") +
  theme_minimal() +
  labs(title = "DecontX Counts - NTRK2", color = "NTRK2 (log2)") +
  theme(plot.title = element_text(hjust = 0.5, size = 6),
        axis.title = element_text(size = 4), axis.text = element_text(size = 4),
        legend.text = element_text(size = 4), legend.title = element_text(size = 4),
        legend.key.size = unit(0.5, "lines"))
u3 | u3_decont

# NTRK3
umap_decontX$NTRK3_expression <- expr_decontX["NTRK3", ]
u4_decont <- ggplot(umap_decontX, aes(x = UMAP1, y = UMAP2, color = log(NTRK3_expression + 1, base = 2))) +
  geom_point(size = 0.1) +
  scale_color_gradient(low = "grey90", high = "blue") +
  theme_minimal() +
  labs(title = "DecontX Counts - NTRK3", color = "NTRK3 (log2)") +
  theme(plot.title = element_text(hjust = 0.5, size = 6),
        axis.title = element_text(size = 4), axis.text = element_text(size = 4),
        legend.text = element_text(size = 4), legend.title = element_text(size = 4),
        legend.key.size = unit(0.5, "lines"))
u4 | u4_decont

# CALCA
umap_decontX$CALCA_expression <- expr_decontX["CALCA", ]
u5_decont <- ggplot(umap_decontX, aes(x = UMAP1, y = UMAP2, color = log(CALCA_expression + 1, base = 2))) +
  geom_point(size = 0.1) +
  scale_color_gradient(low = "grey90", high = "blue") +
  theme_minimal() +
  labs(title = "DecontX Counts - CALCA", color = "CALCA (log2)") +
  theme(plot.title = element_text(hjust = 0.5, size = 6),
        axis.title = element_text(size = 4), axis.text = element_text(size = 4),
        legend.text = element_text(size = 4), legend.title = element_text(size = 4),
        legend.key.size = unit(0.5, "lines"))
u5 | u5_decont

# TRPV1
umap_decontX$TRPV1_expression <- expr_decontX["TRPV1", ]
u6_decont <- ggplot(umap_decontX, aes(x = UMAP1, y = UMAP2, color = log(TRPV1_expression + 1, base = 2))) +
  geom_point(size = 0.1) +
  scale_color_gradient(low = "grey90", high = "blue") +
  theme_minimal() +
  labs(title = "DecontX Counts - TRPV1", color = "TRPV1 (log2)") +
  theme(plot.title = element_text(hjust = 0.5, size = 6),
        axis.title = element_text(size = 4), axis.text = element_text(size = 4),
        legend.text = element_text(size = 4), legend.title = element_text(size = 4),
        legend.key.size = unit(0.5, "lines"))
u6 | u6_decont

# MRGPRD
umap_decontX$MRGPRD_expression <- expr_decontX["MRGPRD", ]
u7_decont <- ggplot(umap_decontX, aes(x = UMAP1, y = UMAP2, color = log(MRGPRD_expression + 1, base = 2))) +
  geom_point(size = 0.1) +
  scale_color_gradient(low = "grey90", high = "blue") +
  theme_minimal() +
  labs(title = "DecontX Counts - MRGPRD", color = "MRGPRD (log2)") +
  theme(plot.title = element_text(hjust = 0.5, size = 6),
        axis.title = element_text(size = 4), axis.text = element_text(size = 4),
        legend.text = element_text(size = 4), legend.title = element_text(size = 4),
        legend.key.size = unit(0.5, "lines"))
u7 | u7_decont

# POU5F1
umap_decontX$POU5F1_expression <- expr_decontX["POU5F1", ]
u8_decont <- ggplot(umap_decontX, aes(x = UMAP1, y = UMAP2, color = log(POU5F1_expression + 1, base = 2))) +
  geom_point(size = 0.1) +
  scale_color_gradient(low = "grey90", high = "blue") +
  theme_minimal() +
  labs(title = "DecontX Counts - POU5F1", color = "POU5F1 (log2)") +
  theme(plot.title = element_text(hjust = 0.5, size = 6),
        axis.title = element_text(size = 4), axis.text = element_text(size = 4),
        legend.text = element_text(size = 4), legend.title = element_text(size = 4),
        legend.key.size = unit(0.5, "lines"))
u8 | u8_decont

# SOX2
umap_decontX$SOX2_expression <- expr_decontX["SOX2", ]
u9_decont <- ggplot(umap_decontX, aes(x = UMAP1, y = UMAP2, color = log(SOX2_expression + 1, base = 2))) +
  geom_point(size = 0.1) +
  scale_color_gradient(low = "grey90", high = "blue") +
  theme_minimal() +
  labs(title = "DecontX Counts - SOX2", color = "SOX2 (log2)") +
  theme(plot.title = element_text(hjust = 0.5, size = 6),
        axis.title = element_text(size = 4), axis.text = element_text(size = 4),
        legend.text = element_text(size = 4), legend.title = element_text(size = 4),
        legend.key.size = unit(0.5, "lines"))
u9 | u9_decont

# NANOG
umap_decontX$NANOG_expression <- expr_decontX["NANOG", ]
u10_decont <- ggplot(umap_decontX, aes(x = UMAP1, y = UMAP2, color = log(NANOG_expression + 1, base = 2))) +
  geom_point(size = 0.1) +
  scale_color_gradient(low = "grey90", high = "blue") +
  theme_minimal() +
  labs(title = "DecontX Counts - NANOG", color = "NANOG (log2)") +
  theme(plot.title = element_text(hjust = 0.5, size = 6),
        axis.title = element_text(size = 4), axis.text = element_text(size = 4),
        legend.text = element_text(size = 4), legend.title = element_text(size = 4),
        legend.key.size = unit(0.5, "lines"))
u10 | u10_decont

# SNAP25
umap_decontX$SNAP25_expression <- expr_decontX["SNAP25", ]
u11_decont <- ggplot(umap_decontX, aes(x = UMAP1, y = UMAP2, color = log(SNAP25_expression + 1, base = 2))) +
  geom_point(size = 0.1) +
  scale_color_gradient(low = "grey90", high = "blue") +
  theme_minimal() +
  labs(title = "DecontX Counts - SNAP25", color = "SNAP25 (log2)") +
  theme(plot.title = element_text(hjust = 0.5, size = 6),
        axis.title = element_text(size = 4), axis.text = element_text(size = 4),
        legend.text = element_text(size = 4), legend.title = element_text(size = 4),
        legend.key.size = unit(0.5, "lines"))
u11 | u11_decont

# MAP2
umap_decontX$MAP2_expression <- expr_decontX["MAP2", ]
u12_decont <- ggplot(umap_decontX, aes(x = UMAP1, y = UMAP2, color = log(MAP2_expression + 1, base = 2))) +
  geom_point(size = 0.1) +
  scale_color_gradient(low = "grey90", high = "blue") +
  theme_minimal() +
  labs(title = "DecontX Counts - MAP2", color = "MAP2 (log2)") +
  theme(plot.title = element_text(hjust = 0.5, size = 6),
        axis.title = element_text(size = 4), axis.text = element_text(size = 4),
        legend.text = element_text(size = 4), legend.title = element_text(size = 4),
        legend.key.size = unit(0.5, "lines"))
u12 | u12_decont

u_decont <- wrap_plots(u1_decont, u2_decont, u3_decont, u4_decont,
                       u5_decont, u6_decont, u7_decont, u8_decont,
                       u9_decont, u10_decont, u11_decont, ncol = 3)
u_decont

# Save output


ggsave("./scripts/01.2_DecontX/DecontX_out/01_contamination_UMAP.png",
       plot = p1, height = 8, width = 8, dpi = 600)
ggsave("./scripts/01.2_DecontX/DecontX_out/02_nCount_violin.png",
       plot = v1, height = 8, width = 11, dpi = 600)
ggsave("./scripts/01.2_DecontX/DecontX_out/03_markers_raw.png",
       plot = u_raw, height = 11, width = 8, dpi = 600)
ggsave("./scripts/01.2_DecontX/DecontX_out/04_markers_decontX.png",
       plot = u_decont, height = 11, width = 8, dpi = 600)

# Marker percentage bar graph: % cells expressing each marker, raw vs decontX counts
markers <- list(
  PanNeuronal    = c("TUBB3", "PRPH", "SNAP25","MAP2"),
  Peptidergic    = c("CALCA", "TRPV1"),
  NonPeptidergic = c("MRGPRD"),
  TrkB_TrkC      = c("NTRK2", "NTRK3"),
  iPSC           = c("POU5F1", "SOX2", "NANOG")
)

# After inspecting the decontX UMAP above, replace NULL with a named list mapping
# cluster IDs to group labels, e.g.:
# cellTypeMappings <- list(iPSC = c(1, 2), Neuronal = c(3, 4, 5))
# NULL plots each cluster individually.
cellTypeMappings <- NULL

b1 <- plotDecontXMarkerPercentage(sce_decont_with_raw,
                                  markers = markers,
                                  groupClusters = cellTypeMappings,
                                  assayName = c("counts", "decontXcounts"))
b1

ggsave("./scripts/01.2_DecontX/DecontX_out/05_marker_percentage.png",
       plot = b1, height = 8, width = 11, dpi = 600)

# Marker expression violin plots — raw counts vs decontXcounts, per cluster
e1 <- plotDecontXMarkerExpression(sce_decont_with_raw,
                                  markers = unlist(markers, use.names = FALSE),
                                  groupClusters = cellTypeMappings,
                                  ncol = 3)
e1

ggsave("./scripts/01.2_DecontX/DecontX_out/06_marker_expression_counts.png",
       plot = e1, height = 11, width = 10, dpi = 600)

# SN markers expression — raw counts vs decontXcounts
e1_SN <- plotDecontXMarkerExpression(sce_decont_with_raw,
                                     markers = unlist(markers[c("PanNeuronal", "Peptidergic", "NonPeptidergic", "TrkB_TrkC")], use.names = FALSE),
                                     groupClusters = cellTypeMappings,
                                     ncol = 3)
e1_SN

ggsave("./scripts/01.2_DecontX/DecontX_out/08_SN_marker_expression_counts.png",
       plot = e1_SN, height = 11, width = 10, dpi = 600)

# iPSC markers expression — raw counts vs decontXcounts
e1_iPSC <- plotDecontXMarkerExpression(sce_decont_with_raw,
                                       markers = markers[["iPSC"]],
                                       groupClusters = cellTypeMappings,
                                       ncol = 3)
e1_iPSC

ggsave("./scripts/01.2_DecontX/DecontX_out/09_iPSC_marker_expression_counts.png",
       plot = e1_iPSC, height = 11, width = 10, dpi = 600)

# Log-normalize decontX counts and store as a new assay for comparison
sce_decont_with_raw <- logNormCounts(sce_decont_with_raw,
                                     exprs_values = "decontXcounts",
                                     name = "decontXlogcounts")

# Marker expression violin plots — logcounts vs decontXlogcounts
e2 <- plotDecontXMarkerExpression(sce_decont_with_raw,
                                  markers = unlist(markers, use.names = FALSE),
                                  groupClusters = cellTypeMappings,
                                  ncol = 3,
                                  assayName = c("logcounts", "decontXlogcounts"))
e2

ggsave("./scripts/01.2_DecontX/DecontX_out/07_marker_expression_lognorm.png",
       plot = e2, height = 11, width = 10, dpi = 600)

# SN markers expression — logcounts vs decontXlogcounts
e2_SN <- plotDecontXMarkerExpression(sce_decont_with_raw,
                                     markers = unlist(markers[c("PanNeuronal", "Peptidergic", "NonPeptidergic", "TrkB_TrkC")], use.names = FALSE),
                                     groupClusters = cellTypeMappings,
                                     ncol = 3,
                                     assayName = c("logcounts", "decontXlogcounts"))
e2_SN

ggsave("./scripts/01.2_DecontX/DecontX_out/10_SN_marker_expression_lognorm.png",
       plot = e2_SN, height = 11, width = 10, dpi = 600)

# iPSC markers expression — logcounts vs decontXlogcounts
e2_iPSC <- plotDecontXMarkerExpression(sce_decont_with_raw,
                                       markers = markers[["iPSC"]],
                                       groupClusters = cellTypeMappings,
                                       ncol = 3,
                                       assayName = c("logcounts", "decontXlogcounts"))
e2_iPSC

ggsave("./scripts/01.2_DecontX/DecontX_out/11_iPSC_marker_expression_lognorm.png",
       plot = e2_iPSC, height = 11, width = 10, dpi = 600)
saveRDS(seu_decont, "./scripts/01.2_DecontX/DecontX_out/iSN_decontX.rds")
capture.output(sessionInfo(), file = "./scripts/01.2_DecontX/DecontX_out/session_info.txt")



#test
# umap_decontX$SNAP25_expression <- expr_decontX["SNAP25", ]
# umap_decontX$sample <- seu_decont$sample_group
# 
# ggplot(umap_decontX, aes(x = UMAP1, y = UMAP2, color = log(MAP2_expression + 1, base = 2))) +
#   geom_point(size = 0.1) +
#   scale_color_gradient(low = "grey90", high = "blue") +
#   geom_text(data = umap_decontX %>% group_by(sample) %>% 
#               summarise(UMAP1 = mean(UMAP1), UMAP2 = mean(UMAP2)),
#             aes(x = UMAP1, y = UMAP2, label = sample),
#             color = "black", size = 3, inherit.aes = FALSE) +
#   theme_minimal() +
#   labs(title = "DecontX Counts - MAP25", color = "MAP2 (log2)")
