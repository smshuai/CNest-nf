#!/usr/bin/env nextflow

// Re-usable componext for adding a helpful help message in our Nextflow script
def helpMessage() {
    log.info"""
    Usage:
    The typical command for running the pipeline is as follows:
    nextflow run main.nf --project test --design design_file.csv --ref ./ref/
    Mandatory arguments:
      --project       [string] Name of the project
      --design        [file] A csv file with sample name, CRAM path and CRAI path
                      A file could look like this:
                      name,cram,crai
                      test,test.cram,test.cram.crai
      --ref           [file] Path for the genome FASTA. Used for CRAM decoding.
    Optional arguments:
      --test          [flag] test mode

    """.stripIndent()
}

if (params.bed) ch_bed = Channel.value(file(params.bed))
if (params.ref) ch_ref = Channel.value(file(params.ref))
if (params.design) {
  Channel.fromPath(params.design)
    .splitCsv(sep: ',', skip: 1)
    .map { name, file_path, index_path -> [ name, file(file_path), file(index_path) ] }
    .set { ch_files_sets }
}
// In test mode, a max of 10 samples are used
if (params.test) {
  ch_files_sets = ch_files_sets.take(10)
}

ch_bedgz = Channel.value(file("$baseDir/data/hg38.1kb.baits.bed.gz"))
process step0 {
  tag "${params.project}"
  echo true

  input:
  file(bedgz) from ch_bedgz

  output:
  file("hg38.1kb.baits.bed") into ch_bed

  when:
  !params.bed

  script:
  if (params.test)
    """
    gzip -cd ${bedgz} | head -1000 > "hg38.1kb.baits.bed"
    """
  else
    """
    gzip -cd ${bedgz} > "hg38.1kb.baits.bed"
    """
}

// Step1 create work directory
process step1 {
  tag "${params.project}"
  echo true

  input: 
  file(bed) from ch_bed

  output: 
  file ("${params.project}") into ch_proj1
  
  script:
  """
  cnest.py step1 --project ${params.project} --bed ${bed}
  """
}

process step2 {
  tag "id:${name}-file:${file_path}-index:${index_path}"
  publishDir "results/", mode: "copy"
  errorStrategy = { task.exitStatus in [403, 401] ? 'ignore' : 'terminate' }
  echo true
  maxForks 70

  input:
  set val(name), file(file_path), file(index_path) from ch_files_sets
  file("genome.fa") from ch_ref
  file(project) from ch_proj1

  output:
  path "${params.project}/bin/$name" into ch_bin
  // path "${params.project}" into ch_proj2
  // val true into ch_done_step2

  script:
  if (params.test)
    """
    ls -lLR
    cnest.py --debug step2 --project ${params.project} --sample ${name} --input ${file_path} --fasta genome.fa --fast
    df -h
    """
  else
    """
    cnest.py step2 --project ${params.project} --sample ${name} --input ${file_path} --fasta genome.fa --fast
    ls -lLR
    df -h
    """
}

// process step3 {
//   tag "${params.project}"
//   echo true
//   publishDir "results/", mode: "copy"

//   input:
//   val flag from ch_done_step2.collect()
//   path project from ch_proj2.first()
  
//   output:
//   path "${params.project}" into ch_proj3

//   script:
//   """
//     ls -lLR
//     cnest.py step3 --project ${params.project}
//   """
// }