process trigger_step_1b_identify_genetic_associations_gwas {
    label "cloudos"

    input:
    val phenofile
    val genotype_files_list
    val project_name
    val project_bucket
    val workspace_id


    output:
    env GWAS_OUT, emit: ch_gwas_out
    env GWAS_JOB_ID, emit: ch_step_1b_job_id 


    script:
    pheno_data = params.step_1b_identify_genetic_associations_gwas_pheno_data ? params.step_1b_identify_genetic_associations_gwas_pheno_data : phenofile
    """
    cloudos job run \
        --cloudos-url "${params.cloudos_url}" \
        --apikey "${params.cloudos_api_key}" \
        --workspace-id "${workspace_id}" \
        --project-name "${project_name}" \
        --workflow-name "${params.step_1b_identify_genetic_associations_gwas_cloudos_workflow_name}" \
        --job-name "${params.step_1b_identify_genetic_associations_gwas_cloudos_job_name}" \
        -p "genotype_format=${params.step_1b_identify_genetic_associations_gwas_genotype_format}" \
        -p "genotype_files_list=$genotype_files_list" \
        -p "genome_build=${params.step_1b_identify_genetic_associations_gwas_genome_build}" \
        -p "annotate_with_rsids=${params.step_1b_identify_genetic_associations_gwas_annotate_with_rsids}" \
        -p "king_reference_data=${params.step_1b_identify_genetic_associations_gwas_king_reference_data}" \
        -p "high_LD_long_range_regions=${params.step_1b_identify_genetic_associations_gwas_high_LD_long_range_regions}" \
        -p "rsid_cpra_table=${params.step_1b_identify_genetic_associations_gwas_rsid_cpra_table}" \
        -p "saige=${params.step_1b_identify_genetic_associations_gwas_saige}" \
        -p "regenie=${params.step_1b_identify_genetic_associations_gwas_regenie}" \
        -p "run_pca=${params.step_1b_identify_genetic_associations_gwas_run_pca}" \
        -p "pheno_data=$pheno_data" \
        -p "phenotype_colname=${params.step_1b_identify_genetic_associations_gwas_phenotype_colname}" \
        -p "mind_threshold=${params.step_1b_identify_genetic_associations_gwas_mind_threshold}" \
        -p "miss=${params.step_1b_identify_genetic_associations_gwas_miss}" \
        -p "miss_test_p_threshold=${params.step_1b_identify_genetic_associations_gwas_miss_test_p_threshold}" \
        -p "sex_check=${params.step_1b_identify_genetic_associations_gwas_sex_check}" \
        -p "remove_related_samples=${params.step_1b_identify_genetic_associations_gwas_remove_related_samples}" \
        -p "reference_data_bucket=${params.step_1b_identify_genetic_associations_gwas_reference_data_bucket}" \
        --resumable \
        --wait-time ${params.step_1b_identify_genetic_associations_gwas_cloudos_wait_time} \
        --batch \
        --job-queue "${params.cloudos_queue_name}" \
        --disable-ssl-verification \
        --wait-completion | tee job_status_gwas.txt

    # Check job status to fail early
    job_status=\$(tail -1 job_status_gwas.txt | rev | cut -d " " -f 1 | rev)
    if [ \$job_status = "completed" ]; then
        echo "Your job finished successfully."
    else
        echo "[ERROR] Your job did not finish successfully."
        exit 1
    fi

    GWAS_JOB_ID=\$(grep -e "Your assigned job id is" job_status_gwas.txt | rev | cut -d " " -f 1 | rev)
    GWAS_OUT="${project_bucket}/\$GWAS_JOB_ID/results/results/*/*/regenie/*-regenie_firth*.regenie"
    """
}