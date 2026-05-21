#!/bin/bash
# Submit all install jobs from the project root:
#   bash r_install/submit_all.sh
#
# Chain: 01_cran → 02_bioc → 03_github  (each waits for previous to succeed)
#        04_python runs independently in parallel with 02_bioc
#
# Logs: r_install/logs/<job>_<jobid>.out / .err
# Failed package lists: /ref/rmlab/software/tyron/R-libs/failed_0*.txt

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

mkdir -p "$PROJECT_ROOT/r_install/logs"
cd "$PROJECT_ROOT"

echo "Submitting install jobs from: $(pwd)"

JOB1=$(sbatch --parsable r_install/01_cran.sh)
echo "01_cran    submitted: $JOB1"

JOB2=$(sbatch --parsable --dependency=afterok:$JOB1 r_install/02_bioc.sh)
echo "02_bioc    submitted: $JOB2  (depends on $JOB1)"

JOB3=$(sbatch --parsable --dependency=afterok:$JOB2 r_install/03_github.sh)
echo "03_github  submitted: $JOB3  (depends on $JOB2)"

JOB4=$(sbatch --parsable r_install/04_python.sh)
echo "04_python  submitted: $JOB4  (independent)"

JOB5=$(sbatch --parsable r_install/05_pandoc.sh)
echo "05_pandoc  submitted: $JOB5  (independent)"

echo ""
echo "Monitor with:"
echo "  squeue -u $USER"
echo "  tail -f r_install/logs/01_cran_${JOB1}.out"
echo ""
echo "After completion, check for failures:"
echo "  ls /ref/rmlab/software/tyron/R-libs/failed_*.txt 2>/dev/null && cat /ref/rmlab/software/tyron/R-libs/failed_*.txt"
