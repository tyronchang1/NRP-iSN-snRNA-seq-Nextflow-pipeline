# Setup Reference

Detailed installation and configuration reference for the iSN Claude pipeline. For the quick-start steps, see [README.md](../README.md). Full package list: [PACKAGES.md](PACKAGES.md).

---

## Software dependencies

If you are in the Mitra lab on HTCF, many of these are already at `/ref/rmlab/software/`, but again I will still double check them. If you are on a different account or cluster, install them yourself and update the paths in step 2.

**Must install yourself** (paths set in `r_install/01_cran.sh` lines 27–42):

| Tool / library | Used by |
|----------------|---------|
| R 4.5.2 | all pipeline scripts |
| Java 17 | Nextflow |
| Nextflow | pipeline orchestration |
| conda / miniconda | `05_pandoc.sh` — pandoc for report rendering |
| fontconfig | font rendering (ragg, Cairo) |
| cairo | 2D graphics (R graphics device) |
| HarfBuzz, FriBidi | text shaping (ragg) |
| libX11, xorgproto | X11 headers (R graphics) |
| libraqm, liblqr | text layout + liquid rescale (ragg, magick) |
| libtiff, libjpeg, libwebp | image formats (magick R package) |
| ImageMagick | image processing (magick R package) |
| HDF5 | Seurat HDF5 support |
| GDAL, GEOS, PROJ | spatial R packages |
| FFTW3 | `qqconf` Bioconductor package |
| udunits2 | `units` R package |
| ODBC libraries | database connectivity |

**Provided via spack** (already at `/ref/rmlab/software/spack-1.1.0/` on HTCF — no action needed unless on a different cluster):

| Tool / library | Used by |
|----------------|---------|
| OpenSSL | curl, HTTPS downloads |
| curl, nghttp2 | R package downloads |
| libpng, freetype | graphics / font rendering |
| libxml2 | XML parsing (many R packages) |
| zlib, bzip2, xz, libiconv | compression / encoding |
| cmake | compiling packages from source |

---

## Path configuration

All hardcoded paths in `r_install/` and `nextflow/` point to Tyron's HTCF directories. Update them for your account before running anything.

### R library and binary paths — 4 files

| What | File | Line | Old value |
|------|------|------|-----------|
| R package library | `r_install/01_cran.sh` | 12 | `export R_LIBS=/ref/rmlab/software/tyron/R-libs` |
| R package library | `r_install/02_bioc.sh` | 12 | same |
| R package library | `r_install/03_github.sh` | 12 | same |
| R package library | `nextflow/nextflow.config` | 4 | `r_libs = "/ref/rmlab/software/tyron/R-libs"` |
| R binary | `r_install/01_cran.sh` | 10 | `R_BIN=/ref/rmlab/software/spack-1.1.0/.../bin` |
| R binary | `r_install/02_bioc.sh` | 10 | same |
| R binary | `r_install/03_github.sh` | 10 | same |
| R binary | `nextflow/nextflow.config` | 3 | `r_bin = "/ref/rmlab/software/spack-1.1.0/.../bin"` |

### Nextflow runtime paths — 3 files

| What | File | Line | Old value |
|------|------|------|-----------|
| Nextflow home dir | `nextflow/run.sh` | 14 | `NXF_HOME=/scratch/rmlab/rmlab_shared3/tyron/.nextflow` |
| Nextflow binary | `nextflow/run.sh` | 16 | `NXF_BIN=/ref/rmlab/software/tyron/nextflow` |
| Java home | `nextflow/run.sh` | 12 | `JAVA_HOME=/ref/rmlab/software/tyron/java17` |
| Email notifications | `nextflow/run.sh` | 10 | `#SBATCH --mail-user=tyron@wustl.edu` |
| Nextflow home dir | `nextflow/submit.sh` | 5 | `export NXF_HOME=/scratch/rmlab/rmlab_shared3/tyron/.nextflow` |
| Pandoc (for reports) | `nextflow/nextflow.config` | 72 | `RSTUDIO_PANDOC = "/home/tyron/miniconda3/bin"` |

> `NXF_HOME` must be the same value in both `run.sh` and `submit.sh`.

### Python and Pandoc paths — 2 files

| What | File | Line | Old value |
|------|------|------|-----------|
| Python binary | `r_install/04_python.sh` | 10 | `PYTHON=/home/tyron/miniconda3/bin/python3` |
| pip binary | `r_install/04_python.sh` | 11 | `PIP=/home/tyron/miniconda3/bin/pip3` |
| Python package dir | `r_install/04_python.sh` | 12 | `PY_TARGET=/ref/rmlab/software/tyron/python-libs` |
| conda binary | `r_install/05_pandoc.sh` | 10 | `CONDA=/home/tyron/miniconda3/bin/conda` |
| conda prefix | `r_install/05_pandoc.sh` | 11 | `CONDA_PREFIX=/home/tyron/miniconda3` |

### System library paths

