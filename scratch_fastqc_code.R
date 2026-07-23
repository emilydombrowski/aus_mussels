### some code I am running with Joaquin to investigate my coverage issue on the VACC

srun --partition=short --nodes=1 --ntasks=1 --mem=40G --time=2:40:00 --pty /bin/bash
NTHREADS=$SLURM_CPUS_ON_NODE

R1=/netfiles/lockwood_lab/aus_mussels/data/raw/AGRF_NXGSQCAGRF25090171-1_23JW2NLT4/C1R1-22C-D19-E1_23JW2NLT4_CAATCCTTGT-CGAAGACGCA_L008_R1.fastq.gz
R2=/netfiles/lockwood_lab/aus_mussels/data/raw/AGRF_NXGSQCAGRF25090171-1_23JW2NLT4/C1R1-22C-D19-E1_23JW2NLT4_CAATCCTTGT-CGAAGACGCA_L008_R2.fastq.gz

fastqc -o /users/e/d/edombro1/scratch/aus_mussels/data/trimmed/fastqc \
-t $NTHREADS \
$R1 $R2