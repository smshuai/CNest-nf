#!/usr/bin/env bash
ref_path=$1 # Change this to your genome reference path
ref_path=`realpath $ref_path`
echo "REF_PATH=$ref_path"
nextflow run ../main.nf --test true --project test_proj --design design.csv  --ref $ref_path 
