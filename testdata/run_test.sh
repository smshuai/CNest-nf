#!/usr/bin/env bash
ref_path="/Users/shimin/test/ref" # Change this to your genome reference path
nextflow run ../main.nf --project test_proj --design design.csv --bed ./test.bed --ref $ref_path 
