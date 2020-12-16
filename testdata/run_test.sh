#!/usr/bin/env bash
ref_path="/Users/shimin/test/ref" # Change this to your genome reference path
nextflow run ../main.nf --test true --project test_proj --design design.csv  --ref $ref_path 
