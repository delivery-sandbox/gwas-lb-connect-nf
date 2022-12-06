#!/usr/bin/env nextflow
/*
========================================================================================
                         lifebit-ai/etl-omop2phenofile
========================================================================================
lifebit-ai/etl-omop2phenofile
 #### Homepage / Documentation
https://github.com/lifebit-ai/etl-omop2phenofile
----------------------------------------------------------------------------------------
*/

// Help message

def helpMessage() {
    log.info """
    Usage:
    The typical command for running the pipeline is as follows:
    nextflow run main.nf \
    --covariateSpecifications 'covariate_specs.json' \
    --cohortSpecifications 'user_cohort_specs.json' \
    --omopDbConnectionDetails 'connection_details.json'
    
    Essential parameters:
    --covariateSpecifications   A file containing details of the covariates to include in the phenofile
    --cohortSpecifications      A file containing user-made cohort(s) specification
    --omopDbConnectionDetails   A file containing connection details to connect to the database using DatabaseConnector

    See docs/README.md for more details.
    """.stripIndent()
}

// Show help message
if (params.help) {
  helpMessage()
  exit 0
}



/*--------------------------------------------------------
  Defining and showing header with all params information 
-----------------------------------------------------------*/

// Header log info

def summary = [:]

if (workflow.revision) summary['Pipeline Release'] = workflow.revision

summary['Output dir']                                  = params.outdir
summary['Launch dir']                                  = workflow.launchDir
summary['Working dir']                                 = workflow.workDir
summary['Script dir']                                  = workflow.projectDir
summary['User']                                        = workflow.userName

summary['covariateSpecifications']                     = params.covariateSpecifications
summary['cohortSpecifications']                        = params.cohortSpecifications
summary['cohortJsonSkeleton']                          = params.cohortJsonSkeleton

summary['omopDbConnectionDetails']                     = params.omopDbConnectionDetails

log.info summary.collect { k,v -> "${k.padRight(18)}: $v" }.join("\n")
log.info "-\033[2m--------------------------------------------------\033[0m-"



/*-------------------------------------------------
  Setting up introspection variables and channels  
----------------------------------------------------*/

// Importantly, in order to successfully introspect:
// - This needs to be done first `main.nf`, before any (non-head) nodes are launched. 
// - All variables to be put into channels in order for them to be available later in `main.nf`.

ch_repository         = Channel.of(workflow.manifest.homePage)
ch_commitId           = Channel.of(workflow.commitId ?: "Not available is this execution mode. Please run 'nextflow run ${workflow.manifest.homePage} [...]' instead of 'nextflow run main.nf [...]'")
ch_revision           = Channel.of(workflow.manifest.version)

ch_scriptName         = Channel.of(workflow.scriptName)
ch_scriptFile         = Channel.of(workflow.scriptFile)
ch_projectDir         = Channel.of(workflow.projectDir)
ch_launchDir          = Channel.of(workflow.launchDir)
ch_workDir            = Channel.of(workflow.workDir)
ch_userName           = Channel.of(workflow.userName)
ch_commandLine        = Channel.of(workflow.commandLine)
ch_configFiles        = Channel.of(workflow.configFiles)
ch_profile            = Channel.of(workflow.profile)
ch_container          = Channel.of(workflow.container)
ch_containerEngine    = Channel.of(workflow.containerEngine)



/*----------------------------------------------------------------
  Setting up additional variables used for documentation purposes  
-------------------------------------------------------------------*/

Channel
    .of(params.raci_owner)
    .set { ch_raci_owner } 

Channel
    .of(params.domain_keywords)
    .set { ch_domain_keywords }



/*----------------------
  Setting up input data  
-------------------------*/

// Define channels

projectDir = workflow.projectDir

// Ensuring essential parameters are supplied

if (!params.covariateSpecifications) {
  exit 1, "You have not supplied a file containing details of the covariates to include in the phenofile.\
  \nPlease use --covariateSpecifications."
}

if (!params.cohortSpecifications) {
  exit 1, "You have not supplied a file containing user-made cohort(s) specification.\
  \nPlease use --cohortSpecifications."
}

if (!params.omopDbConnectionDetails) {
  exit 1, "You have not supplied a file listing connection details to connect to the database using DatabaseConnector.\
  \nPlease use --omopDbConnectionDetails."
}

// Setting up channels

Channel
  .fromPath(params.covariateSpecifications)
  .set { ch_covariate_specification }

Channel
  .fromPath(params.omopDbConnectionDetails)
  .into { ch_connection_details_for_cohorts ; ch_connection_details_for_covariates }

Channel
  .fromPath(params.cohortSpecifications)
  .set { ch_cohort_specification }

Channel
  .fromPath("${projectDir}/${params.cohortJsonSkeleton}",  type: 'file', followLinks: false)
  .set { ch_cohort_skeleton }



/*-------------------------
  Setting up input scripts  
----------------------------*/

Channel
  .fromPath("${projectDir}/bin/createCohortJsonFromSpec.R")
  .set { ch_cohort_json_from_spec_script }

Channel
  .fromPath("${projectDir}/bin/generateCohorts.R")
  .set { ch_generate_cohorts_script }

