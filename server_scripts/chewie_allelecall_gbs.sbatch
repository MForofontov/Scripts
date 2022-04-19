#!/bin/bash
#SBATCH --job-name=sagalactiae
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --nodelist=compute-5
#SBATCH --mem=60G
#SBATCH --cpus-per-task=30
#SBATCH --image=ummidock/chewbbaca:2.8.4-1
#SBATCH --chdir=/mnt/beegfs/scratch/ONEIDA/mykyta.forofontov/staphy/schema

export GENOMES=/mnt/beegfs/scratch/ONEIDA/mykyta.forofontov/staphy/all_assemblies_afterNexclusion
export SCHEMA=/mnt/beegfs/scratch/ONEIDA/mykyta.forofontov/staphy/schema/schema_seed



time srun shifter chewBBACA.py AlleleCall -i $GENOMES -g $SCHEMA --cpu 30 -o BR_results --fr

echo "Statistics for job $SLURM_JOB_ID:"
sacct --format="JOBID,Start,End,Elapsed,CPUTime,AveDiskRead,AveDiskWrite,MaxRSS" -j $SLURM_JOB_ID 
