#!/bin/bash
#SBATCH --partition=interactive
#SBATCH --job-name=r_install_python
#SBATCH --output=r_install/logs/04_python_%j.out
#SBATCH --error=r_install/logs/04_python_%j.err
#SBATCH --time=0:30:00
#SBATCH --mem=64G
#SBATCH --cpus-per-task=2

PYTHON=/home/tyron/miniconda3/bin/python3
PIP=/home/tyron/miniconda3/bin/pip3
PY_TARGET=/ref/rmlab/software/tyron/python-libs

mkdir -p "$PY_TARGET"

echo "=== Python Package Install ==="
echo "Python: $($PYTHON --version)"
echo "Target: $PY_TARGET"
echo "Start: $(date)"

pkgs=(
  numpy
  pandas
  scipy
  scikit-learn
  anndata
  scanpy
)

failed=()

for pkg in "${pkgs[@]}"; do
  echo ""
  echo "=== Installing: $pkg ==="
  for attempt in 1 2 3; do
    if $PIP install --target="$PY_TARGET" --upgrade "$pkg"; then
      echo "OK: $pkg"
      break
    else
      echo "  attempt $attempt failed"
      if [[ $attempt -lt 3 ]]; then sleep 5; fi
      if [[ $attempt -eq 3 ]]; then
        echo "FAILED: $pkg"
        failed+=("$pkg")
      fi
    fi
  done
done

if [[ ${#failed[@]} -gt 0 ]]; then
  echo ""
  echo "--- FAILED PACKAGES ---"
  printf '%s\n' "${failed[@]}"
  printf '%s\n' "${failed[@]}" > /ref/rmlab/software/tyron/R-libs/failed_04_python.txt
else
  echo ""
  echo "=== All Python packages installed successfully ==="
  echo "Add to your SLURM scripts:"
  echo "  export PYTHONPATH=$PY_TARGET:\$PYTHONPATH"
fi

echo "End: $(date)"
