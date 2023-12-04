#!/bin/bash
#SBATCH --job-name=snippy
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --nodelist=compute-13
#SBATCH --mem=80G
#SBATCH --cpus-per-task=30
#SBATCH --chdir=/mnt/beegfs/scratch/ONEIDA/mykyta.forofontov/fish/snippy_reads

export ref=/mnt/beegfs/scratch/ONEIDA/mykyta.forofontov/fish/snippy_reads/reference/GCF_001275545.2.gbff
export input=/mnt/beegfs/scratch/ONEIDA/mykyta.forofontov/fish/reads_path.tsv



time srun apptainer run /mnt/beegfs/apptainer/images/snippy.sif snippy-multi $input $ref --cpus 30 > /mnt/beegfs/scratch/ONEIDA/mykyta.forofontov/fish/snippy_reads/runme.sh

sh /mnt/beegfs/scratch/ONEIDA/mykyta.forofontov/fish/snippy_reads/runme.sh

echo "Statistics for job $SLURM_JOB_ID:"
sacct --format="JOBID,Start,End,Elapsed,CPUTime,AveDiskRead,AveDiskWrite,MaxRSS" -j $SLURM_JOB_ID 
