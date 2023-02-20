#!/bin/bash
set -e

function pfam_profiles_download()
{
  local version=$1
  local output=$2
  curl ftp://ftp.ebi.ac.uk/pub/databases/Pfam/releases/Pfam35.0/Pfam-A.hmm.gz \
    | gunzip -d > $output
}

function pfam_clans_download()
{
  local version=$1
  local output=$2
  curl ftp://ftp.ebi.ac.uk/pub/databases/Pfam/releases/Pfam35.0/Pfam-C.gz \
    | gunzip -d > $output
}

function random_source()
{
  local seed=$1
  local golden_ratio_32bits=1640531527

  val=$seed
  while true;
  do
    val=$((golden_ratio_32bits*$val))
    val=$(echo -n $val | head -c 8)
    echo -n $val
  done
}

function assembly_summary_download()
{
  local domain=$1
  local output=$2
  local baseurl="ftp://ftp.ncbi.nlm.nih.gov/genomes/refseq"

  curl $baseurl/$domain/assembly_summary.txt > $output
}

function assembly_summary_remove_leading_sharp()
{
  local input=$1
  local output=$2

  head -n 2 $input | tail -n 1 | sed 's/# //' > $output
  tail -n +2 $input >> $output
}

function assembly_summary_complete_only()
{
  local input=$1
  local output=$2

  head -n 1 $input > $output
  tail -n +2 $input | grep "Complete Genome" >> $output
}

function assembly_summary_representative_only()
{
  local input=$1
  local output=$2

  head -n 1 $input > $output
  tail -n +2 $input | grep "representative genome" >> $output
}

function assembly_summary_drop_duplicates()
{
  local input=$1
  local output=$2

  # Filter out duplicated rows by taxid and get the latest release
  TAB=$(printf '\t')
  head -n 1 $input > $output
  tail -n +2 $input | sort -t "$TAB" -srk15 | sort -t "$TAB" -unk6 >> $output
}

function assembly_summary_shuffle()
{
  local input=$1
  local output=$2

  head -n 1 $input > $output
  shuf $input --random-source=<(random_source 42) >> $output
}

function assembly_summary_first_entries_only()
{
  local input=$1
  local output=$2
  local nentries=$3

  head -n 1 $input > $output
  tail -n +2 $input | head -n $nentries >> $output
}

pfam_profiles_download "35.0" Pfam-A.hmm
pfam_clans_download "35.0" Pfam-C.sto

assembly_summary_download             archaea \
                                      archaea_assembly_summary.01.txt
assembly_summary_remove_leading_sharp archaea_assembly_summary.01.txt \
                                      archaea_assembly_summary.02.txt
assembly_summary_complete_only        archaea_assembly_summary.02.txt \
                                      archaea_assembly_summary.03.txt
assembly_summary_representative_only  archaea_assembly_summary.03.txt \
                                      archaea_assembly_summary.04.txt
assembly_summary_drop_duplicates      archaea_assembly_summary.04.txt \
                                      archaea_assembly_summary.05.txt
assembly_summary_shuffle              archaea_assembly_summary.05.txt \
                                      archaea_assembly_summary.06.txt
assembly_summary_first_entries_only   archaea_assembly_summary.06.txt \
                                      archaea_assembly_summary.07.txt 20

assembly_summary_download             bacteria \
                                      bacteria_assembly_summary.01.txt
assembly_summary_remove_leading_sharp bacteria_assembly_summary.01.txt \
                                      bacteria_assembly_summary.02.txt
assembly_summary_complete_only        bacteria_assembly_summary.02.txt \
                                      bacteria_assembly_summary.03.txt
assembly_summary_representative_only  bacteria_assembly_summary.03.txt \
                                      bacteria_assembly_summary.04.txt
assembly_summary_drop_duplicates      bacteria_assembly_summary.04.txt \
                                      bacteria_assembly_summary.05.txt
assembly_summary_shuffle              bacteria_assembly_summary.05.txt \
                                      bacteria_assembly_summary.06.txt
assembly_summary_first_entries_only   bacteria_assembly_summary.06.txt \
                                      bacteria_assembly_summary.07.txt 980


# It makes sure we have exactly the same datasets
# sha256sum --check manifest.sha256
