#!/usr/bin/env nextflow
/*
====================================================================================================
|                        end-to-end-target-identification                                          |
====================================================================================================
|    #### Homepage / Documentation                                                                 |
|    https://github.com/lifebit-ai/end-to-end-target-identification/blob/dev/docs/README.md        |
----------------------------------------------------------------------------------------------------
*/

nextflow.enable.dsl = 2

/* --------------------
| Imports              |
--------------------- */

include { configure_project } from './modules/utils/configure_project.nf'
include { trigger_step_1a_identify_genetic_associations_phenofile } from './modules/step_1/step_1a_identify_genetic_associations_phenofile.nf'
include { trigger_step_1b_gwas_prepare_multi_sample_genotypes } from './modules/step_1/step_1b_gwas-prepare-multisample-genotypes.nf'
include { trigger_step_1b_gwas_annotate_samples } from './modules/step_1/step_1b_gwas-annotate-samples.nf'
include { trigger_step_1b_gwas } from './modules/step_1/step_1b_gwas.nf'
include { trigger_step_1c_identify_genetic_associations_harmonisation } from './modules/step_1/step_1c_identify_genetic_associations_harmonisation.nf'
include { trigger_step_2_identify_prioritised_genes } from './modules/step_2/identify_prioritised_genes.nf'
include { trigger_step_3_identify_causal_genes_and_pathways } from './modules/step_3/identify_causal_genes_and_pathways.nf'
include { trigger_step_4_identify_causal_proteins } from './modules/step_4/identify_causal_proteins.nf'
include { trigger_step_5_identify_mechanism_of_action_liftover } from './modules/step_5/identify_mechanism_of_action.nf'
include { trigger_step_5_identify_mechanism_of_action_finemapping } from './modules/step_5/identify_mechanism_of_action.nf'
include { trigger_step_5_identify_mechanism_of_action_cheers } from './modules/step_5/identify_mechanism_of_action.nf'
include { trigger_step_6_identify_candidate_drugs_gsea } from './modules/step_6/identify_candidate_drugs.nf'
include { trigger_step_6_identify_candidate_drugs_drug2ways } from './modules/step_6/identify_candidate_drugs.nf'
include { combine_reports } from './modules/utils/generate_reports.nf'
include { step_check; file_check } from './modules/utils/check_files.nf'

/* --------------------
| Summary              |
--------------------- */

def summary = [:]

if (workflow.revision) summary['Pipeline Release'] = workflow.revision

summary['Launch dir']                                  = workflow.launchDir
summary['Working dir']                                 = workflow.workDir
summary['Script dir']                                  = workflow.projectDir
summary['User']                                        = workflow.userName
summary['Output dir']                                  = params.outdir


