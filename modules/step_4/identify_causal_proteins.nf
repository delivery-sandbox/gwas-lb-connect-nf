process trigger_step_4_identify_causal_proteins {
    label "cloudos"

    input:
    val harmonised_gwas_vcf
    val project_name

    output:
    env STEP_4_JOB_ID, emit: ch_step_4_job_id 

    script:
    harmonised_data = params.step_4_identify_causal_proteins_xqtlbiolinks_gwas_vcf ?: harmonised_gwas_vcf
    """
    cloudos job run \
        --cloudos-url "${params.cloudos_url}" \
        --apikey "${params.cloudos_api_key}" \
        --workspace-id "${params.cloudos_workspace_id}" \
        --project-name "${project_name}" \
        --workflow-name "${params.step_4_identify_causal_proteins_cloudos_workflow_name}" \
        --git-tag "${params.step_4_identify_causal_proteins_xqtlbiolinks_git_tag}" \
        --job-name "${params.step_4_identify_causal_proteins_cloudos_job_name}" \
        -p "gwas_vcf=$harmonised_data" \
        -p "reference_data_bucket=${params.step_4_identify_causal_proteins_xqtlbiolinks_reference_data_bucket}" \
        --resumable \
        --wait-time ${params.step_4_identify_causal_proteins_cloudos_wait_time} \
        --batch \
        --job-queue "${params.step_4_identify_causal_proteins_cloudos_queue_name}" \
        --disable-ssl-verification \
        --wait-completion | tee job_status_step_4.txt

    STEP_4_JOB_ID=\$(grep -e "Your assigned job id is" job_status_step_4.txt | rev | cut -d " " -f 1 | rev)
    """
}