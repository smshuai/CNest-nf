#!/usr/bin/env nextflow

// Re-usable componext for adding a helpful help message in our Nextflow script
def helpMessage() {
    log.info"""
    Usage:
    The typical command for running the pipeline is as follows:
    nextflow run main.nf --project ukb --bed index.bed --sample test --cram test.cram --ref ./ref/
    Mandatory arguments:
      --fastq_list                  [file] A comma seperated file with all the fastq files locations
                                    A header is expected, and 3 columns that define the following:
                                    - accession number, identifier for fastq file pair
                                    - link (ftp, https) to the fastq 1
                                    - link (ftp, https) to the fastq 2
                                    
                                    A file could look like this:
                                    accession,fastq_1,fastq_2
                                    ERR908503,ftp://ERR908503_1.fastq.gz,ftp://ERR908503_2.fastq.gz

    """.stripIndent()
}

if (params.bed) ch_bed = Channel.value(file(params.bed))
if (params.cram) {
  ch_cram = Channel.value(file(params.cram))
  ch_crai = Channel.value(file(params.cram + '.crai'))
  }
if (params.ref) ch_ref = Channel.value(file(params.ref))

// if (params.makeBed) {
//   params.chromSize = Channel.value(file("$baseDir/data/hg38.chrom.sizes"))
//   params.blackList = Channel.value(file("$baseDir/data/hg38.ENCODE.blacklist.ENCFF356LFX.bed"))
//   params.gapList = Channel.value(file("$baseDir/data/hg38.gaps"))
// }

// Generate reference file
// process step0 {
//   tag "step0"
//   echo true
//   publishDir "results", mode: 'copy'

//   input:
//   path chromSize from params.chromSize
//   path blackList from params.blackList
//   path gapList from params.gapList

//   output:
//   path "index.bed" into ch_bed

//   """
//   # make genome wide baits
//   bedtools makewindows -g ${chromSize} -w 1000 > tmp1.bed
//   # remove black list and gap regions
//   # If the bait has >0 bp in blacklist or gap regions, the whole bait is removed
//   bedtools subtract -a tmp1.bed -b ${blackList} -A > tmp2.bed
//   bedtools subtract -a tmp2.bed -b ${gapList} -A > index.bed 
//   """
// }

ch_bedgz = Channel.value(file("$baseDir/data/hg38.1kb.baits.bed.gz"))
process step0 {
  tag "${sample}"
  echo true

  input:
  file(bedgz) from ch_bedgz

  output:
  file("hg38.1kb.baits.bed") into ch_bed

  script:
  """
  gzip -d ${bedgz}
  """
}

// Step1 create work directory
process step1 {
  tag "${sample}"
  echo true

  input: 
  file(bed) from ch_bed

  output: 
  file ("${params.project}") into ch_project

  script:
  """
  mv ./${bed} /input_location/
  cnest.py step1 --project ${params.project} --bed ${bed}
  mv /output_location/${params.project} .
  """
}

// Analyze each CRAM
process step2 {
  tag "${sample}"
  echo true
  publishDir "results", mode: 'copy'


  input: 
  file(project) from ch_project
  file(cram) from ch_cram
  file(crai) from ch_crai
  file("reference") from ch_ref

  output: 
  file ("${params.project}") into ch_project2


  script:
  """
    export REF_PATH="./reference/%2s/%2s/%s"
    mv ${cram} ${crai}  /input_location/
    mv ${params.project} /output_location/
    cnest.py step2 --project ${params.project} --sample ${params.sample} --input ${cram}
    mv /output_location/${params.project} .
  """
}