if (params.debug) {
    summary['reference_data_bucket'] = params.reference_data_bucket
    summary['input'] = params.input
    summary['reference_data'] = params.reference_data
    summary['cloudos_url'] = params.cloudos_url
    summary['cloudos_workspace_id'] = params.cloudos_workspace_id
    summary['cloudos_api_key'] = params.cloudos_api_key.reverse().take(4).reverse()
    summary['cloudos_queue_name'] = params.cloudos_queue_name
    summary['step_1'] = params.step_1
    summary['step_2'] = params.step_2
    summary['step_3'] = params.step_3
    summary['step_4'] = params.step_4
    summary['step_5'] = params.step_5
    summary['step_6'] = params.step_6
    summary['step_1a_identify_genetic_associations_phenofile_cloudos_workflow_name'] = params.step_1a_identify_genetic_associations_phenofile_cloudos_workflow_name
    summary['step_1b_identify_genetic_associations_gwas_cloudos_workflow_name'] = params.step_1b_identify_genetic_associations_gwas_cloudos_workflow_name
    summary['step_1c_identify_genetic_associations_harmonisation_cloudos_workflow_name'] = params.step_1c_identify_genetic_associations_harmonisation_cloudos_workflow_name
    summary['step_2_identify_prioritised_genes_cloudos_workflow_name'] = params.step_2_identify_prioritised_genes_cloudos_workflow_name
    summary['step_3_identify_causal_genes_and_pathways_cloudos_workflow_name'] = params.step_3_identify_causal_genes_and_pathways_cloudos_workflow_name
    summary['step_4_identify_causal_proteins_cloudos_workflow_name'] = params.step_4_identify_causal_proteins_cloudos_workflow_name
    summary['step_5_identify_mechanism_of_action_liftover_cloudos_workflow_name'] = params.step_5_identify_mechanism_of_action_liftover_cloudos_workflow_name
    summary['step_5_identify_mechanism_of_action_finemapping_cloudos_workflow_name'] = params.step_5_identify_mechanism_of_action_finemapping_cloudos_workflow_name
    summary['step_5_identify_mechanism_of_action_cheers_cloudos_workflow_name'] = params.step_5_identify_mechanism_of_action_cheers_cloudos_workflow_name
    summary['step_6_identify_candidate_drugs_gsea_cloudos_workflow_name'] = params.step_6_identify_candidate_drugs_gsea_cloudos_workflow_name
    summary['step_6_identify_candidate_drugs_drug2ways_cloudos_workflow_name'] = params.step_6_identify_candidate_drugs_drug2ways_cloudos_workflow_name

    summary['step_1a_identify_genetic_associations_phenofile_cloudos_job_name'] = params.step_1a_identify_genetic_associations_phenofile_cloudos_job_name
    summary['step_1a_identify_genetic_associations_phenofile_cloudos_cost_limit'] = params.step_1a_identify_genetic_associations_phenofile_cloudos_cost_limit
    summary['step_1a_identify_genetic_associations_phenofile_cloudos_instance_disk_space'] = params.step_1a_identify_genetic_associations_phenofile_cloudos_instance_disk_space
    summary['step_1a_identify_genetic_associations_phenofile_cloudos_nextflow_profile'] = params.step_1a_identify_genetic_associations_phenofile_cloudos_nextflow_profile
    summary['step_1a_identify_genetic_associations_phenofile_cloudos_instance_type'] = params.step_1a_identify_genetic_associations_phenofile_cloudos_instance_type
    summary['step_1a_identify_genetic_associations_phenofile_cloudos_queue_name'] = params.step_1a_identify_genetic_associations_phenofile_cloudos_queue_name
    summary['step_1a_identify_genetic_associations_phenofile_cloudos_wait_time'] = params.step_1a_identify_genetic_associations_phenofile_cloudos_wait_time
    summary['step_1a_identify_genetic_associations_phenofile_covariate_specification'] = params.step_1a_identify_genetic_associations_phenofile_covariate_specification
    summary['step_1a_identify_genetic_associations_phenofile_sql_specification'] = params.step_1a_identify_genetic_associations_phenofile_sql_specification
    summary['step_1a_identify_genetic_associations_phenofile_database_cdm_schema'] = params.step_1a_identify_genetic_associations_phenofile_database_cdm_schema
    summary['step_1a_identify_genetic_associations_phenofile_profile'] = params.step_1a_identify_genetic_associations_phenofile_profile
    summary['step_1a_identify_genetic_associations_phenofile_genotypic_linking_table'] = params.step_1a_identify_genetic_associations_phenofile_genotypic_linking_table
    summary['step_1a_identify_genetic_associations_phenofile_genotypic_id_col'] = params.step_1a_identify_genetic_associations_phenofile_genotypic_id_col
    summary['step_1a_identify_genetic_associations_phenofile_original_id_col'] = params.step_1a_identify_genetic_associations_phenofile_original_id_col
    summary['step_1a_identify_genetic_associations_phenofile_codelist_specification'] = params.step_1a_identify_genetic_associations_phenofile_codelist_specification
    summary['step_1a_identify_genetic_associations_phenofile_pheno_label'] = params.step_1a_identify_genetic_associations_phenofile_pheno_label
    summary['step_1a_identify_genetic_associations_phenofile_phenofile_name'] = params.step_1a_identify_genetic_associations_phenofile_phenofile_name
    summary['step_1a_identify_genetic_associations_phenofile_include_descendants'] = params.step_1a_identify_genetic_associations_phenofile_include_descendants
    summary['step_1a_identify_genetic_associations_phenofile_quantitative_outcome_concept_id'] = params.step_1a_identify_genetic_associations_phenofile_quantitative_outcome_concept_id
    summary['step_1a_identify_genetic_associations_phenofile_quantitative_outcome_occurrence'] = params.step_1a_identify_genetic_associations_phenofile_quantitative_outcome_occurrence
    summary['step_1a_identify_genetic_associations_phenofile_control_index_date'] = params.step_1a_identify_genetic_associations_phenofile_control_index_date
    summary['step_1a_identify_genetic_associations_phenofile_case_cohort_json'] = params.step_1a_identify_genetic_associations_phenofile_case_cohort_json
    summary['step_1a_identify_genetic_associations_phenofile_control_cohort_json'] = params.step_1a_identify_genetic_associations_phenofile_control_cohort_json
    summary['step_1a_identify_genetic_associations_phenofile_create_controls'] = params.step_1a_identify_genetic_associations_phenofile_create_controls
    summary['step_1a_identify_genetic_associations_phenofile_controls_to_match'] = params.step_1a_identify_genetic_associations_phenofile_controls_to_match
    summary['step_1a_identify_genetic_associations_phenofile_min_controls_to_match'] = params.step_1a_identify_genetic_associations_phenofile_min_controls_to_match
    summary['step_1a_identify_genetic_associations_phenofile_match_age_tolerance'] = params.step_1a_identify_genetic_associations_phenofile_match_age_tolerance
    summary['step_1a_identify_genetic_associations_phenofile_match_on_age'] = params.step_1a_identify_genetic_associations_phenofile_match_on_age
    summary['step_1a_identify_genetic_associations_phenofile_match_on_sex'] = params.step_1a_identify_genetic_associations_phenofile_match_on_sex
    summary['step_1a_identify_genetic_associations_phenofile_input_folder_location'] = params.step_1a_identify_genetic_associations_phenofile_input_folder_location
    summary['step_1a_identify_genetic_associations_phenofile_genotypic_linking_table'] = params.step_1a_identify_genetic_associations_phenofile_genotypic_linking_table
    summary['step_1a_identify_genetic_associations_phenofile_preprocess_list_and_linking'] = params.step_1a_identify_genetic_associations_phenofile_preprocess_list_and_linking
    summary['step_1c_identify_genetic_associations_harmonisation_cloudos_job_name'] = params.step_1c_identify_genetic_associations_harmonisation_cloudos_job_name
    summary['step_1c_identify_genetic_associations_harmonisation_cloudos_cost_limit'] = params.step_1c_identify_genetic_associations_harmonisation_cloudos_cost_limit
    summary['step_1c_identify_genetic_associations_harmonisation_cloudos_instance_disk_space'] = params.step_1c_identify_genetic_associations_harmonisation_cloudos_instance_disk_space
    summary['step_1c_identify_genetic_associations_harmonisation_cloudos_nextflow_profile'] = params.step_1c_identify_genetic_associations_harmonisation_cloudos_nextflow_profile
    summary['step_1c_identify_genetic_associations_harmonisation_cloudos_instance_type'] = params.step_1c_identify_genetic_associations_harmonisation_cloudos_instance_type
    summary['step_1c_identify_genetic_associations_harmonisation_cloudos_queue_name'] = params.step_1c_identify_genetic_associations_harmonisation_cloudos_queue_name
    summary['step_1c_identify_genetic_associations_harmonisation_cloudos_wait_time'] = params.step_1c_identify_genetic_associations_harmonisation_cloudos_wait_time
    summary['step_1c_identify_genetic_associations_harmonisation_input'] = params.step_1c_identify_genetic_associations_harmonisation_input
    summary['step_1c_identify_genetic_associations_harmonisation_gwas_source'] = params.step_1c_identify_genetic_associations_harmonisation_gwas_source
    summary['step_1c_identify_genetic_associations_harmonisation_input_type'] = params.step_1c_identify_genetic_associations_harmonisation_input_type
    summary['step_1c_identify_genetic_associations_harmonisation_standardise'] = params.step_1c_identify_genetic_associations_harmonisation_standardise
    summary['step_1c_identify_genetic_associations_harmonisation_coef_conversion'] = params.step_1c_identify_genetic_associations_harmonisation_coef_conversion
    summary['step_1c_identify_genetic_associations_harmonisation_keep_intermediate_files'] = params.step_1c_identify_genetic_associations_harmonisation_keep_intermediate_files
    summary['step_1c_identify_genetic_associations_harmonisation_filter_beta_smaller_than'] = params.step_1c_identify_genetic_associations_harmonisation_filter_beta_smaller_than
    summary['step_1c_identify_genetic_associations_harmonisation_filter_beta_greater_than'] = params.step_1c_identify_genetic_associations_harmonisation_filter_beta_greater_than
    summary['step_1c_identify_genetic_associations_harmonisation_filter_LP_smaller_than'] = params.step_1c_identify_genetic_associations_harmonisation_filter_LP_smaller_than
    summary['step_1c_identify_genetic_associations_harmonisation_filter_freq_smaller_than'] = params.step_1c_identify_genetic_associations_harmonisation_filter_freq_smaller_than
    summary['step_1c_identify_genetic_associations_harmonisation_filter_freq_greater_than'] = params.step_1c_identify_genetic_associations_harmonisation_filter_freq_greater_than
    summary['step_1c_identify_genetic_associations_harmonisation_convert_to_hail'] = params.step_1c_identify_genetic_associations_harmonisation_convert_to_hail
    summary['step_1c_identify_genetic_associations_harmonisation_dbsnp'] = params.step_1c_identify_genetic_associations_harmonisation_dbsnp
    summary['step_1c_identify_genetic_associations_harmonisation_reference_data_bucket'] = params.step_1c_identify_genetic_associations_harmonisation_reference_data_bucket
    summary['step_2_identify_prioritised_genes_cloudos_job_name'] = params.step_2_identify_prioritised_genes_cloudos_job_name
    summary['step_2_identify_prioritised_genes_cloudos_cost_limit'] = params.step_2_identify_prioritised_genes_cloudos_cost_limit
    summary['step_2_identify_prioritised_genes_cloudos_instance_disk_space'] = params.step_2_identify_prioritised_genes_cloudos_instance_disk_space
    summary['step_2_identify_prioritised_genes_cloudos_nextflow_profile'] = params.step_2_identify_prioritised_genes_cloudos_nextflow_profile
    summary['step_2_identify_prioritised_genes_cloudos_instance_type'] = params.step_2_identify_prioritised_genes_cloudos_instance_type
    summary['step_2_identify_prioritised_genes_cloudos_queue_name'] = params.step_2_identify_prioritised_genes_cloudos_queue_name
    summary['step_2_identify_prioritised_genes_cloudos_wait_time'] = params.step_2_identify_prioritised_genes_cloudos_wait_time
    summary['step_2_identify_prioritised_genes_variant_to_gene_git_tag'] = params.step_2_identify_prioritised_genes_variant_to_gene_git_tag
    summary['step_2_identify_prioritised_genes_variant_to_gene_gcta_smr'] = params.step_2_identify_prioritised_genes_variant_to_gene_gcta_smr
    summary['step_2_identify_prioritised_genes_variant_to_gene_closest_genes'] = params.step_2_identify_prioritised_genes_variant_to_gene_closest_genes
    summary['step_2_identify_prioritised_genes_variant_to_gene_metaxcan'] = params.step_2_identify_prioritised_genes_variant_to_gene_metaxcan
    summary['step_2_identify_prioritised_genes_variant_to_gene_gwas_vcf'] = params.step_2_identify_prioritised_genes_variant_to_gene_gwas_vcf
    summary['step_2_identify_prioritised_genes_variant_to_gene_plink_data'] = params.step_2_identify_prioritised_genes_variant_to_gene_plink_data
    summary['step_2_identify_prioritised_genes_variant_to_gene_besd_data'] = params.step_2_identify_prioritised_genes_variant_to_gene_besd_data
    summary['step_2_identify_prioritised_genes_variant_to_gene_diff_freq_prop'] = params.step_2_identify_prioritised_genes_variant_to_gene_diff_freq_prop
    summary['step_3_identify_causal_genes_and_pathways_cloudos_job_name'] = params.step_3_identify_causal_genes_and_pathways_cloudos_job_name
    summary['step_3_identify_causal_genes_and_pathways_cloudos_cost_limit'] = params.step_3_identify_causal_genes_and_pathways_cloudos_cost_limit
    summary['step_3_identify_causal_genes_and_pathways_cloudos_instance_disk_space'] = params.step_3_identify_causal_genes_and_pathways_cloudos_instance_disk_space
    summary['step_3_identify_causal_genes_and_pathways_cloudos_nextflow_profile'] = params.step_3_identify_causal_genes_and_pathways_cloudos_nextflow_profile
    summary['step_3_identify_causal_genes_and_pathways_cloudos_instance_type'] = params.step_3_identify_causal_genes_and_pathways_cloudos_instance_type
    summary['step_3_identify_causal_genes_and_pathways_cloudos_queue_name'] = params.step_3_identify_causal_genes_and_pathways_cloudos_queue_name
    summary['step_3_identify_causal_genes_and_pathways_cloudos_wait_time'] = params.step_3_identify_causal_genes_and_pathways_cloudos_wait_time
    summary['step_3_identify_causal_genes_and_pathways_joint_xqtl_gwas_vcf'] = params.step_3_identify_causal_genes_and_pathways_joint_xqtl_gwas_vcf
    summary['step_3_identify_causal_genes_and_pathways_joint_xqtl_ld_ref_data'] = params.step_3_identify_causal_genes_and_pathways_joint_xqtl_ld_ref_data
    summary['step_3_identify_causal_genes_and_pathways_joint_xqtl_besd_list'] = params.step_3_identify_causal_genes_and_pathways_joint_xqtl_besd_list
    summary['step_3_identify_causal_genes_and_pathways_joint_xqtl_git_tag'] = params.step_3_identify_causal_genes_and_pathways_joint_xqtl_git_tag
    summary['step_3_identify_causal_genes_and_pathways_joint_xqtl_reference_data_bucket'] = params.step_3_identify_causal_genes_and_pathways_joint_xqtl_reference_data_bucket
    summary['step_4_identify_causal_proteins_cloudos_job_name'] = params.step_4_identify_causal_proteins_cloudos_job_name
    summary['step_4_identify_causal_proteins_cloudos_cost_limit'] = params.step_4_identify_causal_proteins_cloudos_cost_limit
    summary['step_4_identify_causal_proteins_cloudos_instance_disk_space'] = params.step_4_identify_causal_proteins_cloudos_instance_disk_space
    summary['step_4_identify_causal_proteins_cloudos_nextflow_profile'] = params.step_4_identify_causal_proteins_cloudos_nextflow_profile
    summary['step_4_identify_causal_proteins_cloudos_instance_type'] = params.step_4_identify_causal_proteins_cloudos_instance_type
    summary['step_4_identify_causal_proteins_cloudos_queue_name'] = params.step_4_identify_causal_proteins_cloudos_queue_name
    summary['step_4_identify_causal_proteins_cloudos_wait_time'] = params.step_4_identify_causal_proteins_cloudos_wait_time
    summary['step_4_identify_causal_proteins_xqtlbiolinks_gwas_vcf'] = params.step_4_identify_causal_proteins_xqtlbiolinks_gwas_vcf
    summary['step_4_identify_causal_proteins_xqtlbiolinks_git_tag'] = params.step_4_identify_causal_proteins_xqtlbiolinks_git_tag
    summary['step_4_identify_causal_proteins_xqtlbiolinks_reference_data_bucket'] = params.step_4_identify_causal_proteins_xqtlbiolinks_reference_data_bucket
    summary['step_5_identify_mechanism_of_action_liftover_cloudos_job_name'] = params.step_5_identify_mechanism_of_action_liftover_cloudos_job_name
    summary['step_5_identify_mechanism_of_action_liftover_cloudos_cost_limit'] = params.step_5_identify_mechanism_of_action_liftover_cloudos_cost_limit
    summary['step_5_identify_mechanism_of_action_liftover_cloudos_instance_disk_space'] = params.step_5_identify_mechanism_of_action_liftover_cloudos_instance_disk_space
    summary['step_5_identify_mechanism_of_action_liftover_cloudos_nextflow_profile'] = params.step_5_identify_mechanism_of_action_liftover_cloudos_nextflow_profile
    summary['step_5_identify_mechanism_of_action_liftover_cloudos_instance_type'] = params.step_5_identify_mechanism_of_action_liftover_cloudos_instance_type
    summary['step_5_identify_mechanism_of_action_liftover_cloudos_queue_name'] = params.step_5_identify_mechanism_of_action_liftover_cloudos_queue_name
    summary['step_5_identify_mechanism_of_action_liftover_cloudos_wait_time'] = params.step_5_identify_mechanism_of_action_liftover_cloudos_wait_time
    summary['step_5_identify_mechanism_of_action_liftover_vcf'] = params.step_5_identify_mechanism_of_action_liftover_vcf
    summary['step_5_identify_mechanism_of_action_liftover_crossmap_preprocess'] = params.step_5_identify_mechanism_of_action_liftover_crossmap_preprocess
    summary['step_5_identify_mechanism_of_action_liftover_collapse_multiallelics_in_output'] = params.step_5_identify_mechanism_of_action_liftover_collapse_multiallelics_in_output
    summary['step_5_identify_mechanism_of_action_liftover_reference_fasta_original'] = params.step_5_identify_mechanism_of_action_liftover_reference_fasta_original
    summary['step_5_identify_mechanism_of_action_liftover_fasta_index_original'] = params.step_5_identify_mechanism_of_action_liftover_fasta_index_original
    summary['step_5_identify_mechanism_of_action_liftover_fasta_chr_name_map_original'] = params.step_5_identify_mechanism_of_action_liftover_fasta_chr_name_map_original
    summary['step_5_identify_mechanism_of_action_liftover_reference_fasta_target'] = params.step_5_identify_mechanism_of_action_liftover_reference_fasta_target
    summary['step_5_identify_mechanism_of_action_liftover_no_comp_alleles'] = params.step_5_identify_mechanism_of_action_liftover_no_comp_alleles
    summary['step_5_identify_mechanism_of_action_liftover_map_warn_pct'] = params.step_5_identify_mechanism_of_action_liftover_map_warn_pct
    summary['step_5_identify_mechanism_of_action_liftover_chunk_size'] = params.step_5_identify_mechanism_of_action_liftover_chunk_size
    summary['step_5_identify_mechanism_of_action_liftover_reference_data_bucket'] = params.step_5_identify_mechanism_of_action_liftover_reference_data_bucket
    summary['step_5_identify_mechanism_of_action_finemapping_cloudos_job_name'] = params.step_5_identify_mechanism_of_action_finemapping_cloudos_job_name
    summary['step_5_identify_mechanism_of_action_finemapping_cloudos_cost_limit'] = params.step_5_identify_mechanism_of_action_finemapping_cloudos_cost_limit
    summary['step_5_identify_mechanism_of_action_finemapping_cloudos_instance_disk_space'] = params.step_5_identify_mechanism_of_action_finemapping_cloudos_instance_disk_space
    summary['step_5_identify_mechanism_of_action_finemapping_cloudos_nextflow_profile'] = params.step_5_identify_mechanism_of_action_finemapping_cloudos_nextflow_profile
    summary['step_5_identify_mechanism_of_action_finemapping_cloudos_instance_type'] = params.step_5_identify_mechanism_of_action_finemapping_cloudos_instance_type
    summary['step_5_identify_mechanism_of_action_finemapping_cloudos_queue_name'] = params.step_5_identify_mechanism_of_action_finemapping_cloudos_queue_name
    summary['step_5_identify_mechanism_of_action_finemapping_cloudos_wait_time'] = params.step_5_identify_mechanism_of_action_finemapping_cloudos_wait_time
    summary['step_5_identify_mechanism_of_action_finemapping_git_tag'] = params.step_5_identify_mechanism_of_action_finemapping_git_tag
    summary['step_5_identify_mechanism_of_action_finemapping_gwas_vcf'] = params.step_5_identify_mechanism_of_action_finemapping_gwas_vcf
    summary['step_5_identify_mechanism_of_action_finemapping_ld_score_weights_annotation_files'] = params.step_5_identify_mechanism_of_action_finemapping_ld_score_weights_annotation_files
    summary['step_5_identify_mechanism_of_action_finemapping_polyfun'] = params.step_5_identify_mechanism_of_action_finemapping_polyfun
    summary['step_5_identify_mechanism_of_action_finemapping_polyfun_pvalue_thr'] = params.step_5_identify_mechanism_of_action_finemapping_polyfun_pvalue_thr
    summary['step_5_identify_mechanism_of_action_finemapping_reference_data_bucket'] = params.step_5_identify_mechanism_of_action_finemapping_reference_data_bucket
    summary['step_5_identify_mechanism_of_action_finemapping_liftover'] = params.step_5_identify_mechanism_of_action_finemapping_liftover
    summary['step_5_identify_mechanism_of_action_cheers_cloudos_job_name'] = params.step_5_identify_mechanism_of_action_cheers_cloudos_job_name
    summary['step_5_identify_mechanism_of_action_cheers_cloudos_cost_limit'] = params.step_5_identify_mechanism_of_action_cheers_cloudos_cost_limit
    summary['step_5_identify_mechanism_of_action_cheers_cloudos_instance_disk_space'] = params.step_5_identify_mechanism_of_action_cheers_cloudos_instance_disk_space
    summary['step_5_identify_mechanism_of_action_cheers_cloudos_nextflow_profile'] = params.step_5_identify_mechanism_of_action_cheers_cloudos_nextflow_profile
    summary['step_5_identify_mechanism_of_action_cheers_cloudos_instance_type'] = params.step_5_identify_mechanism_of_action_cheers_cloudos_instance_type
    summary['step_5_identify_mechanism_of_action_cheers_cloudos_queue_name'] = params.step_5_identify_mechanism_of_action_cheers_cloudos_queue_name
    summary['step_5_identify_mechanism_of_action_cheers_cloudos_wait_time'] = params.step_5_identify_mechanism_of_action_cheers_cloudos_wait_time
    summary['step_5_identify_mechanism_of_action_cheers_git_tag'] = params.step_5_identify_mechanism_of_action_cheers_git_tag
    summary['step_5_identify_mechanism_of_action_cheers_trait_name'] = params.step_5_identify_mechanism_of_action_cheers_trait_name
    summary['step_5_identify_mechanism_of_action_cheers_input_snp_type'] = params.step_5_identify_mechanism_of_action_cheers_input_snp_type
    summary['step_5_identify_mechanism_of_action_cheers_input_peaks'] = params.step_5_identify_mechanism_of_action_cheers_input_peaks
    summary['step_5_identify_mechanism_of_action_cheers_snp_list'] = params.step_5_identify_mechanism_of_action_cheers_snp_list
    summary['step_5_identify_mechanism_of_action_cheers_PIP'] = params.step_5_identify_mechanism_of_action_cheers_PIP
    summary['step_5_identify_mechanism_of_action_cheers_reference_data_bucket'] = params.step_5_identify_mechanism_of_action_cheers_reference_data_bucket
    summary['step_6_identify_candidate_drugs_gsea_cloudos_job_name'] = params.step_6_identify_candidate_drugs_gsea_cloudos_job_name
    summary['step_6_identify_candidate_drugs_gsea_cloudos_cost_limit'] = params.step_6_identify_candidate_drugs_gsea_cloudos_cost_limit
    summary['step_6_identify_candidate_drugs_gsea_cloudos_instance_disk_space'] = params.step_6_identify_candidate_drugs_gsea_cloudos_instance_disk_space
    summary['step_6_identify_candidate_drugs_gsea_cloudos_nextflow_profile'] = params.step_6_identify_candidate_drugs_gsea_cloudos_nextflow_profile
    summary['step_6_identify_candidate_drugs_gsea_cloudos_instance_type'] = params.step_6_identify_candidate_drugs_gsea_cloudos_instance_type
    summary['step_6_identify_candidate_drugs_gsea_cloudos_queue_name'] = params.step_6_identify_candidate_drugs_gsea_cloudos_queue_name
    summary['step_6_identify_candidate_drugs_gsea_cloudos_wait_time'] = params.step_6_identify_candidate_drugs_gsea_cloudos_wait_time
    summary['step_6_identify_candidate_drugs_gsea_git_tag'] = params.step_6_identify_candidate_drugs_gsea_git_tag
    summary['step_6_identify_candidate_drugs_gsea_summary_stats'] = params.step_6_identify_candidate_drugs_gsea_summary_stats
    summary['step_6_identify_candidate_drugs_gsea_snp_col_name'] = params.step_6_identify_candidate_drugs_gsea_snp_col_name
    summary['step_6_identify_candidate_drugs_gsea_pval_col_name'] = params.step_6_identify_candidate_drugs_gsea_pval_col_name
    summary['step_6_identify_candidate_drugs_gsea_ref_panel_bed'] = params.step_6_identify_candidate_drugs_gsea_ref_panel_bed
    summary['step_6_identify_candidate_drugs_gsea_ref_panel_bim'] = params.step_6_identify_candidate_drugs_gsea_ref_panel_bim
    summary['step_6_identify_candidate_drugs_gsea_ref_panel_fam'] = params.step_6_identify_candidate_drugs_gsea_ref_panel_fam
    summary['step_6_identify_candidate_drugs_gsea_ref_panel_synonyms'] = params.step_6_identify_candidate_drugs_gsea_ref_panel_synonyms
    summary['step_6_identify_candidate_drugs_gsea_gene_loc_file'] = params.step_6_identify_candidate_drugs_gsea_gene_loc_file
    summary['step_6_identify_candidate_drugs_gsea_set_anot_file'] = params.step_6_identify_candidate_drugs_gsea_set_anot_file
    summary['step_6_identify_candidate_drugs_gsea_reference_data_bucket'] = params.step_6_identify_candidate_drugs_gsea_reference_data_bucket
    summary['step_6_identify_candidate_drugs_drug2ways_cloudos_job_name'] = params.step_6_identify_candidate_drugs_drug2ways_cloudos_job_name
    summary['step_6_identify_candidate_drugs_drug2ways_cloudos_cost_limit'] = params.step_6_identify_candidate_drugs_drug2ways_cloudos_cost_limit
    summary['step_6_identify_candidate_drugs_drug2ways_cloudos_instance_disk_space'] = params.step_6_identify_candidate_drugs_drug2ways_cloudos_instance_disk_space
    summary['step_6_identify_candidate_drugs_drug2ways_cloudos_nextflow_profile'] = params.step_6_identify_candidate_drugs_drug2ways_cloudos_nextflow_profile
    summary['step_6_identify_candidate_drugs_drug2ways_cloudos_instance_type'] = params.step_6_identify_candidate_drugs_drug2ways_cloudos_instance_type
    summary['step_6_identify_candidate_drugs_drug2ways_cloudos_queue_name'] = params.step_6_identify_candidate_drugs_drug2ways_cloudos_queue_name
    summary['step_6_identify_candidate_drugs_drug2ways_cloudos_wait_time'] = params.step_6_identify_candidate_drugs_drug2ways_cloudos_wait_time
    summary['step_6_identify_candidate_drugs_drug2ways_git_tag'] = params.step_6_identify_candidate_drugs_drug2ways_git_tag
    summary['step_6_identify_candidate_drugs_drug2ways_targets'] = params.step_6_identify_candidate_drugs_drug2ways_targets
    summary['step_6_identify_candidate_drugs_drug2ways_omnipathr_container'] = params.step_6_identify_candidate_drugs_drug2ways_omnipathr_container
    summary['step_6_identify_candidate_drugs_drug2ways_get_drugs'] = params.step_6_identify_candidate_drugs_drug2ways_get_drugs
    summary['step_6_identify_candidate_drugs_drug2ways_network'] = params.step_6_identify_candidate_drugs_drug2ways_network
    summary['step_6_identify_candidate_drugs_drug2ways_sources'] = params.step_6_identify_candidate_drugs_drug2ways_sources
    summary['step_6_identify_candidate_drugs_drug2ways_lmax'] = params.step_6_identify_candidate_drugs_drug2ways_lmax
    summary['step_6_identify_candidate_drugs_drug2ways_reference_data_bucket'] = params.step_6_identify_candidate_drugs_drug2ways_reference_data_bucket
}


