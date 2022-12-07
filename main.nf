#!/usr/bin/env nextflow
/*
========================================================================================
                         lifebit-ai/etl_omop2phenofile
========================================================================================
lifebit-ai/etl_omop2phenofile
 #### Homepage / Documentation
https://github.com/lifebit-ai/etl_omop2phenofile
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
    --database_name "omop_data" \
    --database_host "localhost" \
    --database_port 5432 \
    --database_username "username" \
    --database_password "pass"

    Essential parameters:
    --covariateSpecifications   A file containing details of the covariates to include in the phenofile
    --cohortSpecifications      A file containing user-made cohort(s) specification

    Database parameters:
    --database_name             A database name
    --database_host             A database host
    --database_port             A database port
    --database_username         A database user name
    --database_password         A database password
    --database_dbms             A database dbms
    --database_cdm_schema       A database cdm schema
    --database_cohort_schema    A database cohort schema

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

summary['phenofileName']                               = params.phenofileName

summary['covariateSpecifications']                     = params.covariateSpecifications
summary['cohortSpecifications']                        = params.cohortSpecifications
summary['codelistSpecifications']                      = params.cohortSpecifications
summary['domain']                                      = params.domain
summary['conceptType']                                 = params.conceptType
summary['controlIndexDate']                            = params.controlIndexDate

summary['sqlite_db']                                   = params.sqlite_db
summary['database_dbms']                               = params.database_dbms
summary['database_cdm_schema']                         = params.database_cdm_schema
summary['database_cohort_schema']                      = params.database_cohort_schema

if (params.param_via_aws){
  summary['aws_param_name_for_database_host']          = params.aws_param_name_for_database_host
  summary['aws_param_name_for_database_name']          = params.aws_param_name_for_database_name
  summary['aws_param_name_for_database_port']          = params.aws_param_name_for_database_port
  summary['aws_param_name_for_database_username']      = params.aws_param_name_for_database_username
} else {
  summary['database_name']                             = params.database_name
  summary['database_host']                             = params.database_host
  summary['database_port']                             = params.database_port
  summary['database_username']                         = params.database_username
}

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

if (!params.cohortSpecifications & !params.codelistSpecifications) {
  exit 1, "You have not supplied a file containing user-made cohort(s) specification or a codelist.\
  \nPlease use --cohortSpecifications or --codelistSpecifications."
}

if (!!params.cohortSpecifications & !!params.codelistSpecifications) {
  exit 1, "Choose either a cohort specifaction or a codelist specfication."
}

if (!!params.codelistSpecifications & !(!!params.conceptType & !!params.domain & !!params.controlIndexDate)) {
  exit 1, "When using a codelist specfication you must also specity a conceptType, a domain, and an index date for controls."
}

if (!params.database_cdm_schema) {
  exit 1, "You have not supplied the database cdm schema name.\
  \nPlease use --database_cdm_schema."
}

if (!params.database_cohort_schema) {
  exit 1, "You have not supplied the database cohort schema name.\
  \nPlease use --database_cohort_schema."
}

// Setting up channels

Channel
  .fromPath(params.covariateSpecifications)
  .set { ch_covariate_specification }

if (!!params.cohortSpecifications) {
  Channel
    .fromPath(params.cohortSpecifications)
    .into { ch_cohort_specification_for_json ; ch_cohort_specification_for_cohorts }
}

Channel
    .value(params.phenofileName)
    .set{ ch_phenofile_name}

if (params.codelistSpecifications) {
  Channel
    .fromPath(params.codelistSpecifications)
    .set { ch_codelist }

  Channel
    .value(params.conceptType)
    .set{ ch_concept_type}

  Channel
    .value(params.domain)
    .set{ ch_domain }

  Channel
    .value(params.controlIndexDate)
    .set{ ch_control_group_occurrence }
}

Channel
    .fromPath("${projectDir}/${params.path_to_db_jars}",  type: 'file', followLinks: false)
    .into { ch_db_jars_for_cohorts; ch_db_jars_for_covariates ; ch_db_jars_for_json ; ch_db_jars_for_codelist }

Channel
    .fromPath(params.sqlite_db)
    .into { ch_sqlite_db_cohorts; ch_sqlite_db_json; ch_sqlite_db_for_codelist }

Channel
    .value(params.convert_plink)
    .set{ ch_convert_plink }

  Channel
    .value(params.pheno_label)
    .set{ ch_pheno_label }


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


Channel
  .fromPath("${projectDir}/bin/simpleCohortSpecFromCsv.R")
  .set { ch_codelist_script }

/*---------------------
  Retrieve parameters
-----------------------*/
if (params.param_via_aws){
  if ((!params.aws_param_name_for_database_name) || (!params.aws_param_name_for_database_host) || (!params.aws_param_name_for_database_port) || (!params.aws_param_name_for_database_username) || (!params.aws_param_name_for_database_password)) {
    exit 1, "You have not supplied all aws parameter locations.\
    \nPlease use --aws_param_name_for_*."
  }
}
process retrieve_parameters {

  output:
  file ("*.log") into ch_retrieve_ssm_parameters_log
  file ("*.json") into ( ch_connection_details_for_json, ch_connection_details_for_cohorts, ch_connection_details_for_covariates, ch_connection_details_for_codelist )

  shell:
  '''
  if [ !{params.param_via_aws} = true ]
  then
    database_host=\$(aws ssm get-parameter --name "!{params.aws_param_name_for_database_host}" --region !{params.aws_region} | jq -r ".Parameter.Value")
    database_port=\$(aws ssm get-parameter --name "!{params.aws_param_name_for_database_port}" --region !{params.aws_region} | jq -r ".Parameter.Value")
    database_username=\$(aws ssm get-parameter --name "!{params.aws_param_name_for_database_username}" --region !{params.aws_region} | jq -r ".Parameter.Value")
    database_password=\$(aws ssm get-parameter --name "!{params.aws_param_name_for_database_password}" --region !{params.aws_region} | jq -r ".Parameter.Value")
    database_name=\$(aws ssm get-parameter --name "!{params.aws_param_name_for_database_name}" --region !{params.aws_region} | jq -r ".Parameter.Value")
  else
    database_host="!{params.database_host}"
    database_port="!{params.database_port}"
    database_username="!{params.database_username}"
    database_password="!{params.database_password}"
    database_name="!{params.database_name}"
  fi

  string="{\n"
  string+='"dbms":"!{params.database_dbms}",\n'

  if [[ "\$database_name" != "false"  && "\$database_password" != "false" && "\$database_username" != "false" && "\$database_port" != "false" ]]
  then
    string=$(echo $string'"server":"'\$database_host'/'\$database_name'",\n')
    string=$(echo $string'"port":"'\$database_port'",\n')
    string=$(echo $string'"user":"'\$database_username'",\n')
    string=$(echo $string'"password":"'\$database_password'",\n')
  else
    string=$(echo $string'"server":"'\$database_host'",\n')
  fi

  string+='"cdmDatabaseSchema":"!{params.database_cdm_schema}",\n'
  string+='"cohortDatabaseSchema":"!{params.database_cohort_schema}"\n'
  string+="\n}"
  echo $string
  echo -e $string > connection_details.json

  echo "Database parameters were retrieved" > ssm_parameter_retrieval.log
  '''
}

