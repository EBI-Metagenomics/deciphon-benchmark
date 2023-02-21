#!/usr/bin/env nextflow

nextflow.enable.dsl=2

println " "
println "  Project name  $params.project_name"
println "  Output dir    $params.output_dir"
println "  Launch dir    $workflow.launchDir"
println "  Work dir      $workflow.workDir"
println "  Project dir   $workflow.projectDir"
println "  Command line  $workflow.commandLine"
println " "

x = file("$baseDir/custom.config", checkIfExists: true)
x.copyTo("$params.output_dir/$params.project_name/custom.config")

y = file("$baseDir/report.config", checkIfExists: true)
y.copyTo("$params.output_dir/$params.project_name/report.config")

workflow {
  clan_file = create_clan_csv(params.clan_file)
  clan_id_regex = params.select_hmm_by_clan_id
  hmm_file = select_hmm_by_clan_id(params.hmm_file, clan_file, clan_id_regex)
  hmmdb = hmmpress(hmm_file).collect()
  def faa_ch = Channel.fromPath("/hps/nobackup/rdf/metagenomics/research-team/horta/data/archaea/GCF_000144915.1_ASM14491v1/translated_cds.faa")
  def aa_ch = faa_ch.map { tuple("$it.parent.parent.name", "$it.parent.name", it) }
  /* hmmscan(hmmdb, aa_ch.map()) | publish */
}

//def hmm_file_ch = Channel.fromPath(params.hmm_file)
//def clan_file_ch = Channel.fromPath(params.clan_file)
/* scriptDir = file("$projectDir/script") */
/* decyDir = file("$projectDir/decy") */
/* groupRoot = "/horta/$workflow.runName" */

//Channel
//  .fromList(params.domains.tokenize(","))
//  .set { domain_specs_ch }

process publish_file {
  publishDir "$output_dir/$filepath.getName()", mode:"copy"

  input:
    path dstdir
    path infile

  output:
    path outfile

  script:
  outfile = 
}

process create_clan_csv {
  publishDir "${params.output_dir}/${params.project_name}", mode:"copy"
  storeDir "/hps/nobackup/rdf/metagenomics/research-team/horta/cache"

  input:
    path clan_sto

  output:
    path "clan.csv"

  "create_clan_csv.py ${clan_sto} clan.csv"
}

process select_hmm_by_clan_id {
  memory "16 GB"
  publishDir "${params.output_dir}/${params.project_name}", mode:"copy"
  storeDir "/hps/nobackup/rdf/metagenomics/research-team/horta/cache"

  input:
    path hmm_file
    path clan_file
    val clan_id_regex

  output:
    path "db.hmm"

  "select_hmm_by_clan_id.py ${hmm_file} ${clan_file} db.hmm '${clan_id_regex}'"
}

process hmmpress {
  storeDir "/hps/nobackup/rdf/metagenomics/research-team/horta/cache"

  input:
    path hmm_file

  output:
    path "${hmm_file}*" ,  includeInputs: true

  "hmmpress $hmm_file"
}

process hmmscan {
  input:
    path hmmdb
    path fasta_file

  output:
    path "domtbl.txt"

  "hmmscan -o /dev/null --noali --cut_ga --domtblout domtbl.txt --cpu 1 *.hmm $fasta_file"
}

//process hmmscan {
//    publishDir "${params.output_dir}/${params.project_name}", mode:"copy", saveAs: { name -> "${domain}/${accession}/domtbl.txt" }
//
//    input:
//      path hmmdb
//      path fasta_file
//
//    output:
//      path "domtbl.txt"
//
//    script:
//    domain=fasta_file.getParent().getParent().getName()
//    accession=fasta_file.getParent().getName()
//    "hmmscan -o /dev/null --noali --cut_ga --domtblout domtbl.txt --cpu 1 *.hmm $fasta_file"
//}

// process hmmscan {
//     publishDir params.publish, mode:"copy", saveAs: { name -> "${acc}/$name" }
//     scratch true
//     stageInMode "copy"
// 
//     input:
//     path hmmdb from hmmdb_ch.collect()
//     tuple val(acc), path(amino) from cds_amino_ch
// 
//     output:
//     tuple val(acc), path("domtblout.txt") into hmmscan_output_ch
// 
//     script:
//     "hmmscan -o /dev/null --noali --cut_ga --domtblout domtblout.txt --cpu 1 \$hmmfile $amino"
// }