log.info summary.collect { k,v -> "${k.padRight(18)}: $v" }.join("\n")
log.info "-\033[2m--------------------------------------------------\033[0m-"

/* --------------------
| Help Message         |
--------------------- */

def helpMessage() {
    if ( workflow.userName != "ec2-user" ) {
        log.info lifebitLogo()
    }
    log.info """
    Usage:
    The typical command for running the pipeline is as follows (using default parameters):

    nextflow run main.nf --cloudos_api_key '****'

    Mandatory:
    --cloudos_api_key     CloudOS workspace API key

    For a full set of options for each step of the orchestrator, please take a look at `docs/README.md`.

    Resource Options:
    --max_cpus          Maximum number of CPUs (int)
                        (default: $params.max_cpus)  
    --max_memory        Maximum memory (memory unit)
                        (default: $params.max_memory)
    --max_time          Maximum time (time unit)
                        (default: $params.max_time)

    """.stripIndent()
}

// Print Lifebit logo to stdout
if ( workflow.userName != "ec2-user" ) {
    print lifebitLogo()
}

// Show help message
if (params.help) {
    helpMessage()
    exit 0
}

// check mandatory params
if (!params.cloudos_api_key){
    exit 1, "Missing mandatory option to run analysis: '--cloudos_api_key'"
}

