process trigger_step_3_identify_causal_genes_and_pathways {
    label "cloudos"

    input:
    val harmonised_gwas_vcf
    val project_name

    output:
    env STEP_3_JOB_ID, emit: ch_step_3_job_id 

    script:
    harmonised_data = params.step_3_identify_causal_genes_and_pathways_joint_xqtl_gwas_vcf ?: harmonised_gwas_vcf
    """
    cloudos job run \
        --cloudos-url "${params.cloudos_url}" \
        --apikey "${params.cloudos_api_key}" \
        --workspace-id "${params.cloudos_workspace_id}" \
        --project-name "${project_name}" \
        --workflow-name "${params.step_3_identify_causal_genes_and_pathways_cloudos_workflow_name}" \
        --git-tag "${params.step_3_identify_causal_genes_and_pathways_joint_xqtl_git_tag}" \
        --job-name "${params.step_3_identify_causal_genes_and_pathways_cloudos_job_name}" \
        -p "gwas_vcf=$harmonised_data" \
        -p "ld_ref_data=${params.step_3_identify_causal_genes_and_pathways_joint_xqtl_ld_ref_data}" \
        -p "besd_list=${params.step_3_identify_causal_genes_and_pathways_joint_xqtl_besd_list}" \
        -p "reference_data_bucket=${params.step_3_identify_causal_genes_and_pathways_joint_xqtl_reference_data_bucket}" \
        --resumable \
        --wait-time ${params.step_3_identify_causal_genes_and_pathways_cloudos_wait_time} \
        --instance-type "${params.step_3_identify_causal_genes_and_pathways_cloudos_instance_type}" \
        --batch \
        --job-queue "${params.step_3_identify_causal_genes_and_pathways_cloudos_queue_name}" \
        --disable-ssl-verification \
        --wait-completion | tee job_status_step_3.txt

    STEP_3_JOB_ID=\$(grep -e "Your assigned job id is" job_status_step_3.txt | rev | cut -d " " -f 1 | rev)
    """
}