// process download_genbank_catalog {
//     clusterOptions "-g $groupRoot/download_genbank_catalog"
//     storeDir "$params.storage/genbank"
// 
//     input:
//     val db from Channel.fromList(["gss", "other"])
// 
//     output:
//     path "gb238.catalog.${db}.tsv" into gb_catalog_ch1
// 
//     script:
//     """
//     $scriptDir/download_genbank_catalog.sh $db gb238.catalog.${db}.tsv
//     """
// }
// 
// process merge_genbank_catalogs {
//     clusterOptions "-g $groupRoot/merge_genbank_catalogs"
//     storeDir "$params.storage/genbank"
// 
//     input:
//     path "*" from gb_catalog_ch1.collect()
// 
//     output:
//     path "gb238.catalog.all.tsv" into gb_catalog_ch2
// 
//     script:
//     """
//     $scriptDir/merge_genbank_catalog.sh *.tsv gb238.catalog.all.tsv
//     """
// }
// 
// process unique_genbank_organisms {
//     clusterOptions "-g $groupRoot/unique_genbank_organisms"
//     memory "30 GB"
//     storeDir "$params.storage/genbank"
// 
//     input:
//     path "gb238.catalog.all.tsv" from gb_catalog_ch2
// 
//     output:
//     path "gb238.catalog.tsv" into gb_catalog_ch3
// 
//     script:
//     """
//     $scriptDir/unique_genbank_catalog.py gb238.catalog.all.tsv gb238.catalog.tsv
//     """
// }
// 
// process sample_accessions {
//     clusterOptions "-g $groupRoot/sample_accessions"
//     errorStrategy "retry"
//     maxForks 1
//     maxRetries 2
//     storeDir "$params.storage/genbank"
// 
//     input:
//     path "gb238.catalog.tsv" from gb_catalog_ch3
//     tuple val(domain), val(nsamples), path(domaintxt) from domain_files_spec_ch
// 
//     output:
//     path "${domain}_${nsamples}_accessions" into acc_file_ch
// 
//     script:
//     """
//     $scriptDir/sample_accessions.py gb238.catalog.tsv $domaintxt ${domain}_${nsamples}_accessions $nsamples $params.seed
//     """
// }
// 
// acc_file_ch
//     .splitText() { it.trim() }
//     .filter ( ~"$params.filterAcc" )
//     .into { acc_ch1; acc_ch2 }
// 
// filterClanHash = params.filterClan.digest('SHA-256')
// filterClanHash = filterClanHash[0..3] + filterClanHash[4..7]
// 
// 
// process download_genbank_gb {
//     clusterOptions "-g $groupRoot/download_genbank_gb"
//     errorStrategy "retry"
//     maxForks 1
//     maxRetries 2
//     publishDir params.publish, mode:"copy", saveAs: { name -> "${acc}/$name" }
//     storeDir "$params.storage/genbank"
// 
//     input:
//     val acc from acc_ch1
// 
//     output:
//     tuple val(acc), path("${acc}.gb") into genbank_gb_ch
// 
//     script:
//     """
//     $scriptDir/download_genbank.py $acc gb ${acc}.gb
//     """
// }
// 
// process download_genbank_fasta {
//     clusterOptions "-g $groupRoot/download_genbank_fasta"
//     errorStrategy "retry"
//     maxForks 1
//     maxRetries 2
//     publishDir params.publish, mode:"copy", saveAs: { name -> "${acc}/$name" }
//     storeDir "$params.storage/genbank"
// 
//     input:
//     val acc from acc_ch2
// 
//     output:
//     tuple val(acc), path("${acc}.fasta") into genbank_fasta_ch
// 
//     script:
//     """
//     $scriptDir/download_genbank.py $acc fasta ${acc}.fasta
//     """
// }
// 
// process extract_cds {
//     clusterOptions "-g $groupRoot/extract_cds"
//     publishDir params.publish, mode:"copy", saveAs: { name -> "${acc}/$name" }
// 
//     input:
//     tuple val(acc), path(gb) from genbank_gb_ch
// 
//     output:
//     tuple val(acc), path("cds_amino.fasta") into cds_amino_ch
//     tuple val(acc), path("cds_nucl.fasta") into cds_nucl_ch
// 
//     script:
//     """
//     $scriptDir/extract_cds.py $gb cds_amino.fasta cds_nucl.fasta
//     if [[ "$params.downsampleCDS" != "0" ]];
//     then
//        $scriptDir/downsample_fasta.py cds_amino.fasta .cds_amino.fasta $params.downsampleCDS
//        mv .cds_amino.fasta cds_amino.fasta
//        $scriptDir/downsample_fasta.py cds_nucl.fasta .cds_nucl.fasta $params.downsampleCDS
//        mv .cds_nucl.fasta cds_nucl.fasta
//     fi
//     """
// }
// 
// process hmmscan {
//     clusterOptions "-g $groupRoot/hmmscan -R 'rusage[scratch=5120]'"
//     cpus 4
//     memory "8 GB"
//     publishDir params.publish, mode:"copy", saveAs: { name -> "${acc}/$name" }
//     scratch true
//     stageInMode "copy"
// 
//     input:
//     path hmmdb from hmmdb_ch.collect()
//     tuple val(acc), path(amino) from cds_amino_ch
// 
//     output:
//     tuple val(acc), path("domtblout.txt") into hmmscan_output_ch
// 
//     script:
//     """
//     hmmfile=\$(echo *.hmm)
//     if [ -s \$hmmfile ]
//     then
//         hmmscan -o /dev/null --noali --cut_ga --domtblout domtblout.txt --cpu ${task.cpus} \$hmmfile $amino
//     else
//         touch domtblout.txt
//     fi
//     """
// }
// 
// process create_solution_space {
//     clusterOptions "-g $groupRoot/create_solution_space -R 'rusage[scratch=5120]'"
//     publishDir params.publish, mode:"copy", saveAs: { name -> "${acc}/$name" }
// 
//     input:
//     path hmmdb from hmmdb_ch.collect()
//     tuple val(acc), path("domtblout.txt") from hmmscan_output_ch
// 
//     output:
//     tuple val(acc), path("*.hmm*") into dbspace_ch
// 
//     script:
//     """
//     hmmfile=\$(echo *.hmm)
//     if [ -s \$hmmfile ]
//     then
//         $scriptDir/create_solution_space.py domtblout.txt \$hmmfile accspace.txt dbspace.hmm $params.seed
//         if [ -s dbspace.hmm ]
//         then
//             hmmfetch --index dbspace.hmm
//         fi
//     else
//         touch dbspace.hmm
//     fi
//     """
// }
// 
// cds_nucl_ch
//     .join(dbspace_ch)
//     .splitFasta(by:params.chunkSize, file:true, elem:1)
//     .set { cds_nucl_db_split_ch }
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
