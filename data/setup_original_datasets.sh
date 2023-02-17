#!/bin/bash
set -e

curl ftp://ftp.ebi.ac.uk/pub/databases/Pfam/releases/Pfam35.0/Pfam-A.hmm.gz | gunzip -d > Pfam35.0-A.hmm
curl ftp://ftp.ebi.ac.uk/pub/databases/Pfam/releases/Pfam35.0/Pfam-C.gz | gunzip -d > Pfam35.0-C.sto

function download_assembly_summary()
{
  local domain=$1
  curl ftp://ftp.ncbi.nlm.nih.gov/genomes/refseq/$domain/assembly_summary.txt > ${domain}_assembly_summary.01.txt
}

function remove_duplicates()
{
  local domain=$1

  # Remove leading #
  head -n 2 ${domain}_assembly_summary.01.txt | tail -n 1 | sed 's/# //' > ${domain}_assembly_summary.02.txt
  # I want complete genomes only
  tail -n +2 ${domain}_assembly_summary.01.txt | grep "Complete Genome" >> ${domain}_assembly_summary.02.txt

  # Lets filter out duplicated rows by taxid and get the latest release
  TAB=$(printf '\t')
  head -n 1 ${domain}_assembly_summary.02.txt > ${domain}_assembly_summary.03.txt
  tail -n +2 ${domain}_assembly_summary.02.txt | sort -t "$TAB" -srk15 | sort -t "$TAB" -unk6 >> ${domain}_assembly_summary.03.txt
}

for domain in archaea bacteria
do
  download_assembly_summary $domain
  remove_duplicates $domain
done

# It makes sure we have exactly the same datasets
sha256sum --check manifest.sha256
