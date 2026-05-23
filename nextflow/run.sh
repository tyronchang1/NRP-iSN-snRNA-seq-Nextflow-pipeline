#!/bin/bash
#SBATCH --job-name=nextflow_iSN
#SBATCH --partition=interactive
#SBATCH --time=12:00:00
#SBATCH --mem=8G
#SBATCH --cpus-per-task=2
#SBATCH --output=nextflow/logs/nextflow_%j.out
#SBATCH --error=nextflow/logs/nextflow_%j.err
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=tyron@wustl.edu

export JAVA_HOME=/ref/rmlab/software/tyron/java17
export PATH=$JAVA_HOME/bin:$PATH
export NXF_HOME=/scratch/rmlab/rmlab_shared3/tyron/.nextflow

NXF_BIN=/ref/rmlab/software/tyron/nextflow

PROJECT_ROOT="$(pwd)"

mkdir -p nextflow/logs

# ── Track selection ───────────────────────────────────────────────────────────
if [ -n "${TRACK:-}" ]; then
    track_input_lower=$(echo "$TRACK" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')
    case "$track_input_lower" in
        1|soupx)   TRACK="soupx"   ;;
        2|decontx) TRACK="decontx" ;;
        3|both)    TRACK="both"    ;;
        *)
            echo "Invalid TRACK env var: '$TRACK'. Must be 'soupx', 'decontx', or 'both'. Exiting."
            exit 1
            ;;
    esac
    echo "Track (from env): $TRACK"
else
    echo ""
    echo "Which ambient RNA track to use for cell filtering and clustering?"
    echo "  1) SoupX"
    echo "  2) DecontX"
    echo "  3) Both (run both tracks in parallel)"
    echo -n "Choice [1/2/3] or type 'soupx'/'decontx'/'both': "
    read -r track_input
    track_input_lower=$(echo "$track_input" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')
    case "$track_input_lower" in
        1|soupx)   TRACK="soupx"   ;;
        2|decontx) TRACK="decontx" ;;
        3|both)    TRACK="both"    ;;
        *)
            echo "Invalid track choice: '$track_input'. Must be 1, 2, 3, 'soupx', 'decontx', or 'both'. Exiting."
            exit 1
            ;;
    esac
    echo "Selected track: $TRACK"
fi
# ─────────────────────────────────────────────────────────────────────────────

# ── Interactive gene-set prompt ───────────────────────────────────────────────
GENES_pan_neuronal="TUBB3,PRPH,SNAP25"
GENES_peptidergic="CALCA,TRPV1"
GENES_non_peptidergic="MRGPRD"
GENES_trkbc="NTRK2,NTRK3"
GENES_iPSC="POU5F1,SOX2,NANOG"
GENES_g2m="ATF5,AURKA,AURKB,BARD1,BIRC5,BRCA2,BUB1,CCNA2,CCNB2,CCND1,CDC20,CDC45,CDC6,CDK1,CDK2,CDK4,CDKN3,CENPA,CENPE,CENPF,CHAF1A,CHEK1,CKS1B,CKS2,E2F1,E2F2,EGF,ESPL1,EXO1,FBXO5,GINS2,HMGN2,HMMR,KIF11,KIF15,KIF20B,KIF23,KIF2C,KIF4A,KNL1,LMNB1,MAD2L1,MAP3K20,MCM2,MCM3,MCM4,MCM5,MCM6,MKI67,MT2A,MYBL2,NDC80,NEK2,NOTCH2,NUSAP1,ORC6,PBK,PCNA,PLK1,PLK4,POLA2,POLQ,PTTG1,RAD54L,SMC4,STIL,TACC3,TOP2A,TPX2,TROAP,TTK,UBE2C"

SET_NAMES=("pan_neuronal" "peptidergic" "non_peptidergic" "trkbc" "iPSC" "g2m")

GENE_SETS=""

if [ -f "${NXF_HOME}/gene_sets_input.txt" ]; then
    GENE_SETS=$(cat "${NXF_HOME}/gene_sets_input.txt")
    rm -f "${NXF_HOME}/gene_sets_input.txt"
    echo "Gene sets (from file): $GENE_SETS"
elif [ -n "${GENE_SETS_INPUT:-}" ]; then
    GENE_SETS="$GENE_SETS_INPUT"
    echo "Gene sets (from env): $GENE_SETS"
else
    echo "ERROR: No gene sets provided."
    echo "       Always run the pipeline via:  bash nextflow/submit.sh"
    echo "       submit.sh collects gene set inputs interactively, then submits this job."
    exit 1
fi

echo ""
echo "Gene sets: $GENE_SETS"
echo ""
# ─────────────────────────────────────────────────────────────────────────────

# ── Run Nextflow ──────────────────────────────────────────────────────────────
echo ""
echo "Pipeline started at: $(date)"
PIPELINE_START=$(date +%s)

$NXF_BIN run nextflow/main.nf \
    -c nextflow/nextflow.config \
    --project_root "$PROJECT_ROOT" \
    --gene_sets    "$GENE_SETS"    \
    --track        "$TRACK"        \
    -with-trace    nextflow/logs/trace.txt             \
    -with-report   nextflow/logs/execution_report.html \
    -with-timeline nextflow/logs/timeline.html         \
    -resume

PIPELINE_END=$(date +%s)
ELAPSED=$(( PIPELINE_END - PIPELINE_START ))
echo ""
echo "Pipeline finished at: $(date)"
printf "Total wall time: %02dh:%02dm:%02ds\n" \
    $((ELAPSED/3600)) $(((ELAPSED%3600)/60)) $((ELAPSED%60))
echo "Trace:    nextflow/logs/trace.txt"
echo "Report:   nextflow/logs/execution_report.html"
echo "Timeline: nextflow/logs/timeline.html"
# ─────────────────────────────────────────────────────────────────────────────
