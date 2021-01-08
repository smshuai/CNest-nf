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
      --help          [flag] Show help messages

    """.stripIndent()
}

// Show help message
if (params.help) exit 0, helpMessage()

/*
================================================================================
                                Set parameters
================================================================================
*/

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

if (params.part == 1) {
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
    publishDir "results/", mode: "copy", pattern: "${params.project}/index*"
    echo true

    input: 
    file(bed) from ch_bed

    output: 
    file ("${params.project}") into ch_proj
    path "${params.project}/index_tab.txt" into ch_index_tab
    path "${params.project}/index.txt" into ch_index
    path "${params.project}/index.bed" into ch_index_bed

    script:
    """
    cnest.py step1 --project ${params.project} --bed ${bed}
    """
  }

  process step2 {
    tag "id:${name}-file:${file_path}-index:${index_path}"
    publishDir "results/", mode: "copy"
    errorStrategy 'ignore'
    echo true

    input:
    set val(name), file(file_path), file(index_path) from ch_files_sets
    file("genome.fa") from ch_ref
    file(project) from ch_proj

    output:
    path "${params.project}/bin/$name" into ch_bin

    script:
    if (params.test)
      """
      cnest.py --debug step2 --project ${params.project} --sample ${name} --input ${file_path} --fasta genome.fa --fast
      """
    else
      """
      cnest.py step2 --project ${params.project} --sample ${name} --input ${file_path} --fasta genome.fa --fast
      """
  }
}

if (params.part == 2) {
  process step3 {
  echo true
  publishDir "results/", mode: "copy"

  input:
  path bin_dir from ch_bin
  path index from ch_index

  output:
  path "gender_qc.txt" into ch_gender_qc
  path "gender_classification.txt" into ch_gender_file
  path "mean_coverage.txt" into ch_cov_file

  script:
  """
    cnest.py step3 \
    --indextab $index \
    --bindir $bin_dir \
    --qc gender_qc.txt \
    --gender gender_classification.txt \
    --cov mean_coverage.txt
  """
  }
}

if (params.part == 3) {
  process step4 {
  tag "${sample_name}"
  echo true
  publishDir "results/", mode: "copy"
  memory { 2.GB * params.batch / 100 }

  input:
  path bin_dir from ch_bin
  path index from ch_index
  path gender from ch_gender
  val sample_name from ch_sample_names

  output:
  path "${params.project}/cor/$sample_name" into ch_cor
  path "${params.project}/logr/$sample_name" into ch_logr
  path "${params.project}/rbin/$sample_name" into ch_rbin

  script:
  """
    echo "Processing sample $sample_name"
    mkdir -p ${params.project}/cor ${params.project}/logr ${params.project}/rbin
    cnest.py step4 \
      --bindir $bin_dir \
      --indextab $index \
      --gender $gender \
      --sample $sample_name \
      --batch ${params.batch} \
      --cordir ${params.project}/cor \
      --logrdir ${params.project}/logr \
      --rbindir ${params.project}/rbin
  """
  }
}