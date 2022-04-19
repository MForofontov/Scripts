#!/bin/bash
#SBATCH --job-name=prokka
#SBATCH --nodes=1
#SBATCH --nodelist=compute-4
#SBATCH --ntasks-per-node=2
#SBATCH --cpus-per-task=10
#SBATCH --mem-per-cpu=4GB
#SBATCH --chdir=/mnt/beegfs/scratch/ONEIDA/mykyta.forofontov/prokka_out

# Optimize resource use
export parallel_jobs=$(($SLURM_NTASKS_PER_NODE * $SLURM_NNODES))
export cpus_per_task=$SLURM_CPUS_PER_TASK

export workdir='/mnt/beegfs/scratch/ONEIDA/mykyta.forofontov/prokka_out'

# Prokka information
export prokka_db=/mnt/nfs/lobo/ONEIDA-NFS/oneida/DB/prokka
export kingdom='Bacteria'
export gcode='11'
export centre='UMMI'
export prokka_parameters="--addgenes --usegenus --rfam --rnammer --increment 10 --mincontiglen 1 --gcode $gcode --kingdom $kingdom"
export genus='Shewanella'
export species='Shewanella'
export gram='neg'
export prokka_image='ummidock/prokka:1.14.5-2'

export input_directory='/mnt/beegfs/scratch/ONEIDA/mykyta.forofontov/shewanella'

# Setup prokka DB
# Create directory to store DB files
mkdir $workdir/prokka
if [ ! -d "$workdir/prokka/$species" ]; then
  mkdir $workdir/prokka/$species
fi

# Create directory and copy DB files into that directory
if [ -d "$prokka_db/$species" ]; then
  # Get default DB that is bundled with Prokka
  mkdir $workdir/prokka/$species/prokka_db
  shifter --image=$prokka_image cp -r /NGStools/prokka/db/genus/ $workdir/prokka/$species/prokka_db
  mv $workdir/prokka/$species/prokka_db/genus/* $workdir/prokka/$species/prokka_db/
  rm -r $workdir/prokka/$species/prokka_db/genus/

  # Check if custom DB that is in LOBO has files for current species
  export genus_db=$(ls $prokka_db/$species/$species* | wc -l)
  if [ "$genus_db" -eq "0" ]; then
    echo "WARNING: Prokka DB not found for $species"
  else
    # Copy files from custom DB to use during execution
    export genus=$(echo "${species^}" | cut -d "_" -f 1)
    ls $prokka_db/$species/$species* | parallel -j 1 'cp {} $workdir/prokka/$species/prokka_db/$(echo {/} | sed "s#$species#$genus#1")'
  fi
fi

# Run Prokka
ls $input_directory | parallel --delay 0.2 -j $parallel_jobs --joblog $workdir/parallel.prokka.log --resume-failed \
'assembly=$input_directory/{}; basename=${assembly##*/}; strain=${basename%.*}; srun --exclusive --oversubscribe --job-name=prokka --task-prolog=/mnt/nfs/lobo/ONEIDA-NFS/oneida/NGStools/task_prolog.sh \
--task-epilog=/mnt/nfs/lobo/ONEIDA-NFS/oneida/NGStools/task_epilog.sh --nodes=1 --ntasks=1 --cpus-per-task=$cpus_per_task shifter \
--image=$prokka_image --volume=$workdir/prokka/$species/prokka_db:/NGStools/prokka/db/genus /mnt/nfs/lobo/ONEIDA-NFS/oneida/NGStools/prokka \
--outdir $workdir/prokka_results/$strain --force --centre $centre --genus $genus --species $species --strain $strain --cpus $cpus_per_task --prefix $strain \
--locustag ${strain}p --gram $gram $prokka_parameters $assembly'

#echo "Statistics for job $SLURM_JOB_ID:"
#sacct --format="JOBID,Start,End,Elapsed,CPUTime,AveDiskRead,AveDiskWrite,MaxRSS" -j $SLURM_JOB_ID

