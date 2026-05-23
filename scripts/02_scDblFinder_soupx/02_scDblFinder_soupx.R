# Load necessary libraries
library(Seurat)
library(scDblFinder)
library(ggplot2)
library(cowplot)
library(dplyr)
library(SingleCellExperiment)
# ----For loop is just a disaster, don't use ReadMtx function from the Seurat package----

# Use Read10X(data.dir=path) to combine all the data together.
rm(list = ls(all.name = TRUE)) # remove all variables first
getwd()
dir <- "/scratch/rmlab/rmlab_shared3/tyron/Rscriptv2/iSN/iSN_claude"
setwd(dir)
pdf(NULL)

# Input: SoupX-corrected count matrices from Stage 01
# Uncomment each line below once the corresponding SoupX script has been run
dirs <- c('./scripts/01_SoupX/SoupX_dir_out/NR00_Day13_1Counts',
          './scripts/01_SoupX/SoupX_dir_out/NR00_Day13_1_dupCounts',
          './scripts/01_SoupX/SoupX_dir_out/NR00_Day13_2Counts',
          './scripts/01_SoupX/SoupX_dir_out/NR00_Day13_2_dupCounts',
          './scripts/01_SoupX/SoupX_dir_out/NR00_Day7_1Counts',
           './scripts/01_SoupX/SoupX_dir_out/NR00_Day7_2Counts',       
          './scripts/01_SoupX/SoupX_dir_out/NR00_iPSC_1Counts',
          './scripts/01_SoupX/SoupX_dir_out/NR00_iPSC_2Counts'        
          )

cts <- Read10X(data.dir = dirs)
all_seu <- CreateSeuratObject(counts = cts) # create combined Seurat object

# Reassign meaningful sample group labels to each cell
# Read10X assigns orig.ident as numeric index (1, 2, 3...) when given multiple dirs


all_cts_meta <- all_seu@meta.data
# View(all_cts_meta)
desired_order <- c("NR00_Day13_1", "NR00_Day13_1_dup",
                   "NR00_Day13_2",
                   "NR00_Day13_2_dup",  
                   "NR00_Day7_1",
                   "NR00_Day7_2",       
                   "NR00_iPSC_1",
                   "NR00_iPSC_2")

sample_mapping <- data.frame(
  orig_ident   = factor(1:length(desired_order)),
  sample_group = desired_order
)

# Save barcodes before left_join strips rownames
barcodes <- rownames(all_cts_meta)


all_cts_meta <- all_cts_meta %>%
  left_join(sample_mapping, by = c("orig.ident" = "orig_ident")) %>%
  mutate(sample_group = factor(sample_group, levels = desired_order))

# View(all_cts_meta)

# Restore rownames so AddMetaData can match cells
rownames(all_cts_meta) <- barcodes

all_seu <- AddMetaData(all_seu, metadata = all_cts_meta["sample_group"])

# Pre-QC: histogram of nCount_RNA per sample to inspect count distributions
all_cst_p <- ggplot(all_cts_meta, aes(x = nCount_RNA, y = ..density..)) +
  geom_histogram(fill = "white", color = "black", bins = 500) +
  scale_x_continuous(breaks = seq(0, 20000, 2000), lim = c(0, 20000)) +
  facet_wrap(~sample_group) +
  geom_vline(aes(xintercept = 500), color = "red", lty = "longdash") +
  RotatedAxis() +
  ggtitle('nCount_RNA — iSN samples pre-QC')
all_cst_p
ggsave(filename = "01_totalcounts_preQC_all.png", width = 12, height = 14, unit = "in",
       path = "./scripts/02_scDblFinder_soupx/scDblFinder_output")

# Check for data quality issues
sum(is.na(all_cts_meta$nCount_RNA))       # should be 0
sum(is.infinite(all_cts_meta$nCount_RNA)) # should be 0

all_cst_p

# Remove cells with fewer than 500 counts before doublet scoring
select  <- WhichCells(all_seu, expression = nCount_RNA > 500)

all_seu <- subset(all_seu, cells = select)

DefaultAssay(all_seu) # confirm default assay is RNA

##### scDblFinder requires a SingleCellExperiment object — convert from Seurat
all_sce <- as.SingleCellExperiment(all_seu)
# Warning messages expected:
# 1: Layer 'data' is empty
# 2: Layer 'scale.data' is empty

set.seed(123) # for reproducibility
all_sce <- scDblFinder(all_sce,
                       samples  = "orig.ident", # score doublets per sample independently
                       clusters = TRUE)          # pre-cluster to improve sensitivity

all_sce@colData # inspect per-cell metadata including scDblFinder scores and calls
# View(all_sce$ident)
# Summarise doublet counts and percentages per sample
db_table    <- table(all_sce$scDblFinder.class, all_sce$orig.ident)
percent_db  <- db_table[2, ] / colSums(db_table) * 100
db_table    <- rbind(db_table, percent_db)
db_table
sum(db_table[2, ]) # total number of doublets across all samples

# Convert back to Seurat (includes scDblFinder.class column in metadata)
# logcounts slot is required by as.Seurat(); assign counts as a placeholder
logcounts(all_sce) <- assay(all_sce, "counts") # not true log counts — required for conversion
all_seu <- as.Seurat(all_sce)
# View(all_seu@meta.data)
table(all_seu$scDblFinder.class) # expected ~8–10% doublets per sample
# Save Seurat object with doublet labels; actual doublet removal happens in Stage 03
# dir.create("./scripts/02_scDblFinder_soupx/scDblFinder_output", recursive = TRUE, showWarnings = FALSE)
# SaveH5Seurat(all_seu,
#              "./scripts/02_scDblFinder_soupx/scDblFinder_output/iSN_doubletstep.h5Seurat",
#              overwrite = TRUE)
saveRDS(all_seu, "./scripts/02_scDblFinder_soupx/scDblFinder_output/iSN_doubletstep.rds")
capture.output(sessionInfo(),
               file = "./scripts/02_scDblFinder_soupx/scDblFinder_output/session_info.txt")

