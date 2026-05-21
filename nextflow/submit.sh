#!/bin/bash
# Run directly in the terminal: bash nextflow/submit.sh
# DO NOT submit via sbatch — this script collects inputs interactively then submits the pipeline.

export NXF_HOME=/scratch/rmlab/rmlab_shared3/tyron/.nextflow

# ── Track selection ───────────────────────────────────────────────────────────
echo ""
echo "Which ambient RNA track to use for cell filtering and clustering?"
echo "  1) SoupX"
echo "  2) DecontX"
echo -n "Choice [1/2] or type 'soupx'/'decontx': "
read -r track_input
track_input_lower=$(echo "$track_input" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')
case "$track_input_lower" in
    1|soupx)   TRACK="soupx"   ;;
    2|decontx) TRACK="decontx" ;;
    *)
        echo "Invalid track choice: '$track_input'. Must be 1, 2, 'soupx', or 'decontx'. Exiting."
        exit 1
        ;;
esac
echo "Selected track: $TRACK"
# ─────────────────────────────────────────────────────────────────────────────

# ── Gene set selection ────────────────────────────────────────────────────────
GENES_pan_neuronal="TUBB3,PRPH,SNAP25"
GENES_peptidergic="CALCA,TRPV1"
GENES_non_peptidergic="MRGPRD"
GENES_trkbc="NTRK2,NTRK3"
GENES_iPSC="POU5F1,SOX2,NANOG"
GENES_g2m="ATF5,AURKA,AURKB,BARD1,BIRC5,BRCA2,BUB1,CCNA2,CCNB2,CCND1,CDC20,CDC45,CDC6,CDK1,CDK2,CDK4,CDKN3,CENPA,CENPE,CENPF,CHAF1A,CHEK1,CKS1B,CKS2,E2F1,E2F2,EGF,ESPL1,EXO1,FBXO5,GINS2,HMGN2,HMMR,KIF11,KIF15,KIF20B,KIF23,KIF2C,KIF4A,KNL1,LMNB1,MAD2L1,MAP3K20,MCM2,MCM3,MCM4,MCM5,MCM6,MKI67,MT2A,MYBL2,NDC80,NEK2,NOTCH2,NUSAP1,ORC6,PBK,PCNA,PLK1,PLK4,POLA2,POLQ,PTTG1,RAD54L,SMC4,STIL,TACC3,TOP2A,TPX2,TROAP,TTK,UBE2C"

SET_NAMES=("pan_neuronal" "peptidergic" "non_peptidergic" "trkbc" "iPSC" "g2m")

echo ""
echo "Gene set selection:"
echo "  1) Enter custom genes manually  (format: setname=GENE1,GENE2  semicolon-separated sets)"
echo "  2) Choose from predefined sets"
echo -n "Choice [1/2]: "
read -r choice

if [ "$choice" = "1" ]; then
    echo "  Format: setname=GENE1,GENE2  — separate multiple sets with semicolons"
    echo "  Example: mymarkers=TUBB3,PRPH;iPSC_check=POU5F1,SOX2"
    echo -n "Enter gene sets: "
    read -r GENE_SETS
    GENE_SETS=$(echo "$GENE_SETS" | tr -d '[:space:]')
    if [ -z "$GENE_SETS" ]; then
        echo "No gene sets entered. Exiting."
        exit 1
    fi

elif [ "$choice" = "2" ]; then
    echo ""
    echo "Available gene sets:"
    for i in "${!SET_NAMES[@]}"; do
        echo "  $((i+1))) ${SET_NAMES[$i]}"
    done
    echo -n "Enter numbers separated by commas (e.g. 1,3): "
    read -r selection

    GENE_SETS=""
    IFS=',' read -ra picks <<< "$selection"
    first=1
    n_sets=${#SET_NAMES[@]}
    for pick in "${picks[@]}"; do
        pick=$(echo "$pick" | tr -d '[:space:]')
        if ! [[ "$pick" =~ ^[0-9]+$ ]] || [ "$pick" -lt 1 ] || [ "$pick" -gt "$n_sets" ]; then
            echo "Invalid selection: '$pick'. Must be a number between 1 and ${n_sets}. Exiting."
            exit 1
        fi
        idx=$((pick - 1))
        name="${SET_NAMES[$idx]}"
        var="GENES_${name}"
        genes="${!var}"
        if [ "$first" = "1" ]; then
            GENE_SETS="${name}=${genes}"
            first=0
        else
            GENE_SETS="${GENE_SETS};${name}=${genes}"
        fi
    done

    if [ -z "$GENE_SETS" ]; then
        echo "No gene sets selected. Exiting."
        exit 1
    fi

else
    echo "Invalid choice: '$choice'. Must be 1 or 2. Exiting."
    exit 1
fi

echo ""
echo "Gene sets: $GENE_SETS"
echo ""
# ─────────────────────────────────────────────────────────────────────────────

# ── Write gene sets to file for run.sh to read ────────────────────────────────
mkdir -p "${NXF_HOME}"
echo "$GENE_SETS" > "${NXF_HOME}/gene_sets_input.txt"
echo "Gene sets written to ${NXF_HOME}/gene_sets_input.txt"
# ─────────────────────────────────────────────────────────────────────────────

# ── Submit pipeline ───────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo ""
echo "Submitting pipeline with track=$TRACK ..."
sbatch --chdir="$(pwd)" --export=ALL,TRACK="$TRACK" "${SCRIPT_DIR}/run.sh"
# ─────────────────────────────────────────────────────────────────────────────
