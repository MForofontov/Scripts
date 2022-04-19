#!/bin/bash
#SBATCH --job-name=sagalactiae
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --nodelist=compute-5
#SBATCH --mem=60G
#SBATCH --cpus-per-task=30
#SBATCH --image=ummidock/chewbbaca:2.8.4-1
#SBATCH --chdir=/mnt/beegfs/scratch/ONEIDA/mykyta.forofontov/streptococcus_agalactiae2/new_schema

export SCHEMA=/mnt/beegfs/scratch/ONEIDA/mykyta.forofontov/streptococcus_agalactiae2/new_schema/schema_2021_01_06/schema_seed
export OUT=/mnt/beegfs/scratch/ONEIDA/mykyta.forofontov/streptococcus_agalactiae2/new_schema/schema_2021_01_06/annotation
export TABLE=/mnt/beegfs/scratch/ONEIDA/mykyta.forofontov/streptococcus_agalactiae2/new_schema/schema_2021_01_06/cds_info.tsv


time srun shifter chewBBACA.py UniprotFinder -i $SCHEMA -o $OUT --cpu 30 -t $TABLE --taxa "Streptococcus agalactiae"


echo "Statistics for job $SLURM_JOB_ID:"
sacct --format="JOBID,Start,End,Elapsed,CPUTime,AveDiskRead,AveDiskWrite,MaxRSS" -j $SLURM_JOB_ID 
