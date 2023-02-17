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
  tail -n +2 ${domain}_assembly_summary.01.txt | grep "Complete Genome" | grep "representative genome" >> ${domain}_assembly_summary.02.txt

  # Lets filter out duplicated rows by taxid and get the latest release
  TAB=$(printf '\t')
  head -n 1 ${domain}_assembly_summary.02.txt > ${domain}_assembly_summary.03.txt
  tail -n +2 ${domain}_assembly_summary.02.txt | sort -t "$TAB" -srk15 | sort -t "$TAB" -unk6 >> ${domain}_assembly_summary.03.txt
}

# Setup the assembly summaries for the following domains
for domain in archaea bacteria
do
  download_assembly_summary $domain
  remove_duplicates $domain
done

function fetch_genbank_catalog()
{
  local db=$1
  url=ftp://ftp.ncbi.nlm.nih.gov/genbank/catalog
  version=253

  # The DNA sequence for Porcine circovirus type 2 strain MLP-22
  # is 1726 base pairs long.
  curl -s $url/gb${version}.catalog.${db}.txt.gz \
    | gunzip -c \
    | cut -d$'\t' -f2,4,5,6,7 \
    | grep $'\\(\tRNA\t\\|\tDNA\t\\)' \
    | grep --invert-match $'\tNoTaxID' \
    | awk -F '\t' '{ if ($3 >= 1726) { print } }'
}


# Setup the genbank catalog
exec 3>genbank.catalog.tsv
printf "Version\tMolType\tBasePairs\tOrganism\tTaxID\n" >&3
fetch_genbank_catalog gss >&3
fetch_genbank_catalog other >&3
exec 3>&-

# It makes sure we have exactly the same datasets
sha256sum --check manifest.sha256
