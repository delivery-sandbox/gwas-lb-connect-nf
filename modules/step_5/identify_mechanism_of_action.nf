process trigger_step_5_identify_mechanism_of_action_liftover {
    label "cloudos"
    tag "GRCh38->GRCh37"

    input:
    val harmonised_gwas_vcf
    val project_name
    val project_bucket
    val workspace_id

    output:
    env GWAS_HARMONISED_VCF_LIFTOVERED, emit: ch_liftovered_gwas_vcf
    env LIFTOVER_JOB_ID, emit: ch_liftover_job_id 

    script:
    harmonised_data = params.step_5_identify_mechanism_of_action_liftover_vcf ?: harmonised_gwas_vcf
    """
    # LIFTOVER
    cloudos job run \
        --cloudos-url "${params.cloudos_url}" \
        --apikey "${params.cloudos_api_key}" \
        --workspace-id "${workspace_id}" \
        --project-name "${project_name}" \
        --workflow-name "${params.step_5_identify_mechanism_of_action_liftover_cloudos_workflow_name}" \
        --job-name "${params.step_5_identify_mechanism_of_action_liftover_cloudos_job_name.replaceAll( / /, '_').replaceAll( /-/, '_').replaceAll(/:/, '_')}" \
        -p "vcf=$harmonised_data" \
        -p "liftover_from_to=GRCh38->GRCh37" \
        -p "crossmap_preprocess=${params.step_5_identify_mechanism_of_action_liftover_crossmap_preprocess}" \
        -p "collapse_multiallelics_in_output=${params.step_5_identify_mechanism_of_action_liftover_collapse_multiallelics_in_output}" \
        -p "reference_fasta_original=${params.step_5_identify_mechanism_of_action_liftover_reference_fasta_original}" \
        -p "fasta_index_original=${params.step_5_identify_mechanism_of_action_liftover_fasta_index_original}" \
        -p "fasta_chr_name_map_original=${params.step_5_identify_mechanism_of_action_liftover_fasta_chr_name_map_original}" \
        -p "reference_fasta_target=${params.step_5_identify_mechanism_of_action_liftover_reference_fasta_target}" \
        -p "no_comp_alleles=${params.step_5_identify_mechanism_of_action_liftover_no_comp_alleles}" \
        -p "map_warn_pct=${params.step_5_identify_mechanism_of_action_liftover_map_warn_pct}" \
        -p "chunk_size=${params.step_5_identify_mechanism_of_action_liftover_chunk_size}" \
        -p "reference_data_bucket=${params.step_5_identify_mechanism_of_action_liftover_reference_data_bucket}" \
        --resumable \
        --wait-time ${params.step_5_identify_mechanism_of_action_liftover_cloudos_wait_time} \
        --cost-limit ${params.step_5_identify_mechanism_of_action_liftover_cloudos_cost_limit} \
        --instance-disk ${params.step_5_identify_mechanism_of_action_liftover_cloudos_instance_disk_space} \
        --instance-type "${params.step_5_identify_mechanism_of_action_liftover_cloudos_instance_type}" \
        --batch \
        --job-queue "${params.cloudos_queue_name}" \
        --disable-ssl-verification \
        --wait-completion | tee job_status_liftover.txt

    # Check job status to fail early
    job_status=\$(tail -1 job_status_liftover.txt | rev | cut -d " " -f 1 | rev)
    if [ \$job_status = "completed" ]; then
        echo "Your job finished successfully."
    else
        echo "[ERROR] Your job did not finish successfully."
        exit 1
    fi

    LIFTOVER_JOB_ID=\$(grep -e "Your assigned job id is" job_status_liftover.txt | rev | cut -d " " -f 1 | rev)
    GWAS_HARMONISED_VCF_LIFTOVERED="${project_bucket}/\$LIFTOVER_JOB_ID/results/results/*_GRCh37_liftover_pass.vcf.gz"
    """
}

