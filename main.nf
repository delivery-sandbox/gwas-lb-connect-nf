#!/usr/bin/env nextflow
/*
====================================================================================================
|                        drug-discovery-protocol-orchestrator-nf                                   |
====================================================================================================
|    #### Homepage / Documentation                                                                 |
|    https://github.com/lifebit-ai/drug-discovery-protocol-orchestrator-nf/blob/dev/docs/README.md |
----------------------------------------------------------------------------------------------------
*/

nextflow.enable.dsl = 2

/* --------------------
| Imports              |
--------------------- */
include { configure_project } from './modules/utils/configure_project.nf'
include { trigger_step_1a_identify_genetic_associations_phenofile } from './modules/step_1/step_1a_identify_genetic_associations_phenofile.nf'
include { trigger_step_1b_identify_genetic_associations_gwas } from './modules/step_1/step_1b_identify_genetic_associations_gwas.nf'
include { trigger_step_1c_identify_genetic_associations_harmonisation } from './modules/step_1/step_1c_identify_genetic_associations_harmonisation.nf'
include { trigger_step_2_identify_prioritised_genes } from './modules/step_2/identify_prioritised_genes.nf'
include { trigger_step_3_identify_causal_genes_and_pathways } from './modules/step_3/identify_causal_genes_and_pathways.nf'
include { trigger_step_4_identify_causal_proteins } from './modules/step_4/identify_causal_proteins.nf'
include { trigger_step_5_identify_mechanism_of_action_liftover } from './modules/step_5/identify_mechanism_of_action.nf'
include { trigger_step_5_identify_mechanism_of_action_finemapping } from './modules/step_5/identify_mechanism_of_action.nf'
include { trigger_step_5_identify_mechanism_of_action_cheers } from './modules/step_5/identify_mechanism_of_action.nf'
include { trigger_step_6_identify_candidate_drugs_gsea } from './modules/step_6/identify_candidate_drugs.nf'
include { trigger_step_6_identify_candidate_drugs_drug2ways } from './modules/step_6/identify_candidate_drugs.nf'
include { generate_job_id_report } from './modules/utils/generate_job_id_report.nf'

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
if ([params.cloudos_api_key as Boolean,
    params.step_1a_identify_genetic_associations_phenofile_sql_specification as Boolean,
    params.step_1a_identify_genetic_associations_phenofile_database_cdm_schema as Boolean,
    params.step_1a_identify_genetic_associations_phenofile_pheno_label as Boolean,].count(true) < 4){

    exit 1, "Missing mandatory options to run analysis: --cloudos_api_key, " + \
            "--step_1a_identify_genetic_associations_phenofile_sql_specification, " + \
            "--step_1a_identify_genetic_associations_phenofile_database_cdm_schema, " + \
            " --step_1a_identify_genetic_associations_phenofile_pheno_label"
}

workflow {

    configure_project()

    if (params.step_1) {
        // generate phenofile
        trigger_step_1a_identify_genetic_associations_phenofile(
            configure_project.out.ch_project_name,
            configure_project.out.ch_project_bucket
        )
        phenofile = trigger_step_1a_identify_genetic_associations_phenofile.out.ch_phenofile_out
        genotype_files_list = trigger_step_1a_identify_genetic_associations_phenofile.out.ch_genotype_files_list
        pheno_job_id = trigger_step_1a_identify_genetic_associations_phenofile.out.ch_step_1a_job_id

        // run gwas (regenie)
        trigger_step_1b_identify_genetic_associations_gwas(
            phenofile,
            genotype_files_list,
            configure_project.out.ch_project_name,
            configure_project.out.ch_project_bucket
        )
        gwas = trigger_step_1b_identify_genetic_associations_gwas.out.ch_gwas_out
        gwas_job_id = trigger_step_1b_identify_genetic_associations_gwas.out.ch_step_1b_job_id

        // run harmonisation
        trigger_step_1c_identify_genetic_associations_harmonisation(
            gwas,
            configure_project.out.ch_project_name,
            configure_project.out.ch_project_bucket
        )
        harmonised = trigger_step_1c_identify_genetic_associations_harmonisation.out.ch_harmonisation_out
        harmonised_job_id = trigger_step_1c_identify_genetic_associations_harmonisation.out.ch_step_1c_job_id
    } else {
        harmonised = false
        pheno_job_id = false
        gwas_job_id = false
        harmonised_job_id = false
    }

    if (params.step_2) {
        trigger_step_2_identify_prioritised_genes(
            harmonised,
            configure_project.out.ch_project_name
        )
        step_2_job_id = trigger_step_2_identify_prioritised_genes.out.ch_step_2_job_id
    } else {
        step_2_job_id = false
    }

    if (params.step_3) {
        trigger_step_3_identify_causal_genes_and_pathways(
            harmonised,
            configure_project.out.ch_project_name   
        )
        step_3_job_id = trigger_step_3_identify_causal_genes_and_pathways.out.ch_step_3_job_id
    } else {
        step_3_job_id = false
    }

    if (params.step_4) {
        trigger_step_4_identify_causal_proteins(
            harmonised,
            configure_project.out.ch_project_name
        )
        step_4_job_id = trigger_step_4_identify_causal_proteins.out.ch_step_4_job_id
    } else {
        step_4_job_id = false
    }

    if (params.step_5) {
        trigger_step_5_identify_mechanism_of_action_liftover(
            harmonised,
            configure_project.out.ch_project_name,
            configure_project.out.ch_project_bucket
        )
        trigger_step_5_identify_mechanism_of_action_finemapping(
            trigger_step_5_identify_mechanism_of_action_liftover.out.ch_liftovered_gwas_vcf,
            configure_project.out.ch_project_name,
            configure_project.out.ch_project_bucket
        )
        trigger_step_5_identify_mechanism_of_action_cheers(
            trigger_step_5_identify_mechanism_of_action_finemapping.out.ch_finemapping_out,
            configure_project.out.ch_project_name
        )
        liftover_job_id = trigger_step_5_identify_mechanism_of_action_liftover.out.ch_liftover_job_id
        finemapping_job_id = trigger_step_5_identify_mechanism_of_action_finemapping.out.ch_finemapping_job_id
        cheers_job_id = trigger_step_5_identify_mechanism_of_action_cheers.out.ch_cheers_job_id
    } else {
        liftover_job_id = false
        finemapping_job_id = false
        cheers_job_id = false
    }

    if (params.step_6) {
        trigger_step_6_identify_candidate_drugs_gsea(
            harmonised,
            configure_project.out.ch_project_name,
            configure_project.out.ch_project_bucket
        )
        trigger_step_6_identify_candidate_drugs_drug2ways(
            trigger_step_6_identify_candidate_drugs_gsea.out.ch_gsea_genenames,
            configure_project.out.ch_project_name
        )
        gsea_job_id = trigger_step_6_identify_candidate_drugs_gsea.out.ch_gsea_job_id
        drug2ways_job_id = trigger_step_6_identify_candidate_drugs_drug2ways.out.ch_drug2ways_job_id
    } else {
        gsea_job_id = false
        drug2ways_job_id = false
    }

    generate_job_id_report(
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

// Trace report
user_name = workflow.userName

if (user_name == "ubuntu" || user_name == "ec2-user") {
    workflow.onComplete {
        def trace_timestamp = new java.util.Date().format('yyyy-MM-dd_HH-mm-ss')
        trace_report = file("/home/${user_name}/nf-out/trace.txt")
        trace_report.copyTo("results/pipeline_info/execution_trace_${trace_timestamp}.txt")
    }
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
