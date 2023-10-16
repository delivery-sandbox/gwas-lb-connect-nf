process trigger_step_2_identify_prioritised_genes {
    label "cloudos"

    input:
    val harmonised_gwas_vcf
    val project_name
    val workspace_id

    output:
    env STEP_2_JOB_ID, emit: ch_step_2_job_id 

    script:
    harmonised_data = params.step_2_identify_prioritised_genes_variant_to_gene_gwas_vcf ?: harmonised_gwas_vcf
    """
    cloudos job run \
        --cloudos-url "${params.cloudos_url}" \
        --apikey "${params.cloudos_api_key}" \
        --workspace-id "${workspace_id}" \
        --project-name "${project_name}" \
        --workflow-name "${params.step_2_identify_prioritised_genes_cloudos_workflow_name}" \
        --git-tag "${params.step_2_identify_prioritised_genes_variant_to_gene_git_tag}" \
        --job-name "${params.step_2_identify_prioritised_genes_cloudos_job_name}" \
        -p "gcta_smr=${params.step_2_identify_prioritised_genes_variant_to_gene_gcta_smr}" \
        -p "closest_genes=${params.step_2_identify_prioritised_genes_variant_to_gene_closest_genes}" \
        -p "metaxcan=${params.step_2_identify_prioritised_genes_variant_to_gene_metaxcan}" \
        -p "gwas_vcf=$harmonised_data" \
        -p "plink_data=${params.step_2_identify_prioritised_genes_variant_to_gene_plink_data}" \
        -p "besd_data=${params.step_2_identify_prioritised_genes_variant_to_gene_besd_data}" \
        -p "diff_freq_prop=${params.step_2_identify_prioritised_genes_variant_to_gene_diff_freq_prop}" \
        --resumable \
        --wait-time ${params.step_2_identify_prioritised_genes_cloudos_wait_time} \
        --batch \
        --job-queue "${params.cloudos_queue_name}" \
        --disable-ssl-verification \
        --wait-completion | tee job_status_step_2.txt

    STEP_2_JOB_ID=\$(grep -e "Your assigned job id is" job_status_step_2.txt | rev | cut -d " " -f 1 | rev)
    """
}