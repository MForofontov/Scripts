#!/bin/bash

#SBATCH --job-name=innuca
#SBATCH --output=innuca-%j.out
#SBATCH --error=innuca-%j.err
#SBATCH --mail-user=rmamede@medicina.ulisboa.pt
#SBATCH --mail-type=ALL
#SBATCH --nodes=4
#SBATCH --ntasks-per-node=5
#SBATCH --exclude=compute-[1,2,5,9,13,17,21]
# --nodelist=compute-[17,18,19,20]
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=3GB
#SBATCH --chdir=/mnt/beegfs/scratch/ONEIDA/mykyta.forofontov/INNUCA

# NOTES:
#
# Make sure samples names do not include _
# Try using -
#
# In samples_species place the shorter names at the end to avoid the name to be contained

# Define working dir
export workdir=/mnt/beegfs/scratch/ONEIDA/mykyta.forofontov/INNUCA
#mkdir -p $workdir

# Define Kraken DB path
export original_kraken_db=/mnt/nfs/lobo/ONEIDA-NFS/oneida/DB/metagenomics/kraken2_standard_db_20180917_second
export kraken_db=$workdir/kraken_db/$(basename $original_kraken_db)

# Define innuca and prokka images and determine versions
export innuca_image='ummidock/innuca:4.2.2-02'
innuca_version=$(shifter --image=$innuca_image INNUca.py --version 2>&1)
export innuca_parameters="--runInsertSize --adapters /NGStools/INNUca/src/Trimmomatic-0.36/adapters/Nextera_XT_INNUca.fasta --runKraken --krakenDB $kraken_db --krakenProceed --trueCoverageProceed --trueCoverageIgnoreQC"
echo $innuca_parameters

# Define prokka image, determine version and set parameters
export prokka_image="ummidock/prokka:1.14.5-2"
prokka_version=$(LANG="" && shifter --image=$prokka_image prokka --version 2>&1)
export prokka_db=/mnt/nfs/lobo/ONEIDA-NFS/oneida/DB/prokka
export kingdom="Bacteria"
export gcode="11"
export centre="UMMI"
export prokka_parameters="--addgenes --usegenus --rfam --rnammer --increment 10 --mincontiglen 1 --gcode $gcode --kingdom $kingdom"

# Define date of the analysis
analysis_date=$(date +"%Y_%m_%d")

# Define path to directory with reads sets
# Paired reads sets, all files in same directory
export reads=$workdir/reads

# Define path to file with sample metadata
# File structure example (TSV file, do not include headers)
# sample        species genome_size     numberContigs   strategy        source  selection       comment gram
# SH12316A      streptococcus_pyogenes  2       100     whole_genome_sequencing genomic random  renamed_from_GBS_13     pos
export samples_species=$workdir/data.tsv

# Define compressed reads files extension
export fastq_end=".fastq.gz"
# Define compressed reads file name suffix
export left_fastq_end="_1.fastq.gz"

# Clean the tmp directory before starting run
export clean_tmp_script=/mnt/nfs/lobo/ONEIDA-NFS/oneida/NGStools/clean_tmp.sh
for node in $(scontrol show hostname $SLURM_JOB_NODELIST); do
  echo "CLEANING $node"
  srun --job-name=clean_node --nodes=1 --ntasks=1 --cpus-per-task=1 --nodelist=$node sh $clean_tmp_script $(whoami)
done

# Define available resources
export available_cpus=$(($SLURM_NNODES * $SLURM_NTASKS_PER_NODE * $SLURM_CPUS_PER_TASK))
export n_simultaneous_samples=$(($SLURM_NTASKS_PER_NODE * $SLURM_NNODES))
export cpus_node=$(($SLURM_NTASKS_PER_NODE * $SLURM_CPUS_PER_TASK))

# Check samples_species information
# Define flag to signal that file is invalid
stop=false
# check if file has repeated sample identifiers
if [ $(cut -f 1 $samples_species | sort | uniq -d | wc -l) -ne 0 ]; then
  echo "ERROR: duplicated samples in samples_species file."
  echo "Duplicated samples IDs saved in ${samples_species}.duplicated.txt"
  cut -f 1 $samples_species | sort | uniq -d | parallel --no-notice -j 1 'echo "^{}"' > ${samples_species}.temp.txt
  egrep -f ${samples_species}.temp.txt $samples_species > ${samples_species}.duplicated.txt
  rm ${samples_species}.temp.txt
  stop=true
