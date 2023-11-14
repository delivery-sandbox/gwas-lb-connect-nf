process trigger_step_6_identify_candidate_drugs_gsea {
    label "cloudos"

    input:
    val harmonised_gwas_vcf
    val project_name
    val project_bucket
    val workspace_id

    output:
    env GSEA_OUT, emit: ch_gsea_genenames
    env GSEA_JOB_ID, emit: ch_gsea_job_id

    script:
    harmonised_data = params.step_6_identify_candidate_drugs_gsea_summary_stats ?: harmonised_gwas_vcf
    """
    # GSEA
    cloudos job run \
        --cloudos-url "${params.cloudos_url}" \
        --apikey "${params.cloudos_api_key}" \
        --workspace-id "${workspace_id}" \
        --project-name "${project_name}" \
        --workflow-name "${params.step_6_identify_candidate_drugs_gsea_cloudos_workflow_name}" \
        --git-tag "${params.step_6_identify_candidate_drugs_gsea_git_tag}" \
        --job-name "${params.step_6_identify_candidate_drugs_gsea_cloudos_job_name.replaceAll( / /, '_').replaceAll( /-/, '_').replaceAll(/:/, '_')}" \
        -p "summary_stats=$harmonised_data" \
        -p "snp_col_name=${params.step_6_identify_candidate_drugs_gsea_snp_col_name}" \
        -p "pval_col_name=${params.step_6_identify_candidate_drugs_gsea_pval_col_name}" \
        -p "ref_panel_bed=${params.step_6_identify_candidate_drugs_gsea_ref_panel_bed}" \
        -p "ref_panel_bim=${params.step_6_identify_candidate_drugs_gsea_ref_panel_bim}" \
        -p "ref_panel_fam=${params.step_6_identify_candidate_drugs_gsea_ref_panel_fam}" \
        -p "ref_panel_synonyms=${params.step_6_identify_candidate_drugs_gsea_ref_panel_synonyms}" \
        -p "gene_loc_file=${params.step_6_identify_candidate_drugs_gsea_gene_loc_file}" \
        -p "set_anot_file=${params.step_6_identify_candidate_drugs_gsea_set_anot_file}" \
        -p "reference_data_bucket=${params.step_6_identify_candidate_drugs_gsea_reference_data_bucket}" \
        --resumable \
        --batch \
        --job-queue "${params.cloudos_queue_name}" \
        --disable-ssl-verification \
        --wait-time 20000 \
        --wait-completion | tee job_status_gsea.txt

    # Check job status to fail early
    job_status=\$(tail -1 job_status_gsea.txt | rev | cut -d " " -f 1 | rev)
    if [ \$job_status = "completed" ]; then
        echo "Your job finished successfully."
    else
        echo "[ERROR] Your job did not finish successfully."
        exit 1
    fi

    GSEA_JOB_ID=\$(grep -e "Your assigned job id is" job_status_gsea.txt | rev | cut -d " " -f 1 | rev)
    GSEA_OUT="${project_bucket}/\$GSEA_JOB_ID/results/results/magma/magma_out.genes.out.prioritised.genenames.tsv"
    """
}

process trigger_step_6_identify_candidate_drugs_drug2ways {
    label "cloudos"

    input:
    val gsea_genenames
    val project_name
    val workspace_id

    output:
    env DRUG2WAYS_JOB_ID, emit: ch_drug2ways_job_id

    script:
    """
    # DRUG2WAYS
    cloudos job run \
        --cloudos-url "${params.cloudos_url}" \
        --apikey "${params.cloudos_api_key}" \
        --workspace-id "${workspace_id}" \
        --project-name "${project_name}" \
        --workflow-name "${params.step_6_identify_candidate_drugs_drug2ways_cloudos_workflow_name}" \
        --git-tag "${params.step_6_identify_candidate_drugs_drug2ways_git_tag}" \
        --job-name "${params.step_6_identify_candidate_drugs_drug2ways_cloudos_job_name.replaceAll( / /, '_').replaceAll( /-/, '_').replaceAll(/:/, '_')}" \
        -p "targets=$gsea_genenames" \
        -p "omnipathr_container=${params.step_6_identify_candidate_drugs_drug2ways_omnipathr_container}" \
        -p "get_drugs=${params.step_6_identify_candidate_drugs_drug2ways_get_drugs}" \
        -p "network=${params.step_6_identify_candidate_drugs_drug2ways_network}" \
        -p "sources=${params.step_6_identify_candidate_drugs_drug2ways_sources}" \
        -p "lmax=${params.step_6_identify_candidate_drugs_drug2ways_lmax}" \
        -p "reference_data_bucket=${params.step_6_identify_candidate_drugs_drug2ways_reference_data_bucket}" \
        -p "errorStrategy=${params.module_strategy}" \
        --resumable \
        --batch \
        --job-queue "${params.cloudos_queue_name}" \
        --disable-ssl-verification \
        --wait-completion | tee job_status_drug2ways.txt

    DRUG2WAYS_JOB_ID=\$(grep -e "Your assigned job id is" job_status_drug2ways.txt | rev | cut -d " " -f 1 | rev)
    """
}
