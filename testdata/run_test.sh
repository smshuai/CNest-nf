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

nextflow run ../part1.nf --project test_proj --design design.csv  --ref $ref_path 

nextflow run ../part2.nf --binDir ./results/test_proj/bin --index ./results/test_proj/index_tab.txt

nextflow run ../part3.nf --project test_proj --binDir ./results/test_proj/bin --index ./results/test_proj/index_tab.txt --gender ./results/gender_classification.txt