if (!params.step_1a_identify_genetic_associations_phenofile_sql_specification){
    exit 1, "Missing mandatory option to run analysis: '--step_1a_identify_genetic_associations_phenofile_sql_specification'"
}

if (!params.step_1a_identify_genetic_associations_phenofile_database_cdm_schema){
    exit 1, "Missing mandatory option to run analysis: '--step_1a_identify_genetic_associations_phenofile_database_cdm_schema'"
}

if (!params.step_1a_identify_genetic_associations_phenofile_pheno_label){
    exit 1, "Missing mandatory option to run analysis: '--step_1a_identify_genetic_associations_phenofile_pheno_label'"
}

/* --------------------
| Main workflow        |
--------------------- */

workflow {

    configure_project()

    project_dir = workflow.projectDir

    if( workflow.workDir.toString().startsWith("/${params.cloudos_workdir}") ) {
        end_to_end_job_id = workflow.workDir.subpath(8,9).toString()
    }
    pheno_job_id = false
    gwas_job_id = false
    harmonised_job_id = false
    step_2_job_id = false
    step_3_job_id = false
    step_4_job_id = false
    liftover_job_id = false
    finemapping_job_id = false
    cheers_job_id = false
    gsea_job_id = false
    drug2ways_job_id = false

    if (params.step_1) {
        // generate phenofile
        trigger_step_1a_identify_genetic_associations_phenofile(
            configure_project.out.ch_project_name,
            configure_project.out.ch_project_bucket,
            configure_project.out.ch_workspace_id,
            end_to_end_job_id
        )
        phenofile = step_check(
            trigger_step_1a_identify_genetic_associations_phenofile.out.ch_phenofile_out
        )        
        genotype_files_list = step_check(
            trigger_step_1a_identify_genetic_associations_phenofile.out.ch_genotype_files_list
        )
        pheno_job_id = trigger_step_1a_identify_genetic_associations_phenofile.out.ch_step_1a_job_id

        // run gwas (regenie)
        trigger_step_1b_gwas_prepare_multi_sample_genotypes(
            phenofile,
            genotype_files_list,
            configure_project.out.ch_project_name,
            configure_project.out.ch_project_bucket,
            configure_project.out.ch_workspace_id,
            end_to_end_job_id
        )
        geno_out_ld_pruned = step_check(
            trigger_step_1b_gwas_prepare_multi_sample_genotypes.out.ch_geno_out_ld_pruned
        )
        geno_out_merged = step_check(
            trigger_step_1b_gwas_prepare_multi_sample_genotypes.out.ch_geno_out_merged
        )

        step_1b_geno_multisample = trigger_step_1b_gwas_prepare_multi_sample_genotypes.out.ch_step_1b_geno_multisample

        trigger_step_1b_gwas_annotate_samples(
            geno_out_ld_pruned,
            geno_out_ld_pruned,
            configure_project.out.ch_project_name,
            configure_project.out.ch_project_bucket,
            configure_project.out.ch_workspace_id,
            end_to_end_job_id
        )

        pca_out = step_check(
            trigger_step_1b_gwas_annotate_samples.out.ch_pca_out
        )

        trigger_step_1b_gwas(
            phenofile,
            genotype_files_list,
            pca_out,
            configure_project.out.ch_project_name,
            configure_project.out.ch_project_bucket,
            configure_project.out.ch_workspace_id,
            end_to_end_job_id
        )

        // run harmonisation
        trigger_step_1c_identify_genetic_associations_harmonisation(
            gwas,
            configure_project.out.ch_project_name,
            configure_project.out.ch_project_bucket,
            configure_project.out.ch_workspace_id,
            end_to_end_job_id
        )
        harmonised = step_check(
            trigger_step_1c_identify_genetic_associations_harmonisation.out.ch_harmonisation_out
        )
        harmonised_job_id = trigger_step_1c_identify_genetic_associations_harmonisation.out.ch_step_1c_job_id
    } else {
        harmonised = false
    }
    if (! harmonised) {
        exit 0, "There are no harmonised summary statistics available to progress through the drug discovery"
    }

    if (params.step_2) {
        trigger_step_2_identify_prioritised_genes(
            harmonised,
            configure_project.out.ch_project_name,
            configure_project.out.ch_project_bucket,
            configure_project.out.ch_workspace_id,
            end_to_end_job_id
        )
        step_2_job_id = trigger_step_2_identify_prioritised_genes.out.ch_step_2_job_id
        ch_step_2_results_dir = file_check(
            trigger_step_2_identify_prioritised_genes.out.ch_step_2_results_dir,
            "$project_dir/assets/NO_FILE_STEP_2"
        )
    } else {
        ch_step_2_results_dir = Channel.fromPath("$project_dir/assets/NO_FILE_STEP_2")
    }

    if (params.step_3) {
        trigger_step_3_identify_causal_genes_and_pathways(
            harmonised,
            configure_project.out.ch_project_name,
            configure_project.out.ch_project_bucket,
            configure_project.out.ch_workspace_id,
            end_to_end_job_id
        )
        step_3_job_id = trigger_step_3_identify_causal_genes_and_pathways.out.ch_step_3_job_id
        ch_step_3_results_dir = file_check(
            trigger_step_3_identify_causal_genes_and_pathways.out.ch_step_3_results_dir,
            "$project_dir/assets/NO_FILE_STEP_3"
        )
    } else {
        ch_step_3_results_dir = Channel.fromPath("$project_dir/assets/NO_FILE_STEP_3")
    }

    if (params.step_4) {
        trigger_step_4_identify_causal_proteins(
            harmonised,
            configure_project.out.ch_project_name,
            configure_project.out.ch_project_bucket,
            configure_project.out.ch_workspace_id,
            end_to_end_job_id
        )
        step_4_job_id = trigger_step_4_identify_causal_proteins.out.ch_step_4_job_id
        ch_step_4_results_dir = file_check(
            trigger_step_4_identify_causal_proteins.out.ch_step_4_results_dir,
            "$project_dir/assets/NO_FILE_STEP_4"
        )
    } else {
        ch_step_4_results_dir = Channel.fromPath("$project_dir/assets/NO_FILE_STEP_4")
    }

    if (params.step_5) {
        trigger_step_5_identify_mechanism_of_action_liftover(
            harmonised,
            configure_project.out.ch_project_name,
            configure_project.out.ch_project_bucket,
            configure_project.out.ch_workspace_id,
            end_to_end_job_id
        )
        ch_step_5_liftover_results = step_check(
            trigger_step_5_identify_mechanism_of_action_liftover.out.ch_liftovered_gwas_vcf
        )
        if (! ch_step_5_liftover_results as Boolean) {
            log.warn "There are no lifted over summary statistics available to progress through the Mechanism of Action"
        } else {
            trigger_step_5_identify_mechanism_of_action_finemapping(
                ch_step_5_liftover_results,
                configure_project.out.ch_project_name,
                configure_project.out.ch_project_bucket,
                configure_project.out.ch_workspace_id,
                end_to_end_job_id
            )
            ch_step_5_finemapping_results = step_check(
                trigger_step_5_identify_mechanism_of_action_finemapping.out.ch_finemapping_out
            )
            if (! ch_step_5_finemapping_results as Boolean) {
                log.warn "There are no finemapping results available to progress through the Mechanism of Action"
            } else {
                trigger_step_5_identify_mechanism_of_action_cheers(
                    trigger_step_5_identify_mechanism_of_action_finemapping.out.ch_finemapping_out,
                    configure_project.out.ch_project_name,
                    configure_project.out.ch_project_bucket,
                    configure_project.out.ch_workspace_id,
                    end_to_end_job_id
                )
            }
            liftover_job_id = trigger_step_5_identify_mechanism_of_action_liftover.out.ch_liftover_job_id
            finemapping_job_id = trigger_step_5_identify_mechanism_of_action_finemapping.out.ch_finemapping_job_id
            cheers_job_id = trigger_step_5_identify_mechanism_of_action_cheers.out.ch_cheers_job_id
            ch_step_5_results_dir = file_check(
                trigger_step_5_identify_mechanism_of_action_cheers.out.ch_step_5_results_dir,
                "$project_dir/assets/NO_FILE_STEP_5"
            )
        }
    } else {
        ch_step_5_results_dir = Channel.fromPath("$project_dir/assets/NO_FILE_STEP_5")
    }

    if (params.step_6) {
        trigger_step_6_identify_candidate_drugs_gsea(
            harmonised,
            configure_project.out.ch_project_name,
            configure_project.out.ch_project_bucket,
            configure_project.out.ch_workspace_id,
            end_to_end_job_id
        )
        ch_step_6_gsea_results = step_check(
            trigger_step_6_identify_candidate_drugs_gsea.out.ch_gsea_genenames
        )
        if (! ch_step_6_gsea_results as Boolean) {
            log.warn "There are no causal genes results available to progress through the Candidate Drug Identification"
        } else {
            trigger_step_6_identify_candidate_drugs_drug2ways(
                ch_step_6_gsea_results,
                configure_project.out.ch_project_name,
                configure_project.out.ch_project_bucket,
                configure_project.out.ch_workspace_id,
                end_to_end_job_id
            )
            gsea_job_id = trigger_step_6_identify_candidate_drugs_gsea.out.ch_gsea_job_id
            drug2ways_job_id = trigger_step_6_identify_candidate_drugs_drug2ways.out.ch_drug2ways_job_id
            ch_step_6_results_dir = file_check(
                trigger_step_6_identify_candidate_drugs_drug2ways.out.ch_step_6_results_dir,
                "$project_dir/assets/NO_FILE_STEP_6"
            )
        }
    } else {
        ch_step_6_results_dir = Channel.fromPath("$project_dir/assets/NO_FILE_STEP_6")
    }

    ch_report_dir = Channel.value(file("$project_dir/bin/report"))

    combine_reports(
        ch_report_dir,
        ch_step_2_results_dir,
        ch_step_3_results_dir,
        ch_step_4_results_dir,
        ch_step_5_results_dir,
        ch_step_6_results_dir,
        pheno_job_id,
        gwas_job_id,
        harmonised_job_id,
        step_2_job_id,
        step_3_job_id,
        step_4_job_id,
        liftover_job_id,
        finemapping_job_id,
        cheers_job_id,
        gsea_job_id,
        drug2ways_job_id
    )

}

// ANSII string of Lifebit logo
def lifebitLogo() {
    logo  = """
        .................................................................................................
        .................███████.........................................................................
        ..............███.......███......................................................................
        .............███.........███.....................................................................
        ..............███.......███.........██...██.....██████.............██..............██....██......
        ...............████...████..........██.........██..................██....................██......
        ..............██..█████.............██...██...██████....███████....██...█████......██..███████...
        ............██.......██.............██...██....██....███.......██..████.......██...██....██......
        .....███████..........██............██...██....██...██████████████.███.........██..██....██......
        ....██....██...........██...........██...██....██...██.............███.........██..██....██......
        .....██████............████.........██...██....██....██.........█..███........███..██....██......
        ....................███....███......██...██....██......█████████...██.█████████....██....██......
        ....................██......███..................................................................
        ....................███....███...................................................................
        ......................██████.....................................................................
        .................................................................................................
        """.stripIndent()
    return logo
}