fi
if [ $(cut -f 1 $samples_species | sort | uniq | wc -l) -ne $(ls $reads/ | egrep ${left_fastq_end}$ | sed -E "s/${left_fastq_end}$//" | sort | uniq | wc -l) ]; then
  echo "ERROR: different number of samples"
  
  echo "Samples without sample_species information saved in ${samples_species}.no_sample_species.txt"
  cat <(cut -f 1 $samples_species | sort | uniq) <(ls $reads/ | egrep ${left_fastq_end}$ | sed -E "s/${left_fastq_end}$//" | sort | uniq) | sort | uniq -u
  comm -13  <(cut -f 1 $samples_species | sort | uniq) <(ls $reads/ | egrep ${left_fastq_end}$ | sed -E "s/${left_fastq_end}$//" | sort | uniq) > ${samples_species}.no_sample_species.txt
  
  echo "Samples without sequencing data saved in ${samples_species}.no_sequencing.txt"
  comm -23  <(cut -f 1 $samples_species | sort | uniq) <(ls $reads/ | egrep ${left_fastq_end}$ | sed -E "s/${left_fastq_end}$//" | sort | uniq) | parallel --no-notice -j 1 'echo "^{}"' > ${samples_species}.temp.txt
  egrep -f ${samples_species}.temp.txt $samples_species > ${samples_species}.no_sequencing.txt
  rm ${samples_species}.temp.txt
  
  stop=true
fi

if [ "$stop" = true ] ; then
  exit 1
fi

