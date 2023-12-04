#!/bin/bash

outdir=$1
sample=$2
cpus=$3
workdir=$4
prokka_image=$5
species=$6
DB_already_produced=$7
centre=$8
gram=$9
assembly=${10}
prokka_parameters=${11}

mkdir -p $outdir/$sample

genus=$(echo "${species^}" | cut -d "_" -f 1)
species_prokka=$(echo $species | cut -d "_" -f 2)

apptainer run $prokka_image $DB_already_produced /mnt/nfs/lobo/ONEIDA-NFS/oneida/NGStools/prokka --outdir $outdir/$sample/$sample/ --force --centre $centre --genus $genus --species $species_prokka --strain $sample --cpus $cpus --prefix $sample --locustag ${sample}p --gram $gram $prokka_parameters $assembly
exit_code=$?

if [ $exit_code -eq 0 ]; then
  if [ -d "$workdir/$sample/" ]; then
    rm -r $workdir/$sample/
  fi
  
  mv $outdir/$sample/$sample/ $workdir/
else
  exit 1
fi
