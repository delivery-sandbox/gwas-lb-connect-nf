process trigger_step_1c_identify_genetic_associations_harmonisation {
    label "cloudos"

    input:
    val gwas
    val project_name
    val project_bucket

    output:
    env HARMONISATION_OUT, emit: ch_harmonisation_out
    env HARMONISATION_JOB_ID, emit: ch_step_1c_job_id 

    script:
    gwas_data = params.step_1c_identify_genetic_associations_harmonisation_input ?: gwas
    """
    cloudos job run \
        --cloudos-url "${params.cloudos_url}" \
        --apikey "${params.cloudos_api_key}" \
        --workspace-id "${params.cloudos_workspace_id}" \
        --project-name "${project_name}" \
        --workflow-name "${params.step_1c_identify_genetic_associations_harmonisation_cloudos_workflow_name}" \
        --job-name "${params.step_1c_identify_genetic_associations_harmonisation_cloudos_job_name}" \
        -p "input=$gwas_data" \
        -p "gwas_source=${params.step_1c_identify_genetic_associations_harmonisation_gwas_source}" \
        -p "input_type=${params.step_1c_identify_genetic_associations_harmonisation_input_type}" \
        -p "standardise=${params.step_1c_identify_genetic_associations_harmonisation_standardise}" \
        -p "coef_conversion=${params.step_1c_identify_genetic_associations_harmonisation_coef_conversion}" \
        -p "keep_intermediate_files=${params.step_1c_identify_genetic_associations_harmonisation_keep_intermediate_files}" \
        -p "filter_beta_smaller_than=${params.step_1c_identify_genetic_associations_harmonisation_filter_beta_smaller_than}" \
        -p "filter_beta_greater_than=${params.step_1c_identify_genetic_associations_harmonisation_filter_beta_greater_than}" \
        -p "filter_LP_smaller_than=${params.step_1c_identify_genetic_associations_harmonisation_filter_LP_smaller_than}" \
        -p "filter_freq_smaller_than=${params.step_1c_identify_genetic_associations_harmonisation_filter_freq_smaller_than}" \
        -p "filter_freq_greater_than=${params.step_1c_identify_genetic_associations_harmonisation_filter_freq_greater_than}" \
        -p "convert_to_hail=${params.step_1c_identify_genetic_associations_harmonisation_convert_to_hail}" \
        -p "dbsnp=${params.step_1c_identify_genetic_associations_harmonisation_dbsnp}" \
        -p "reference_data_bucket=${params.step_1c_identify_genetic_associations_harmonisation_reference_data_bucket}" \
        --resumable \
        --wait-time ${params.step_1c_identify_genetic_associations_harmonisation_cloudos_wait_time} \
        --batch \
        --job-queue "${params.step_1c_identify_genetic_associations_harmonisation_cloudos_queue_name}" \
        --disable-ssl-verification \
        --wait-completion | tee job_status_harmonisation.txt

    # Check job status to fail early
    job_status=\$(tail -1 job_status_harmonisation.txt | rev | cut -d " " -f 1 | rev)
    if [ \$job_status = "completed" ]; then
        echo "Your job finished successfully."
    else
        echo "[ERROR] Your job did not finish successfully."
        exit 1
    fi

    HARMONISATION_JOB_ID=\$(grep -e "Your assigned job id is" job_status_harmonisation.txt | rev | cut -d " " -f 1 | rev)
    HARMONISATION_OUT="${project_bucket}/\$HARMONISATION_JOB_ID/results/results/harmonised/*.harmonised.gwas.vcf"
    """
}