Channel
  .fromPath("${projectDir}/bin/generatePhenofile.R")
  .set { ch_generate_covariates_script }



/*---------------------------------------------------------------------------------------
  Obtain a OHDSI JSON cohort definition using a user-made input JSON specification file
------------------------------------------------------------------------------------------*/

process generate_cohort_jsons_from_user_spec {
  publishDir "${params.outdir}/cohorts/json", mode: "copy"

  input:
  each file("createCohortJsonFromSpec.R") from ch_cohort_json_from_spec_script
  each file(spec) from ch_cohort_specification
  each file(skeleton) from ch_cohort_skeleton

  output:
  file("*json") into (ch_cohort_json)

  shell:
  """
  createCohortJsonFromSpec.R \
  --cohort_specs=${spec} \
  --cohort_skeleton=${skeleton}
  """
}



/*-------------------------------------------------------------------------
  Using the cohort definition file(s), write cohort(s) in the OMOP database
----------------------------------------------------------------------------*/

process generate_cohorts_in_db {
  publishDir "${params.outdir}/cohorts", mode: "copy"

  input:
  each file("generateCohorts.R") from ch_generate_cohorts_script
  each file(connection_details) from ch_connection_details_for_cohorts
  file("*") from ch_cohort_json.collect()

  output:
  file("*txt") into (ch_cohort_table_name)
  file("*csv") into (ch_cohort_counts)

  shell:
  """
  generateCohorts.R --connection_details=${connection_details}
  """
}



/*------------------------------------------------------------------------------------------------------------
  Generate a phenofile using the cohort(s) written to the OMOP database and an input covariate specification
--------------------------------------------------------------------------------------------------------------*/

process generate_phenofile {
  publishDir "${params.outdir}/phenofile", mode: "copy"

  input:
  each file("generatePhenofile.R") from ch_generate_covariates_script
  each file(connection_details) from ch_connection_details_for_covariates
  each file(cohort_table_name) from ch_cohort_table_name
  each file(covariate_specs) from ch_covariate_specification
  each file(cohort_counts) from ch_cohort_counts

  output:
  file("*csv") into (ch_covariates_file)

  shell:
  """
  generatePhenofile.R \
  --connection_details=${connection_details} \
  --cohort_counts=${cohort_counts} \
  --cohort_table=${cohort_table_name} \
  --covariate_spec=${covariate_specs}
  """
}



/*---------------------------
  Create introspection report
------------------------------*/

process obtain_pipeline_metadata {
  publishDir "${params.tracedir}", mode: "copy"

  input:
  val repository from ch_repository
  val commit from ch_commitId
  val revision from ch_revision
  val script_name from ch_scriptName
  val script_file from ch_scriptFile
  val project_dir from ch_projectDir
  val launch_dir from ch_launchDir
  val work_dir from ch_workDir
  val user_name from ch_userName
  val command_line from ch_commandLine
  val config_files from ch_configFiles
  val profile from ch_profile
  val container from ch_container
  val container_engine from ch_containerEngine
  val raci_owner from ch_raci_owner
  val domain_keywords from ch_domain_keywords

  output:
  file("pipeline_metadata_report.tsv") into ch_pipeline_metadata_report
  
  shell:
  '''
  echo "Repository\t!{repository}"                  > temp_report.tsv
  echo "Commit\t!{commit}"                         >> temp_report.tsv
  echo "Revision\t!{revision}"                     >> temp_report.tsv
  echo "Script name\t!{script_name}"               >> temp_report.tsv
  echo "Script file\t!{script_file}"               >> temp_report.tsv
  echo "Project directory\t!{project_dir}"         >> temp_report.tsv
  echo "Launch directory\t!{launch_dir}"           >> temp_report.tsv
  echo "Work directory\t!{work_dir}"               >> temp_report.tsv
  echo "User name\t!{user_name}"                   >> temp_report.tsv
  echo "Command line\t!{command_line}"             >> temp_report.tsv
  echo "Configuration file(s)\t!{config_files}"    >> temp_report.tsv
  echo "Profile\t!{profile}"                       >> temp_report.tsv
  echo "Container\t!{container}"                   >> temp_report.tsv
  echo "Container engine\t!{container_engine}"     >> temp_report.tsv
  echo "RACI owner\t!{raci_owner}"                 >> temp_report.tsv
  echo "Domain keywords\t!{domain_keywords}"       >> temp_report.tsv

  awk 'BEGIN{print "Metadata_variable\tValue"}{print}' OFS="\t" temp_report.tsv > pipeline_metadata_report.tsv
  '''
}

// When the pipeline is run is not run locally
// Ensure trace report is output in the pipeline results (in 'pipeline_info' folder)

userName = workflow.userName

if ( userName == "ubuntu" || userName == "ec2-user") {
  workflow.onComplete {

  def trace_timestamp = new java.util.Date().format( 'yyyy-MM-dd_HH-mm-ss')

  traceReport = file("/home/${userName}/nf-out/trace.txt")
  traceReport.copyTo("results/pipeline_info/execution_trace_${trace_timestamp}.txt")
  }
}