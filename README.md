# Run with LSF/SLURM

```bash
git clone https://github.com/smshuai/CNest-nf
cd CNest-nf

# module load singularity/3.5.0
# ref_path=/hps/research1/birney/users/shimin/reference/UKBB_FE/genome.fa
# bed_path=/hps/research1/birney/users/shimin/CNest/index_files/ukbb_wes_index.bed

# set this to slurm for SLURM HPCs
executor=lsf

# Part 1
nextflow run -with-report -profile $executor part1.nf \
    --project test_proj \
    --design design.csv \
    --ref $ref_path \
    --bed $bed_path

# Part 2
nextflow run -with-report -profile $executor part2.nf \
    --binDir ./results/test_proj/bin/ \
    --index ./results/test_proj/index_tab.txt

# ! Do QC here before continue

# Part 3
nextflow run -with-report -profile $executor part3.nf --project test_proj \
    --binDir ./results/test_proj/bin/ \
    --index ./results/test_proj/index_tab.txt \
    --gender ./results/gender_classification.txt \
    --batch 100

# Part 4
nextflow run -with-report -profile $executor smshuai/CNest-nf \
    --part 4 \
    --project test_proj \
    --rbindir ./results/test_proj/rbin/ \
    --cordir ./results/test_proj/cov/ \
    --index ./results/test_proj/index_tab.txt \
    --gender ./results/gender_classification.txt \
    --cov ./results/mean_coverage.txt

```