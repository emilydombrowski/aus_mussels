#!/usr/bin/env bash
#SBATCH --job-name=variant_calling_freebayes
#SBATCH --partition=general
#SBATCH --nodes=1 
#SBATCH --time=48:00:00 
#SBATCH --mem=60G 
#SBATCH --cpus-per-task=1
#SBATCH --array=1-1700%50
#SBATCH --output=/users/e/d/edombro1/scratch/aus_mussels/data/vcf_freebayes/logs/%x.%A_%a.out
#SBATCH --error=/users/e/d/edombro1/scratch/aus_mussels/data/vcf_freebayes/logs/%x.%A_%a.err
#SBATCH --mail-type=ALL

#--------------------------------------------------------------------------------
# Load modules and dependency
module load gcc/13.3.0-xp3epyt
module load freebayes/1.3.6-r67va2b
module load bcftools/1.19-iq5mwek

#--------------------------------------------------------------------------------
# Define paths
PROJECT_DIR=/users/e/d/edombro1/scratch/aus_mussels
WORKING_FOLDER=$PROJECT_DIR/data
REFERENCE_FOLDER=$PROJECT_DIR/data/reference
REFERENCE=$REFERENCE_FOLDER/GCF_965363235.1_xbMytGall1.hap1.1_genomic.fna

# Master 1Mb guide file and pre-generated CRAM list
GUIDE_FILE=$REFERENCE_FOLDER/regions_1Mb.txt
BAMLIST=$REFERENCE_FOLDER/mussels_cram_names.list

# Determine region to process
echo "Processing Slurm Array Task ID: ${SLURM_ARRAY_TASK_ID}"
REGION=$(sed -n "${SLURM_ARRAY_TASK_ID}p" $GUIDE_FILE)
echo "Processing region: $REGION"

# Ensure output directory exists
mkdir -p $WORKING_FOLDER/vcf_freebayes/partitions

#--------------------------------------------------------------------------------
# Execute Freebayes with speed and repeat-limiting flags:
#  -F 0.01 -C 1 -G 5      : Sensitive detection of rare pool variants
#  --use-best-n-alleles 4 : Restricts combinatorial evaluation to top 4 alleles
#  --limit-coverage 500   : Downsamples high-coverage sites to 500x
#  --skip-coverage 1000  : Completely skips extreme repeat/organellar piles >1000x; highly repetitive regions that may cause a bottle neck
#  -q 20 -m 30            : High-confidence quality thresholds

freebayes \
  -f $REFERENCE \
  -L $BAMLIST \
  -r "$REGION" \
  -K \
  -F 0.01 \
  -C 1 \
  -G 5 \
  --use-best-n-alleles 4 \
  --limit-coverage 500 \
  --skip-coverage 1000 \
  -n 4 \
  -m 30 \
  -q 20 | \
  gzip -c > $WORKING_FOLDER/vcf_freebayes/partitions/${SLURM_ARRAY_TASK_ID}.vcf.gz

#--------------------------------------------------------------------------------
date
echo "Task ${SLURM_ARRAY_TASK_ID} completed successfully."