process trigger_step_1b_gwas_prepare_multi_sample_genotypes {
    label "cloudos"

    input:
    val phenofile
    val genotype_files_list
    val project_name
    val project_bucket
    val workspace_id
    val end_to_end_job_id


    output:
    env GENO_OUT_LD_PRUNED, emit: ch_geno_out_ld_pruned
    env GENO_OUT_MERGED, emit: ch_geno_out_merged
    env GENO_MULTISAMPLE_JOB_ID, emit: ch_step_1b_geno_multisample


    script:
    geno_data = params.collect_genotypes_from_step_1a ? genotype_files_list : params.step_1b_gwas_prepare_multi_sample_genotypes_genotype_files_list
    phenofile = params.step_1b_gwas_prepare_multi_sample_genotypes_phenofile ? params.step_1b_gwas_prepare_multi_sample_genotypes_genotype_files_list : phenofile
    """
    cloudos job run \
        --cloudos-url "${params.cloudos_url}" \
        --apikey "${params.cloudos_api_key}" \
        --workspace-id "${workspace_id}" \
        --project-name "${project_name}" \
        --workflow-name "${params.step_1b_gwas_prepare_multi_sample_genotypes_cloudos_workflow_name}" \
        --job-name "${params.step_1b_gwas_prepare_multi_sample_genotypes_cloudos_job_name.replaceAll( / /, '_').replaceAll( /-/, '_').replaceAll(/:/, '_')}" \
        -p "genotype_format=${params.step_1b_gwas_prepare_multi_sample_genotypes_genotype_format}" \
        -p "genotype_files_list=$geno_data" \
        -p "genome_build=${params.step_1b_gwas_prepare_multi_sample_genotypes_genome_build}" \
        -p "miss=${params.step_1b_gwas_prepare_multi_sample_genotypes_miss}" \
        -p "miss_test_p_threshold=${params.step_1b_gwas_prepare_multi_sample_genotypes_miss_test_p_threshold}" \
        -p "sex_check=${params.step_1b_gwas_prepare_multi_sample_genotypes_sex_check}" \
        -p "input_folder_location=${params.step_1b_gwas_prepare_multi_sample_genotypes_input_folder_location}" \
        -p "file_pattern=${params.step_1b_gwas_prepare_multi_sample_genotypes_file_pattern}" \
        -p "file_suffix=${params.step_1b_gwas_prepare_multi_sample_file_suffix}" \
        -p "index_suffix=${params.step_1b_gwas_prepare_multi_sample_genotypes_index_suffix}" \
        -p "extract_pruned_region=${params.step_1b_gwas_prepare_multi_sample_genotypes_extract_pruned_region}" \
        -p "analyse_hard_called_gt=${params.step_1b_gwas_prepare_multi_sample_genotypes_analyse_hard_called_gt}" \
        -p "refalt_mode=${params.step_1b_gwas_prepare_multi_sample_genotypes_refalt_mode}" \
        -p "q_filter=${params.step_1b_gwas_prepare_multi_sample_genotypes_q_filter}" \
        -p "mac=${params.step_1b_gwas_prepare_multi_sample_genotypes_mac}" \
        -p "maf=${params.step_1b_gwas_prepare_multi_sample_genotypes_maf}" \
        -p "hwe_threshold=${params.step_1b_gwas_prepare_multi_sample_hwe_threshold}" \
        -p "hwe_test=${params.step_1b_gwas_prepare_multi_sample_genotypes_hwe_test}" \
        -p "remove_multiallelics=${params.step_1b_gwas_prepare_multi_sample_genotypes_remove_multiallelics}" \
        -p "ld_window_size=${params.step_1b_gwas_prepare_multi_sample_genotypes_ld_window_size}" \
        -p "ld_step_size=${params.step_1b_gwas_prepare_multi_sample_genotypes_ld_step_size}" \
        -p "ld_r2_threshold=${params.step_1b_gwas_prepare_multi_sample_genotypes_ld_r2_threshold}" \
        -p "reference_data_bucket=${params.step_1b_gwas_prepare_multi_sample_genotypes_reference_data_bucket}" \
        --git-commit "${params.step_1b_gwas_prepare_multi_sample_genotypes_git_commit}" \
        --resumable \
        --cost-limit ${params.step_1b_gwas_prepare_multi_sample_genotypes_cloudos_cost_limit} \
        --wait-time ${params.step_1b_gwas_prepare_multi_sample_genotypes_cloudos_wait_time} \
        --batch \
        --job-queue "${params.cloudos_queue_name}" \
        --disable-ssl-verification \
        --wait-completion | tee job_status_gwas.txt

    # Check job status to fail early
    job_status=\$(tail -1 job_status_gwas.txt | rev | cut -d " " -f 1 | rev)

    GWAS_JOB_ID=\$(grep -e "Your assigned job id is" job_status_gwas.txt | rev | cut -d " " -f 1 | rev)
    GWAS_OUT="${project_bucket}/\$GWAS_JOB_ID/results/results/genotype_merged_plink/*"

    if [ \$job_status = "completed" ]; then
        echo "Your job finished successfully."
    else
        echo "[ERROR] Your job did not finish successfully."
        GWAS_OUT=false
        exit 0
    fi
    """
}
