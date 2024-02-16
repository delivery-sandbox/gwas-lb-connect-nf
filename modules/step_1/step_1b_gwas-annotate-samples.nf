process trigger_step_1b_gwas_annotate_samples {
    label "cloudos"

    input:
    val plink_sex_chr
    val pgen_ld_pruned
    val project_name
    val project_bucket
    val workspace_id
    val end_to_end_job_id


    output:
    env PCA_OUT, emit: ch_pca_out


    script:
    plink_sex_chr_data = params.step_1b_gwas_annotate_samples_plink_sex_chr ? params.step_1b_gwas_annotate_samples_plink_sex_chr : plink_sex_chr
    pgen_ld_pruned_data = params.step_1b_gwas_annotate_samples_pgen_ld_pruned ? params.step_1b_gwas_annotate_samples_pgen_ld_pruned : pgen_ld_pruned

    """
    cloudos job run \
        --cloudos-url "${params.cloudos_url}" \
        --apikey "${params.cloudos_api_key}" \
        --workspace-id "${workspace_id}" \
        --project-name "${project_name}" \
        --workflow-name "${params.step_1b_gwas_annotate_samples_cloudos_workflow_name}" \
        --job-name "${params.step_1b_gwas_annotate_samples_cloudos_job_name.replaceAll( / /, '_').replaceAll( /-/, '_').replaceAll(/:/, '_')}" \
        -p "annotate_with_rsids=${params.step_1b_gwas_annotate_samples_annotate_with_rsids}" \
        -p "run_pca=${params.step_1b_gwas_annotate_samples_run_pca}" \
        -p "plink_sex_chr=${plink_sex_chr_data}" \
        -p "pgen_ld_pruned=${pgen_ld_pruned_data}" \
        -p "sex_check=${params.step_1b_gwas_annotate_samples_sex_check}" \
        -p "king_coefficient=${params.step_1b_gwas_annotate_samples_king_coefficient}" \
        -p "remove_het_miss_outliers=${params.step_1b_gwas_annotate_samples_remove_het_miss_outliers}" \
        -p "het_std_exclusion_threshold=${params.step_1b_gwas_annotate_samples_het_std_exclusion_threshold}" \
        -p "miss_exclusion_threshold=${params.step_1b_gwas_annotate_samples_miss_exclusion_threshold}" \
        -p "run_ancestry_inference=${params.step_1b_gwas_annotate_samples_run_ancestry_inference}" \
        -p "ancestry_labels=${params.step_1b_gwas_annotate_samples_ancestry_labels}" \
        -p "min_subpop_size=${params.step_1b_gwas_annotate_samples_min_subpop_size}" \
        -p "ancestry_name=${params.step_1b_gwas_annotate_samples_ancestry_name}" \
        -p "number_pcs=${params.step_1b_gwas_annotate_samples_number_pcs}" \
        -p "remove_outliers_sigma=${params.step_1b_gwas_annotate_samples_remove_outliers_sigma}" \
        -p "minimum_number_of_vars=${params.step_1b_gwas_annotate_samples_minimum_number_of_vars}" \
        -p "remove_related_samples=${params.step_1b_gwas_annotate_samples_remove_related_samples}" \
        -p "reference_data_bucket=${params.step_1b_gwas_annotate_samples_reference_data_bucket}" \
        --git-commit "${params.step_1b_gwas_annotate_samples_git_commit}" \
        --resumable \
        --cost-limit ${params.step_1b_gwas_annotate_samples_cloudos_cost_limit} \
        --wait-time ${params.step_1b_gwas_annotate_samples_cloudos_wait_time} \
        --batch \
        --job-queue "${params.cloudos_queue_name}" \
        --disable-ssl-verification \
        --wait-completion | tee job_status_gwas.txt

    # Check job status to fail early
    job_status=\$(tail -1 job_status_gwas.txt | rev | cut -d " " -f 1 | rev)

    GWAS_JOB_ID=\$(grep -e "Your assigned job id is" job_status_gwas.txt | rev | cut -d " " -f 1 | rev)
    PCA_OUT="${project_bucket}/\$GWAS_JOB_ID/results/results/${ancestry_group}/pca/pca_results_final.eigenvec"

    if [ \$job_status = "completed" ]; then
        echo "Your job finished successfully."
    else
        echo "[ERROR] Your job did not finish successfully."
        GWAS_OUT=false
        exit 0
    fi
    """
}