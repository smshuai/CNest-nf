# Run with LSF

```
git clone https://github.com/smshuai/CNest-nf
cd CNest-nf
# module load singularity/3.5.0
# ref_path=/hps/research1/birney/users/shimin/reference/UKBB_FE/genome.fa
# bed_path=/hps/research1/birney/users/shimin/CNest/index_files/ukbb_wes_index.bed
nextflow run -profile lsf part1.nf --project test_proj --design design.csv --ref $ref_path --bed $bed_path

```