process trigger_step_5_identify_mechanism_of_action_finemapping {
    label "cloudos"

    input:
    val liftovered_gwas_vcf
    val project_name
    val project_bucket
    val workspace_id

    output:
    env FINEMAPPING_OUT, emit: ch_finemapping_out
    env FINEMAPPING_JOB_ID, emit: ch_finemapping_job_id

    script:
    """
    # FINEMAPPING
    cloudos job run \
        --cloudos-url "${params.cloudos_url}" \
        --apikey "${params.cloudos_api_key}" \
        --workspace-id "${workspace_id}" \
        --project-name "${project_name}" \
        --workflow-name "${params.step_5_identify_mechanism_of_action_finemapping_cloudos_workflow_name}" \
        --git-tag "${params.step_5_identify_mechanism_of_action_finemapping_git_tag}" \
        --job-name "${params.step_5_identify_mechanism_of_action_finemapping_cloudos_job_name.replaceAll( / /, '_').replaceAll( /-/, '_').replaceAll(/:/, '_')}" \
        -p "gwas_vcf=$liftovered_gwas_vcf" \
        -p "ld_score_weights_annotation_files=${params.step_5_identify_mechanism_of_action_finemapping_ld_score_weights_annotation_files}" \
        -p "polyfun=${params.step_5_identify_mechanism_of_action_finemapping_polyfun}" \
        -p "polyfun_pvalue_thr=${params.step_5_identify_mechanism_of_action_finemapping_polyfun_pvalue_thr}" \
        -p "reference_data_bucket=${params.step_5_identify_mechanism_of_action_finemapping_reference_data_bucket}" \
        -p "liftover=${params.step_5_identify_mechanism_of_action_finemapping_liftover}" \
        -p "max_memory=180.GB" \
        --instance-disk ${params.step_5_identify_mechanism_of_action_finemapping_cloudos_instance_disk_space} \
        --cost-limit ${params.step_5_identify_mechanism_of_action_finemapping_cloudos_cost_limit} \
        --instance-type "${params.step_5_identify_mechanism_of_action_finemapping_cloudos_instance_type}" \
        --resumable \
        --wait-time ${params.step_5_identify_mechanism_of_action_finemapping_cloudos_wait_time} \
        --batch \
        --job-queue "${params.cloudos_queue_name}" \
        --disable-ssl-verification \
        --wait-completion | tee job_status_finemapping.txt

    # Check job status to fail early
    job_status=\$(tail -1 job_status_finemapping.txt | rev | cut -d " " -f 1 | rev)
    if [ \$job_status = "completed" ]; then
        echo "Your job finished successfully."
    else
        echo "[ERROR] Your job did not finish successfully."
        exit 1
    fi

    FINEMAPPING_JOB_ID=\$(grep -e "Your assigned job id is" job_status_finemapping.txt | rev | cut -d " " -f 1 | rev)
    FINEMAPPING_OUT="${project_bucket}/\$FINEMAPPING_JOB_ID/results/results/polyfun/aggregated_results/polyfun_agg_GRCh38.txt"
    """
}

process trigger_step_5_identify_mechanism_of_action_cheers {
    label "cloudos"

    input:
    val finemapping_out
    val project_name
    val workspace_id

    output:
    env CHEERS_JOB_ID, emit: ch_cheers_job_id

    """
    # CHEERS
    cloudos job run \
        --cloudos-url "${params.cloudos_url}" \
        --apikey "${params.cloudos_api_key}" \
        --workspace-id "${workspace_id}" \
        --project-name "${project_name}" \
        --workflow-name "${params.step_5_identify_mechanism_of_action_cheers_cloudos_workflow_name}" \
        --git-tag "${params.step_5_identify_mechanism_of_action_cheers_git_tag}" \
        --job-name "${params.step_5_identify_mechanism_of_action_cheers_cloudos_job_name.replaceAll( / /, '_').replaceAll( /-/, '_').replaceAll(/:/, '_')}" \
        -p "trait_name=${params.step_5_identify_mechanism_of_action_cheers_trait_name}" \
        -p "input_snp_type=${params.step_5_identify_mechanism_of_action_cheers_input_snp_type}" \
        -p "input_peaks=${params.step_5_identify_mechanism_of_action_cheers_input_peaks}" \
        -p "snp_list=$finemapping_out" \
        -p "PIP=${params.step_5_identify_mechanism_of_action_cheers_PIP}" \
        -p "reference_data_bucket=${params.step_5_identify_mechanism_of_action_cheers_reference_data_bucket}" \
        -p "errorStrategy=${params.module_strategy}" \
        --resumable \
        --batch \
        --job-queue "${params.cloudos_queue_name}" \
        --disable-ssl-verification \
        --wait-completion | tee job_status_cheers.txt

    CHEERS_JOB_ID=\$(grep -e "Your assigned job id is" job_status_cheers.txt | rev | cut -d " " -f 1 | rev)
    """
}