`r_install/01_cran.sh`, `02_bioc.sh`, `03_github.sh` (lines 27–42) link against compiled C libraries (fontconfig, cairo, HDF5, GDAL, etc.) under `/ref/rmlab/software/tyron/`. Install these libraries yourself and update the `*_DIR` variables in each script.

---

## Agent behavior

This repo ships with Claude Code agents, rules, and skills. On your first session, Claude automatically bootstraps your personal memory:

1. Reads `.claude/rules/07_behavior.md` — the authoritative behavioral rule file
2. Reads `.claude/memory/project_behavior_rules.md` — the repo-committed template
3. Checks your personal memory directory: `~/.claude/projects/<hash>/memory/`
4. If the file does not exist → writes it to your memory directory and indexes it in `MEMORY.md`
5. Every subsequent session: already exists → skipped

### Rules enforced every session

| # | Rule |
|---|------|
| 1 | No inline edits to `.R` or `.nf` files — always route through the correct agent |
| 2 | SLURM is fully autonomous — Claude runs `sbatch`/`scancel` itself, never asks you |
| 3 | Pipeline monitoring — Claude checks logs every 30 min and fixes errors without asking |
| 4 | Every agent spawn includes a mandatory user-constraints block |
| 5 | Troubleshooting always starts by reading `compact/`, `r_install/`, `r_install/logs/` |
| 6 | Claude announces any file it reads that you didn't explicitly reference |
| 7 | Claude grills you with one question at a time before editing any script |
| 8 | Pipeline ends at Stage 04 — Stage 05 is removed and will never be suggested |
| 9 | `WORKFLOW.md` is for R agents; `NEXTFLOW.md` is for the Nextflow agent |
| 10 | `SKILL.md` files are agent instructions, not slash commands |
| 11 | Any file rename, delete, or path change triggers a project-wide reference update |

---

## Directory structure

```
iSN_claude/
├── CLAUDE.md                        Claude Code instructions and project overview
├── README.md                        Quick-start guide
│
├── samples/                         Raw Cell Ranger outputs (input data, read-only)
│   ├── NR00_Day13_1/                Differentiation day 13, replicate 1
│   ├── NR00_Day13_1_dup/            Differentiation day 13, replicate 1 (duplicate run)
│   ├── NR00_Day13_2/                Differentiation day 13, replicate 2
│   ├── NR00_Day13_2_dup/            Differentiation day 13, replicate 2 (duplicate run)
│   ├── NR00_Day7_1/                 Differentiation day 7, replicate 1
│   ├── NR00_Day7_2/                 Differentiation day 7, replicate 2
│   ├── NR00_iPSC_1/                 Undifferentiated iPSC control, replicate 1
│   └── NR00_iPSC_2/                 Undifferentiated iPSC control, replicate 2
│
├── scripts/                         Analysis R scripts — one subdirectory per pipeline stage
│   ├── 01_SoupX/
│   ├── 01.2_DecontX/
│   ├── 02_scDblFinder_soupx/
│   ├── 02.1_scDblFinder_decontX/
│   ├── 03_Cell_filtering/
│   └── 04_Clustering/
│
├── final_output/                    Final pipeline outputs (written after Stage 04)
│   ├── final_report.Rmd             R Markdown source for the merged pipeline report
│   ├── final_report_decontX.html    Rendered pipeline report — DecontX track
│   └── Biologist_Chat.md            BIOLOGIST agent review log
│
├── r_install/                       SLURM scripts for installing R/Python packages on HTCF
│   ├── submit_all.sh                Run this once: submits all install jobs in dependency order
│   ├── 01_cran.sh / 02_bioc.sh / 03_github.sh / 04_python.sh / 05_pandoc.sh
│   └── logs/                        SLURM install logs
│
├── nextflow/                        Nextflow DSL2 pipeline
│   ├── submit.sh                    ENTRY POINT — bash nextflow/submit.sh
│   ├── run.sh                       SLURM batch script (do not run directly)
│   ├── main.nf                      Main workflow
│   ├── nextflow.config              Params, executor, and resource settings
│   ├── logs/                        SLURM stdout/stderr for the Nextflow head job
│   └── modules/                     One .nf file per pipeline stage
│
├── md_files/                        Pipeline documentation
│   ├── WORKFLOW.md                  R pipeline reference for scrna-seq-script-agent
│   ├── NEXTFLOW.md                  Nextflow reference for nextflow-script-agent
│   ├── STATUS.md                    Per-stage implementation status
│   ├── setup.md                     This file — detailed install and config reference
│   ├── packages.md                  Full R and Python package list
│   └── REPORT.md                    Change log for all .claude/ and md_files/ edits
│
├── compact/                         Session compact logs (written on every context compaction)
│
└── .claude/                         Claude Code configuration
    ├── memory/                      Repo-committed memory templates (bootstrapped on first session)
    ├── rules/                       Rule files — read at every session start
    ├── agents/                      Custom agents (scrna-seq, nextflow, review, troubleshoot, biologist)
    └── skills/                      Stage-specific agent instruction files (SKILL.md per stage)
```
