#!/usr/bin/env nextflow

/*
Part2 is used to run step3 - gender classification (all samples together). QC is required after part2.
*/

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

process step3 {
  tag "${params.project}"
  echo true
  publishDir "results/", mode: "copy"

  input:
  val flag from ch_done_step2.collect()
  path project from ch_proj2.first()
  
  output:
  path "${params.project}" into ch_proj3

  script:
  """
    ls -lLR
    cnest.py step3 --project ${params.project}
  """
}