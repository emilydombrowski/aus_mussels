#!/bin/bash
#SBATCH --job-name=alignment_metrics_qc_array
#SBATCH --partition=general
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=10G
#SBATCH --time=10:00:00
#SBATCH --array=1-70
#SBATCH --output=/gpfs2/scratch/edombro1/aus_mussels/data/dedup/qc/logs/array_%A_%a.out
#SBATCH --mail-type=ALL

# 1. LOAD MODULES - samtools + dependencies
module load gcc/13.3.0-xp3epyt
module load samtools/1.19

# 2. FILE PATHS  - samples, deduplicated crams, qc directory, and picard logs directory
SAMPLE_LIST="/gpfs2/scratch/edombro1/aus_mussels/data/trimmed/unique_samples.txt"
CRAM_DIR="/gpfs2/scratch/edombro1/aus_mussels/data/dedup"
QC_OUT="/gpfs2/scratch/edombro1/aus_mussels/data/dedup/qc"
LOGS_DIR="/gpfs2/scratch/edombro1/aus_mussels/data/dedup/logs"
REF="/gpfs2/scratch/edombro1/aus_mussels/data/reference/GCF_965363235.1_xbMytGall1.hap1.1_genomic.fna"

# 3. IDENTIFY TARGET SAMPLE PER TASK
# use sed -n p to print the array task
sample=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "${SAMPLE_LIST}")

# if sample doesn't exist, error message gets sent to log
if [ -z "${sample}" ]; then
    echo "Line ${SLURM_ARRAY_TASK_ID} is empty. Exiting."
    exit 0
fi

# .txt file gets inititated in output directory
FINAL_COVERAGE="${QC_OUT}/${sample}_coverage.txt"
INDIVIDUAL_MAPPING="${QC_OUT}/${sample}_map_stats.tmp"

# use coverage command in samtools to get mapping statistics for each sample
# CHECKPOINT: If a file exists from the earlier run, skip the heavy computation
# edit after failed script: make sure to include reference and pipe since samtools does not have ref flag
if [ -f "${FINAL_COVERAGE}" ] && [ -s "${FINAL_COVERAGE}" ]; then
    echo "Checkpoint verified for ${sample}. Skipping samtools coverage..."
else
    if [ -f "${CRAM_DIR}/${sample}_dedup.cram" ]; then
        echo "Computing parallel coverage for: ${sample}"
        
        # Open with samtools view using local reference variable, then pipe to samtools coverage
        samtools view -u -T "${REF}" "${CRAM_DIR}/${sample}_dedup.cram" | samtools coverage - > "${FINAL_COVERAGE}"
    else
        echo "ERROR: CRAM missing for ${sample}" >&2
    fi
fi

# 4. EXTRACT PICARD STATS - uses grep and awk to extract coverage data
PICARD_FILE="${LOGS_DIR}/${sample}_metrics.txt"
if [ -f "${PICARD_FILE}" ]; then
    metrics_line=$(grep -A 1 "LIBRARY" "${PICARD_FILE}" | tail -n 1)
    echo "${metrics_line}" | awk -v s="${sample}" -F'\t' '{
        unpaired = $2; pairs = $3; unmapped = $5;
        total = unpaired + (pairs * 2);
        mapped = total - unmapped;
        prop = (total > 0) ? (mapped / total) : 0;
        printf "%s\t%d\t%d\t%d\t%.4f\n", s, total, unmapped, mapped, prop;
    }' > "${INDIVIDUAL_MAPPING}"
fi