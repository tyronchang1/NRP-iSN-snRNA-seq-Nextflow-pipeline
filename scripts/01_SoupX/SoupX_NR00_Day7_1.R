#locate and set your directories.
getwd() # prints the current working directory to confirm your starting location
dir <- "/scratch/rmlab/rmlab_shared3/tyron/Rscriptv2/iSN/iSN_claude" # store project root path in variable 'dir'
setwd(dir) # change working directory to project root so all relative paths resolve correctly
pdf(NULL)
getwd() # output: "/scratch/rmlab/rmlab_shared3/tyron/Rscriptv2/iSN_claude" — confirm the switch worked
library(SoupX)        # ambient RNA estimation and correction
library(ggplot2)      # plotting
library(DropletUtils) # writing corrected counts back to 10x format
library(cowplot)      # arranging multiple plots into a grid
### Load10x will create the Soup object.

#--------------- NR00_Day7_1 -----------
rm(list = ls()) # clear all variables from the environment before loading this sample to avoid carry-over

# load10X() reads the Cell Ranger 'outs' directory and returns a SoupChannel object (sc)
# the object contains: tod (table of droplets — all barcodes), toc (table of counts — filtered cells), metaData (cluster + tSNE info)
sc <- load10X('./samples/NR00_Day7_1')


### check the overall data structure of the soup object.
typeof(sc)  # should return "list" — SoupChannel is an S3 list object
print(sc)   # summary: number of genes, cells, and estimated soup profile
str(sc)     # full internal structure — useful for debugging if fields are missing

# toc is table of total counts
sc_metadata <- sc$metaData # extract per-cell metadata data frame (cluster ID, tSNE1, tSNE2 coordinates)
                            # note: accessed with $ not @meta.data (this is not a Seurat object)
dd <- sc_metadata # working copy used for plotting; keeps sc$metaData unchanged
colnames(dd)      # inspect available columns — should include 'clusters', 'tSNE1', 'tSNE2'

# This is to choose the mean of tSNE1, tSNE2 coordinates for each cluster
# Basically where to label your cluster!
# aggregate() computes the mean tSNE position per cluster — used to place cluster number labels on the plot
mids <- aggregate(cbind(tSNE1, tSNE2) ~ clusters, data = dd, FUN = mean)
# cbind(tSNE1, tSNE2): compute mean for both axes simultaneously
# ~ clusters: group by cluster identity
# FUN = mean: function applied per group
print(mids) # confirm label positions look reasonable before plotting
center <- theme(plot.title = element_text(hjust = 0.5)) # ggplot2 theme snippet: hjust = 0.5 centers the title

###--- check the overall clusters for all and each gene -------
# all clusters
# build tSNE scatter plot with cells coloured by cluster identity
p1 <- ggplot(dd, aes(tSNE1, tSNE2)) +
  geom_point(aes(colour = factor(clusters)), size = 0.2) + # factor() converts cluster IDs to discrete colors; size = 0.2 avoids overplotting
  geom_label(data = mids, aes(label = clusters)) +          # place cluster number labels at mean tSNE positions
  ggtitle("NR00_Day7_1 study pre-Soup") + center            # title identifies sample and that this is before correction
p1 <- p1 + guides(colour = guide_legend(title = "Cluster")) # rename legend from "factor(clusters)" to "Cluster"
p1 # render plot

# iSN marker genes: TUBB3, PRPH, NTRK2, CALCA
# For each marker: (1) extract raw UMI counts from toc, (2) plot binary detection, (3) plot SoupX marker map

# TUBB3: pan-neuronal marker (beta-III tubulin); confirms neuronal identity
dd$TUBB3 = sc$toc["TUBB3", ] # sc$toc["GENE", ] extracts the row for TUBB3 from the filtered count matrix (genes x cells)
tubb3_p <- ggplot(dd, aes(tSNE1, tSNE2)) + geom_point(aes(colour = TUBB3 > 0)) # colour = TRUE/FALSE: detected vs not detected
plot(tubb3_p)
plotMarkerMap(sc, "TUBB3") # SoupX function: shows ratio of observed to soup-expected expression; high ratio = likely real, not ambient

# PRPH: pan-neuronal marker (peripherin); marks peripheral nervous system neurons
dd$PRPH = sc$toc["PRPH", ]
prph_p <- ggplot(dd, aes(tSNE1, tSNE2)) + geom_point(aes(colour = PRPH > 0))
plot(prph_p)
plotMarkerMap(sc, "PRPH")

