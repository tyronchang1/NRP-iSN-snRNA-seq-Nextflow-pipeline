#!/bin/bash
#SBATCH --partition=interactive
#SBATCH --job-name=r_install_pandoc
#SBATCH --output=r_install/logs/05_pandoc_%j.out
#SBATCH --error=r_install/logs/05_pandoc_%j.err
#SBATCH --time=0:30:00
#SBATCH --mem=8G
#SBATCH --cpus-per-task=2

CONDA=/home/tyron/miniconda3/bin/conda
CONDA_PREFIX=/home/tyron/miniconda3

echo "=== Pandoc Install ==="
echo "Conda: $($CONDA --version)"
echo "Target prefix: $CONDA_PREFIX"
echo "Start: $(date)"

if [[ -x "${CONDA_PREFIX}/bin/pandoc" ]]; then
    echo "SKIP: pandoc already installed at ${CONDA_PREFIX}/bin/pandoc"
    "${CONDA_PREFIX}/bin/pandoc" --version | head -1
else
    echo "Installing pandoc via conda..."
    $CONDA install -y pandoc -c pkgs/main -p "$CONDA_PREFIX"
    echo "OK: $("${CONDA_PREFIX}/bin/pandoc" --version | head -1)"
fi

echo "End: $(date)"
