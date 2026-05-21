rm(list = ls(all.name = TRUE))
library(Seurat)
library(scDblFinder)
library(SingleCellExperiment)
library(ggplot2)
library(cowplot)
library(dplyr)

dir <- "/scratch/rmlab/rmlab_shared3/tyron/Rscriptv2/iSN/iSN_claude"
setwd(dir)
pdf(NULL)

# Load DecontX output
all_seu_decontX <- readRDS("./scripts/01.2_DecontX/DecontX_out/iSN_decontX.rds")
dim(all_seu_decontX)
# Pre-QC histogram: nCount_RNA per sample
p_preQC <- ggplot(all_seu_decontX@meta.data, aes(x = nCount_RNA, y = after_stat(density))) +
  geom_histogram(fill = "white", color = "black", bins = 500) +
  scale_x_continuous(breaks = seq(0, 20000, 2000), lim = c(0, 20000)) +
  facet_wrap(~sample_group) +
  geom_vline(aes(xintercept = 700), color = "red", lty = "longdash") +
  RotatedAxis() +
  ggtitle("nCount_RNA distributions between groups") +
  theme(plot.title = element_text(hjust = 0.5)) +
  labs(x = NULL)
p_preQC

ggsave("./scripts/02.1_scDblFinder_decontX/scDblFinder_output/01_totalcounts_preQC_all.png",
       plot = p_preQC, height = 11, width = 8, dpi = 600)

# Filter cells with nCount_RNA (decontx count) > 500
select <- WhichCells(all_seu_decontX, expression = nCount_RNA > 500)
all_seu <- subset(all_seu_decontX, cells = select)
dim(all_seu)#76536

DefaultAssay(all_seu)

# Convert to SingleCellExperiment — scDblFinder cannot process Seurat objects directly
all_sce <- as.SingleCellExperiment(all_seu)
# Warning messages about empty 'data' and 'scale.data' layers are expected and harmless

set.seed(123)
all_sce <- scDblFinder(all_sce,
                       samples = "sample_group",
                       clusters = TRUE)

# Doublet summary per sample
db_table <- table(all_sce$scDblFinder.class, all_sce$sample_group)
db_table

percent_db <- db_table[2, ] / colSums(db_table) * 100
percent_db

db_table <- rbind(db_table, percent_db)
db_table

total_db <- table(all_sce$scDblFinder.class)
total_percent_db <- total_db / sum(total_db) * 100
total_percent_db

total_db <- rbind(total_db, total_percent_db)
total_db

# Convert back to Seurat
# logcounts assigned as placeholder — required by as.Seurat(); not true log counts
logcounts(all_sce) <- assay(all_sce, "counts")
all_seu <- as.Seurat(all_sce)
table(all_seu$scDblFinder.class)


# Save output
saveRDS(all_seu, "./scripts/02.1_scDblFinder_decontX/scDblFinder_output/iSN_decontX_scDblFinder.rds")
capture.output(sessionInfo(), file = "./scripts/02.1_scDblFinder_decontX/scDblFinder_output/session_info.txt")
