#!/usr/bin/env bash
ref_path=$1 # Change this to your genome reference path
ref_path=`realpath $ref_path`
echo "REF_PATH=$ref_path"

if [[ -d results ]]
then
  rm -r ./results/
fi

if [[ -d work ]]
then
  rm -r ./work/
fi

nextflow run ../main.nf --project test_proj --design design.csv  --ref $ref_path 
