process trigger_step_1b_gwas {
    label "cloudos"

    input:
    val phenofile
    val genotype_data
    val geno_step1_pca
    val eigenvec_file
    val project_name
    val project_bucket
    val workspace_id
    val end_to_end_job_id


    output:
    env GWAS_OUT, emit: ch_gwas_out
    env GWAS_JOB_ID, emit: ch_step_1b_job_id 


    script:
    pheno_data = params.step_1b_gwas_pheno_data ? params.step_1b_gwas_pheno_data : phenofile
    genotype_data = params.step_1b_gwas_merged_pgen ? params.step_1b_gwas_merged_pgen : genotype_data
    geno_step1_pca = params.step_1b_gwas_geno_step1_pca ? params.step_1b_gwas_geno_step1_pca : geno_step1_pca
    eigenvec_file = params.step_1b_gwas_eigenvec_file ? params.step_1b_gwas_eigenvec_file : eigenvec_file


    """
    cloudos job run \
        --cloudos-url "${params.cloudos_url}" \
        --apikey "${params.cloudos_api_key}" \
        --workspace-id "${workspace_id}" \
        --project-name "${project_name}" \
        --workflow-name "${params.step_1b_gwas_cloudos_workflow_name}" \
        --job-name "${params.step_1b_gwas_cloudos_job_name.replaceAll( / /, '_').replaceAll( /-/, '_').replaceAll(/:/, '_')}" \
        --git-commit "${params.step_1b_gwas_git_commit}" \
        --resumable \
        --cost-limit ${params.step_1b_gwas_cloudos_cost_limit} \
        --wait-time ${params.step_1b_gwas_cloudos_wait_time} \
        --batch \
        --job-queue "${params.cloudos_queue_name}" \
        --disable-ssl-verification \
        --wait-completion | tee job_status_gwas.txt \
        -p "pheno_data=$pheno_data" \
        -p "phenotype_colname=${params.step_1b_gwas_phenotype_colname.replaceAll( / /, '_')}" \
        -p "transform_pheno=${params.step_1b_gwas_transform_pheno}" \
        -p "ancestry_group=${params.step_1b_gwas_ancestry_group}" \
        -p "sex_colname=${params.step_1b_gwas_sex_colname}" \
        -p "geno_step1_pca=${geno_step1_pca}" \
        -p "overwrite_var_ids=${params.step_1b_gwas_overwrite_var_ids}" \
        -p "regenie_min_imputation_score=${params.step_1b_gwas_regenie_min_imputation_score}" \
        -p "regenie_min_mac=${params.step_1b_gwas_regenie_min_mac}" \
        -p "regenie_geno_model=${params.step_1b_gwas_regenie_geno_model}" \
        -p "regenie_step1_bsize=${params.step_1b_gwas_regenie_step1_bsize}" \
        -p "regenie_step2_bsize=${params.step_1b_gwas_regenie_step2_bsize}" \
        -p "pheno_data=${params.step_1b_gwas_pheno_data}" \
        -p "force_step1=${params.step_1b_gwas_force_step1}" \
        -p "covariate_cols=${params.step_1b_gwas_covariate_cols}" \
        -p "phenotype_colname=${params.step_1b_gwas_phenotype_colname}" \
        -p "pheno_transform=${params.step_1b_gwas_pheno_transform}" \
        -p "gwastrait_type=${params.step_1b_gwas_gwastrait_type}" \
        -p "gwas_tag=${params.step_1b_gwas_gwas_tag}" \
        -p "ancestry_name=${params.step_1b_gwas_ancestry_name}" \
        -p "eigenvec_file=${eigenvec_file}" \
        -p "merged_pgen=${params.step_1b_gwas_merged_pgen}" \
        -p "reference_data_bucket=${params.step_1b_gwas_reference_data_bucket}"

    # Check job status to fail early
    job_status=\$(tail -1 job_status_gwas.txt | rev | cut -d " " -f 1 | rev)

    GWAS_JOB_ID=\$(grep -e "Your assigned job id is" job_status_gwas.txt | rev | cut -d " " -f 1 | rev)
    GWAS_OUT="${project_bucket}/\$GWAS_JOB_ID/results/results/*/*/regenie/*-regenie_firth*.regenie"

    if [ \$job_status = "completed" ]; then
        echo "Your job finished successfully."
    else
        echo "[ERROR] Your job did not finish successfully."
        GWAS_OUT=false
        exit 0
    fi
    """
}