# Copy Kraken DB to working directory
mkdir -p $kraken_db
if [ $(ls $kraken_db/ | wc -l) -eq 0 ]; then
  echo "Copying Kraken DB..."
  time cp $original_kraken_db/* $kraken_db/
  echo "Copied Kraken DB."
  echo ""
fi

# INNUca step

# Create subfolders for each species
mkdir $workdir/innuca
for species in $(cut -f 2 $samples_species | sort | uniq); do
  export species
  if [ ! -d "$workdir/innuca/$species" ]; then
    mkdir $workdir/innuca/$species
  fi
done

# Define tmp directory for INNUca analysis
export outdir=/tmp/$(whoami)_innuca_$date_analysis
echo $outdir

# These functions have two arguments: 1) ID; 2) Filename
species_awk()
{
  echo $(awk -F "\t" -v awk_sample=$1 '$1 == awk_sample' $2 | cut -f 2)
}
export -f species_awk

genome_size_awk()
{
  echo $(awk -F "\t" -v awk_sample=$1 '$1 == awk_sample' $2 | cut -f 3)
}
export -f genome_size_awk

number_contigs_awk()
{
  echo $(awk -F "\t" -v awk_sample=$1 '$1 == awk_sample' $2 | cut -f 4)
}
export -f number_contigs_awk
gram_awk()
{
  echo $(awk -F "\t" -v awk_sample=$1 '$1 == awk_sample' $2 | cut -f 9)
}
export -f gram_awk

# Run INNUca with parallel
cut -f 1 $samples_species | parallel --delay 0.2 -j $n_simultaneous_samples --joblog $workdir/parallel.innuca.log --resume-failed 'species=$(species_awk {} $samples_species); genome_size=$(genome_size_awk {} $samples_species); number_contigs=$(number_contigs_awk {} $samples_species); srun --exclusive --oversubscribe --job-name=innuca --task-prolog=/mnt/nfs/lobo/ONEIDA-NFS/oneida/NGStools/task_prolog.sh --task-epilog=/mnt/nfs/lobo/ONEIDA-NFS/oneida/NGStools/task_epilog.sh --nodes=1 --ntasks=1 --cpus-per-task=$SLURM_CPUS_PER_TASK bash $workdir/run_innuca.sh $outdir {} $SLURM_CPUS_PER_TASK $workdir/innuca/$species $innuca_image $species $genome_size $number_contigs $reads "$fastq_end" "$innuca_parameters"'

# Create report for each sample and combined report for all samples
for species in $(cut -f 2 $samples_species | sort | uniq); do
  head -n 1 $(ls $workdir/innuca/$species/*/innuca/samples_report.*.tab | head -n 1) > $workdir/innuca/$species/samples_report.tab
  grep --no-filename --invert-match "^#" $workdir/innuca/$species/*/innuca/samples_report.*.tab | grep --invert-match "^reads" >> $workdir/innuca/$species/samples_report.tab
  head -n 1 $(ls $workdir/innuca/$species/*/innuca/combine_samples_reports.*.tab | head -n 1) > $workdir/innuca/$species/combine_samples_reports.tab
  grep --no-filename --invert-match "^#" $workdir/innuca/$species/*/innuca/combine_samples_reports.*.tab | grep --invert-match "^reads" >> $workdir/innuca/$species/combine_samples_reports.tab
done

# Remove Kraken DB
rm -r $kraken_db/

# Prokka step

export LANG=""

export prokka_db=/mnt/nfs/lobo/ONEIDA-NFS/oneida/DB/prokka

# Create dirs to store results for each species 
mkdir $workdir/prokka
for species in $(cut -f 2 $samples_species | sort | uniq); do
  export species
  if [ ! -d "$workdir/prokka/$species" ]; then
    mkdir $workdir/prokka/$species
  fi
  # Copy default DB to each species dir
  if [ -d "$prokka_db/$species" ]; then
    mkdir $workdir/prokka/$species/prokka_db
    shifter --image=$prokka_image cp -r /NGStools/prokka/db/genus/ $workdir/prokka/$species/prokka_db
    mv $workdir/prokka/$species/prokka_db/genus/* $workdir/prokka/$species/prokka_db/
    rm -r $workdir/prokka/$species/prokka_db/genus/
    # Determine if there is a custom DB for each species and copy it to working directory
    export genus_db=$(ls $prokka_db/$species/$species* | wc -l)
    if [ "$genus_db" -eq "0" ]; then
      echo "WARNING: Prokka DB not found for $species"
    else
      # Use DB already produced
      export genus=$(echo "${species^}" | cut -d "_" -f 1)
      ls $prokka_db/$species/$species* | parallel -j 1 'cp {} $workdir/prokka/$species/prokka_db/$(echo {/} | sed "s#$species#$genus#1")'
    fi
  fi
done

export outdir=/tmp/$(whoami)_prokka_$date_analysis
# Make sure temp files stay in temp directory
mkdir -p $outdir
cd $outdir

# Run Prokka
cut -f 1 $samples_species | parallel --delay 0.2 -j $available_cpus --joblog $workdir/parallel.prokka.log --resume-failed 'species=$(species_awk {} $samples_species); gram=$(gram_awk {} $samples_species); DB_already_produced=''; if [ -d "$prokka_db/$species" ]; then DB_already_produced="--volume=$workdir/prokka/$species/prokka_db:/NGStools/prokka/db/genus"; fi; srun --exclusive --oversubscribe --job-name=prokka --task-prolog=/mnt/nfs/lobo/ONEIDA-NFS/oneida/NGStools/task_prolog.sh --task-epilog=/mnt/nfs/lobo/ONEIDA-NFS/oneida/NGStools/task_epilog.sh --nodes=1 --ntasks=1 --cpus-per-task=1 bash $workdir/run_prokka.sh $outdir {} 1 $workdir/prokka/$species $prokka_image $species "$DB_already_produced" $centre $gram $(ls $workdir/innuca/$species/{}/innuca/{}/*.fasta | grep --invert-match "SPAdes_original_assembly.contigs.fasta") "$prokka_parameters"'

# Delete prokka DBs
for species in $(cut -f 2 $samples_species | sort | uniq); do
  rm -r $workdir/prokka/$species/prokka_db/
done

# UMMI reads report
paste --delimiters '\t' > $workdir/sequencing_analysis_info.tab <(echo $analysis_date) <(echo $innuca_image) <(echo $prokka_image) <(echo $innuca_version) <(echo $prokka_version) <(echo $innuca_parameters) <(echo $prokka_parameters)

# Clean tmps after run
for node in $(scontrol show hostname $SLURM_JOB_NODELIST); do
  echo "CLEANING $node"
  srun --job-name=clean_node --nodes=1 --ntasks=1 --cpus-per-task=1 --nodelist=$node sh /mnt/nfs/lobo/ONEIDA-NFS/oneida/NGStools/clean_tmp.sh $(whoami)
done

sacct --long --parsable2 -j $SLURM_JOB_ID > $workdir/${SLURM_JOB_NAME}-${SLURM_JOB_ID}.sacct.txt
