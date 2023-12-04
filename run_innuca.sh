#!/bin/bash

outdir=$1
sample=$2
cpus=$3
workdir=$4
innuca_image=$5
species=$6
genome_size=$7
numberContigs=$8
reads=$9
fastq_end=${10}
innuca_parameters=${11}

mkdir -p $outdir/$sample/$sample

for fastq in $(ls $reads/${sample}_*${fastq_end}); do
  ln -s $fastq $outdir/$sample/$sample/$(basename $fastq)
done

export species_innuca=$(echo $(echo "${species^}" | cut -d "_" -f 1) $(echo $species | cut -d "_" -f 2))

export LANG=""
apptainer run $innuca_image INNUca.py -s "$(echo $species_innuca)" -g $genome_size -i $outdir/$sample/ -o $outdir/$sample/innuca/ -j $cpus --maxNumberContigs $numberContigs --noGitInfo --fastQCproceed $innuca_parameters
exit_code=$?

rm -r $outdir/$sample/$sample/

if [ $exit_code -eq 0 ]; then
  if [ -d "$workdir/$sample/" ]; then
    rm -r $workdir/$sample/
  fi
  
  mv $outdir/$sample/ $workdir/
else
  exit 1
fi
