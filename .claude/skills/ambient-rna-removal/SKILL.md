# Skill: Ambient RNA Removal (SoupX)

**Scripts directory:** `scripts/01_SoupX/`
**Script naming:** `SoupX_{SAMPLE}.R`
**Samples:** NR00_Day13_1, NR00_Day13_1_dup, NR00_Day13_2, NR00_Day13_2_dup, NR00_Day7_1, NR00_Day7_2, NR00_iPSC_1, NR00_iPSC_2
**Output directory:** `scripts/01_SoupX/SoupX_dir_out/{SAMPLE}Counts/`
**Libraries:** `SoupX`, `ggplot2`, `DropletUtils`, `cowplot`

---

## Steps

1. **Set working directory**
   - Set `dir` to the project root and call `setwd(dir)`
   - Clear environment with `rm(list = ls())` before loading each sample

2. **Load 10X data**
   - Use `load10X('<cellranger_outs_path>')` to create the SoupChannel object (`sc`)
   - Inspect with `typeof(sc)`, `print(sc)`, `str(sc)`

3. **Extract metadata and tSNE coordinates**
   - `sc_metadata <- sc$metaData`
   - Compute cluster label midpoints: `aggregate(cbind(tSNE1, tSNE2) ~ clusters, data = dd, FUN = mean)`

4. **Visualize clusters**
   - Plot all clusters on tSNE coloured by cluster identity using `ggplot2`
   - Title format: `"{SAMPLE} study pre-Soup"`

5. **Plot iSN marker genes**
   - For each marker (`TUBB3`, `PRPH`, `NTRK2`, `CALCA`):
     - Extract expression: `dd${MARKER} = sc$toc["{MARKER}", ]`
     - Scatter plot: `ggplot(dd, aes(tSNE1, tSNE2)) + geom_point(aes(colour = {MARKER} > 0))`
     - Marker map: `plotMarkerMap(sc, "{MARKER}")`
   - **For `NR00_iPSC_1` only** — also plot iPSC pluripotency markers (`POU5F1`, `SOX2`, `NANOG`) using the same pattern above; these confirm undifferentiated iPSC identity and help distinguish residual undifferentiated cells from iSNs

6. **Estimate contamination**
   - `sc <- autoEstCont(sc)`
   - Expected output: `Estimated global rho of 0.01` (flag if rho > 0.05)

7. **Apply correction**
   - `out_{SAMPLE} <- adjustCounts(sc, roundToInt = TRUE)`

8. **Validate correction**
   - Plot before/after for each marker with `plotChangeMap(sc, out_{SAMPLE}, "{MARKER}")`
   - Combine plots with `plot_grid()`

9. **Check most-zeroed genes**
   - `cntSoggy = rowSums(sc$toc > 0)`
   - `cntStrained = rowSums(out_{SAMPLE} > 0)`
   - `mostZeroed = tail(sort((cntSoggy - cntStrained) / cntSoggy), n = 10)`

10. **Check highest soup-fraction genes**
    - `tail(sort(rowSums(sc$toc > out_{SAMPLE}) / rowSums(sc$toc > 0)), n = 20)`
    - Genes with fraction = 1.0 are pure ambient artifacts

11. **Write corrected counts**
    - `DropletUtils:::write10xCounts("./scripts/01_SoupX/SoupX_dir_out/{SAMPLE}Counts", out_{SAMPLE})`

12. **Remind user to run `/simplify`**
    - After completing the edit, tell the user: "Run `/simplify` to check consistency across all `SoupX_*.R` scripts."

13. **Remind user to run `/review`**
    - Before treating corrected outputs as final, tell the user: "Run `/review` to confirm contamination estimates and output paths."