if (params.codelistSpecifications) {

  process generate_user_spec_from_codelist {
    publishDir "${params.outdir}/cohorts/user_def", mode: "copy"

    input:
    each file("simpleCohortSpecFromCsv.R") from ch_codelist_script
    each file(codelist) from ch_codelist
    each file(db_jars) from ch_db_jars_for_codelist
    each file(connection_details) from ch_connection_details_for_codelist
    each file(sqlite_db) from ch_sqlite_db_for_codelist
    val concept_type from ch_concept_type
    val domain from ch_domain
    val control_group_occurrence from ch_control_group_occurrence

    output:
    file("*json") into ( ch_cohort_specification_for_json , ch_cohort_specification_for_cohorts )

    shell:
    """
    ## Make a permanent copy of sqlite file (NB. This is only used in sqlite testing mode)
    ls -la
    mkdir omopdb/
    chmod 0766 ${sqlite_db}
    cp ${sqlite_db} omopdb/omopdb.sqlite
    mv omopdb/omopdb.sqlite .
    Rscript simpleCohortSpecFromCsv.R \
      --codelist=${codelist} \
      --connection_details=${connection_details} \
      --db_jars=${db_jars} \
      --concept_types=${concept_type} \
      --domain=${domain} \
      --control_group_occurrence=${control_group_occurrence}
    """
}

}



/*---------------------------------------------------------------------------------------
  Obtain a OHDSI JSON cohort definition using a user-made input JSON specification file
------------------------------------------------------------------------------------------*/

