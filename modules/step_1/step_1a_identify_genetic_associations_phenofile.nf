process trigger_step_1a_identify_genetic_associations_phenofile {
    label "cloudos"

    input:
    val project_name
    val project_bucket
    val workspace_id


    output:
    env PHENOFILE_OUT, emit: ch_phenofile_out
    env PHENOFILE_OUT_GENOFILE, emit: ch_genotype_files_list
    env PHENOFILE_JOB_ID, emit: ch_step_1a_job_id


    script:
    if(params.step_1a_identify_genetic_associations_phenofile_sql_specification){
        specification = "sql_specification=${params.step_1a_identify_genetic_associations_phenofile_sql_specification}"
    } else if (params.step_1a_identify_genetic_associations_phenofile_codelist_specification){
        specification = "codelist_specification=${params.step_1a_identify_genetic_associations_phenofile_codelist_specification}"
    }
    """
    cloudos job run \
        --cloudos-url "${params.cloudos_url}" \
        --apikey "${params.cloudos_api_key}" \
        --workspace-id "${workspace_id}" \
        --project-name "${project_name}" \
        --workflow-name "${params.step_1a_identify_genetic_associations_phenofile_cloudos_workflow_name}" \
        --job-name "${params.step_1a_identify_genetic_associations_phenofile_cloudos_job_name.replaceAll( / /, '_').replaceAll( /-/, '_').replaceAll(/:/, '_')}" \
        --git-tag "adds_linking_table_creation" \
        -p "covariate_specification=${params.step_1a_identify_genetic_associations_phenofile_covariate_specification}" \
        -p "database_cdm_schema=${params.step_1a_identify_genetic_associations_phenofile_database_cdm_schema}" \
        -p "$specification" \
        -p "genotypic_linking_table=${params.step_1a_identify_genetic_associations_phenofile_genotypic_linking_table}" \
        -p "genotypic_id_col=${params.step_1a_identify_genetic_associations_phenofile_genotypic_id_col}" \
        -p "original_id_col=${params.step_1a_identify_genetic_associations_phenofile_original_id_col}" \
        -p "pheno_label=${params.step_1a_identify_genetic_associations_phenofile_pheno_label.replaceAll( / /, '_')}" \
        -p "phenofile_name=${params.step_1a_identify_genetic_associations_phenofile_phenofile_name}" \
        -p "include_descendants=${params.step_1a_identify_genetic_associations_phenofile_include_descendants}" \
        -p "quantitative_outcome_concept_id=${params.step_1a_identify_genetic_associations_phenofile_quantitative_outcome_concept_id}" \
        -p "quantitative_outcome_occurrence=${params.step_1a_identify_genetic_associations_phenofile_quantitative_outcome_occurrence}" \
        -p "control_index_date=${params.step_1a_identify_genetic_associations_phenofile_control_index_date}" \
        -p "case_cohort_json=${params.step_1a_identify_genetic_associations_phenofile_case_cohort_json}" \
        -p "control_cohort_json=${params.step_1a_identify_genetic_associations_phenofile_control_cohort_json}" \
        -p "create_controls=${params.step_1a_identify_genetic_associations_phenofile_create_controls}" \
        -p "controls_to_match=${params.step_1a_identify_genetic_associations_phenofile_controls_to_match}" \
        -p "min_controls_to_match=${params.step_1a_identify_genetic_associations_phenofile_min_controls_to_match}" \
        -p "match_age_tolerance=${params.step_1a_identify_genetic_associations_phenofile_match_age_tolerance}" \
        -p "match_on_age=${params.step_1a_identify_genetic_associations_phenofile_match_on_age}" \
        -p "match_on_sex=${params.step_1a_identify_genetic_associations_phenofile_match_on_sex}" \
        -p "input_folder_location=${params.step_1a_identify_genetic_associations_phenofile_input_folder_location}" \
        -p "preprocess_list_and_linking=${params.step_1a_identify_genetic_associations_phenofile_preprocess_list_and_linking}" \
        --nextflow-profile "${params.step_1a_identify_genetic_associations_phenofile_profile}" \
        --resumable \
        --batch \
        --job-queue "${params.cloudos_queue_name}" \
        --disable-ssl-verification \
        --wait-completion | tee job_status_phenofile.txt

    # Check job status to fail early
    job_status=\$(tail -1 job_status_phenofile.txt | rev | cut -d " " -f 1 | rev)
    if [ \$job_status = "completed" ]; then
        echo "Your job finished successfully."
    else
        echo "[ERROR] Your job did not finish successfully."
        exit 1
    fi

    PHENOFILE_JOB_ID=\$(grep -e "Your assigned job id is" job_status_phenofile.txt | rev | cut -d " " -f 1 | rev)
    PHENOFILE_OUT="${project_bucket}/\$PHENOFILE_JOB_ID/results/results/phenofile/matched_linked_phenofile.phe"
    PHENOFILE_OUT_GENOFILE="${project_bucket}/\$PHENOFILE_JOB_ID/results/results/genotype_files_list_and_linking_table/genotype_files_list.csv"
    """
}
