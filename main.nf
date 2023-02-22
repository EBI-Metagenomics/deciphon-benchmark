#!/usr/bin/env nextflow

nextflow.enable.dsl=2

PRJDIR       = "$workflow.projectDir"
OUTDIR       = "$workflow.launchDir/$params.project_name"
DATADIR      = "$params.data_dir"
CACHEDIR     = "$params.cache_dir"
CLANID_REGEX = "$params.select_hmm_by_clan_id"
PFAM_A       = "$DATADIR/Pfam-A.hmm"
PFAM_C       = "$DATADIR/Pfam-C.sto"

println
println "  Project name  $params.project_name"
println "  Output dir    $OUTDIR"
println "  Work dir      $workflow.workDir"
println "  Project dir   $PRJDIR"
println "  Command line  $workflow.commandLine"
println

x = file("$PRJDIR/custom.config", checkIfExists: true)
x.copyTo("$OUTDIR/custom.config")

y = file("$PRJDIR/report.config", checkIfExists: true)
y.copyTo("$OUTDIR/report.config")

def domain_of(x) { "$x.parent.name" }
def accession_of(x) { "$x.name" }
def key_of(x) { domain_of(x) + "/" + accession_of(x) }
def faa_of(x) { file("$x/translated_cds.faa") }
def fna_of(x) { file("$x/cds_from_genomic.fna") }

ch = Channel.fromPath(DATADIR)
            .map{it.listFiles()}.flatten().filter{it.isDirectory()}
            .map{it.listFiles()}.flatten().filter{it.isDirectory()}
            .filter{it.getName() =~ /GCF_.*/ }.first()
            .multiMap{hmmer:deciphon:it}

workflow {
  clan_file = create_clan_csv(PFAM_C)
  hmm_file = select_hmm_by_clan_id(PFAM_A, clan_file, CLANID_REGEX)

  hmmdb = hmmpress(hmm_file).collect()
  hmmscan(hmmdb, ch.hmmer.map{[key_of(it), faa_of(it)]})
}

process create_clan_csv {
  publishDir "$OUTDIR", mode:"copy"

  input:
    path clan_sto

  output:
    path "clan.csv"

  "create_clan_csv.py ${clan_sto} clan.csv"
}

process select_hmm_by_clan_id {
  memory "16 GB"
  publishDir "$OUTDIR", mode:"copy"

  input:
    path hmm_file
    path clan_file
    val clan_id_regex

  output:
    path "db.hmm"

  "select_hmm_by_clan_id.py ${hmm_file} ${clan_file} db.hmm '${clan_id_regex}'"
}

process hmmpress {
  input:
    path hmm_file

  output:
    path "${hmm_file}*", includeInputs: true

  "hmmpress $hmm_file"
}

process hmmscan {
  publishDir "$OUTDIR/$key", mode:"copy"
  cpus 2

  input:
    path hmmdb
    tuple(val(key), path(fasta))

  output:
    tuple(val(key), path("*.txt"))

  "hmmscan --noali --cut_ga -o output.txt --tblout tbl.txt --domtblout domtbl.txt --pfamtblout pfamtbl.txt *.hmm $fasta"
}

//process dcpscan {
//
//}
// 
// process iseq_scan {
//     clusterOptions "-g $groupRoot/iseq_scan -R 'rusage[scratch=${task.attempt * 5120}]'"
//     errorStrategy "retry"
//     maxRetries 4
//     memory { 6.GB * task.attempt }
//     publishDir params.publish, mode:"copy", saveAs: { name -> "${acc}/chunks/$name" }
//     scratch true
//     stageInMode "copy"
// 
//     input:
//     tuple val(acc), path(nucl), path(dbspace) from cds_nucl_db_split_ch
// 
//     output:
//     tuple val(acc), path("output.*.gff") into iseq_output_split_ch
//     tuple val(acc), path("oamino.*.fasta") into iseq_oamino_split_ch
//     tuple val(acc), path("ocodon.*.fasta") into iseq_ocodon_split_ch
// 
//     script:
//     chunk = nucl.name.toString().tokenize('.')[-2]
//     """
//     hmmfile=\$(echo *.hmm)
//     if [ -s \$hmmfile ]
//     then
//         iseq pscan3 \$hmmfile $nucl --hit-prefix chunk_${chunk}_item\
//             --output output.${chunk}.gff --oamino oamino.${chunk}.fasta\
//             --ocodon ocodon.${chunk}.fasta\
//             --no-cut-ga --quiet
//     else
//         echo "##gff-version 3" > output.${chunk}.gff
//         touch oamino.${chunk}.fasta
//         touch ocodon.${chunk}.fasta
//     fi
//     """
// }
// 
// iseq_output_split_ch
//     .collectFile(keepHeader:true, skip:1)
//     .map { ["output.gff", it] }
//     .set { iseq_output_ch }
// 
// iseq_oamino_split_ch
//     .collectFile()
//     .map { ["oamino.fasta", it] }
//     .set { iseq_oamino_ch }
// 
// iseq_ocodon_split_ch
//     .collectFile()
//     .map { ["ocodon.fasta", it] }
//     .set { iseq_ocodon_ch }
// 
// iseq_output_ch
//     .mix(iseq_oamino_ch, iseq_ocodon_ch)
//     .set { iseq_results_ch }
// 
// process save_output {
//     clusterOptions "-g $groupRoot/save_output"
//     publishDir params.publish, mode:"copy", saveAs: { name -> "${acc}/${name}" }, overwrite: true
// 
//     input:
//     tuple val(name), path(acc) from iseq_results_ch
// 
//     output:
//     path(name)
// 
//     script:
//     """
//     mv $acc $name
//     """
// }
