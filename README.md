# Run with SLURM

```
git clone https://github.com/smshuai/CNest-nf
cd CNest-nf
nextflow run -profile slurm part1.nf --project test_proj --design design.csv  --ref $ref_path --bed $bed_path
```