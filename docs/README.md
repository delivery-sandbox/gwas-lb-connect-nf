# drug-discovery-protocol-orchestrator-nf <!-- omit in toc -->
- [Pipeline description](#pipeline-description)
- [Input](#input)
- [Output](#output)
  - [Step 1](#step-1)
    - [OMOP to phenofile](#omop-to-phenofile)
    - [GWAS](#gwas)
    - [Harmonisation](#harmonisation)
  - [Step 2](#step-2)
  - [Step 3](#step-3)
  - [Step 4](#step-4)
  - [Step 5](#step-5)
    - [Finemapping](#finemapping)
    - [Cheers](#cheers)
  - [Step 6](#step-6)
    - [GSEA](#gsea)
    - [Drug2ways](#drug2ways)
- [Usage](#usage)
    - [Profiles](#profiles)
- [Options](#options)
  - [Mandatory options](#mandatory-options)
  - [CloudOS options](#cloudos-options)
  - [Step 1a](#step-1a)
  - [Step 1b](#step-1b)
  - [Step 1c](#step-1c)
  - [Step 2](#step-2-1)
  - [Step 3](#step-3-1)
  - [Step 4](#step-4-1)
  - [Step 5](#step-5-1)
    - [Liftover](#liftover)
    - [Finemapping](#finemapping-1)
    - [Cheers (tissue enrichment)](#cheers-tissue-enrichment)
  - [Step 6](#step-6-1)
    - [Gene set enrichement](#gene-set-enrichement)
    - [Drug2ways](#drug2ways-1)

<!-- This README.md is the single page user documentation for this pipeline. -->

## Pipeline description

Pipeline to orchestrate different Drug Discovery modules.

## Input

The input is a set of boolean flags that activate certain steps of the pipeline.

- **`--step_1`**: activates step 1 in order to identify genetic associations. Default: `true`.

- **`--step_2`**: activates step 2 in order to identify candidate genes. Default: `false`.

- **`--step_3`**: activates step 3 in order to identify causal genes and pathways. Default: `false`.

- **`--step_4`**: activates step 4 in order to identify causal proteins. Default: `false`.

- **`--step_5`**: activates step 5 in order to identify the mechanism of action. Default: `false`.

- **`--step_6`**: activates step 6 in order to identify candidate drugs. Default: `false`.

## Output

### Step 1

#### OMOP to phenofile

<details>
<summary>Expected output:</summary>

```
$ tree -fh results/
[ 114]  results
├── [255K]  results/flowchart.png
├── [210K]  results/machine-resources-manager-1.0.15.zip
├── [ 49M]  results/Miniconda_Install.sh
└── [  59]  results/results
    ├── [ 136]  results/results/cohorts
    │   ├── [ 102]  results/results/cohorts/cohort_counts_full.csv
    │   ├── [  88]  results/results/cohorts/linked_cohort_counts.csv
    │   ├── [  87]  results/results/cohorts/matched_cohort_counts.csv
    │   └── [  51]  results/results/cohorts/sql
    │       ├── [ 13K]  results/results/cohorts/sql/cohort_5grtwPM3hy.sql
    │       └── [ 15K]  results/results/cohorts/sql/query.sql
    ├── [  91]  results/results/phenofile
    │   ├── [ 89M]  results/results/phenofile/linked_phenofile.phe
    │   ├── [4.7M]  results/results/phenofile/matched_linked_phenofile.phe
    │   └── [ 10M]  results/results/phenofile/phenofile.phe
    └── [  89]  results/results/pipeline_info
        ├── [1.2K]  results/results/pipeline_info/execution_trace_2023-09-04_09-16-12.txt
        └── [ 976]  results/results/pipeline_info/pipeline_metadata_report.tsv

6 directories, 15 files
```

</details>
<br>

#### GWAS

<details>
<summary>Expected output:</summary>

```
$ tree -fh -L 5 results/
[ 137]  results
├── [418K]  results/flowchart.png
├── [210K]  results/machine-resources-manager-1.0.15.zip
├── [ 49M]  results/Miniconda_Install.sh
└── [ 188]  results/results
    ├── [  36]  results/results/allancs
    │   ├── [ 177]  results/results/allancs/notransform
    │   │   ├── [ 947]  results/results/allancs/notransform/aligned_test_variants.log
    │   │   ├── [2.3M]  results/results/allancs/notransform/aligned_test_variants.pgen
    │   │   ├── [1.4K]  results/results/allancs/notransform/aligned_test_variants.psam
    │   │   ├── [3.1M]  results/results/allancs/notransform/aligned_test_variants.pvar
    │   │   ├── [9.4K]  results/results/allancs/notransform/phenofile.phe
    │   │   └── [ 260]  results/results/allancs/notransform/regenie
    │   │       ├── [ 24K]  results/results/allancs/notransform/regenie/allancs-notransform-regenie_firth.log
    │   │       ├── [ 10M]  results/results/allancs/notransform/regenie/allancs-notransform-regenie_firth_NEW_QUANT_TRAIT.regenie
    │   │       ├── [ 18K]  results/results/allancs/notransform/regenie/allancs-notransform-regenie_step1_1.loco
    │   │       ├── [ 54K]  results/results/allancs/notransform/regenie/allancs-notransform-regenie_step1.log
    │   │       └── [  57]  results/results/allancs/notransform/regenie/allancs-notransform-regenie_step1_pred.list
    │   └── [ 123]  results/results/allancs/pca
    │       ├── [ 500]  results/results/allancs/pca/out.keep.tsv
    │       ├── [  80]  results/results/allancs/pca/pca_results_final.eigenval
    │       ├── [8.8K]  results/results/allancs/pca/pca_results_final.eigenvec
    │       └── [ 256]  results/results/allancs/pca/remove_outliers_0.log
    ├── [8.0K]  results/results/filter_miss
    │   ├── [1.0K]  results/results/filter_miss/quantfamdata.chr10_new_ids_pat_mat_pheno.misHWEfiltered.log
    │   ├── [131K]  results/results/filter_miss/quantfamdata.chr10_new_ids_pat_mat_pheno.misHWEfiltered.pgen
    │   ├── [1.9K]  results/results/filter_miss/quantfamdata.chr10_new_ids_pat_mat_pheno.misHWEfiltered.psam
    │   ├── [131K]  results/results/filter_miss/quantfamdata.chr10_new_ids_pat_mat_pheno.misHWEfiltered.pvar
    │   ├── [1.0K]  results/results/filter_miss/quantfamdata.chr11_new_ids_pat_mat_pheno.misHWEfiltered.log
    │   ├── [131K]  results/results/filter_miss/quantfamdata.chr11_new_ids_pat_mat_pheno.misHWEfiltered.pgen
    │   ├── [1.9K]  results/results/filter_miss/quantfamdata.chr11_new_ids_pat_mat_pheno.misHWEfiltered.psam
    │   ├── [131K]  results/results/filter_miss/quantfamdata.chr11_new_ids_pat_mat_pheno.misHWEfiltered.pvar
    │   ├── [1.0K]  results/results/filter_miss/quantfamdata.chr12_new_ids_pat_mat_pheno.misHWEfiltered.log
    │   ├── [429K]  results/results/filter_miss/quantfamdata.chr12_new_ids_pat_mat_pheno.misHWEfiltered.pgen
    │   ├── [1.9K]  results/results/filter_miss/quantfamdata.chr12_new_ids_pat_mat_pheno.misHWEfiltered.psam
    │   ├── [451K]  results/results/filter_miss/quantfamdata.chr12_new_ids_pat_mat_pheno.misHWEfiltered.pvar
    │   ├── [1.0K]  results/results/filter_miss/quantfamdata.chr13_new_ids_pat_mat_pheno.misHWEfiltered.log
    │   ├── [ 97K]  results/results/filter_miss/quantfamdata.chr13_new_ids_pat_mat_pheno.misHWEfiltered.pgen
    │   ├── [1.9K]  results/results/filter_miss/quantfamdata.chr13_new_ids_pat_mat_pheno.misHWEfiltered.psam
    │   ├── [ 96K]  results/results/filter_miss/quantfamdata.chr13_new_ids_pat_mat_pheno.misHWEfiltered.pvar
    │   ├── [1.0K]  results/results/filter_miss/quantfamdata.chr14_new_ids_pat_mat_pheno.misHWEfiltered.log
    │   ├── [ 89K]  results/results/filter_miss/quantfamdata.chr14_new_ids_pat_mat_pheno.misHWEfiltered.pgen
    │   ├── [1.9K]  results/results/filter_miss/quantfamdata.chr14_new_ids_pat_mat_pheno.misHWEfiltered.psam
    │   ├── [ 88K]  results/results/filter_miss/quantfamdata.chr14_new_ids_pat_mat_pheno.misHWEfiltered.pvar
    │   ├── [1.0K]  results/results/filter_miss/quantfamdata.chr15_new_ids_pat_mat_pheno.misHWEfiltered.log
    │   ├── [ 79K]  results/results/filter_miss/quantfamdata.chr15_new_ids_pat_mat_pheno.misHWEfiltered.pgen
    │   ├── [1.9K]  results/results/filter_miss/quantfamdata.chr15_new_ids_pat_mat_pheno.misHWEfiltered.psam
    │   ├── [ 78K]  results/results/filter_miss/quantfamdata.chr15_new_ids_pat_mat_pheno.misHWEfiltered.pvar
    │   ├── [1.0K]  results/results/filter_miss/quantfamdata.chr16_new_ids_pat_mat_pheno.misHWEfiltered.log
    │   ├── [ 74K]  results/results/filter_miss/quantfamdata.chr16_new_ids_pat_mat_pheno.misHWEfiltered.pgen
    │   ├── [1.9K]  results/results/filter_miss/quantfamdata.chr16_new_ids_pat_mat_pheno.misHWEfiltered.psam
    │   ├── [ 72K]  results/results/filter_miss/quantfamdata.chr16_new_ids_pat_mat_pheno.misHWEfiltered.pvar
    │   ├── [1.0K]  results/results/filter_miss/quantfamdata.chr17_new_ids_pat_mat_pheno.misHWEfiltered.log
    │   ├── [ 77K]  results/results/filter_miss/quantfamdata.chr17_new_ids_pat_mat_pheno.misHWEfiltered.pgen
    │   ├── [1.9K]  results/results/filter_miss/quantfamdata.chr17_new_ids_pat_mat_pheno.misHWEfiltered.psam
    │   ├── [ 75K]  results/results/filter_miss/quantfamdata.chr17_new_ids_pat_mat_pheno.misHWEfiltered.pvar
    │   ├── [1.0K]  results/results/filter_miss/quantfamdata.chr18_new_ids_pat_mat_pheno.misHWEfiltered.log
    │   ├── [ 76K]  results/results/filter_miss/quantfamdata.chr18_new_ids_pat_mat_pheno.misHWEfiltered.pgen
    │   ├── [1.9K]  results/results/filter_miss/quantfamdata.chr18_new_ids_pat_mat_pheno.misHWEfiltered.psam
    │   ├── [ 75K]  results/results/filter_miss/quantfamdata.chr18_new_ids_pat_mat_pheno.misHWEfiltered.pvar
    │   ├── [1.0K]  results/results/filter_miss/quantfamdata.chr19_new_ids_pat_mat_pheno.misHWEfiltered.log
    │   ├── [ 57K]  results/results/filter_miss/quantfamdata.chr19_new_ids_pat_mat_pheno.misHWEfiltered.pgen
    │   ├── [1.9K]  results/results/filter_miss/quantfamdata.chr19_new_ids_pat_mat_pheno.misHWEfiltered.psam
    │   ├── [ 55K]  results/results/filter_miss/quantfamdata.chr19_new_ids_pat_mat_pheno.misHWEfiltered.pvar
    │   ├── [1.0K]  results/results/filter_miss/quantfamdata.chr1_new_ids_pat_mat_pheno.misHWEfiltered.log
    │   ├── [216K]  results/results/filter_miss/quantfamdata.chr1_new_ids_pat_mat_pheno.misHWEfiltered.pgen
    │   ├── [1.9K]  results/results/filter_miss/quantfamdata.chr1_new_ids_pat_mat_pheno.misHWEfiltered.psam
    │   ├── [212K]  results/results/filter_miss/quantfamdata.chr1_new_ids_pat_mat_pheno.misHWEfiltered.pvar
    │   ├── [1.0K]  results/results/filter_miss/quantfamdata.chr20_new_ids_pat_mat_pheno.misHWEfiltered.log
    │   ├── [ 60K]  results/results/filter_miss/quantfamdata.chr20_new_ids_pat_mat_pheno.misHWEfiltered.pgen
    │   ├── [1.9K]  results/results/filter_miss/quantfamdata.chr20_new_ids_pat_mat_pheno.misHWEfiltered.psam
    │   ├── [ 58K]  results/results/filter_miss/quantfamdata.chr20_new_ids_pat_mat_pheno.misHWEfiltered.pvar
    │   ├── [1.0K]  results/results/filter_miss/quantfamdata.chr21_new_ids_pat_mat_pheno.misHWEfiltered.log
    │   ├── [ 35K]  results/results/filter_miss/quantfamdata.chr21_new_ids_pat_mat_pheno.misHWEfiltered.pgen
    │   ├── [1.9K]  results/results/filter_miss/quantfamdata.chr21_new_ids_pat_mat_pheno.misHWEfiltered.psam
    │   ├── [ 34K]  results/results/filter_miss/quantfamdata.chr21_new_ids_pat_mat_pheno.misHWEfiltered.pvar
    │   ├── [1.0K]  results/results/filter_miss/quantfamdata.chr22_new_ids_pat_mat_pheno.misHWEfiltered.log
    │   ├── [ 33K]  results/results/filter_miss/quantfamdata.chr22_new_ids_pat_mat_pheno.misHWEfiltered.pgen
    │   ├── [1.9K]  results/results/filter_miss/quantfamdata.chr22_new_ids_pat_mat_pheno.misHWEfiltered.psam
    │   ├── [ 33K]  results/results/filter_miss/quantfamdata.chr22_new_ids_pat_mat_pheno.misHWEfiltered.pvar
    │   ├── [1.0K]  results/results/filter_miss/quantfamdata.chr2_new_ids_pat_mat_pheno.misHWEfiltered.log
    │   ├── [237K]  results/results/filter_miss/quantfamdata.chr2_new_ids_pat_mat_pheno.misHWEfiltered.pgen
    │   ├── [1.9K]  results/results/filter_miss/quantfamdata.chr2_new_ids_pat_mat_pheno.misHWEfiltered.psam
    │   ├── [231K]  results/results/filter_miss/quantfamdata.chr2_new_ids_pat_mat_pheno.misHWEfiltered.pvar
    │   ├── [1.0K]  results/results/filter_miss/quantfamdata.chr3_new_ids_pat_mat_pheno.misHWEfiltered.log
    │   ├── [198K]  results/results/filter_miss/quantfamdata.chr3_new_ids_pat_mat_pheno.misHWEfiltered.pgen
    │   ├── [1.9K]  results/results/filter_miss/quantfamdata.chr3_new_ids_pat_mat_pheno.misHWEfiltered.psam
    │   ├── [191K]  results/results/filter_miss/quantfamdata.chr3_new_ids_pat_mat_pheno.misHWEfiltered.pvar
    │   ├── [1.0K]  results/results/filter_miss/quantfamdata.chr4_new_ids_pat_mat_pheno.misHWEfiltered.log
    │   ├── [189K]  results/results/filter_miss/quantfamdata.chr4_new_ids_pat_mat_pheno.misHWEfiltered.pgen
    │   ├── [1.9K]  results/results/filter_miss/quantfamdata.chr4_new_ids_pat_mat_pheno.misHWEfiltered.psam
    │   ├── [184K]  results/results/filter_miss/quantfamdata.chr4_new_ids_pat_mat_pheno.misHWEfiltered.pvar
    │   ├── [1.0K]  results/results/filter_miss/quantfamdata.chr5_new_ids_pat_mat_pheno.misHWEfiltered.log
    │   ├── [179K]  results/results/filter_miss/quantfamdata.chr5_new_ids_pat_mat_pheno.misHWEfiltered.pgen
    │   ├── [1.9K]  results/results/filter_miss/quantfamdata.chr5_new_ids_pat_mat_pheno.misHWEfiltered.psam
    │   ├── [172K]  results/results/filter_miss/quantfamdata.chr5_new_ids_pat_mat_pheno.misHWEfiltered.pvar
    │   ├── [1.0K]  results/results/filter_miss/quantfamdata.chr6_new_ids_pat_mat_pheno.misHWEfiltered.log
    │   ├── [465K]  results/results/filter_miss/quantfamdata.chr6_new_ids_pat_mat_pheno.misHWEfiltered.pgen
    │   ├── [1.9K]  results/results/filter_miss/quantfamdata.chr6_new_ids_pat_mat_pheno.misHWEfiltered.psam
    │   ├── [457K]  results/results/filter_miss/quantfamdata.chr6_new_ids_pat_mat_pheno.misHWEfiltered.pvar
    │   ├── [1.0K]  results/results/filter_miss/quantfamdata.chr7_new_ids_pat_mat_pheno.misHWEfiltered.log
    │   ├── [153K]  results/results/filter_miss/quantfamdata.chr7_new_ids_pat_mat_pheno.misHWEfiltered.pgen
    │   ├── [1.9K]  results/results/filter_miss/quantfamdata.chr7_new_ids_pat_mat_pheno.misHWEfiltered.psam
    │   ├── [147K]  results/results/filter_miss/quantfamdata.chr7_new_ids_pat_mat_pheno.misHWEfiltered.pvar
    │   ├── [1.0K]  results/results/filter_miss/quantfamdata.chr8_new_ids_pat_mat_pheno.misHWEfiltered.log
    │   ├── [143K]  results/results/filter_miss/quantfamdata.chr8_new_ids_pat_mat_pheno.misHWEfiltered.pgen
    │   ├── [1.9K]  results/results/filter_miss/quantfamdata.chr8_new_ids_pat_mat_pheno.misHWEfiltered.psam
    │   ├── [138K]  results/results/filter_miss/quantfamdata.chr8_new_ids_pat_mat_pheno.misHWEfiltered.pvar
    │   ├── [1.0K]  results/results/filter_miss/quantfamdata.chr9_new_ids_pat_mat_pheno.misHWEfiltered.log
    │   ├── [111K]  results/results/filter_miss/quantfamdata.chr9_new_ids_pat_mat_pheno.misHWEfiltered.pgen
    │   ├── [1.9K]  results/results/filter_miss/quantfamdata.chr9_new_ids_pat_mat_pheno.misHWEfiltered.psam
    │   └── [107K]  results/results/filter_miss/quantfamdata.chr9_new_ids_pat_mat_pheno.misHWEfiltered.pvar
    ├── [  30]  results/results/gwas_filtering
    │   └── [8.0K]  results/results/gwas_filtering/user_input_plink
    │       ├── [1.3K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr10_new_ids_pat_mat_pheno_filtered.log
    │       ├── [131K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr10_new_ids_pat_mat_pheno_filtered.pgen
    │       ├── [1.9K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr10_new_ids_pat_mat_pheno_filtered.psam
    │       ├── [131K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr10_new_ids_pat_mat_pheno_filtered.pvar
    │       ├── [1.3K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr11_new_ids_pat_mat_pheno_filtered.log
    │       ├── [131K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr11_new_ids_pat_mat_pheno_filtered.pgen
    │       ├── [1.9K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr11_new_ids_pat_mat_pheno_filtered.psam
    │       ├── [131K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr11_new_ids_pat_mat_pheno_filtered.pvar
    │       ├── [1.3K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr12_new_ids_pat_mat_pheno_filtered.log
    │       ├── [429K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr12_new_ids_pat_mat_pheno_filtered.pgen
    │       ├── [1.9K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr12_new_ids_pat_mat_pheno_filtered.psam
    │       ├── [451K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr12_new_ids_pat_mat_pheno_filtered.pvar
    │       ├── [1.3K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr13_new_ids_pat_mat_pheno_filtered.log
    │       ├── [ 97K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr13_new_ids_pat_mat_pheno_filtered.pgen
    │       ├── [1.9K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr13_new_ids_pat_mat_pheno_filtered.psam
    │       ├── [ 96K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr13_new_ids_pat_mat_pheno_filtered.pvar
    │       ├── [1.3K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr14_new_ids_pat_mat_pheno_filtered.log
    │       ├── [ 89K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr14_new_ids_pat_mat_pheno_filtered.pgen
    │       ├── [1.9K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr14_new_ids_pat_mat_pheno_filtered.psam
    │       ├── [ 88K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr14_new_ids_pat_mat_pheno_filtered.pvar
    │       ├── [1.3K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr15_new_ids_pat_mat_pheno_filtered.log
    │       ├── [ 79K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr15_new_ids_pat_mat_pheno_filtered.pgen
    │       ├── [1.9K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr15_new_ids_pat_mat_pheno_filtered.psam
    │       ├── [ 78K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr15_new_ids_pat_mat_pheno_filtered.pvar
    │       ├── [1.3K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr16_new_ids_pat_mat_pheno_filtered.log
    │       ├── [ 74K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr16_new_ids_pat_mat_pheno_filtered.pgen
    │       ├── [1.9K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr16_new_ids_pat_mat_pheno_filtered.psam
    │       ├── [ 72K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr16_new_ids_pat_mat_pheno_filtered.pvar
    │       ├── [1.3K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr17_new_ids_pat_mat_pheno_filtered.log
    │       ├── [ 77K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr17_new_ids_pat_mat_pheno_filtered.pgen
    │       ├── [1.9K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr17_new_ids_pat_mat_pheno_filtered.psam
    │       ├── [ 75K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr17_new_ids_pat_mat_pheno_filtered.pvar
    │       ├── [1.3K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr18_new_ids_pat_mat_pheno_filtered.log
    │       ├── [ 76K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr18_new_ids_pat_mat_pheno_filtered.pgen
    │       ├── [1.9K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr18_new_ids_pat_mat_pheno_filtered.psam
    │       ├── [ 75K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr18_new_ids_pat_mat_pheno_filtered.pvar
    │       ├── [1.3K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr19_new_ids_pat_mat_pheno_filtered.log
    │       ├── [ 57K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr19_new_ids_pat_mat_pheno_filtered.pgen
    │       ├── [1.9K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr19_new_ids_pat_mat_pheno_filtered.psam
    │       ├── [ 55K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr19_new_ids_pat_mat_pheno_filtered.pvar
    │       ├── [1.3K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr1_new_ids_pat_mat_pheno_filtered.log
    │       ├── [216K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr1_new_ids_pat_mat_pheno_filtered.pgen
    │       ├── [1.9K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr1_new_ids_pat_mat_pheno_filtered.psam
    │       ├── [212K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr1_new_ids_pat_mat_pheno_filtered.pvar
    │       ├── [1.3K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr20_new_ids_pat_mat_pheno_filtered.log
    │       ├── [ 60K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr20_new_ids_pat_mat_pheno_filtered.pgen
    │       ├── [1.9K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr20_new_ids_pat_mat_pheno_filtered.psam
    │       ├── [ 58K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr20_new_ids_pat_mat_pheno_filtered.pvar
    │       ├── [1.3K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr21_new_ids_pat_mat_pheno_filtered.log
    │       ├── [ 35K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr21_new_ids_pat_mat_pheno_filtered.pgen
    │       ├── [1.9K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr21_new_ids_pat_mat_pheno_filtered.psam
    │       ├── [ 34K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr21_new_ids_pat_mat_pheno_filtered.pvar
    │       ├── [1.3K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr22_new_ids_pat_mat_pheno_filtered.log
    │       ├── [ 33K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr22_new_ids_pat_mat_pheno_filtered.pgen
    │       ├── [1.9K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr22_new_ids_pat_mat_pheno_filtered.psam
    │       ├── [ 33K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr22_new_ids_pat_mat_pheno_filtered.pvar
    │       ├── [1.3K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr2_new_ids_pat_mat_pheno_filtered.log
    │       ├── [237K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr2_new_ids_pat_mat_pheno_filtered.pgen
    │       ├── [1.9K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr2_new_ids_pat_mat_pheno_filtered.psam
    │       ├── [231K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr2_new_ids_pat_mat_pheno_filtered.pvar
    │       ├── [1.3K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr3_new_ids_pat_mat_pheno_filtered.log
    │       ├── [198K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr3_new_ids_pat_mat_pheno_filtered.pgen
    │       ├── [1.9K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr3_new_ids_pat_mat_pheno_filtered.psam
    │       ├── [191K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr3_new_ids_pat_mat_pheno_filtered.pvar
    │       ├── [1.3K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr4_new_ids_pat_mat_pheno_filtered.log
    │       ├── [189K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr4_new_ids_pat_mat_pheno_filtered.pgen
    │       ├── [1.9K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr4_new_ids_pat_mat_pheno_filtered.psam
    │       ├── [184K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr4_new_ids_pat_mat_pheno_filtered.pvar
    │       ├── [1.3K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr5_new_ids_pat_mat_pheno_filtered.log
    │       ├── [179K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr5_new_ids_pat_mat_pheno_filtered.pgen
    │       ├── [1.9K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr5_new_ids_pat_mat_pheno_filtered.psam
    │       ├── [172K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr5_new_ids_pat_mat_pheno_filtered.pvar
    │       ├── [1.3K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr6_new_ids_pat_mat_pheno_filtered.log
    │       ├── [465K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr6_new_ids_pat_mat_pheno_filtered.pgen
    │       ├── [1.9K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr6_new_ids_pat_mat_pheno_filtered.psam
    │       ├── [457K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr6_new_ids_pat_mat_pheno_filtered.pvar
    │       ├── [1.3K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr7_new_ids_pat_mat_pheno_filtered.log
    │       ├── [153K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr7_new_ids_pat_mat_pheno_filtered.pgen
    │       ├── [1.9K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr7_new_ids_pat_mat_pheno_filtered.psam
    │       ├── [147K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr7_new_ids_pat_mat_pheno_filtered.pvar
    │       ├── [1.3K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr8_new_ids_pat_mat_pheno_filtered.log
    │       ├── [143K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr8_new_ids_pat_mat_pheno_filtered.pgen
    │       ├── [1.9K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr8_new_ids_pat_mat_pheno_filtered.psam
    │       ├── [138K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr8_new_ids_pat_mat_pheno_filtered.pvar
    │       ├── [1.3K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr9_new_ids_pat_mat_pheno_filtered.log
    │       ├── [111K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr9_new_ids_pat_mat_pheno_filtered.pgen
    │       ├── [1.9K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr9_new_ids_pat_mat_pheno_filtered.psam
    │       └── [107K]  results/results/gwas_filtering/user_input_plink/quantfamdata.chr9_new_ids_pat_mat_pheno_filtered.pvar
    ├── [  58]  results/results/het_check
    │   ├── [ 500]  results/results/het_check/het_passing_samples.tsv
    │   └── [3.0K]  results/results/het_check/het_stats.het
    ├── [  81]  results/results/merged_plink
    │   ├── [1.2K]  results/results/merged_plink/merged.log
    │   ├── [3.2M]  results/results/merged_plink/merged.pgen
    │   ├── [2.0K]  results/results/merged_plink/merged.psam
    │   └── [3.1M]  results/results/merged_plink/merged.pvar
    ├── [ 185]  results/results/merged_pruned_plink
    │   ├── [ 827]  results/results/merged_pruned_plink/merged_pruned.log
    │   ├── [936K]  results/results/merged_pruned_plink/merged_pruned.pgen
    │   ├── [2.0K]  results/results/merged_pruned_plink/merged_pruned.psam
    │   ├── [863K]  results/results/merged_pruned_plink/merged_pruned.pvar
    │   ├── [   0]  results/results/merged_pruned_plink/sex_chr.bed
    │   ├── [   0]  results/results/merged_pruned_plink/sex_chr.bim
    │   ├── [   0]  results/results/merged_pruned_plink/sex_chr.fam
    │   └── [   0]  results/results/merged_pruned_plink/sex_chr.log
    ├── [8.0K]  results/results/qc_filtering
    │   ├── [1.6K]  results/results/qc_filtering/quantfamdata.chr10_new_ids_pat_mat_pheno_QC_filtered.log
    │   ├── [131K]  results/results/qc_filtering/quantfamdata.chr10_new_ids_pat_mat_pheno_QC_filtered.pgen
    │   ├── [1.9K]  results/results/qc_filtering/quantfamdata.chr10_new_ids_pat_mat_pheno_QC_filtered.psam
    │   ├── [131K]  results/results/qc_filtering/quantfamdata.chr10_new_ids_pat_mat_pheno_QC_filtered.pvar
    │   ├── [1.6K]  results/results/qc_filtering/quantfamdata.chr11_new_ids_pat_mat_pheno_QC_filtered.log
    │   ├── [131K]  results/results/qc_filtering/quantfamdata.chr11_new_ids_pat_mat_pheno_QC_filtered.pgen
    │   ├── [1.9K]  results/results/qc_filtering/quantfamdata.chr11_new_ids_pat_mat_pheno_QC_filtered.psam
    │   ├── [131K]  results/results/qc_filtering/quantfamdata.chr11_new_ids_pat_mat_pheno_QC_filtered.pvar
    │   ├── [1.6K]  results/results/qc_filtering/quantfamdata.chr12_new_ids_pat_mat_pheno_QC_filtered.log
    │   ├── [429K]  results/results/qc_filtering/quantfamdata.chr12_new_ids_pat_mat_pheno_QC_filtered.pgen
    │   ├── [1.9K]  results/results/qc_filtering/quantfamdata.chr12_new_ids_pat_mat_pheno_QC_filtered.psam
    │   ├── [451K]  results/results/qc_filtering/quantfamdata.chr12_new_ids_pat_mat_pheno_QC_filtered.pvar
    │   ├── [1.6K]  results/results/qc_filtering/quantfamdata.chr13_new_ids_pat_mat_pheno_QC_filtered.log
    │   ├── [ 97K]  results/results/qc_filtering/quantfamdata.chr13_new_ids_pat_mat_pheno_QC_filtered.pgen
    │   ├── [1.9K]  results/results/qc_filtering/quantfamdata.chr13_new_ids_pat_mat_pheno_QC_filtered.psam
    │   ├── [ 96K]  results/results/qc_filtering/quantfamdata.chr13_new_ids_pat_mat_pheno_QC_filtered.pvar
    │   ├── [1.6K]  results/results/qc_filtering/quantfamdata.chr14_new_ids_pat_mat_pheno_QC_filtered.log
    │   ├── [ 89K]  results/results/qc_filtering/quantfamdata.chr14_new_ids_pat_mat_pheno_QC_filtered.pgen
    │   ├── [1.9K]  results/results/qc_filtering/quantfamdata.chr14_new_ids_pat_mat_pheno_QC_filtered.psam
    │   ├── [ 88K]  results/results/qc_filtering/quantfamdata.chr14_new_ids_pat_mat_pheno_QC_filtered.pvar
    │   ├── [1.6K]  results/results/qc_filtering/quantfamdata.chr15_new_ids_pat_mat_pheno_QC_filtered.log
    │   ├── [ 79K]  results/results/qc_filtering/quantfamdata.chr15_new_ids_pat_mat_pheno_QC_filtered.pgen
    │   ├── [1.9K]  results/results/qc_filtering/quantfamdata.chr15_new_ids_pat_mat_pheno_QC_filtered.psam
    │   ├── [ 78K]  results/results/qc_filtering/quantfamdata.chr15_new_ids_pat_mat_pheno_QC_filtered.pvar
    │   ├── [1.6K]  results/results/qc_filtering/quantfamdata.chr16_new_ids_pat_mat_pheno_QC_filtered.log
    │   ├── [ 74K]  results/results/qc_filtering/quantfamdata.chr16_new_ids_pat_mat_pheno_QC_filtered.pgen
    │   ├── [1.9K]  results/results/qc_filtering/quantfamdata.chr16_new_ids_pat_mat_pheno_QC_filtered.psam
    │   ├── [ 72K]  results/results/qc_filtering/quantfamdata.chr16_new_ids_pat_mat_pheno_QC_filtered.pvar
    │   ├── [1.6K]  results/results/qc_filtering/quantfamdata.chr17_new_ids_pat_mat_pheno_QC_filtered.log
    │   ├── [ 77K]  results/results/qc_filtering/quantfamdata.chr17_new_ids_pat_mat_pheno_QC_filtered.pgen
    │   ├── [1.9K]  results/results/qc_filtering/quantfamdata.chr17_new_ids_pat_mat_pheno_QC_filtered.psam
    │   ├── [ 75K]  results/results/qc_filtering/quantfamdata.chr17_new_ids_pat_mat_pheno_QC_filtered.pvar
    │   ├── [1.6K]  results/results/qc_filtering/quantfamdata.chr18_new_ids_pat_mat_pheno_QC_filtered.log
    │   ├── [ 76K]  results/results/qc_filtering/quantfamdata.chr18_new_ids_pat_mat_pheno_QC_filtered.pgen
    │   ├── [1.9K]  results/results/qc_filtering/quantfamdata.chr18_new_ids_pat_mat_pheno_QC_filtered.psam
    │   ├── [ 75K]  results/results/qc_filtering/quantfamdata.chr18_new_ids_pat_mat_pheno_QC_filtered.pvar
    │   ├── [1.6K]  results/results/qc_filtering/quantfamdata.chr19_new_ids_pat_mat_pheno_QC_filtered.log
    │   ├── [ 57K]  results/results/qc_filtering/quantfamdata.chr19_new_ids_pat_mat_pheno_QC_filtered.pgen
    │   ├── [1.9K]  results/results/qc_filtering/quantfamdata.chr19_new_ids_pat_mat_pheno_QC_filtered.psam
    │   ├── [ 55K]  results/results/qc_filtering/quantfamdata.chr19_new_ids_pat_mat_pheno_QC_filtered.pvar
    │   ├── [1.6K]  results/results/qc_filtering/quantfamdata.chr1_new_ids_pat_mat_pheno_QC_filtered.log
    │   ├── [216K]  results/results/qc_filtering/quantfamdata.chr1_new_ids_pat_mat_pheno_QC_filtered.pgen
    │   ├── [1.9K]  results/results/qc_filtering/quantfamdata.chr1_new_ids_pat_mat_pheno_QC_filtered.psam
    │   ├── [212K]  results/results/qc_filtering/quantfamdata.chr1_new_ids_pat_mat_pheno_QC_filtered.pvar
    │   ├── [1.6K]  results/results/qc_filtering/quantfamdata.chr20_new_ids_pat_mat_pheno_QC_filtered.log
    │   ├── [ 60K]  results/results/qc_filtering/quantfamdata.chr20_new_ids_pat_mat_pheno_QC_filtered.pgen
    │   ├── [1.9K]  results/results/qc_filtering/quantfamdata.chr20_new_ids_pat_mat_pheno_QC_filtered.psam
    │   ├── [ 58K]  results/results/qc_filtering/quantfamdata.chr20_new_ids_pat_mat_pheno_QC_filtered.pvar
    │   ├── [1.6K]  results/results/qc_filtering/quantfamdata.chr21_new_ids_pat_mat_pheno_QC_filtered.log
    │   ├── [ 35K]  results/results/qc_filtering/quantfamdata.chr21_new_ids_pat_mat_pheno_QC_filtered.pgen
    │   ├── [1.9K]  results/results/qc_filtering/quantfamdata.chr21_new_ids_pat_mat_pheno_QC_filtered.psam
    │   ├── [ 34K]  results/results/qc_filtering/quantfamdata.chr21_new_ids_pat_mat_pheno_QC_filtered.pvar
    │   ├── [1.6K]  results/results/qc_filtering/quantfamdata.chr22_new_ids_pat_mat_pheno_QC_filtered.log
    │   ├── [ 33K]  results/results/qc_filtering/quantfamdata.chr22_new_ids_pat_mat_pheno_QC_filtered.pgen
    │   ├── [1.9K]  results/results/qc_filtering/quantfamdata.chr22_new_ids_pat_mat_pheno_QC_filtered.psam
    │   ├── [ 33K]  results/results/qc_filtering/quantfamdata.chr22_new_ids_pat_mat_pheno_QC_filtered.pvar
    │   ├── [1.6K]  results/results/qc_filtering/quantfamdata.chr2_new_ids_pat_mat_pheno_QC_filtered.log
    │   ├── [237K]  results/results/qc_filtering/quantfamdata.chr2_new_ids_pat_mat_pheno_QC_filtered.pgen
    │   ├── [1.9K]  results/results/qc_filtering/quantfamdata.chr2_new_ids_pat_mat_pheno_QC_filtered.psam
    │   ├── [231K]  results/results/qc_filtering/quantfamdata.chr2_new_ids_pat_mat_pheno_QC_filtered.pvar
    │   ├── [1.6K]  results/results/qc_filtering/quantfamdata.chr3_new_ids_pat_mat_pheno_QC_filtered.log
    │   ├── [198K]  results/results/qc_filtering/quantfamdata.chr3_new_ids_pat_mat_pheno_QC_filtered.pgen
    │   ├── [1.9K]  results/results/qc_filtering/quantfamdata.chr3_new_ids_pat_mat_pheno_QC_filtered.psam
    │   ├── [191K]  results/results/qc_filtering/quantfamdata.chr3_new_ids_pat_mat_pheno_QC_filtered.pvar
    │   ├── [1.6K]  results/results/qc_filtering/quantfamdata.chr4_new_ids_pat_mat_pheno_QC_filtered.log
    │   ├── [189K]  results/results/qc_filtering/quantfamdata.chr4_new_ids_pat_mat_pheno_QC_filtered.pgen
    │   ├── [1.9K]  results/results/qc_filtering/quantfamdata.chr4_new_ids_pat_mat_pheno_QC_filtered.psam
    │   ├── [184K]  results/results/qc_filtering/quantfamdata.chr4_new_ids_pat_mat_pheno_QC_filtered.pvar
    │   ├── [1.6K]  results/results/qc_filtering/quantfamdata.chr5_new_ids_pat_mat_pheno_QC_filtered.log
    │   ├── [179K]  results/results/qc_filtering/quantfamdata.chr5_new_ids_pat_mat_pheno_QC_filtered.pgen
    │   ├── [1.9K]  results/results/qc_filtering/quantfamdata.chr5_new_ids_pat_mat_pheno_QC_filtered.psam
    │   ├── [172K]  results/results/qc_filtering/quantfamdata.chr5_new_ids_pat_mat_pheno_QC_filtered.pvar
    │   ├── [1.6K]  results/results/qc_filtering/quantfamdata.chr6_new_ids_pat_mat_pheno_QC_filtered.log
    │   ├── [465K]  results/results/qc_filtering/quantfamdata.chr6_new_ids_pat_mat_pheno_QC_filtered.pgen
    │   ├── [1.9K]  results/results/qc_filtering/quantfamdata.chr6_new_ids_pat_mat_pheno_QC_filtered.psam
    │   ├── [457K]  results/results/qc_filtering/quantfamdata.chr6_new_ids_pat_mat_pheno_QC_filtered.pvar
    │   ├── [1.6K]  results/results/qc_filtering/quantfamdata.chr7_new_ids_pat_mat_pheno_QC_filtered.log
    │   ├── [153K]  results/results/qc_filtering/quantfamdata.chr7_new_ids_pat_mat_pheno_QC_filtered.pgen
    │   ├── [1.9K]  results/results/qc_filtering/quantfamdata.chr7_new_ids_pat_mat_pheno_QC_filtered.psam
    │   ├── [147K]  results/results/qc_filtering/quantfamdata.chr7_new_ids_pat_mat_pheno_QC_filtered.pvar
    │   ├── [1.6K]  results/results/qc_filtering/quantfamdata.chr8_new_ids_pat_mat_pheno_QC_filtered.log
    │   ├── [143K]  results/results/qc_filtering/quantfamdata.chr8_new_ids_pat_mat_pheno_QC_filtered.pgen
    │   ├── [1.9K]  results/results/qc_filtering/quantfamdata.chr8_new_ids_pat_mat_pheno_QC_filtered.psam
    │   ├── [138K]  results/results/qc_filtering/quantfamdata.chr8_new_ids_pat_mat_pheno_QC_filtered.pvar
    │   ├── [1.6K]  results/results/qc_filtering/quantfamdata.chr9_new_ids_pat_mat_pheno_QC_filtered.log
    │   ├── [111K]  results/results/qc_filtering/quantfamdata.chr9_new_ids_pat_mat_pheno_QC_filtered.pgen
    │   ├── [1.9K]  results/results/qc_filtering/quantfamdata.chr9_new_ids_pat_mat_pheno_QC_filtered.psam
    │   └── [107K]  results/results/qc_filtering/quantfamdata.chr9_new_ids_pat_mat_pheno_QC_filtered.pvar
    ├── [ 104]  results/results/relatedness_check
    │   ├── [ 515]  results/results/relatedness_check/relatedness.king.cutoff.in.id
    │   ├── [ 247]  results/results/relatedness_check/relatedness.king.cutoff.out.id
    │   └── [ 938]  results/results/relatedness_check/relatedness.log
    └── [  27]  results/results/sex_check
        └── [ 100]  results/results/sex_check/sex_check.log

35 directories, 271 files
```

</details>
<br>

#### Harmonisation

<details>
<summary>Expected output:</summary>

```
$ tree -fh results/
[ 114]  results
├── [140K]  results/flowchart.png
├── [210K]  results/machine-resources-manager-1.0.15.zip
├── [ 49M]  results/Miniconda_Install.sh
└── [  85]  results/results
    ├── [ 273]  results/results/all_harmonised_gwas_sumstats.csv
    ├── [  59]  results/results/harmonised
    │   └── [399M]  results/results/harmonised/1_EUR-notransform-regenie.harmonised.gwas.vcf
    └── [ 142]  results/results/pipeline_info
        ├── [2.8M]  results/results/pipeline_info/execution_report_2023-08-29_14-03-00.html
        ├── [247K]  results/results/pipeline_info/execution_timeline_2023-08-29_14-03-00.html
        └── [1.8K]  results/results/pipeline_info/pipeline_metadata_report.tsv

3 directories, 8 files
```

</details>
<br>

### Step 2

<details>
<summary>Expected output:</summary>

```
$ tree -fh results/
[  65]  results
├── [ 56K]  results/flowchart.png
├── [   7]  results/parameters.json
└── [  43]  results/results
    ├── [ 132]  results/results/gcta_smr
    │   ├── [1.2M]  results/results/gcta_smr/1_allancs-notransform-regenie_smr_results.smr
    │   └── [3.1M]  results/results/gcta_smr/1_allancs-notransform-regenie_smr_results.snp_failed_freq_ck.list
    └── [ 106]  results/results/pipeline_info
        ├── [2.8M]  results/results/pipeline_info/execution_report_2023-09-04_09-28-49.html
        └── [246K]  results/results/pipeline_info/execution_timeline_2023-09-04_09-28-49.html

3 directories, 6 files
```

</details>
<br>

### Step 3

<details>
<summary>Expected output:</summary>

```
$ tree -fh results 
[  65]  results
├── [218K]  results/flowchart.png
├── [   7]  results/parameters.json
└── [ 306]  results/results
    ├── [  80]  results/results/1_GCST90091033.harmonised.gwas_1_expos_assoc.ppa
    ├── [  62]  results/results/1_GCST90091033.harmonised.gwas_2_expos_assoc.ppa
    ├── [4.0K]  results/results/1_GCST90091033.harmonised.gwas.pdf
    ├── [ 147]  results/results/1_GCST90091033.harmonised.gwas.pi
    ├── [413M]  results/results/1_GCST90091033.harmonised.gwas.txt
    ├── [  36]  results/results/1_GCST90091033.harmonised.gwas.var
    └── [ 189]  results/results/pipeline_info
        ├── [2.8M]  results/results/pipeline_info/execution_report_2023-09-04_09-46-58.html
        ├── [247K]  results/results/pipeline_info/execution_timeline_2023-09-04_09-46-58.html
        ├── [ 965]  results/results/pipeline_info/execution_trace_2023-09-04_14-51-31.txt
        └── [2.2K]  results/results/pipeline_info/pipeline_metadata_report.tsv

2 directories, 12 files
```

</details>
<br>


### Step 4

<details>
<summary>Expected output:</summary>

```
$ tree -fh results 
[  65]  results
├── [ 84K]  results/flowchart.png
├── [   7]  results/parameters.json
└── [ 149]  results/results
    ├── [154M]  results/results/gwas_vcf_dataframe.tsv.gz
    ├── [ 189]  results/results/pipeline_info
    │   ├── [2.8M]  results/results/pipeline_info/execution_report_2023-09-04_10-03-58.html
    │   ├── [247K]  results/results/pipeline_info/execution_timeline_2023-09-04_10-03-58.html
    │   ├── [ 711]  results/results/pipeline_info/execution_trace_2023-09-04_10-12-31.txt
    │   └── [2.0K]  results/results/pipeline_info/pipeline_metadata_report.tsv
    ├── [ 286]  results/results/ProtVar_results.tsv
    ├── [164K]  results/results/PZ_plot.pdf
    ├── [3.5K]  results/results/QQ_plot.pdf
    └── [ 551]  results/results/sQTL_results.tsv

2 directories, 11 files
```

</details>
<br>

### Step 5

#### Finemapping

<details>
<summary>Expected output:</summary>

```
$ tree -fh -L 3 results/
[  65]  results
├── [136K]  results/flowchart.png
├── [   7]  results/parameters.json
└── [  41]  results/results
    ├── [  84]  results/results/polyfun
    │   ├── [  34]  results/results/polyfun/filtered_regions
    │   ├── [ 44K]  results/results/polyfun/finemapping
    │   ├── [  39]  results/results/polyfun/per_snp_her
    │   └── [  37]  results/results/polyfun/sumstats
    └── [  63]  results/results/vcf_sumstats
        ├── [ 58M]  results/results/vcf_sumstats/converted_sumstats.tsv
        └── [   4]  results/results/vcf_sumstats/max_sample_size.txt

7 directories, 4 files
```
> **NOTE**: Folder `results/results/polyfun/finemapping/` is populated with many genetic region file results, e.g. `results/results/polyfun/finemapping/finemap.UKB.10.85000001.88000001.gz`, for each chromosome and the respective bin. For a better visualisation, the files of this folder are not presented in this documentation.

</details>
<br>

#### Cheers

<details>
<summary>Expected output:</summary>

```
$ tree -fh results 
[  65]  results
├── [ 39K]  results/flowchart.png
├── [   7]  results/parameters.json
└── [ 144]  results/results
    ├── [1.2K]  results/results/CHEERS_disease_enrichment_pValues.txt
    ├── [ 83K]  results/results/CHEERS_SNPsOverlappingPeaks.txt
    ├── [ 35K]  results/results/list_snps_credset_PIP.txt
    └── [  53]  results/results/pipeline_info
        └── [ 414]  results/results/pipeline_info/execution_trace_2023-09-04_11-18-04.txt

2 directories, 6 files
```

</details>
<br>

### Step 6

#### GSEA

<details>
<summary>Expected output:</summary>

```
$ tree -fh results 
[  65]  results
├── [149K]  results/flowchart.png
├── [   7]  results/parameters.json
└── [  55]  results/results
    ├── [4.0K]  results/results/magma
    │   ├── [103M]  results/results/magma/magma_out.genes.annot
    │   ├── [2.1K]  results/results/magma/magma_out.genes.annot.log
    │   ├── [1.5M]  results/results/magma/magma_out.genes.out
    │   ├── [1.1K]  results/results/magma/magma_out.genes.out.log
    │   ├── [ 318]  results/results/magma/magma_out.genes.out.prioritised.genenames.tsv
    │   ├── [1.1M]  results/results/magma/magma_out.genes.out.sorted.genenames.tsv
    │   ├── [ 10M]  results/results/magma/magma_out.genes.raw
    │   ├── [228K]  results/results/magma/magma_out.gsa.out
    │   ├── [1.3K]  results/results/magma/magma_out.gsa.out.log
    │   ├── [182K]  results/results/magma/magma_out.gsa.out.sorted.csv
    │   ├── [703K]  results/results/magma/magma_out.gsa.out.sorted.genenames.tsv
    │   ├── [1.2K]  results/results/magma/magma_out.gsa.out.top_10.plot.csv
    │   ├── [2.1K]  results/results/magma/magma_out.gsa.out.top_10.plot.genenames.tsv
    │   └── [149K]  results/results/magma/magma_out.gsa.out.top_10.plot.png
    ├── [  33]  results/results/MultiQC
    │   └── [2.6M]  results/results/MultiQC/multiqc_report.html
    └── [  66]  results/results/pipeline_info
        ├── [2.8M]  results/results/pipeline_info/execution_report.html
        └── [248K]  results/results/pipeline_info/execution_timeline.html

4 directories, 19 files
```

</details>
<br>

#### Drug2ways

<details>
<summary>Expected output:</summary>

```
$ tree -fh results 
[  65]  results
├── [ 99K]  results/flowchart.png
├── [   7]  results/parameters.json
└── [ 144]  results/results
    ├── [  81]  results/results/available_targets.tsv
    ├── [ 31K]  results/results/db_drugs.tsv
    ├── [  41]  results/results/drug2ways
    │   └── [1.3M]  results/results/drug2ways/all_against_all_lmax_6.json
    ├── [1.4M]  results/results/drug_target_interactions.tsv
    ├── [  33]  results/results/MultiQC
    │   └── [2.7M]  results/results/MultiQC/multiqc_report.html
    └── [ 189]  results/results/pipeline_info
        ├── [2.8M]  results/results/pipeline_info/execution_report_2023-09-04_11-23-01.html
        ├── [247K]  results/results/pipeline_info/execution_timeline_2023-09-04_11-23-01.html
        ├── [1.0K]  results/results/pipeline_info/execution_trace_2023-09-04_11-31-45.txt
        └── [2.1K]  results/results/pipeline_info/pipeline_metadata_report.tsv

4 directories, 11 files
```

</details>
<br>

## Usage

To run this pipeline, one of the steps needs to be activated and the API key to be passed.

```terminal
nextflow run main.nf --step_2_identify_prioritised_genes --cloudos_api_key '****'
```
#### Profiles

For each step a Nextflow profile exists:

- **`test_full_step_1_identify_genetic_associations`**: activates step 1
- **`test_full_step_2_identify_prioritised_genes`**: activates step 2
- **`test_full_step_3_identify_causal_genes_and_pathways`**: activates step 3
- **`test_full_step_4_identify_causal_proteins`**: activates step 4
- **`test_full_step_5_identify_mechanism_of_action`**: activates step 5
- **`test_full_step_6_identify_candidate_drugs`**: activates step 6

> **NOTE**: no CI tests are found in GitHub because the tests take a long time (specially the step 3, which can take up to 5 hours) and will slow down PR reviews.

## Options

### Mandatory options

- **`--cloudos_api_key`**: API key from CloudOS

### CloudOS options

- **`--cloudos_url`**: CloudOS URL. Default: "https://stg.cloud-os.test.aws.gel.ac".

- **`--cloudos_workspace_id`**: Workspace ID from CloudOS. Default: "62c5ca77577efc01458b949b" (Lifebit Internal Production).

- **`--cloudos_queue_name`**: Queue name from CloudOS. Default: "job_queue_nextflow".

### Step 1a

- **`--step_1a_identify_genetic_associations_phenofile_cloudos_workflow_name`**: Workflow name in CloudOS. Default: "etl_omop2phenofile".

- **`--step_1a_identify_genetic_associations_phenofile_cloudos_job_name`**: Job name in CloudOS, combination of step name and workflow name. Default: `"step_1a_identify_genetic_associations_phenofile:${params.data_source}-${params.phenotype_group}-${params.phenotype_label}:${params.step_1a_identify_genetic_associations_phenofile_cloudos_workflow_name}"`.

- **`--step_1a_identify_genetic_associations_phenofile_cloudos_cost_limit`**: Job cost limit: Default. `false`.

- **`--step_1a_identify_genetic_associations_phenofile_cloudos_instance_disk_space`**: Job instance disk space. Default: `false`.

- **`--step_1a_identify_genetic_associations_phenofile_cloudos_nextflow_profile`**: Nextflow profile to use. Default: `false`.

- **`--step_1a_identify_genetic_associations_phenofile_cloudos_instance_type`**: Job instance type. Default: `false`.

- **`--step_1a_identify_genetic_associations_phenofile_cloudos_queue_name`**: Job queue. Default: `"${params.cloudos_queue_name}"`.

- **`--step_1a_identify_genetic_associations_phenofile_cloudos_wait_time`**: Job wait time. Default: `false`.

- **`--step_1a_identify_genetic_associations_phenofile_covariate_specification`**: A file containing details of the covariates to include in the phenofile. Default: "s3://gel-lifebit-featured-datasets/pipelines/etl_omop2phenofile/covariate_specs_age_sex.json".

- **`--step_1a_identify_genetic_associations_phenofile_sql_specification`**: A SQL specification for the case defintion. Default: `'SELECT * FROM omop_data_100kv13_covidv4.person WHERE omop_data_100kv13_covidv4.person.person_id < 1000'`.

- **`--step_1a_identify_genetic_associations_phenofile_database_host`**: An OMOP database host. A credential used to connect to the database. Default: "clinical-cb-sql-tst.cnt2wlftsbgx.eu-west-2.rds.amazonaws.com".

- **`--step_1a_identify_genetic_associations_phenofile_database_port`**: An OMOP database port. A credential used to connect to the database. Default: 5432.

- **`--step_1a_identify_genetic_associations_phenofile_database_username`**: An OMOP database user name. A credential used to connect to the database. Default: "nextflow".

- **`--step_1a_identify_genetic_associations_phenofile_database_password`**: An OMOP database password. A credential used to connect to the database. Ideally provided in the UI, based on CloudOS `ENV_VARIABLE`. Default: `false`.

- **`--step_1a_identify_genetic_associations_phenofile_database_cdm_schema`**: An OMOP database cdm schema name. A credential used to connect to the database. Default: "omop_data_100kv13_covidv4".

- **`--step_1a_identify_genetic_associations_phenofile_database_cohort_schema`**: An OMOP database cohort schema name. A credential used to connect to the database. Default: "public".

- **`--step_1a_identify_genetic_associations_phenofile_database_dbms`**: An OMOP database dbms. A credential used to connect to the database. Default: "postgresql".

- **`--step_1a_identify_genetic_associations_phenofile_database_name`**: An OMOP database name. A credential used to connect to the database. Default: "gel_clinical_cb_sql_tst".

- **`--step_1a_identify_genetic_associations_phenofile_genotype_files_list`**: Default: "s3://lifebit-user-data-26b5dd54-e417-4e2f-9f5b-8f6a5422f0ef/deploit/teams/62c5ca77577efc01458b949b/users/635aaca4bd3645015c8cb5e4/dataset/6501b2957484579dc4cff197/gel_masked_bgen_design_file.csv".

- **`--step_1a_identify_genetic_associations_phenofile_genotypic_linking_table`**: An optional file that can be used to replace IDs found in phenotypic data with the supplied IDs found in genotypic data and to add any additional fields to the final phenofile. Default: "s3://lifebit-user-data-e9f0c6bd-2af5-478b-a3cd-61c96a8ad8ce/deploit/teams/62c5ca77577efc01458b949b/users/60c220d04dd6ea01bea4c5ab/projects/64f9cf32c195ce56c8b956b3/jobs/65031de21ef2842a31c5dc7f/work/25/baff305294fdf202b76021b1bfcf77/processed_linking_table.csv".

- **`--step_1a_identify_genetic_associations_phenofile_genotypic_id_col`**: The name of the column containing genotypic ID in genotypic_linking_table, If not supplied, the ID will not be changed.. Default: "platekey".

- **`--step_1a_identify_genetic_associations_phenofile_original_id_col`**: The name of the column containing phenotypic ID in genotypic_linking_table. If not supplied, it will be assumed to be the first column in the file. Default: "participant_id".

- **`--step_1a_identify_genetic_associations_phenofile_codelist_specification`**: A file containing user-made codelist specification. Default: `false`.

- **`--step_1a_identify_genetic_associations_phenofile_pheno_label`**: A phenolabel value used in generating a phenofile using the cohort(s) written to the OMOP database and an input covariate specification. Default: "phenotype-X".

- **`--step_1a_identify_genetic_associations_phenofile_phenofile_name`**: A name for the output TSV file. Default: "phenofile".

- **`--step_1a_identify_genetic_associations_phenofile_include_descendants`**: Should descendants be included in supplied codelist. Default: `false`.

- **`--step_1a_identify_genetic_associations_phenofile_quantitative_outcome_concept_id`**: Can be specified to use a measurement value as the outcome variable. This currently cannot be used alongside json or codelist cohort specifications. Default: `false`.

- **`--step_1a_identify_genetic_associations_phenofile_quantitative_outcome_occurrence`**: If multiple measurements are present, the user can either the first of last occurrence. Default: "last".

- **`--step_1a_identify_genetic_associations_phenofile_control_index_date`**: Defines which date to use as the control group index date. Can either be 'first', 'last', 'random' or 'observation_period_end'. Default: "observation_period_end".

- **`--step_1a_identify_genetic_associations_phenofile_case_cohort_json`**: Case cohort definition JSON files. Default: `false`.

- **`--step_1a_identify_genetic_associations_phenofile_control_cohort_json`**: Control cohort definition JSON files. Default: `false`.

- **`--step_1a_identify_genetic_associations_phenofile_create_controls`**: When using `--sql_specification`, defines whether a control cohort be made using the remaining database population. Default: `true`.

- **`--step_1a_identify_genetic_associations_phenofile_controls_to_match`**: Defines the number of controls to match per cases. `false` will not perform any matching and return all controls. Default: 4.

- **`--step_1a_identify_genetic_associations_phenofile_min_controls_to_match`**: Minimum nnumber of controls to match. Default: 0.

- **`--step_1a_identify_genetic_associations_phenofile_match_age_tolerance`**: Defines the tolerance in years when matching by age. Default: 2.

- **`--step_1a_identify_genetic_associations_phenofile_match_on_age`**: Defines whether controls should be matched on age. Default: `true`.

- **`--step_1a_identify_genetic_associations_phenofile_match_on_sex`**: Defines whether controls should be matched on sex. Default: `true`.

### Step 1b

- **`--step_1b_identify_genetic_associations_gwas_cloudos_workflow_name`**: Workflow name in CloudOS. Default: "GH_gwas_nf".

- **`--step_1b_identify_genetic_associations_gwas_cloudos_job_name`**: Job name in CloudOS, combination of step name and workflow name. Default: `"step_1b_identify_genetic_associations_gwas:${params.data_source}-${params.phenotype_group}-${params.phenotype_label}:${params.step_1b_identify_genetic_associations_gwas_cloudos_workflow_name}"`.

- **`--step_1b_identify_genetic_associations_gwas_cloudos_cost_limit`**: Job cost limit: Default. `false`.

- **`--step_1b_identify_genetic_associations_gwas_cloudos_instance_disk_space`**: Job instance disk space. Default: `false`.

- **`--step_1b_identify_genetic_associations_gwas_cloudos_nextflow_profile`**: Nextflow profile to use. Default: `false`.

- **`--step_1b_identify_genetic_associations_gwas_cloudos_instance_type`**: Job instance type. Default: `false`.

- **`--step_1b_identify_genetic_associations_gwas_cloudos_queue_name`**: Job queue. Default: `"${params.cloudos_queue_name}"`.

- **`--step_1b_identify_genetic_associations_gwas_cloudos_wait_time`**: Job wait time. Default: 20000.

- **`--step_1b_identify_genetic_associations_gwas_genotype_format`**: Specify the file format of the input genotype data. One of :'vcf,' 'bgen', 'plink', 'dosage' and 'pgen'. Default: "bgen".

- **`--step_1b_identify_genetic_associations_gwas_genotype_files_list`**: Provide a csv file with 1 row for each input fileset, header line and columns should correspond to chromosome names and filepaths: chr, vcf, vcf_index for vcf format; chr, bgen, bgi_index for bgen format; chr, bed, bim, fam for PLINK1 binary format; chr, dosage, map, fam for PLINK1 dosage format; chr, pgen, pvar, psam for PLINK2 binary .pgen format. Default: "s3://lifebit-user-data-26b5dd54-e417-4e2f-9f5b-8f6a5422f0ef/deploit/teams/62c5ca77577efc01458b949b/users/635aaca4bd3645015c8cb5e4/dataset/6501b2957484579dc4cff197/gel_masked_bgen_design_file.csv".

- **`--step_1b_identify_genetic_associations_gwas_genome_build`**: Manually specify the genome build of the input data (e.g. "GRCh38"). The value of this parameter is added to output metadata. This is used to inform the harmonisation pipeline of the genome build so that the build does not need to be inferred. Default: "GRCh38".

- **`--step_1b_identify_genetic_associations_gwas_annotate_with_rsids`**: annotate the genotypic filtered plink data files with rsids. Default: `true`.

- **`--step_1b_identify_genetic_associations_gwas_king_reference_data`**: Path to plink files with genotypic reference data for inferring ancestry using KING Default: "s3://gel-lifebit-featured-datasets/pipelines/gwas-nf/ancestry_ref/KGref.{bed,bim,fam}.xz".

- **`--step_1b_identify_genetic_associations_gwas_high_LD_long_range_regions`**: File specifying regions of long-range high LD in which all varaints will be excluded for the high quality variant set. Default: "s3://gel-lifebit-featured-datasets/pipelines/bi-gwas-nf/high-LD-regions-hg38-GRCh38.txt".

- **`--step_1b_identify_genetic_associations_gwas_rsid_cpra_table`**: Default: "s3://gel-lifebit-featured-datasets/pipelines/omics/rsid_cpra_GRCh38_conv.txt".

- **`--step_1b_identify_genetic_associations_gwas_saige`**: Run SAIGE association testing. Default: `false`.

- **`--step_1b_identify_genetic_associations_gwas_regenie`**: Run Regenie association testing. Default: `true`.

- **`--step_1b_identify_genetic_associations_gwas_run_pca`**: Enable PC calculation and iterative PCA-based outlier removal. Default: `false`.

- **`--step_1b_identify_genetic_associations_gwas_pheno_data`**: Provide the phenofile containing the phenotypic data. Will be the output from step 1a. If provided, will overwrite the output from step 1a. Default: `false`.

- **`--step_1b_identify_genetic_associations_gwas_phenotype_colname`**: If not using a phenotype transformation file, specify the focal phenotype in the phenofile. Default: `"${params.step_1a_identify_genetic_associations_phenofile_pheno_label}"`.

- **`--step_1b_identify_genetic_associations_gwas_mind_threshold`**: Remove individuals with overall missingness > mind_threshold i.e. individuals with >10% missingness. Default: 1.

- **`--step_1b_identify_genetic_associations_gwas_miss`**: Filter out all variants with missingness > miss. Default: 1.

- **`--step_1b_identify_genetic_associations_gwas_miss_test_p_threshold`**: For focal phenotypes that are binary, filter out variants with significantly unbalanced distribution of missingness between cases and controls. Default: 0.5.

- **`--step_1b_identify_genetic_associations_gwas_sex_check`**: Performs a check to see whether labelled phenotypic sex matches genetic data for each individual. Default: `false`.

- **`--step_1b_identify_genetic_associations_gwas_remove_related_samples`**: Enable relatedness-based filtering. Default: `false`.

- **`--step_1b_identify_genetic_associations_gwas_reference_data_bucket`**: Prefix of the S3 bucket path. Default: "s3://gel-lifebit-featured-datasets".

### Step 1c

- **`--step_1c_identify_genetic_associations_harmonisation_cloudos_workflow_name`**: Workflow name in CloudOS. Default: "GH_gwas_sumstats_harmonisation_nf".

- **`--step_1c_identify_genetic_associations_harmonisation_cloudos_job_name`**: Job name in CloudOS, combination of step name and workflow name. Default: `"step_1c_identify_genetic_associations_harmonisation:${params.data_source}-${params.phenotype_group}-${params.phenotype_label}:${params.step_1c_identify_genetic_associations_harmonisation_cloudos_workflow_name}"`.

- **`--step_1c_identify_genetic_associations_harmonisation_cloudos_cost_limit`**: Job cost limit: Default. `false`.

- **`--step_1c_identify_genetic_associations_harmonisation_cloudos_instance_disk_space`**: Job instance disk space. Default: `false`.

- **`--step_1c_identify_genetic_associations_harmonisation_cloudos_nextflow_profile`**: Nextflow profile to use. Default: `false`.

- **`--step_1c_identify_genetic_associations_harmonisation_cloudos_instance_type`**: Job instance type. Default: `false`.

- **`--step_1c_identify_genetic_associations_harmonisation_cloudos_queue_name`**: Job queue. Default: `"${params.cloudos_queue_name}"`.

- **`--step_1c_identify_genetic_associations_harmonisation_cloudos_wait_time`**: Job wait time. Default: 20000.

- **`--step_1c_identify_genetic_associations_harmonisation_input`**: Input file (path). Newline delimited list of IDs or file paths. Will be the output from step 1b. If provided, will overwrite the output from step 1b. Default: `false`.

- **`--step_1c_identify_genetic_associations_harmonisation_gwas_source`**: Type/source of GWAS input data. It should be one of the following supported strings 'ebi', 'ieu', 'gwas_vcf', 'gwas_tables'. Default: "gwas_table".

- **`--step_1c_identify_genetic_associations_harmonisation_input_type`**: Type of input, 'list' or 'single'. Default: "single".

- **`--step_1c_identify_genetic_associations_harmonisation_standardise`**: Whether to perform BETA and SE standardisation (bool). Default: `true`.

- **`--step_1c_identify_genetic_associations_harmonisation_coef_conversion`**: Whether to perform the coefficient conversion, from BETA to Odds Ratio (bool). Default: `true`.

- **`--step_1c_identify_genetic_associations_harmonisation_keep_intermediate_files`**: Whether to keep intermediate files (bool). Default: `true`.

- **`--step_1c_identify_genetic_associations_harmonisation_filter_beta_smaller_than`**: Exclude variants with BETA smaller than the specified value (float). Default: -0.3.

- **`--step_1c_identify_genetic_associations_harmonisation_filter_beta_greater_than`**: Exclude variants with BETA greater than the specified value (float). Default: 0.3.

- **`--step_1c_identify_genetic_associations_harmonisation_filter_LP_smaller_than`**: Exclude variants with a LP (-log10 P) value smaller than the specified value (float). Default: 0.3.

- **`--step_1c_identify_genetic_associations_harmonisation_filter_freq_smaller_than`**: Exclude variants with a alternate allele frequency smaller than the specified value (float). Default: 0.3.

- **`--step_1c_identify_genetic_associations_harmonisation_filter_freq_greater_than`**: Exclude variants with a alternate allele frequency greater than the specified value (float). Default: 0.8.

- **`--step_1c_identify_genetic_associations_harmonisation_convert_to_hail`**: Whether to convert the harmonised VCF to Hail MatrixTable format (bool). Default: `false`.

- **`--step_1c_identify_genetic_associations_harmonisation_dbsnp`**: Version of dbSNP database to use when harmonising variants. Supported versions: '144', '155'. Default: 155.

- **`--step_1c_identify_genetic_associations_harmonisation_reference_data_bucket`**: Prefix of the S3 bucket path. Default: "s3://gel-lifebit-featured-datasets".

### Step 2

- **`--step_2_identify_prioritised_genes_cloudos_workflow_name`**: Workflow name in CloudOS. Default: "variant-to-gene-mapping-nf".

- **`--step_2_identify_prioritised_genes_cloudos_job_name`**: Job name in CloudOS, combination of step name and workflow name. Default: `"step_2_identify_prioritised_genes:${params.data_source}-${params.phenotype_group}-${params.phenotype_label}:${params.step_2_identify_prioritised_genes_cloudos_workflow_name}"`.

- **`--step_2_identify_prioritised_genes_cloudos_cost_limit`**: Job cost limit: Default. `false`.

- **`--step_2_identify_prioritised_genes_cloudos_instance_disk_space`**: Job instance disk space. Default: `false`.

- **`--step_2_identify_prioritised_genes_cloudos_nextflow_profile`**: Nextflow profile to use. Default: `false`.

- **`--step_2_identify_prioritised_genes_cloudos_instance_type`**: Job instance type. Default: `false`.

- **`--step_2_identify_prioritised_genes_cloudos_queue_name`**: Job queue. Default: `"${params.cloudos_queue_name}"`.

- **`--step_2_identify_prioritised_genes_cloudos_wait_time`**: Job wait time. Default: 9000.

- **`--step_2_identify_prioritised_genes_variant_to_gene_git_tag`**: Branch of the workflow to run. Default: "dev".

- **`--step_2_identify_prioritised_genes_variant_to_gene_gcta_smr`**: Activates the GCTA analysis process. Default: `true`.

- **`--step_2_identify_prioritised_genes_variant_to_gene_closest_genes`**: Activates the closest gene process. Default: `false`.

- **`--step_2_identify_prioritised_genes_variant_to_gene_metaxcan`**: Activates the MetaXcan analysis process. Default: `false`.

- **`--step_2_identify_prioritised_genes_variant_to_gene_gwas_vcf`**: Path to GWAS summary statistics file. From the output of step 1c. If provided, will overwrite the output from step 1c. Default: `false`.

- **`--step_2_identify_prioritised_genes_variant_to_gene_plink_data`**: List of .bed, .bim, .fam genotype files. Default: "s3://gel-lifebit-featured-datasets/pipelines/downstream-omics/1000G_plink_by_pop/1000G_spopEUR.{bed,bim,fam}".

- **`--step_2_identify_prioritised_genes_variant_to_gene_besd_data`**: List of .besd, .epi and .esi. Default: "s3://gel-lifebit-featured-datasets/pipelines/downstream-omics/joint-xqtl/xQTL_data/eQTL/cage_eqtl_data_lite_hg19/CAGE.sparse.lite.{besd,epi,esi}".

- **`--step_2_identify_prioritised_genes_variant_to_gene_diff_freq_prop`**: Proportion of the frequency difference for p-eQTL. Default: 0.3.

### Step 3

- **`--step_3_identify_causal_genes_and_pathways_cloudos_workflow_name`**: Workflow name in CloudOS. Default: "joint-xqtl".

- **`--step_3_identify_causal_genes_and_pathways_cloudos_job_name`**: Job name in CloudOS, combination of step name and workflow name. Default: `"step_3_identify_causal_genes_and_pathways:${params.data_source}-${params.phenotype_group}-${params.phenotype_label}:${step_3_identify_causal_genes_and_pathways_cloudos_workflow_name}"`.

- **`--step_3_identify_causal_genes_and_pathways_cloudos_cost_limit`**: Job cost limit: Default. `false`.

- **`--step_3_identify_causal_genes_and_pathways_cloudos_instance_disk_space`**: Job instance disk space. Default: `false`.

- **`--step_3_identify_causal_genes_and_pathways_cloudos_nextflow_profile`**: Nextflow profile to use. Default: `false`.

- **`--step_3_identify_causal_genes_and_pathways_cloudos_instance_type`**: Job instance type. Default: "c6a.4xlarge".

- **`--step_3_identify_causal_genes_and_pathways_cloudos_queue_name`**: Job queue. Default: `"${params.cloudos_queue_name}"`.

- **`--step_3_identify_causal_genes_and_pathways_cloudos_wait_time`**: Job wait time. Default: 20000.

- **`--step_3_identify_causal_genes_and_pathways_joint_xqtl_gwas_vcf`**: Path to GWAS summary statistics file. From the output of step 1c. If provided, will overwrite the output from step 1c. Default: `false`.

- **`--step_3_identify_causal_genes_and_pathways_joint_xqtl_ld_ref_data`**: LD reference in PLINK format. Default: "s3://gel-lifebit-featured-datasets/pipelines/downstream-omics/1000G_plink_by_pop/1000G_spopEUR.{bed,bim,fam}".

- **`--step_3_identify_causal_genes_and_pathways_joint_xqtl_besd_list`**: a list of full paths of the multiple xQTL BESD files. Default: "s3://gel-lifebit-featured-datasets/pipelines/downstream-omics/joint-xqtl/testdata/full_test_besd_list".

- **`--step_3_identify_causal_genes_and_pathways_joint_xqtl_git_tag`**: Branch of the workflow to run. Default: "dev".

- **`--step_3_identify_causal_genes_and_pathways_joint_xqtl_reference_data_bucket`**: Prefix of the S3 bucket path. Default: "s3://gel-lifebit-featured-datasets".

### Step 4

- **`--step_4_identify_causal_proteins_cloudos_workflow_name`**: Workflow name in CloudOS. Default: "xqtlbiolinks-nf".

- **`--step_4_identify_causal_proteins_cloudos_job_name`**: Job name in CloudOS, combination of step name and workflow name. Default: `"step_4_identify_causal_proteins:${params.data_source}-${params.phenotype_group}-${params.phenotype_label}:${step_4_identify_causal_proteins_cloudos_workflow_name}"`.

- **`--step_4_identify_causal_proteins_cloudos_cost_limit`**: Job cost limit: Default. `false`.

- **`--step_4_identify_causal_proteins_cloudos_instance_disk_space`**: Job instance disk space. Default: `false`.

- **`--step_4_identify_causal_proteins_cloudos_nextflow_profile`**: Nextflow profile to use. Default: `false`.

- **`--step_4_identify_causal_proteins_cloudos_instance_type`**: Job instance type. Default: `false`.

- **`--step_4_identify_causal_proteins_cloudos_queue_name`**: Job queue. Default: `"${params.cloudos_queue_name}"`.

- **`--step_4_identify_causal_proteins_cloudos_wait_time`**: Job wait time. Default: 9000.

- **`--step_4_identify_causal_proteins_xqtlbiolinks_gwas_vcf`**: Path to GWAS summary statistics file. From the output of step 1c. If provided, will overwrite step 1c. If provided, will overwrite the output from step 1c. Default: `false`.

- **`--step_4_identify_causal_proteins_xqtlbiolinks_git_tag`**: Branch of the workflow to run. Default: "dev".

- **`--step_4_identify_causal_proteins_xqtlbiolinks_reference_data_bucket`**: Prefix of the S3 bucket path. Default: "s3://gel-lifebit-featured-datasets".

### Step 5

#### Liftover

- **`--step_5_identify_mechanism_of_action_liftover_cloudos_workflow_name`**: Workflow name in CloudOS. Default: "liftover-nf".

- **`--step_5_identify_mechanism_of_action_liftover_cloudos_job_name`**: Job name in CloudOS, combination of step name and workflow name. Default: `"step_5_identify_mechanism_of_action_liftover:${params.data_source}-${params.phenotype_group}-${params.phenotype_label}:${params.step_5_identify_mechanism_of_action_liftover_cloudos_workflow_name}"`.

- **`--step_5_identify_mechanism_of_action_liftover_cloudos_cost_limit`**: Job cost limit: Default. Default: 60.0.

- **`--step_5_identify_mechanism_of_action_liftover_cloudos_instance_disk_space`**: Job instance disk space. Default: 1000.

- **`--step_5_identify_mechanism_of_action_liftover_cloudos_nextflow_profile`**: Nextflow profile to use. Default: `false`.

- **`--step_5_identify_mechanism_of_action_liftover_cloudos_instance_type`**: Job instance type. Default: "c5.xlarge".

- **`--step_5_identify_mechanism_of_action_liftover_cloudos_queue_name`**: Job queue. Default: `"${params.cloudos_queue_name}"`.

- **`--step_5_identify_mechanism_of_action_liftover_cloudos_wait_time`**: Job wait time. Default: 20000.

- **`--step_5_identify_mechanism_of_action_liftover_vcf`**: Path to input file containing summary-level GWAS summary statics in GWAS VCF format. From the output of step 1c. If provided, will overwrite step 1c. If provided, will overwrite the output from step 1c. Default: `false`.

- **`--step_5_identify_mechanism_of_action_liftover_crossmap_preprocess`**: CrossMap does not support copy number variants or multiallelic variants represented in a single row in VCF files. This step runs bcftools to split multiallelic variants and remove copy number variants prior to performing liftover. Default: `true`.

- **`--step_5_identify_mechanism_of_action_liftover_collapse_multiallelics_in_output`**: This optional process collapses multiallelic variants back into a single row. Default: `true`.

- **`--step_5_identify_mechanism_of_action_liftover_reference_fasta_original`**: Path to FASTA reference file, corresponding to genome build of original data. Default: `false`.

- **`--step_5_identify_mechanism_of_action_liftover_fasta_index_original`**: Path to FASTA .fai index, corresponding to the file supplied via `--reference_fasta_original`. Default: `false`.

- **`--step_5_identify_mechanism_of_action_liftover_fasta_chr_name_map_original`**: Path to chromosome name mapping file, corresponding to genome build of original data, or 'false' to set no mapping file to be used. Default: `true`.

- **`--step_5_identify_mechanism_of_action_liftover_reference_fasta_target`**: Path to FASTA reference file, corresponding to target genome build. Default: `false`.

- **`--step_5_identify_mechanism_of_action_liftover_no_comp_alleles`**: Do not check if old ALT allele == new REF allele during liftover. Default: `false`.

- **`--step_5_identify_mechanism_of_action_liftover_map_warn_pct`**: Threshold for warning of low successful mapping percentage in the HTML report. Default: 0.95.

- **`--step_5_identify_mechanism_of_action_liftover_chunk_size`**: For scatter-gather on very large VCF files (>10 million variants - greater gains in performance on HPC likely). Default: `false`.

- **`--step_5_identify_mechanism_of_action_liftover_reference_data_bucket`**: Prefix of the S3 bucket path. Default: "s3://gel-lifebit-featured-datasets".

#### Finemapping

- **`--step_5_identify_mechanism_of_action_finemapping_cloudos_workflow_name`**: Workflow name in CloudOS. Default: "finemapping-nf".

- **`--step_5_identify_mechanism_of_action_finemapping_cloudos_job_name`**: Job name in CloudOS, combination of step name and workflow name. Default: `"step_5_identify_mechanism_of_action:${params.data_source}-${params.phenotype_group}-${params.phenotype_label}:${step_5_identify_mechanism_of_action_finemapping_cloudos_workflow_name}"`.

- **`--step_5_identify_mechanism_of_action_finemapping_cloudos_cost_limit`**: Job cost limit: Default. 60.0.

- **`--step_5_identify_mechanism_of_action_finemapping_cloudos_instance_disk_space`**: Job instance disk space. Default: 1500.

- **`--step_5_identify_mechanism_of_action_finemapping_cloudos_nextflow_profile`**: Nextflow profile to use. Default: `false`.

- **`--step_5_identify_mechanism_of_action_finemapping_cloudos_instance_type`**: Job instance type. Default: "c5.4xlarge".

- **`--step_5_identify_mechanism_of_action_finemapping_cloudos_queue_name`**: Job queue. Default: `"${params.cloudos_queue_name}"`.

- **`--step_5_identify_mechanism_of_action_finemapping_cloudos_wait_time`**: Job wait time. Default: 20000.

- **`--step_5_identify_mechanism_of_action_finemapping_git_tag`**: Branch of the workflow to run. Default: "dev".

- **`--step_5_identify_mechanism_of_action_finemapping_gwas_vcf`**: Path to GWAS summary statistics file. Will automatically get the output from step 5 liftover. If provided, will overwrite it. Default: `false`.

- **`--step_5_identify_mechanism_of_action_finemapping_ld_score_weights_annotation_files`**: This parameter allows to auto-populate `annotations` and `weights` parameters from the `finemapping-nf`. Option `UKB` will use functional annotations for ~19 million UK Biobank imputed SNPs with MAF>0.1%, based on the baseline-LF 2.2.UKB annotations, provided by PolyFun and option`test` will use a small subset of UK Biobank annotations and weights (**to be used only for testing**). Default: "UKB".

- **`--step_5_identify_mechanism_of_action_finemapping_polyfun`**: Determines whether PolyFun is used for computing prior causal probabilities. Default: `true`.

- **`--step_5_identify_mechanism_of_action_finemapping_polyfun_pvalue_thr`**: P-value used to finemap only around significant regions when the Polyfun method is used. Default: "5e-05".

- **`--step_5_identify_mechanism_of_action_finemapping_liftover`**: Liftover Polyfun results to GRCh38. Default: `false`.

- **`--step_5_identify_mechanism_of_action_finemapping_reference_data_bucket`**: Prefix of the S3 bucket path. Default: "s3://gel-lifebit-featured-datasets".

#### Cheers (tissue enrichment)

- **`--step_5_identify_mechanism_of_action_cheers_cloudos_workflow_name`**: Workflow name in CloudOS. Default: "tissue_enrichment-nf".

- **`--step_5_identify_mechanism_of_action_cheers_cloudos_job_name`**: Job name in CloudOS, combination of step name and workflow name. Default: `"step_5_identify_mechanism_of_action:${params.data_source}-${params.phenotype_group}-${params.phenotype_label}:${step_5_identify_mechanism_of_action_cheers_cloudos_workflow_name}"`.

- **`--step_5_identify_mechanism_of_action_cheers_cloudos_cost_limit`**: Job cost limit: Default. `false`.

- **`--step_5_identify_mechanism_of_action_cheers_cloudos_instance_disk_space`**: Job instance disk space. Default: `false`.

- **`--step_5_identify_mechanism_of_action_cheers_cloudos_nextflow_profile`**: Nextflow profile to use. Default: `false`.

- **`--step_5_identify_mechanism_of_action_cheers_cloudos_instance_type`**: Job instance type. Default: `false`.

- **`--step_5_identify_mechanism_of_action_cheers_cloudos_queue_name`**: Job queue. Default: `"${params.cloudos_queue_name}"`.

- **`--step_5_identify_mechanism_of_action_cheers_cloudos_wait_time`**: Job wait time. Default: `false`.

- **`--step_5_identify_mechanism_of_action_cheers_git_tag`**: Branch of the workflow to run. Default: "dev".

- **`--step_5_identify_mechanism_of_action_cheers_trait_name`**: The trait name that will be used to label the output. Default: "CHEERS".

- **`--step_5_identify_mechanism_of_action_cheers_input_snp_type`**: Type of input that contains the list of SNPs to analyse. This can be either "list_snps" or "polyfun" depending whether a list of SNPs is provided as input or if a path pointing to the output of the finemapping-nf pipeline with polyfun option is given. Default: "polyfun".

- **`--step_5_identify_mechanism_of_action_cheers_input_peaks`**: This is a matrix in txt format containing the normalised peak annotation from a ATAC-seq or a CHIP-Seq study. Default: "s3://gel-lifebit-featured-datasets/pipelines/Tissue_enrichment/CHEERS_tissues_references/DHS_counts_normToMax_quantileNorm_euclideanNorm_35ts_grch37.txt".

- **`--step_5_identify_mechanism_of_action_cheers_snp_list`**: This can be a simple list of SNPs in a file if the "list_snps" is given from the parameter above; Otherwise the path containing the output from a finemapping-nf pipeline run with the "polyfun" option can be given. Default: `false`.

- **`--step_5_identify_mechanism_of_action_cheers_PIP`**: Posterior inclusion probability to use when filtering credible sets after finemapping. Default: "0.05".

- **`--step_5_identify_mechanism_of_action_cheers_reference_data_bucket`**: Prefix of the S3 bucket path. Default: "s3://gel-lifebit-featured-datasets".

### Step 6

#### Gene set enrichement

- **`--step_6_identify_candidate_drugs_gsea_cloudos_workflow_name`**: Workflow name in CloudOS. Default: "geneset-enrichment-analysis-nf".

- **`--step_6_identify_candidate_drugs_gsea_cloudos_job_name`**: Job name in CloudOS, combination of step name and workflow name. Default: `"step_6_identify_candidate_drugs:${params.data_source}-${params.phenotype_group}-${params.phenotype_label}:${step_6_identify_candidate_drugs_gsea_cloudos_workflow_name}"`.

- **`--step_6_identify_candidate_drugs_gsea_cloudos_cost_limit`**: Job cost limit: Default. `false`.

- **`--step_6_identify_candidate_drugs_gsea_cloudos_instance_disk_space`**: Job instance disk space. Default: `false`.

- **`--step_6_identify_candidate_drugs_gsea_cloudos_nextflow_profile`**: Nextflow profile to use. Default: `false`.

- **`--step_6_identify_candidate_drugs_gsea_cloudos_instance_type`**: Job instance type. Default: `false`.

- **`--step_6_identify_candidate_drugs_gsea_cloudos_queue_name`**: Job queue. Default: `"${params.cloudos_queue_name}"`.

- **`--step_6_identify_candidate_drugs_gsea_cloudos_wait_time`**: Job wait time. Default: `false`.

- **`--step_6_identify_candidate_drugs_gsea_git_tag`**: Branch of the workflow to run. Default: "dev".

- **`--step_6_identify_candidate_drugs_gsea_summary_stats`**: A SummaryStats file from GWAS study. From the output of step 1c. If provided, will overwrite step 1c. If provided, will overwrite the output from step 1c. Default: `false`.

- **`--step_6_identify_candidate_drugs_gsea_snp_col_name`**: Column name from SummaryStats file in which SNP ids present. Default: "SNPID".

- **`--step_6_identify_candidate_drugs_gsea_pval_col_name`**: Column name from SummaryStats file in which P-values present. Default: "p.value".

- **`--step_6_identify_candidate_drugs_gsea_ref_panel_plink`**: Reference panel plink files. Default: "s3://gel-lifebit-featured-datasets/pipelines/gwasgsa/reference/g1000_eur/g1000_eur.{bed,bim,fam}".

- **`--step_6_identify_candidate_drugs_gsea_ref_panel_synonyms`**: Reference panel synonyms file. Default: "s3://gel-lifebit-featured-datasets/pipelines/gwasgsa/reference/g1000_eur/g1000_eur.synonyms".

- **`--step_6_identify_candidate_drugs_gsea_gene_loc_file`**: Gene-SNP mapped Location file (This can be downloaded from MAGMA homepage). Default: "s3://gel-lifebit-featured-datasets/pipelines/gwasgsa/testdata/NCBI37.3/NCBI37.3.gene.loc".

- **`--step_6_identify_candidate_drugs_gsea_set_anot_file`**: A SET file (Ex. A .gmt file, check MSigDB). Default: "s3://gel-lifebit-featured-datasets/pipelines/gwasgsa/msigdb/c2.cp.reactome.v7.2.entrez.gmt".

- **`--step_6_identify_candidate_drugs_gsea_reference_data_bucket`**: Prefix of the S3 bucket path. Default: "s3://gel-lifebit-featured-datasets".

#### Drug2ways

- **`--step_6_identify_candidate_drugs_drug2ways_cloudos_workflow_name`**: Workflow name in CloudOS. Default: "drug-two-ways-nf".

- **`--step_6_identify_candidate_drugs_drug2ways_cloudos_job_name`**: Job name in CloudOS, combination of step name and workflow name. Default: `"step_6_identify_candidate_drugs:${params.data_source}-${params.phenotype_group}-${params.phenotype_label}:${step_6_identify_candidate_drugs_drug2ways_cloudos_workflow_name}"`.

- **`--step_6_identify_candidate_drugs_drug2ways_cloudos_cost_limit`**: Job cost limit: Default. `false`.

- **`--step_6_identify_candidate_drugs_drug2ways_cloudos_instance_disk_space`**: Job instance disk space. Default: `false`.

- **`--step_6_identify_candidate_drugs_drug2ways_cloudos_nextflow_profile`**: Nextflow profile to use. Default: `false`.

- **`--step_6_identify_candidate_drugs_drug2ways_cloudos_instance_type`**: Job instance type. Default: `false`.

- **`--step_6_identify_candidate_drugs_drug2ways_cloudos_queue_name`**: Job queue. Default: `"${params.cloudos_queue_name}"`.

- **`--step_6_identify_candidate_drugs_drug2ways_cloudos_wait_time`**: Job wait time. Default: `false`.

- **`--step_6_identify_candidate_drugs_drug2ways_git_tag`**: Branch of the workflow to run. Default: "dev".

- **`--step_6_identify_candidate_drugs_drug2ways_targets`**: This is a path to a tsv file containing a list of nodes considered as conditions/phenotypes molecules. Default: `false`.

- **`--step_6_identify_candidate_drugs_drug2ways_omnipathr_container`**: Omnipath R Docker container. Default: "quay.io/lifebitaiorg/omnipathr-db:v1.1.0-dbdev".

- **`--step_6_identify_candidate_drugs_drug2ways_get_drugs`**: Derive drugs from DrugBank if DrugBank available. Default: `true`.

- **`--step_6_identify_candidate_drugs_drug2ways_network`**: Input tsv of interaction/relation network. Default: `false`.

- **`--step_6_identify_candidate_drugs_drug2ways_lmax`**: Maximum length of pathways. Default: 6.

- **`--step_6_identify_candidate_drugs_drug2ways_reference_data_bucket`**: Prefix of the S3 bucket path. Default: "s3://gel-lifebit-featured-datasets".

<!-- For Sphinx doc, This option will be auto rendered help() section from Nextflow main.nf in the doc build -->


<!------------------
Build of this doc in github handle by - .github/workflows/build-deploy-doc.yml

To build this doc locally follow these steps.

Needs to have installed - 
1. sphinx
2. sphinx-rtd-theme
3. nextflow

Supposing your currently in base directory of the pipeline -
```
cd docs && bash src/pre-build.sh
cp README.md src
cd src && make html 
```
index.html will be generated in `docs/src/build/html` folder
-->