# NTRK2: TrkB receptor; marks myelinated / Aδ sensory neuron subtypes
dd$NTRK2 = sc$toc["NTRK2", ]
ntrk2_p <- ggplot(dd, aes(tSNE1, tSNE2)) + geom_point(aes(colour = NTRK2 > 0))
plot(ntrk2_p)
plotMarkerMap(sc, "NTRK2")

# CALCA: CGRP (calcitonin gene-related peptide); marks peptidergic nociceptors
dd$CALCA = sc$toc["CALCA", ]
calca_p <- ggplot(dd, aes(tSNE1, tSNE2)) + geom_point(aes(colour = CALCA > 0))
plot(calca_p)
plotMarkerMap(sc, "CALCA")

# autoEstCont() automatically estimates the global contamination fraction (rho)
# it uses TF-IDF to identify genes highly enriched in empty droplets (soup) vs real cells
# rho ~ 0.01 is typical; rho > 0.05 warrants investigation
sc <- autoEstCont(sc)#0.42
# Estimated global rho of 0.01

# adjustCounts() applies the soup correction to every cell using the estimated rho
# roundToInt = TRUE: rounds corrected values to integers (required by Seurat and most downstream tools)


out <- adjustCounts(sc)

cntSoggy    <- rowSums(sc$toc > 0)
cntStrained <- rowSums(out > 0)

genes_check <- c("TUBB3", "PRPH", "NTRK2", "CALCA", "POU5F1", "SOX2", "STMN2","MAP2","NANOG",
                 "SNAP25","ACTB","RBFOX3")
genes_check <- genes_check[genes_check %in% rownames(sc$toc)]

data.frame(
  gene     = genes_check,
  before   = cntSoggy[genes_check],
  after    = cntStrained[genes_check],
  pct_lost = round((cntSoggy[genes_check] - cntStrained[genes_check]) /
                     cntSoggy[genes_check] * 100, 1)
)

out_NR00_Day7_1 <- adjustCounts(sc, roundToInt = TRUE)
out_NR00_Day7_1 # print summary of corrected matrix

# plotChangeMap(): shows where in tSNE space the correction reduced counts for each marker
# blue = counts decreased after correction (likely ambient); red/grey = unchanged (likely real)
corrected_tubb3  <- plotChangeMap(sc, out_NR00_Day7_1, "TUBB3") + ggtitle("TUBB3, NR00_Day7_1 post-Soup") + center
corrected_prph   <- plotChangeMap(sc, out_NR00_Day7_1, "PRPH")  + ggtitle("PRPH, NR00_Day7_1 post-Soup")  + center
corrected_ntrk2  <- plotChangeMap(sc, out_NR00_Day7_1, "NTRK2") + ggtitle("NTRK2, NR00_Day7_1 post-Soup") + center
corrected_calca  <- plotChangeMap(sc, out_NR00_Day7_1, "CALCA") + ggtitle("CALCA, NR00_Day7_1 post-Soup") + center
strained_p <- plot_grid(corrected_tubb3, corrected_prph, corrected_ntrk2, corrected_calca) # arrange all 4 panels in a grid
strained_p

#### CHECK what genes have the most changes after correction
cntSoggy    <- rowSums(sc$toc > 0)            # pre-Soup: number of cells expressing each gene (UMI > 0)
cntStrained <- rowSums(out_NR00_Day7_1 > 0)   # post-Soup: same count after correction
# ratio: fraction of originally-expressing cells that lost expression after correction
# value of 1.0 = all cells lost expression → gene is a pure ambient artifact
mostZeroed  <- tail(sort((cntSoggy - cntStrained) / cntSoggy), n = 200) # top 200 most-affected genes
mostZeroed

# soup fraction: for each gene, proportion of expressed cells where correction reduced counts
# rowSums(sc$toc > out): cells where raw > corrected (i.e., correction had an effect)
# values near 1.0 = gene is almost entirely ambient contamination
tail(sort(rowSums(sc$toc > out_NR00_Day7_1) / rowSums(sc$toc > 0)), n = 200) # top 20 highest soup-fraction genes

# write corrected count matrix to disk in 10x Genomics format (barcodes.tsv, features.tsv, matrix.mtx)
# output consumed by Stage 02 (DoubletRemoval)
dir.create("./scripts/01_SoupX/SoupX_dir_out", recursive = TRUE, showWarnings = FALSE)
DropletUtils:::write10xCounts("./scripts/01_SoupX/SoupX_dir_out/NR00_Day7_1Counts", out_NR00_Day7_1)