process generate_cohort_jsons_from_user_spec {
  publishDir "${params.outdir}/cohorts/json", mode: "copy"

  input:
  each file("createCohortJsonFromSpec.R") from ch_cohort_json_from_spec_script
  each file(spec) from ch_cohort_specification_for_json
  each file(db_jars) from ch_db_jars_for_json
  each file(connection_details) from ch_connection_details_for_json
  each file(sqlite_db) from ch_sqlite_db_json

  output:
  file("*json") into (ch_cohort_json_for_cohorts)

  shell:
  """
  ## Make a permanent copy of sqlite file (NB. This is only used in sqlite testing mode)
  mkdir omopdb/
  chmod 0766 ${sqlite_db}
  cp ${sqlite_db} omopdb/omopdb.sqlite
  mv omopdb/omopdb.sqlite .
  Rscript createCohortJsonFromSpec.R \
  --cohort_specs=${spec} \
  --connection_details=${connection_details} \
  --db_jars=${db_jars}
  """
}



/*-------------------------------------------------------------------------
  Using the cohort definition file(s), write cohort(s) in the OMOP database
----------------------------------------------------------------------------*/

process generate_cohorts_in_db {
  publishDir "${params.outdir}", mode: "copy",
   saveAs: { filename -> 
      if (filename.endsWith('csv')) "cohorts/$filename"
    }

  input:
  each file("generateCohorts.R") from ch_generate_cohorts_script
  each file(connection_details) from ch_connection_details_for_cohorts
  file("*") from ch_cohort_json_for_cohorts.collect()
  each file(spec) from ch_cohort_specification_for_cohorts
  each file(db_jars) from ch_db_jars_for_cohorts
  each file(sqlite_db) from ch_sqlite_db_cohorts

  output:
  file("*txt") into (ch_cohort_table_name)
  file("*csv") into (ch_cohort_counts)
  file("omopdb.sqlite") into (ch_sqlite_db_covariates)

  shell:
  """
  ## Make a permanent copy of sqlite file (NB. This is only used in sqlite testing mode)
  mkdir omopdb/
  chmod 0766 ${sqlite_db}
  cp ${sqlite_db} omopdb/omopdb.sqlite
  mv omopdb/omopdb.sqlite .
  Rscript generateCohorts.R --connection_details=${connection_details} --db_jars=${db_jars} --cohort_specs=${spec}
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
  each file(db_jars) from ch_db_jars_for_covariates
  each file(sqlite_db) from ch_sqlite_db_covariates
  val pheno_label from ch_pheno_label
  val convert_plink from ch_convert_plink
  val phenofile_name from ch_phenofile_name

  output:
  file("*phe") into (ch_pheno_for_standardise)

  shell:
  """
  Rscript generatePhenofile.R \
    --connection_details=${connection_details} \
    --cohort_counts=${cohort_counts} \
    --cohort_table=${cohort_table_name} \
    --covariate_spec=${covariate_specs} \
    --db_jars=${db_jars} \
    --pheno_label=${pheno_label} \
    --convert_plink=${convert_plink} \
    --phenofile_name=${phenofile_name}
  """
}

// from gwas-nf pipeline

process standardise_phenofile_and_get_samples {

  label 'gwas_deafault'
  input:
  file('original.pheno.tsv') from ch_pheno_for_standardise
  //each file('transform_pheno.R') from Channel.fromPath("${projectDir}/bin/transform_pheno.R")

  output:
  file("notransform.phe") into ch_standardised_pheno
  file("all_samples.tsv") into ch_all_samples_file

  script:
  """
  # make dummy transform file to move params.phenotype_colname to 3rd column
  # and IGNORE anything that is not the phenotype column or specified covariate_column

  if [ "${params.phenotype_colname}" = "false" ]; then
    pheno_col=\$(head -n 1 original.pheno.tsv | cut -f3 )
  else
    pheno_col=${params.phenotype_colname}
  fi

  if [ "${params.covariate_cols}" = "ALL" ]; then
    covar_cols=\$(head -n 1 original.pheno.tsv | cut --complement -f1,2 | tr '\\t' ',')
  elif [ "${params.covariate_cols}" = "NONE" ]; then
    covar_cols=" "
  else
    covar_cols=${params.covariate_cols}
  fi

  awk -v covar_cols="\$covar_cols" -v pheno_col="\$pheno_col" '\
    BEGIN{FS=OFS="\\t"} \
    NR==1{ \
      \$1="run_id"; \$2="test"; \
      print \$0; \
      split(covar_cols,covs,","); for(i in covs){cols[covs[i]]}; \
      cols[pheno_col]; \
      \$1="notransform"; \$2=pheno_col; \
      for (i=3; i <= NF; i++){if(\$i in cols){\$i=""}else{\$i="IGNORE"}}; \
      print \$0 \
    }' original.pheno.tsv > dummmy_transform.tsv

  Rscript '$baseDir/bin/transform_pheno.R' \
    --pheno original.pheno.tsv \
    --transform dummmy_transform.tsv \
    --out_prefix ./

  cut -f1,2 notransform.phe > all_samples.tsv
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