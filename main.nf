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



if (params.tre == 'bi') {
 params.config = 'conf/bi.config'
}

if (params.tre == 'gel') {
 params.config = 'conf/gel.config'
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

if (params.omop2pheofile_mode == true) {

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
  file("*phe") into ch_pheno_for_standardise

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
}

// from gwas-nf pipeline

def all_params =  params.collect{ k,v -> "$k=$v" }.join(", ")

if (params.omop2pheofile_mode == false){
  Channel
  .fromPath(params.pheno_data)
  .ifEmpty { exit 1, "Cannot find phenotype file : ${params.pheno_data}" }
  .into{
    ch_pheno_for_standardise;
    ch_pheno_for_transform;
  }
}

def get_chromosome( file ) {
    // using RegEx to extract chromosome number from file name
    regexpPE = /(?:chr)[a-zA-Z0-9]+/
    (file =~ regexpPE)[0].replaceAll('chr','')
}

def checkParameterList(list, realList) {
    return list.every{ checkParameterExistence(it, realList) }
}

def defineFormatList() {
    return [
      'bgen',
      'vcf'
    ]
}
/*--------------------------------------------------
  Channel setup
---------------------------------------------------*/
if (params.input_folder_location) {
  Channel.fromPath("${params.input_folder_location}/**${params.file_pattern}*.{${params.file_suffix},${params.index_suffix}}")
       .map { it -> [ get_chromosome(file(it).simpleName.minus(".${params.index_suffix}").minus(".${params.file_suffix}")), "s3:/"+it] }
       .groupTuple(by:0)
       .map { chr, files_pair -> [ chr, files_pair[0], files_pair[1] ] }
       .map { chr, vcf, index -> [ file(vcf).simpleName, chr, file(vcf), file(index) ] }
       .take( params.number_of_files_to_process )
       .set { ch_user_input_vcf }
}
// KING tool for ancestry inference reference data
Channel
  .fromFilePairs("${params.king_reference_data}",size:3, flat : true)
  .ifEmpty { exit 1, "KING reference data PLINK files not found: ${params.king_reference_data}.\nPlease specify a valid --king_reference_data value. e.g. refdata/king_ref*.{bed,bim,fam}" }
  .set{ ch_king_reference_data }

//Pheno transform file
ch_input_pheno_transform = Channel.fromPath("${params.pheno_transform}")

ch_rsid_cpra_table = Channel.fromPath("${params.rsid_cpra_table}")

projectDir = workflow.projectDir

ch_ancestry_inference_Rscript = Channel.fromPath("${projectDir}/bin/Ancestry_Inference.R", followLinks: false)
ch_rsid_annotation_pyscript = Channel.fromPath("${projectDir}/bin/annotate_with_rsids.py", followLinks: false)
ch_het_check_pyscript = Channel.fromPath("${projectDir}/bin/remove_het_outliers.py", followLinks: false)
ch_hail_gwas_script = Channel.fromPath("${projectDir}/bin/hail_gwas.py", followLinks: false)

// Fail early if violations in the parameters specified are detected
if (!params.genotype_files_list && !params.input_folder_location ) {
  exit 1, "File containing paths to genotype files not specified. Please specify a .csv file with paths using --genotype_files_list parameter, or an input s3 path (folder) using --input_folder_location parameter."
}
if (params.genotype_files_list && params.input_folder_location) {
  exit 1, "Redundant input! You have provided both --genotype_files_list and --input_folder_location. Please specify only one of them and set the other to false."
}
if (params.genotype_format != 'vcf' && params.genotype_format != 'bgen' && params.genotype_format != 'plink' && params.genotype_format!= "hail_matrix"  && params.genotype_format != 'dosage' && params.genotype_format != 'pgen') {
  exit 1, "Genotype format not supported. Please choose one of the available supported formats [vcf, bgen, plink, hail_matrix, dosage, pgen]."
}
if (!params.phenotype_colname && !params.pheno_transform) {
  log.info "Phenotype column name or phenotype transform file has not been specified. Defaulting to 3rd column in phenotype file as phenotype."
}

if (params.genotype_files_list && params.genotype_format == 'vcf') {
  Channel
    .fromPath(params.genotype_files_list)
    .ifEmpty { exit 1, "Cannot find CSV VCFs file : ${params.genotype_files_list}" }
    .splitCsv(skip:1)
    .map { chr, vcf, index -> [file(vcf).simpleName, chr, file(vcf), file(index)] }
    .take( params.number_of_files_to_process )
    .set { ch_user_input_vcf }
}
else if (params.genotype_files_list && params.genotype_format == 'bgen') {
  Channel
  .fromPath(params.genotype_files_list)
  .ifEmpty { exit 1, "Cannot find CSV file containing paths to .bgen/.sample files: ${params.genotype_files_list}" }
  .splitCsv(skip:1)
  .map { chr, bgen, bgi_index -> [file(bgen).simpleName, chr, file(bgen), file(bgi_index)] }
  .set { ch_user_input_bgen }

  Channel
  .fromPath(params.bgen_sample_file)
  .set { ch_bgen_sample_file }
}
else if (params.genotype_files_list && params.genotype_format == 'pgen') {
    Channel
      .fromPath(params.genotype_files_list)
      .ifEmpty { exit 1, "Cannot find .csv file with PLINK2 (.pgen/.pvar/.psam) datasets: ${params.genotype_files_list}" }
      .splitCsv(skip:1)
      .map { chr, pgen, pvar, psam -> [file(pgen).baseName, chr, file(pgen), file(pvar), file(psam)] }
      .take( params.number_of_files_to_process )
      .set { ch_user_input_pgen }
}
else if (params.genotype_files_list && params.genotype_format == 'plink') {
  Channel
  .fromPath(params.genotype_files_list)
  .ifEmpty { exit 1, "Cannot find CSV file containing paths to bed,bim,fam files: ${params.genotype_files_list}" }
  .splitCsv(skip:1)
  // Using baseName below, because plink when splitting the files per chrom it emits them as name.chr1.bed etc, simpleName would trim more than we want
  .map { chr, bed, bim, fam -> [file(bed).baseName, chr, file(bed), file(bim), file(fam)] }
  .take( params.number_of_files_to_process )
  .set { ch_user_input_plink }
}
else if (params.input_folder_location && params.genotype_format == 'hail_matrix') {
  Channel
  .fromPath(params.input_folder_location)
  .ifEmpty { exit 1, "Cannot find folder containing paths hail matrix files, folder ${params.input_folder_location} does not exist or is empty." }
  .set { ch_user_input_hail_matrix }
}
else if (params.genotype_files_list && params.genotype_format == 'dosage') {
    Channel
      .fromPath(params.genotype_files_list)
      .ifEmpty { exit 1, "Cannot find CSV Dosage file : ${params.genotype_files_list}" }
      .splitCsv(skip:1)
      .map { chr, dosage, map, fam -> [file(dosage).baseName, chr, file(dosage), file(map), file(fam)] }
      .take( params.number_of_files_to_process )
      .set { ch_user_input_dosage }
}

Channel
  .fromPath(params.high_LD_long_range_regions)
  .ifEmpty { exit 1, "Cannot find file containing long-range LD regions for exclusion : ${params.high_LD_long_range_regions}" }
  .into { ch_high_ld_regions; ch_high_ld_regions_regenie }

if (params.ld_scores) {
  Channel
      .fromPath(params.ld_scores)
      .ifEmpty { exit 1, "Cannot find file containing LD scores : ${params.ld_scores}" }
      .set { ch_ld_scores }
}

process standardise_phenofile_and_get_samples {

  label 'gwas_default'
  input:
  file(original_pheno_tsv) from ch_pheno_for_standardise
  //each file('transform_pheno.R') from Channel.fromPath("${projectDir}/bin/transform_pheno.R")

  output:
  file("notransform.phe") into ch_standardised_pheno
  file("all_samples.tsv") into ch_all_samples_file

  script:
  """
  # make dummy transform file to move params.phenotype_colname to 3rd column
  # and IGNORE anything that is not the phenotype column or specified covariate_column

  if [ "${params.phenotype_colname}" = "false" ]; then
    pheno_col=\$(head -n 1 $original_pheno_tsv | cut -f3 )
  else
    pheno_col=${params.phenotype_colname}
  fi

  if [ "${params.covariate_cols}" = "ALL" ]; then
    covar_cols=\$(head -n 1 $original_pheno_tsv | cut --complement -f1,2 | tr '\\t' ',')
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
    }' $original_pheno_tsv > dummmy_transform.tsv

  Rscript '$baseDir/bin/transform_pheno.R' \
    --pheno $original_pheno_tsv \
    --transform dummmy_transform.tsv \
    --out_prefix ./

  cut -f1,2 notransform.phe > all_samples.tsv
  """
}

ch_standardised_pheno.into{
  ch_pheno_hail;
  ch_pheno_no_transform;
}

ch_all_samples_file.into{
  ch_samples_vcf2plink;
  ch_samples_bgen;
  ch_samples_pgen;
  ch_samples_user_input_plink;
  ch_samples_user_input_dosage;
  ch_samples_for_no_related_filter;
}

if (!params.hail) {
  /*--------------------------------------------------
  Pre-GWAS filtering - download, filter and convert VCFs
  ---------------------------------------------------*/
  if (params.genotype_format == 'vcf') {
    process vcf2plink {
      tag "$name"
      label 'large_resources'
      publishDir "${params.outdir}/gwas_filtering", mode: 'copy'

      input:
      set val(name), val(chr), file(vcf), file(index) from ch_user_input_vcf
      each file(phe_file) from ch_samples_vcf2plink

      output:
      set val(name), val(chr), file('*.pgen'), file('*.pvar'), file('*.psam'), file('*.log') into filteredPlinkCh

      script:
      make_pgen = params.analyse_hard_called_gt ? "--make-pgen erase-dosage erase-phase" : "--make-pgen"
      """
      # Download, filter and convert (bcf or vcf.gz) -> vcf.gz
      tail -n +2 ${phe_file}| cut -f2 > samples.txt
      bcftools view -S samples.txt $vcf -Oz -o ${name}_downsampled.vcf.gz
      bcftools view -q ${params.q_filter} ${name}_downsampled.vcf.gz -Oz -o ${name}_filtered.vcf.gz
      bcftools norm -m +any ${name}_filtered.vcf.gz -Oz -o ${name}_filtered_norm.vcf.gz
      bcftools index ${name}_filtered_norm.vcf.gz

      # Create PLINK binary from vcf.gz
      plink2 \
        $make_pgen \
        --set-missing-var-ids @:#,\\\$r,\\\$a \
        --vcf ${name}_filtered_norm.vcf.gz \
        --vcf-half-call m \
        --double-id \
        --no-psam-pheno \
        --set-hh-missing \
        --new-id-max-allele-len 60 missing \
        --threads ${task.cpus -1} --memory ${task.memory.toMega() -200} \
        --out ${name}_filtered

      # Re-format .pvar file (not handled by default in plink2, throws an error in next steps, potential plink2 bug)
      sed '/#CHROM/,\$!d' ${name}_filtered.pvar | cut -f1-5 > ${name}_filtered_reformatted.pvar
      rm ${name}_filtered.pvar 
      mv ${name}_filtered_reformatted.pvar ${name}_filtered.pvar

      """
    }
  }
  else if (params.genotype_format == 'bgen') {
    process bgen2plink {
      tag "$name"
      label "large_resources"
      label 'gwas_default'
      publishDir "${params.outdir}/gwas_filtering", mode: 'copy'

      input:
      set val(name), val(chr), file(bgen), file(index) from ch_user_input_bgen
      each file(phe_file) from ch_samples_bgen
      each file(sample_file) from ch_bgen_sample_file

      output:
      set val(name), val(chr), file('*.pgen'), file('*.pvar'), file('*.psam'), file('*.log') into filteredPlinkCh

      script:
      """
      # Create a sample ID file for --keep
      tail -n +2 ${phe_file}| cut -f1,2 > samples.txt

      # Create PLINK binary from vcf.gz
      plink2 \
        --make-pgen \
        --bgen ${bgen}\
        --sample ${sample_file} \
        --maf ${params.maf} \
        --double-id \
        --keep samples.txt \
        --threads ${task.cpus -1} --memory ${task.memory.toMega() -200} \
        --out ${name}_filtered

      rm -rf ${bgen} ${sample_file}

      """
    }
  }
  else if (params.genotype_format == 'pgen') {
    process pgen {
      tag "${name}_chr${chr}"
      label "large_resources"
      publishDir "${params.outdir}/gwas_filtering", mode: 'copy'

      input:
      set val(name), val(chr), file(pgen), file(pvar), file(psam) from ch_user_input_pgen
      each file(phe_file) from ch_samples_pgen

      output:
      set val(name), val(chr), file('*.pgen'), file('*.pvar'), file('*.psam'), file('*.log') into filteredPlinkCh
      script:
      """
      # Create a sample ID file for --keep
      tail -n +2 ${phe_file}| cut -f1,2 > samples.txt
      # Create PLINK binary from vcf.gz
      plink2 \
        --make-pgen \
        --pfile ${name} \
        --out ${name}_filtered \
        --maf ${params.maf} \
        --double-id \
        --threads ${task.cpus -1} \
        --memory ${task.memory.toMega() -200} \
        --keep samples.txt

      rm -rf ${name}.*

      """
    }
  }
  else if (params.genotype_format == 'plink') {
    process keep_bfile_pheno_intersect {
      tag "$name"
      label "large_resources"
      publishDir "${params.outdir}/gwas_filtering/user_input_plink/", mode: 'copy'

      input:
      set val(name), val(chr), file(bed), file(bim), file(fam) from ch_user_input_plink
      each file(phe_file) from ch_samples_user_input_plink

      output:
      set val(name), val(chr), file('*.pgen'), file('*.pvar'), file('*.psam'), file('*.log') into filteredPlinkCh

      script:
      """
      # Create a sample ID file for --keep
      tail -n +2 ${phe_file}| cut -f1,2 > samples.txt

      # Keep only the intersect of individuals in pheno and bfile
      # Filter by MAF; Reformat snps with unknown rsID (restricted to 60chars);
      plink2  \
        --bfile ${name} \
        --keep samples.txt \
        --make-pgen \
        --maf ${params.maf} \
        --double-id \
        --threads ${task.cpus -1} --memory ${task.memory.toMega() -200} \
        --out ${name}_filtered \
      """
    }
  }
  else if (params.genotype_format == 'dosage') {
    process dosage2plink {
      tag "$name"
      label "medium_resources"
      publishDir "${params.outdir}/gwas_filtering/user_input_dosage/", mode: 'copy'

      input:
      set val(name), val(chr), file(dosage), file(map), file(fam) from ch_user_input_dosage
      each file(phe_file) from ch_samples_user_input_dosage

      output:
      set val(name), val(chr), file('*.pgen'), file('*.pvar'), file('*.psam'), file('*.log') into filteredPlinkCh

      script:
      """
      # Create a sample ID file for --keep
      tail -n +2 ${phe_file}| cut -f1,2 > samples.txt

      # Convert dosage data to plink2 background file
      plink2 \
      --import-dosage ${dosage} \
      --fam ${fam} \
      --map ${map} \
      --threads ${task.cpus -1} --memory ${task.memory.toMega() -200} \
      --out plink2_dosage 

      # Keep only the intersect of individuals in pheno and bfile
      # Filter by MAF
      plink2  \
        --make-pgen \
        --pfile plink2_dosage \
        --maf ${params.maf} \
        --double-id \
        --keep samples.txt \
        --threads ${task.cpus -1} --memory ${task.memory.toMega() -200} \
        --out ${name}_filtered \
      """
    }
  }

  // Filter out all variants with missingness > 0.1 [--geno 0.1]
  // Filter out all variants with minor allele frequency < 0.05 [--maf 0.05]
  // Filter out all variants with minor allele count < 1 [--mac 1]
  // For reference: minor allele count - number of times minor allele was observed in the cohort. E.g. mac=237 would mean 237 participants had this allele.
  process qc_filtering {
    tag "$name"
    label "large_resources"
    label 'gwas_default'
    publishDir "${params.outdir}/qc_filtering", mode: 'copy'
    input:
    set val(name), val(chr), file(bed), file(bim), file(fam), file(log) from filteredPlinkCh

    output:
    set val(name), val(chr), file('*_QC_filtered.pgen'), file('*_QC_filtered.pvar'), file('*_QC_filtered.psam'), file('*_QC_filtered.log') into ch_basic_qc_out_plink_format

    script:
    handle_duplicate_var_ids = params.remove_multiallelics ? "--rm-dup force-first" : ""
    """
    plink2 \
      --pfile ${name}_filtered \
      --mind ${params.mind_threshold} \
      --geno ${params.miss} \
      --maf ${params.maf} \
      --mac ${params.mac} \
      --make-pgen \
      $handle_duplicate_var_ids \
      --threads ${task.cpus -1} --memory ${task.memory.toMega() -200} \
      --out ${name}_QC_filtered 

      rm -rf ${name}_filtered.*
    """
  }


  process filter_hwe {
    tag "$name"
    label "large_resources"
    label 'gwas_default'
    publishDir "${params.outdir}/filter_miss", mode: 'copy'

    input:
    set val(name), val(chr), file('in.pgen'), file('in.pvar'), file('in.psam'), file('in.log') from ch_basic_qc_out_plink_format

    output:
    set val(name), val(chr), file("${name}.misHWEfiltered.pgen"), file("${name}.misHWEfiltered.pvar"), file("${name}.misHWEfiltered.psam"), file("${name}.misHWEfiltered.log") into ch_hwe_out_for_merge

    script:
    """
    # plink -> hwe_filtered plink
    plink2 \
      --pfile in \
      --hwe ${params.hwe_threshold} ${params.hwe_test} \
      --make-pgen \
      --threads ${task.cpus -1} --memory ${task.memory.toMega() -200} \
      --out ${name}.misHWEfiltered

    rm -rf in.*
    """
  }

  process merge_plink {
    label "large_resources"
    publishDir "${params.outdir}/merged_plink", mode: 'copy'
    input:
    file("*") from ch_hwe_out_for_merge.collect()

    output:
    set file('merged.pgen'), file('merged.pvar'), file('merged.psam'), file('merged.log') into ch_plink_merged_het_filter
    set file('merged.bed'), file('merged.bim'), file('merged.fam'), file('merged.log') into ch_plink_merged_het_check

    script:
    overwrite_rsid = params.overwrite_var_ids ? "--set-all-var-ids @_#_\\\$r_\\\$a --new-id-max-allele-len 577" : ""
    """
    ls *.pgen > pgen.txt
    ls *.pvar > pvar.txt
    ls *.psam > psam.txt
    if [ \$(wc -l pvar.txt | cut -d' ' -f1) -lt 2 ]; then
        echo "Only one genotypic dataset detected - skipping merging step."
        pgen_file=\$(ls *.pgen)
        pgen_prefix=`echo "\${pgen_file%.*}"`

        # Rename the rsid if overwrite_var_ids true and generate plink1 output for sex check
        /tools/plink2 \
        --pfile \${pgen_prefix} \
        --make-pgen \
        --export ind-major-bed \
        --max-alleles 2 \
        --out merged \
        --threads ${task.cpus -1} --memory ${task.memory.toMega() -200} \
        $overwrite_rsid 

    else
        paste pgen.txt pvar.txt psam.txt > merge.temp.list
        tail -n +2 merge.temp.list > merge.list
        pgen_file=\$(head -n1 merge.temp.list | cut -f1)
        pgen_prefix=`echo "\${pgen_file%.*}"`
        /tools/plink2 \
        --pfile \${pgen_prefix} \
        --pmerge-list merge.list pfile \
        --make-pgen \
        --export ind-major-bed \
        --max-alleles 2 \
        --threads ${task.cpus -1} --memory ${task.memory.toMega() -200} \
        --out merged \
        $overwrite_rsid
    fi

    rm -rf *misHWEfiltered*

    """
  }

    process het_check {
    label "large_resources"
    label 'gwas_default'
    tag "Heterozygosity-based QC"
    publishDir "${params.outdir}/het_check", mode: 'copy'

    input:
    set file('merged.bed'), file('merged.bim'), file('merged.fam'), file('merged.log') from ch_plink_merged_het_check
    file(het_check_pyscript) from ch_het_check_pyscript
    output:
    file("*.het")
    file("het_passing_samples.tsv") into ch_het_pass_samples


    script:
    """
    plink --bfile merged \
        --het \
        --threads ${task.cpus -1} --memory ${task.memory.toMega() -200} \
        --out merged_het

    rm -rf merged.*
    python3 $het_check_pyscript --plink_het merged_het.het  --sd ${params.het_std_exclusion_threshold}
    """

  }

process het_filter {
    label "medium_resources"
    label 'gwas_default'
    tag "Heterozygosity-based filter"
    publishDir "${params.outdir}/het_check", mode: 'copy'

    input:
    file(het_pass_samples) from ch_het_pass_samples
    set file('merged.pgen'), file('merged.pvar'), file('merged.psam'), file('merged.log') from ch_plink_merged_het_filter
    output:
    set file('merged_het_pass.pgen'), file('merged_het_pass.pvar'), file('merged_het_pass.psam'), file('merged_het_pass.log') into (ch_plink_merged_het_passed, ch_plink_merged_for_align)
    set file('sex_chr.bed'), file('sex_chr.bim'), file('sex_chr.fam'), file('sex_chr.log') into ch_plink_sex_chr

    script:
    """
    plink2 --pfile merged \
          --keep het_passing_samples.tsv \
          --make-pgen \
          --threads ${task.cpus -1} --memory ${task.memory.toMega() -200} \
          --out merged_het_pass 
    
    x_chrom=\$(cut -f1 merged_het_pass.pvar | grep X || true )

      if [ -z \$x_chrom ]; then
        touch sex_chr.bed
        touch sex_chr.bim
        touch sex_chr.fam
        touch sex_chr.log
      else
        plink2 --pfile merged_het_pass \
           --chr X \
           --make-bed \
           --threads ${task.cpus -1} --memory ${task.memory.toMega() -200} \
           --out sex_chr
      fi
    
    rm -rf merged.*

    """

}

  if (params.sex_check) {
    process sex_check {
      tag "Sex check"
      label "medium_resources"
      publishDir "${params.outdir}/sex_check", mode: 'copy'

      input:
      set file('sex_chr.bed'), file('sex_chr.bim'), file('sex_chr.fam'), file('sex_chr.log') from ch_plink_sex_chr
      output:
      file("*") into ch_sex_check_log
      script:
      """

      if [ -s sex_chr.bim ]; then
        echo "X chromosome identified in genotype data - performing sex check." > sex_check.log
        plink --keep-allele-order --bfile sex_chr --check-sex --out sex_check --threads ${task.cpus -1} --memory ${task.memory.toMega() -200}
      else
        echo "No chromosome X detected in genotype data - continuing without performing sex check/sex imputation." > sex_check.log
      fi

      """
    }
  }




  process ld_prune {
    label "medium_resources"
    label 'gwas_default'
    publishDir "${params.outdir}/merged_pruned_plink", mode: 'copy'

    input:
    set file('merged.pgen'), file('merged.pvar'), file('merged.psam'), file('merged_het_pass.log') from ch_plink_merged_het_passed
    file(long_range_ld_regions) from ch_high_ld_regions

    output:
    set val('merged_pruned'), file('merged_pruned.pgen'), file('merged_pruned.pvar'), file('merged_pruned.psam'), file('merged_pruned.log') into ch_pruned_variants_out

    script:
    extract_options = params.extract_pruned_region ? "--extract merged.prune.in" : ""
    """
    plink2 \
    --pfile merged \
    --indep-pairwise ${params.ld_window_size} ${params.ld_step_size} ${params.ld_r2_threshold} \
    --exclude range ${long_range_ld_regions} \
    --threads ${task.cpus -1} --memory ${task.memory.toMega() -200} \
    --out merged
    
    plink2 \
    --pfile merged \
    ${extract_options} \
    --make-pgen \
    --threads ${task.cpus -1} --memory ${task.memory.toMega() -200} \
    --out merged_pruned

    rm -rf merged.pgen merged.pvar merged.psam
    """
  }

  ch_pruned_variants_out.into{
    ch_pruned_variants_for_grm;
    ch_pruned_variants_for_relatedness;
    ch_unrelated_for_pca;
    ch_unrelated_for_ancestry_inference;
    ch_unrelated_annotate_rsid
  }


  if (params.remove_related_samples) {

    process calculate_relatedness {
      label "large_resources"
      label 'gwas_default'
      publishDir "${params.outdir}/relatedness_check", mode: 'copy'

      input:
      set val(name), file(pgen), file(pvar), file(psam), file(log) from ch_pruned_variants_for_relatedness

      output:
      file("relatedness.king.cutoff.in.id") into (ch_related_filter_keep_files, ch_related_filter_keep_files_rsid)
      file("relatedness.king.cutoff.out.id")
      file("relatedness*.log") into ch_relatedness_log

      script:
      """
      plink2 \
          --pfile ${pvar.baseName} \
          --king-cutoff ${params.king_coefficient} \
          --threads ${task.cpus -1} --memory ${task.memory.toMega() -200} \
          --out relatedness
      """
    }

  } else {
    //ch_related_filter_keep_files = ch_samples_for_no_related_filter
    ch_samples_for_no_related_filter.into{ ch_related_filter_keep_files; ch_related_filter_keep_files_rsid }
  }
  if (params.annotate_with_rsids) {
    process annotate_with_rsids {
      label "medium_resources"
      publishDir "${params.outdir}/with_rsids", mode: 'copy'

      input:
      set val(name), file(pgen), file(pvar), file(psam), file(log) from ch_unrelated_annotate_rsid
      file(rsid_cpra_table) from ch_rsid_cpra_table
      file(annotate_rsids_pyscript) from ch_rsid_annotation_pyscript
      output:
      set val('merged_pruned_rsid'), file('merged_pruned_rsid.bed'), file('merged_pruned_rsid.bim'), file('merged_pruned_rsid.fam'), file('merged_pruned_rsid.log') into ch_unrelated_merged_pruned_rsid

      script:
      """
      python3 annotate_with_rsids.py \
          --pvar_file ${pvar} \
          --rsid_cpra_table ${rsid_cpra_table} \
          --output_var_conv output_var_conv.tsv
      plink2 \
        --pfile ${pvar.baseName} \
        --make-bed \
        --threads ${task.cpus -1} --memory ${task.memory.toMega() -200} \
        --out intermediate
      plink \
          --bfile intermediate \
          --update-name output_var_conv.tsv 1 2 \
          --threads ${task.cpus -1} --memory ${task.memory.toMega() -200} \
          --make-bed \
          --out merged_pruned_rsid

      rm -rf intermediate*
      """

    }

  }
  if (params.run_ancestry_inference) {
    if (params.annotate_with_rsids) {
            ch_related_filter_keep_files_rsid.combine(ch_unrelated_merged_pruned_rsid).into{ ch_input_for_ancestry_inference; ch_test}
            ch_test.view()
    } else if (!params.annotate_with_rsids) {
            ch_related_filter_keep_files.combine(ch_unrelated_for_ancestry_inference).into{ ch_input_for_ancestry_inference; ch_test1}
    }
    process infer_ancestry {
      label "large_resources"
      publishDir "${params.outdir}/ancestry_inference/", mode: 'copy'

      input:
      set file('keep.tsv'), val(name), file('in.bed'), file('in.bim'), file('in.fam'), file('in.log') from ch_input_for_ancestry_inference
      //file('Ancestry_Inference.R') from Channel.fromPath("${projectDir}/bin/Ancestry_Inference.R")
      set val(ref_name), file('ref.bed.xz'), file('ref.bim.xz'), file('ref.fam.xz') from ch_king_reference_data

      output:
      file("*.keep.tsv") into ch_split_ancestry_keep_files_out
      set file("samples_*.tsv"), file("samples_*.png"), file("samplespc.txt"), file("samples_eigenvals.txt"), file("samples_popref.txt")

      script:
      """
      # decompress .xz suffixed king reference files
      unxz --force ref.bed.xz
      unxz --force ref.bim.xz
      unxz --force ref.fam.xz

      # subset input to just samples to keep
      cut -f 1-2 keep.tsv > inputkeep.tsv
      plink2 --bfile in --keep inputkeep.tsv --make-bed --out samples --threads ${task.cpus -1} --memory ${task.memory.toMega() -200}

      # calculate PCs
      king -b ref.bed,samples.bed --pca --projection --prefix samples --cpus ${task.cpus} > king.log

      # get eigenvalues
      grep 'eigenvalues' king.log | cut -d' ' -f1-3 --complement | tr ' ' '\\n' > samples_eigenvals.txt

      Rscript '$baseDir/bin/Ancestry_Inference.R' \
        --pc_file=samplespc.txt \
        --eigenval_file=samples_eigenvals.txt \
        --ref_id_file=samples_popref.txt \
        --prefix=samples \
        --cpus=${task.cpus}

      awk 'BEGIN{FS=OFS="\\t"} NR>1{print \$1,\$2 > \$5 ".keep.tsv" }' samples_InferredAncestry.tsv
      """
    }

    ch_split_ancestry_keep_files_out
        .flatMap()
        .map{[it.simpleName, it] }
        .filter{ it[1].readLines().size() >= params.min_subpop_size }
        .set{ch_ancestry_keep_files}

  } else {
      ch_related_filter_keep_files
        .map{["allancs"] + [it] }
        .set{ch_ancestry_keep_files}
  }


  if (params.run_pca) {
    ch_input_for_pca = ch_ancestry_keep_files.combine(ch_unrelated_for_pca)
    process filter_pca {
      label 'medium_resources'
      label 'gwas_default'
      tag "${ancestry_group}"
      publishDir "${params.outdir}/${ancestry_group}/pca/", mode: 'copy'

      input:
      set val(ancestry_group), file('in.tsv'), val(name), file('in.bed'), file('in.bim'), file('in.fam'), file('in.log') from ch_input_for_pca
      //each file('pca_outliers.R') from Channel.fromPath("${projectDir}/bin/pca_outliers.R")

      output:
      set val(ancestry_group), file('pca_results_final.eigenvec'), file('pca_results_final.eigenval') into ch_pca_results
      set val(ancestry_group), file('out.keep.tsv') into ch_pca_keep_files
      file("remove_outliers_*.log") into ch_pca_logs

      script:
      """
      # subset to only the ancestry group we are currently operating on
      cut -f 1-2 in.tsv > in.keep.tsv
      plink2 --bfile in --keep in.keep.tsv --make-bed --out subset --threads ${task.cpus -1} --memory ${task.memory.toMega() -200}

      if [ \$(wc -l subset.bim | cut -d " " -f1) -lt 220 ]; then
          echo "Error: PCA requires data to contain at least 220 variants." 1>&2
          exit 1
      fi

      touch plink_remove_ids_init.tsv
      i=0
      n_outliers=-1

      while [ \$i -le ${params.remove_outliers_maxiter} ] && [ \$n_outliers -ne 0 ]; do

        cat plink_remove_ids_*.tsv > all_plink_remove_ids.tsv

        if [ \$(wc -l in.fam | cut -d " " -f1) -gt 5000 ]; then
          plink2 --bfile subset \
            --remove all_plink_remove_ids.tsv \
            --pca ${params.number_pcs} approx \
            --threads ${task.cpus -1} --memory ${task.memory.toMega() -200} \
            --out pca_results_\${i} 1>&2
        else
          plink2 --bfile subset \
            --remove all_plink_remove_ids.tsv \
            --pca ${params.number_pcs} \
            --threads ${task.cpus -1} --memory ${task.memory.toMega() -200} \
            --out pca_results_\${i} 1>&2
        fi

        Rscript '$baseDir/bin/pca_outliers.R' --input=pca_results_\${i}.eigenvec \
          --out=plink_remove_ids_\${i}.tsv \
          --sigma=${params.remove_outliers_sigma} > remove_outliers_\${i}.log

        n_outliers=\$(wc -l plink_remove_ids_\${i}.tsv | cut -d " " -f1)
        i=\$[\$i+1]

      done

      i=\$[\$i-1]
      cp pca_results_\${i}.eigenval pca_results_final.eigenval
      cp pca_results_\${i}.eigenvec pca_results_final.eigenvec

      tail -n +2 pca_results_final.eigenvec | cut -f 1-2 > out.keep.tsv
      """
    }
    
  } else {
    ch_pca_keep_files = ch_ancestry_keep_files
  }

  if (params.pheno_transform) {
    process transform_phenofile {
      label 'micro_resources'
      label 'gwas_default'

      input:
      file('original.pheno.tsv') from ch_pheno_for_transform
      file('transform.tsv') from ch_input_pheno_transform
      //each file('transform_pheno.R') from Channel.fromPath("${projectDir}/bin/transform_pheno.R")


      output:
      file("*.phe") into ch_transform_pheno_out

      script:
      """
      Rscript '$baseDir/bin/transform_pheno.R' --pheno original.pheno.tsv --transform transform.tsv --out_prefix ./
      """

    }
    ch_transform_pheno_out
      .flatMap()
      .map{[it.baseName, it]}
      .set{ch_transformed_phenos}

  } else {
    ch_pheno_no_transform
      .map{["notransform", it]}
      .set{ch_transformed_phenos}
  }

  ch_input_for_pheno_cross = ch_pca_keep_files.combine(ch_transformed_phenos)
  process create_ancestry_x_transform_pheno {
    label 'micro_resources'
    label 'gwas_default'
    tag "${ancestry_group} ${gwas_tag}"
    
    input:
    set val(ancestry_group), file('keep.tsv'), val(gwas_tag), file('in.phenofile.phe') from ch_input_for_pheno_cross

    output:
    set val(ancestry_group), val(gwas_tag), file('out.phenofile.phe') into ch_crossed_pheno_out

    script:
    """
    awk '\
      BEGIN{FS=OFS="\\t"} \
      ARGIND==1{a[\$1 "%" \$2]++; next} \
      FNR==1{print \$0; next} \
      a[\$1 "%" \$2]>0{print \$0} \
    ' keep.tsv in.phenofile.phe > out.phenofile.phe
    """
  }


  if (params.run_pca) {

    ch_input_for_add_pcs = ch_pca_results.combine(ch_crossed_pheno_out, by:0)
    process add_pcs_to_pheno {
      label 'micro_resources'
      label 'gwas_default'
      tag "${ancestry_group} ${gwas_tag}"

      input:
      set val(ancestry_group), file('pca_results.eigenvec'), file('pca_results.eigenval'), val(gwas_tag), file('in.phenofile.phe') from ch_input_for_add_pcs

      output:
      set val(ancestry_group), val(gwas_tag), file('out.phenofile.phe') into ch_final_phenos

      script:
      """
      awk '
        BEGIN{FS=OFS="\\t"} \
        ARGIND==1{fid=\$1;iid=\$2;\$1="%%";\$2="%%";a[fid "%" iid] = \$0} \
        ARGIND==2{print \$0, a[\$1 "%" \$2]} \
      ' pca_results.eigenvec in.phenofile.phe \
      | sed -r 's/%%\\t//g' > out.phenofile.phe
      """
    }
  } else {
    ch_final_phenos = ch_crossed_pheno_out
  }

  /*---------------------------------------------------------------
    Prepare test variant & GRM variant channels for GWAS software
  ----------------------------------------------------------------*/
  // Here we will split the final phenofile channel to each GWAS analysis process.
  // We will also subset the GRM and Test variant files based on the final phenofile (alignment).
  // Finally we convert the test variant files where needed and split the test variant and
  // GRM variant channels into each GWAS analysis process.


  ch_final_phenos.into{
    ch_final_pheno_for_align_plink;
    ch_final_pheno_for_align_grm;
  }


  ch_align_pheno_with_test_variant_plink_in = ch_final_pheno_for_align_plink.combine(ch_plink_merged_for_align)
  process align_pheno_with_test_variant_plink {
    label "medium_resources"
    label 'gwas_default'
    tag "${ancestry_group} ${gwas_tag}"
    publishDir "${params.outdir}/${ancestry_group}/${gwas_tag}/", mode: 'copy'

    input:
    set val(ancestry_group), val(gwas_tag), file('phenofile.phe'), file('in.pgen'), file('in.pvar'), file('in.psam'), file('in.log') from ch_align_pheno_with_test_variant_plink_in

    output:
    set val(ancestry_group), val(gwas_tag), file('trait_type'), file('phenofile.phe'), file('aligned_test_variants.pgen'), file('aligned_test_variants.pvar'), file('aligned_test_variants.psam'), file('aligned_test_variants.log') into ch_align_pheno_with_test_variant_plink_out

    script:
    """
    cut -f1-2 phenofile.phe > keep_samples.txt
    plink2 --pfile in \
          --keep keep_samples.txt \
          --make-pgen \
          --threads ${task.cpus -1} --memory ${task.memory.toMega() -200} \
          --out aligned_test_variants
    
    uniquevals=\$(cut -f 3 phenofile.phe | tail -n +2 | sort -u | wc -l)
    if [ \$uniquevals -gt 2 ]; then
      echo -n "quantitative" > trait_type
    else
      echo -n "binary" > trait_type
    fi
    """
  }

  ch_align_pheno_with_test_variant_plink_out
    .map{ it[0..1] + [it[2].text] + it[3..7] }
    .branch {
        binary: it[2] == "binary"
        quant: it[2] == "quantitative"
    }
    .set{ch_aligned_test_vars_out}

  
  // Case/control variant filtering for missingness
  // Under null hypothesis (no batch effect etc) missingness for each variant should be similar for cases and controls.
  // This step filters out all variants where missingness in cases and is significantly different from missingness in controls.
  process filter_binary_missingness {
    tag "${ancestry_group} ${gwas_tag}"
    label "medium_resources"
    label 'gwas_default'
    publishDir "${params.outdir}/${ancestry_group}/${gwas_tag}/", mode: 'copy'

    input:
    set val(ancestry_group), val(gwas_tag), val(trait_type), file('phenofile.phe'), file('in.pgen'), file('in.pvar'), file('in.psam'), file('in.log') from ch_aligned_test_vars_out.binary

    output:
    set val(ancestry_group), val(gwas_tag), val(trait_type), file('phenofile.phe'), file('*_filtered.pgen'), file('*_filtered.pvar'), file('*_filtered.psam'), file('*_filtered.log') into ch_aligned_test_vars_binary_hwe_filtered

    script:
    """

    plink2 \
      --pfile in \
      --make-bed \
      --threads ${task.cpus -1} --memory ${task.memory.toMega() -200} \
      --out plink1
    plink \
      --bfile plink1 \
      --pheno phenofile.phe \
      --allow-no-sex \
      --keep-allele-order \
      --test-missing midp \
      --threads ${task.cpus -1} --memory ${task.memory.toMega() -200} \
      --out hwe

    awk '\$5 < ${params.miss_test_p_threshold} {print \$2 }' hwe.missing > hwe.missing_FAIL

    plink2 --pfile in \
      --allow-no-sex \
      --exclude hwe.missing_FAIL \
      --threads ${task.cpus -1} --memory ${task.memory.toMega() -200} \
      --make-pgen \
      --out aligned_test_variants.binary_hwe_miss_filtered
    """
  }

  ch_aligned_test_variants_out_plink_format = ch_aligned_test_vars_out.quant.mix(ch_aligned_test_vars_binary_hwe_filtered)

  ch_aligned_test_variants_out_plink_format.into{
    ch_aligned_test_variants_plink_for_convert2bgen;
    ch_aligned_test_variants_plink_for_convert2vcf;
    ch_aligned_test_variants_for_plink2_gwas;
    ch_aligned_test_variants_for_fastgwa_glmm;
    ch_aligned_pheno_info_for_saige_step1;
  }


  if (params.bolt_lmm || params.regenie) {
    process convert2bgen {
      label 'medium_resources'
      label 'gwas_default'
      tag "${ancestry_group} ${gwas_tag}"
      label "convert2bgen"

      input:
      set val(ancestry_group), val(gwas_tag), val(trait_type), file('phenofile.phe'), file('in.pgen'), file('in.pvar'), file('in.psam'), file('in.log') from ch_aligned_test_variants_plink_for_convert2bgen

      output:
      set val(ancestry_group), val(gwas_tag), val(trait_type), file('phenofile.phe'), file('aligned_filtered.bgen'), file('aligned_filtered.sample'), file('aligned_filtered.log') into ch_aligned_test_variants_out_bgen_format

      script:
      """
      plink2 --pfile in \
        --export bgen-1.2 bits=8 \
        --threads ${task.cpus -1} --memory ${task.memory.toMega() -200} \
        --out aligned_filtered
      """
    }

    ch_aligned_test_variants_out_bgen_format.into{
      ch_merged_bgen_bolt_lmm;
      ch_merged_bgen_regenie_step1;
    }

  }

  if (params.saige) {
    process convert2vcf {
      label 'medium_resources'
      label 'gwas_default'
      tag "${ancestry_group} ${gwas_tag}"

      input:
      set val(ancestry_group), val(gwas_tag), val(trait_type), file('phenofile.phe'), file('in.pgen'), file('in.pvar'), file('in.psam'), file('in.log') from ch_aligned_test_variants_plink_for_convert2vcf

      output:
      set val(ancestry_group), val(gwas_tag), val(trait_type), file('phenofile.phe'), file("*.vcf.gz"), file("*.vcf.gz.csi") into ch_aligned_test_variants_vcf_out

      script:
      """
      chroms=\$(tail -n +2 in.pvar |cut -f 1 | sort -u | tr '\\n' ' ')
      for chr in \$chroms; do
        plink2 -pfile in \
          --chr \$chr \
          --export vcf bgz id-paste=iid \
          --threads ${task.cpus -1} --memory ${task.memory.toMega() -200} \
          --out \${chr}.chrom
        bcftools index \${chr}.chrom.vcf.gz
      done
      """
    }

    ch_aligned_test_variants_vcf_out
      .map{ 
        if (!(it[4] instanceof Collection)) {
          [it[0], it[1], it[2], it[3], [it[4]], [it[5]]]
        } else {
          it
        }
      }
      .transpose(by: [4,5])
      .map{ it[0..2] + [it[4].simpleName] + it[3..5] }
      .set{ch_aligned_test_variants_chrom_for_saige_step2}
  }

  if (params.saige || params.bolt_lmm) {

    ch_align_pheno_with_grm_variant_plink_in = ch_final_pheno_for_align_grm.combine(ch_pruned_variants_for_grm)
    process align_pheno_with_grm_variant_plink {
      label 'small_resources'
      label 'gwas_default'
      tag "${ancestry_group} ${gwas_tag}"
      publishDir "${params.outdir}/${ancestry_group}/${gwas_tag}/", mode: 'copy'

      input:
      set val(ancestry_group), val(gwas_tag), file('phenofile.phe'), val(name), file('in.pgen'), file('in.pvar'), file('in.psam'), file('in.log') from ch_align_pheno_with_grm_variant_plink_in

      output:
      set val(ancestry_group), val(gwas_tag), file('aligned_grm_variants.bed'), file('aligned_grm_variants.bim'), file('aligned_grm_variants.fam'), file('aligned_grm_variants.log') into ch_align_pheno_with_grm_variant_plink_out

      script:
      """
      cut -f1-2 phenofile.phe > keep_samples.txt
      plink2 --pfile in \
            --keep keep_samples.txt \
            --make-bed \
            --threads ${task.cpus -1} --memory ${task.memory.toMega() -200} \
            --out aligned_grm_variants
      """
    }

    ch_align_pheno_with_grm_variant_plink_out.into{
      ch_plink_input_for_grm_saige;
      ch_plink_input_for_grm_bolt_lmm;
    }

  }


  /*--------------------------------------------------
    GWAS analyses
  ---------------------------------------------------*/

  /*--------------------------------------------------
    GWAS using REGENIE
  ---------------------------------------------------*/
  if (params.regenie) {
    process regenie_step1_fit_model {
      tag "${ancestry_group} ${gwas_tag}"
      label 'regenie'
      label "large_resources"

      publishDir "${params.outdir}/${ancestry_group}/${gwas_tag}/regenie/", mode: 'copy', pattern: "${ancestry_group}-${gwas_tag}-regenie_step1*"

      input:
      set val(ancestry_group), val(gwas_tag), val(trait_type), file('phenofile.phe'), file('in.bgen'), file('in.sample'), file('in.log') from ch_merged_bgen_regenie_step1
      each file(long_range_ld_regions) from ch_high_ld_regions_regenie
      output:
      set val(ancestry_group), val(gwas_tag), val(trait_type), file('phenofile.phe'), file('in.bgen'), file('in.sample'),file('in.log'), file("*.loco"), file("*_pred.list"), file ("covariates.txt"), file ("pheno.txt") into ch_inputs_for_regenie_step2
      file("${ancestry_group}-${gwas_tag}-regenie_step1*")

      script:
      extract_options = params.extract_pruned_region ? "--extract merged.prune.in" : ""
      """
      sed -e '1s/^.//' phenofile.phe | sed 's/\t/ /g' > full_pheno_covariates.txt
      cut -d' ' -f1-3 full_pheno_covariates.txt > pheno.txt
      cut -d' ' --complement -f 3 full_pheno_covariates.txt > covariates.txt


      plink2 \
      --bgen in.bgen ref-last \
      --sample in.sample \
      --indep-pairwise ${params.ld_window_size} ${params.ld_step_size} ${params.ld_r2_threshold} \
      --exclude range ${long_range_ld_regions} \
      --allow-no-sex \
      --rm-dup force-first \
      --threads ${task.cpus -1} --memory ${task.memory.toMega() -200} \
      --out merged
    
      plink2 \
      --bgen in.bgen ref-last \
      --sample in.sample \
      ${extract_options} \
      --threads ${task.cpus -1} --memory ${task.memory.toMega() -200} \
      --allow-no-sex \
      --export bgen-1.2 bits=8 \
      --out pruned


      regenie \
      --step 1 \
        --bgen pruned.bgen \
        --covarFile covariates.txt \
        --phenoFile pheno.txt \
        --cc12 \
        ${params.force_step1 ? '--force-step1' : ''} \
        --bsize 100 \
        --threads ${task.cpus} \
        ${trait_type == "binary" ? '--bt' : ''} \
        --lowmem \
        --lowmem-prefix tmp_rg \
        --use-relative-path \
        --out ${ancestry_group}-${gwas_tag}-regenie_step1
      """
    }

    process regenie_step2_association_testing {
      tag "${ancestry_group} ${gwas_tag}"
      label 'regenie'
      label "medium_resources"
      publishDir "${params.outdir}/${ancestry_group}/${gwas_tag}/regenie", mode: 'copy'

      input:
      set val(ancestry_group), val(gwas_tag), val(trait_type), file('phenofile.phe'), file('in.bgen'), file('in.sample'), file('in.log'), file(loco), file(pred), file ("covariates.txt"), file ("pheno.txt") from ch_inputs_for_regenie_step2

      output:
      set file("${ancestry_group}-${gwas_tag}-regenie_firth*.regenie"), file("${ancestry_group}-${gwas_tag}-regenie_firth.log")
      script:
      """
      regenie \
        --step 2 \
        --bgen in.bgen \
        --covarFile covariates.txt \
        --phenoFile pheno.txt \
        --cc12 \
        --bsize 200 \
        --threads ${task.cpus} \
        ${trait_type == "binary" ? '--bt' : ''} \
        --minMAC ${params.regenie_min_mac} \
        --minINFO ${params.regenie_min_imputation_score} \
        --firth --approx \
        --test ${params.regenie_geno_model} \
        --pThresh 0.01 \
        --pred ${pred} \
        --out ${ancestry_group}-${gwas_tag}-regenie_firth
  
      # add metadata to output table
      pheno_name=\$(awk 'NR==1{print \$3}' pheno.txt)
      covar_names=\$(awk 'NR==1{for(i=3; i <= NF; i++){printf("%s, ", \$i)}}' covariates.txt)

      if [ ${trait_type}  == 'binary' ]; then
        cases=\$(sed -n -E '/cases and/ s/[^:]*: ([0-9]+) cases and ([0-9]+) controls/\\1/p' ${ancestry_group}-${gwas_tag}-regenie_firth.log)
        controls=\$(sed -n -E '/cases and/ s/[^:]*: ([0-9]+) cases and ([0-9]+) controls/\\2/p' ${ancestry_group}-${gwas_tag}-regenie_firth.log)
      else
        cases=\$(sed -n -E '/number of individuals used in analysis/ s/[^=]*= ([0-9]+)/\\1/p' ${ancestry_group}-${gwas_tag}-regenie_firth.log)
        controls=0
      fi

      echo "##AnalysisType\tGWAS" >> header.txt
      echo "##StudyTag\t${gwas_tag}" >> header.txt
      echo "##StudyType\t${trait_type == "binary" ? 'CaseControl' : 'Continuous'}" >> header.txt
      echo "##PhenoName\t\${pheno_name}" >> header.txt
      echo "##CovarNames\t\${covar_names}" >> header.txt
      echo "##Population\t${ancestry_group}" >> header.txt
      echo "##TotalCases\t\${cases}" >> header.txt
      echo "##TotalControls\t\${controls}" >> header.txt
      echo "##Method\tregenie" >> header.txt
      echo "##GeneticModel\t${params.regenie_geno_model}" >> header.txt
      echo "##gwas_pipeline_params\t${all_params}" >> header.txt
      cat header.txt ${ancestry_group}-${gwas_tag}-regenie_firth*.regenie > regenie_out.tmp
      mv regenie_out.tmp ${ancestry_group}-${gwas_tag}-regenie_firth*.regenie
      """
    }
  }

  /*--------------------------------------------------
    GWAS using fastGWA-GLMM
  ---------------------------------------------------*/

  if (params.fastgwa_glmm) {
    process run_fastgwa_glmm {
      tag "${ancestry_group} ${gwas_tag}"
      label 'large_resources'
      label 'fastgwa_glmm'
      publishDir "${params.outdir}/${ancestry_group}/${gwas_tag}/fastgwa_glmm", mode: 'copy'
      stageInMode 'copy'

      input:
      set val(ancestry_group), val(gwas_tag), val(trait_type), file('phenofile.phe'), file('in.pgen'), file('in.pvar'), file('in.psam'), file('in.log') from ch_aligned_test_variants_for_fastgwa_glmm

      output:
      set file("${ancestry_group}-${gwas_tag}-fastgwa_glmm.fastGWA"), file("*GCTAgrm*"), file("*GCTAsparsegrm*"), file("*-fastgwa_glmm.*")

      script:
      """
      # Split covariates into quantitative and binary
      cut --complement -f 3 phenofile.phe > covariates.tsv
      numfields=\$(head -n 1 covariates.tsv | tr '\\t' '\\n' | wc -l)
      qcovs="1,2"; qnum=0
      bcovs="1,2"; bnum=0
      for col in \$(seq 3 \$numfields); do
        uniqvals=\$(tail -n +2 covariates.tsv | cut -f \$col | sort -u | wc -l)
        if [ \$uniqvals -gt 2 ]; then
          qcovs="\${qcovs},\${col}"
          ((qnum=qnum+1))
        else
          bcovs="\${bcovs},\${col}"
          ((bnum=bnum+1))
        fi
      done
      cut -f \$qcovs covariates.tsv > qnt_covariates.tsv
      cut -f \$bcovs covariates.tsv > bin_covariates.tsv

      if [ \$bnum -gt 0 ]; then bcovar_flag="--covar bin_covariates.tsv"; else bcovar_flag=""; fi
      if [ \$qnum -gt 0 ]; then qcovar_flag="--qcovar qnt_covariates.tsv"; else qcovar_flag=""; fi
      
      # Make full GRM
      plink2 \
        --pfile in \
        --make-grm-bin \
        --threads ${task.cpus -1} --memory ${task.memory.toMega() -200} \
        --out ${ancestry_group}-${gwas_tag}-GCTAgrm
      
      # Make sparse GRM
      gcta_v1.94.0Beta_linux_kernel_2_x86_64_static \
        --grm ${ancestry_group}-${gwas_tag}-GCTAgrm \
        --make-bK-sparse 0.05 \
        --out ${ancestry_group}-${gwas_tag}-GCTAsparsegrm
      
      # Run association tests
      gcta_v1.94.0Beta_linux_kernel_2_x86_64_static \
        --pfile in \
        --grm-sparse ${ancestry_group}-${gwas_tag}-GCTAsparsegrm \
        --fastGWA-mlm \
        --pheno phenofile.phe \
        \$bcovar_flag \
        \$qcovar_flag \
        --out ${ancestry_group}-${gwas_tag}-fastgwa_glmm

      # add metadata to output table
      pheno_name=\$(awk 'NR==1{print \$3}' phenofile.phe)
      covar_names=\$(awk 'NR==1{for(i=4; i <= NF; i++){printf("%s, ", \$i)}}' phenofile.phe)

      if [ ${trait_type}  == 'binary' ]; then
        cases=\$(awk '\$3==2{cases++}END{print cases}' phenofile.phe)
        controls=\$(awk '\$3==1{cntrls++}END{print cntrls}' phenofile.phe)
      else
        cases=\$(awk 'NR>1{smpls++}END{print smpls}' phenofile.phe)
        controls=0
      fi

      echo "##AnalysisType\tGWAS" >> header.txt
      echo "##StudyTag\t${gwas_tag}" >> header.txt
      echo "##StudyType\t${trait_type == "binary" ? 'CaseControl' : 'Continuous'}" >> header.txt
      echo "##PhenoName\t\${pheno_name}" >> header.txt
      echo "##CovarNames\t\${covar_names}" >> header.txt
      echo "##Population\t${ancestry_group}" >> header.txt
      echo "##TotalCases\t\${cases}" >> header.txt
      echo "##TotalControls\t\${controls}" >> header.txt
      echo "##Method\tfastGWA-GLMM" >> header.txt
      echo "##GeneticModel\tadditive" >> header.txt
      echo "##gwas_pipeline_params\t${all_params}" >> header.txt

      cat header.txt ${ancestry_group}-${gwas_tag}-fastgwa_glmm.fastGWA > fastgwa_glmm_out.tmp
      mv fastgwa_glmm_out.tmp ${ancestry_group}-${gwas_tag}-fastgwa_glmm.fastGWA
      """
    }
  }

  /*--------------------------------------------------
    GWAS using BOLT-LMM
  ---------------------------------------------------*/
  if (params.bolt_lmm) {
    ch_run_bolt_lmm_in = ch_merged_bgen_bolt_lmm.combine(ch_plink_input_for_grm_bolt_lmm, by: [0,1])
    process run_bolt_lmm {
      tag "${ancestry_group} ${gwas_tag}"
      label 'large_resources'
      label 'bolt_lmm'
      publishDir "${params.outdir}/${ancestry_group}/${gwas_tag}/bolt_lmm", mode: 'copy'

      input:
      set val(ancestry_group), val(gwas_tag), val(trait_type), file('phenofile.phe'), file('in.bgen'), file('in.sample'), file('in.log'), file('aligned_grm_variants.bed'), file('aligned_grm_variants.bim'), file('aligned_grm_variants.fam'), file('aligned_grm_variants.log') from ch_run_bolt_lmm_in
      each file(ld_scores) from ch_ld_scores

      output:
      set file("${ancestry_group}-${gwas_tag}-bolt_lmm.tsv"), file("${ancestry_group}-${gwas_tag}-bolt_lmm.*")
      
      script:
      """
      # remove leading '#' in phenofile header
      sed '1 s/^#//' phenofile.phe > phenofile.phe_1 && mv phenofile.phe_1 phenofile.phe

      # get pheno col name
      phenocol=\$(head -n 1 phenofile.phe | cut -f3 )

      # Split covariates into quantitative and binary
      cut --complement -f 1-3 phenofile.phe > covariates.tsv
      numfields=\$(head -n 1 covariates.tsv | tr '\\t' '\\n' | wc -l)
      qcovs=""
      bcovs=""
      for col in \$(seq 1 \$numfields); do
        colname=\$(head -n 1 covariates.tsv | cut -f \$col)
        uniqvals=\$(tail -n +2 covariates.tsv | cut -f \$col | sort -u | sed '/^NA\$/d' | wc -l)
        if [ \$uniqvals -gt 2 ]; then
          qcovs="\${qcovs} --qCovarCol=\${colname}"
        else
          bcovs="\${bcovs} --covarCol=\${colname}"
        fi
      done

      bolt --lmm \
          --bfile=aligned_grm_variants \
          --bgenFile=in.bgen \
          --sampleFile=in.sample \
          --phenoFile=phenofile.phe \
          --phenoCol=\$phenocol \
          --covarFile=phenofile.phe \
          \$qcovs \
          \$bcovs \
          --LDscoresFile=${ld_scores} \
          --verboseStats \
          --LDscoresMatchBp \
          --statsFileBgenSnps=${ancestry_group}-${gwas_tag}-bolt_lmm.tsv.gz \
          --statsFile=${ancestry_group}-${gwas_tag}-bolt_lmm.ldpruned.tsv \
          > ${ancestry_group}-${gwas_tag}-bolt_lmm.log

      gzip -d ${ancestry_group}-${gwas_tag}-bolt_lmm.tsv.gz

      # add metadata to output table
      pheno_name=\$(awk 'NR==1{print \$3}' phenofile.phe)
      covar_names=\$(awk 'NR==1{for(i=4; i <= NF; i++){printf("%s, ", \$i)}}' phenofile.phe)

      if [ ${trait_type}  == 'binary' ]; then
        cases=\$(awk '\$3==2{cases++}END{print cases}' phenofile.phe)
        controls=\$(awk '\$3==1{cntrls++}END{print cntrls}' phenofile.phe)
      else
        cases=\$(awk 'NR>1{smpls++}END{print smpls}' phenofile.phe)
        controls=0
      fi

      echo "##AnalysisType\tGWAS" >> header.txt
      echo "##StudyTag\t${gwas_tag}" >> header.txt
      echo "##StudyType\t${trait_type == "binary" ? 'CaseControl' : 'Continuous'}" >> header.txt
      echo "##PhenoName\t\${pheno_name}" >> header.txt
      echo "##CovarNames\t\${covar_names}" >> header.txt
      echo "##Population\t${ancestry_group}" >> header.txt
      echo "##TotalCases\t\${cases}" >> header.txt
      echo "##TotalControls\t\${controls}" >> header.txt
      echo "##Method\tBOLT-LMM" >> header.txt
      echo "##GeneticModel\tadditive" >> header.txt
      echo "##gwas_pipeline_params\t${all_params}" >> header.txt

      cat header.txt ${ancestry_group}-${gwas_tag}-bolt_lmm.tsv > bolt_lmm_out.tmp
      mv bolt_lmm_out.tmp ${ancestry_group}-${gwas_tag}-bolt_lmm.tsv
      """
    }
  }

  /*--------------------------------------------------
    GWAS Analysis with Plink2
  ---------------------------------------------------*/
  if (params.plink2_gwas) {
    process plink2_gwas {
      tag "${ancestry_group} ${gwas_tag}"
      label "plink2_gwas"
      label "medium_resources"
      publishDir "${params.outdir}/${ancestry_group}/${gwas_tag}/plink2_gwas", mode: 'copy'

      input:
      set val(ancestry_group), val(gwas_tag), val(trait_type), file('phenofile.phe'), file('in.pgen'), file('in.pvar'), file('in.psam'), file('in.log') from ch_aligned_test_variants_for_plink2_gwas

      output:
      set file("${ancestry_group}-${gwas_tag}-plink2_glm_gen.*.glm.*"), file("${ancestry_group}-${gwas_tag}-plink2_glm_gen.log")
      
      script:
      """
      # rename PAT/MAT columns to _PAT/_MAT
      sed -r '1 s/(MAT|PAT)/_\\1/g' phenofile.phe > pheno_reheadered.phe

      # make covar file from phenofile
      cut --complement -f 3 pheno_reheadered.phe > covar.tsv

      # if pheno col is coded as 0/1 -> 1/2
      uniquevals=\$(cut -f 3 pheno_reheadered.phe | tail -n +2 | sort -u | tr -d '\\n')
      if [ \$uniquevals == '01' ]; then
        awk -v 'BEGIN{FS=OFS="\\t"} NR==1{print \$0} NR>1{gsub("1","2",\$3);gsub("0","1",\$3);print \$0}' pheno_reheadered.phe > pheno_temp.phe
        mv pheno_temp.phe pheno_reheadered.phe
      fi

      /tools/plink2 --pfile in \
      --pheno pheno_reheadered.phe \
      --pheno-col-nums 3 \
      --glm omit-ref cols=+a1freq,+beta hide-covar allow-no-covars ${params.plink2_gwas_glm_flags} ${params.plink2_gwas_method} \
      --covar covar.tsv \
      --covar-variance-standardize \
      --vif ${params.plink2_vif} \
      --threads ${task.cpus -1} --memory ${task.memory.toMega() -200} \
      --out ${ancestry_group}-${gwas_tag}-plink2_glm_gen

      # add metadata to output table
      pheno_name=\$(awk 'NR==1{print \$3}' phenofile.phe)
      covar_names=\$(awk 'NR==1{for(i=4; i <= NF; i++){printf("%s, ", \$i)}}' phenofile.phe)

      if [ ${trait_type}  == 'binary' ]; then
        cases=\$(sed -E -n '/phenotype loaded/ s/.+ \\(([0-9]+) cases, ([0-9]+) controls.+/\\1/p' ${ancestry_group}-${gwas_tag}-plink2_glm_gen.log)
        controls=\$(sed -E -n '/phenotype loaded/ s/.+ \\(([0-9]+) cases, ([0-9]+) controls.+/\\2/p' ${ancestry_group}-${gwas_tag}-plink2_glm_gen.log)
      else
        cases=\$(sed -E -n '/phenotype loaded/ s/.+ \\(([0-9]+) values.+/\\1/p' ${ancestry_group}-${gwas_tag}-plink2_glm_gen.log)
        controls=0
      fi

      echo "##AnalysisType\tGWAS" >> header.txt
      echo "##StudyTag\t${gwas_tag}" >> header.txt
      echo "##StudyType\t${trait_type == "binary" ? 'CaseControl' : 'Continuous'}" >> header.txt
      echo "##PhenoName\t\${pheno_name}" >> header.txt
      echo "##CovarNames\t\${covar_names}" >> header.txt
      echo "##Population\t${ancestry_group}" >> header.txt
      echo "##TotalCases\t\${cases}" >> header.txt
      echo "##TotalControls\t\${controls}" >> header.txt
      echo "##Method\tPLINK2-GLM" >> header.txt
      echo "##gwas_pipeline_params\t${all_params}" >> header.txt

      cat header.txt ${ancestry_group}-${gwas_tag}-plink2_glm_gen.*.glm.* > plink2_gwas_out.tmp
      mv plink2_gwas_out.tmp ${ancestry_group}-${gwas_tag}-plink2_glm_gen.*.glm.*
      """
    }
  }

  /*--------------------------------------------------
    GWAS Analysis with SAIGE
  ---------------------------------------------------*/
  if (params.saige) {

    ch_aligned_pheno_info_for_saige_step1
      .map{it[0..3]}
      .combine(ch_plink_input_for_grm_saige, by: [0,1])
      .set{ch_saige_step1_fit_model_in}
    
    process saige_step1_fit_model {
      tag "${ancestry_group} ${gwas_tag}"
      label 'saige'
      label 'large_resources'
      publishDir "${params.outdir}/${ancestry_group}/${gwas_tag}/saige", mode: 'copy'

      input:
      set val(ancestry_group), val(gwas_tag), val(trait_type), file('phenofile.phe'), file('aligned_grm_variants.bed'), file('aligned_grm_variants.bim'), file('aligned_grm_variants.fam'), file('aligned_grm_variants.log') from ch_saige_step1_fit_model_in

      output:
      set val(ancestry_group), val(gwas_tag), file("${ancestry_group}-${gwas_tag}-saige_step1.rda"), file("${ancestry_group}-${gwas_tag}-saige_step1.varianceRatio.txt") into ch_saige_step1_out
      file("${ancestry_group}-${gwas_tag}-saige_step1*")

      script:
      """
      covar_cols=\$(head -n 1 phenofile.phe | cut --complement -f1,2,3 | tr '\\t' ',')
      pheno_col=\$(head -n 1 phenofile.phe | cut -f3)

      # recode phenotype column 1/2 -> 0/1
      if [ ${trait_type}  == 'binary' ]; then
        awk 'BEGIN{FS=OFS="\\t"} NR==1{print \$0} NR>1{\$3=\$3 - 1; print \$0}' phenofile.phe > pheno_temp.phe
        mv pheno_temp.phe phenofile.phe
      fi

      # Replace ChrX to 23
      sed 's/^X/23/' aligned_grm_variants.bim > aligned_grm_variants_modified.bim
      mv aligned_grm_variants.bed aligned_grm_variants_modified.bed
      mv aligned_grm_variants.fam aligned_grm_variants_modified.fam
      step1_fitNULLGLMM.R \
        --plinkFile=aligned_grm_variants_modified \
        --phenoFile=phenofile.phe \
        --covarColList="\$covar_cols" \
        --phenoCol="\$pheno_col" \
        --sampleIDColinphenoFile=IID \
        --traitType=${trait_type} \
        --outputPrefix="${ancestry_group}-${gwas_tag}-saige_step1" \
        --nThreads=${task.cpus} \
        ${params.saige_step1_extra_flags} \
        > ${ancestry_group}-${gwas_tag}-saige_step1.log
      """
    }

    ch_saige_step2_spa_tests_in = ch_aligned_test_variants_chrom_for_saige_step2.combine(ch_saige_step1_out, by: [0,1])
    
    process saige_step2_spa_tests {
      tag "${ancestry_group} ${gwas_tag} chrom-${chrom}"
      label 'saige'
      label 'medium_resources'

      input:
      set val(ancestry_group), val(gwas_tag), val(trait_type), val(chrom), file('phenofile.phe'), file(vcf_file), file(vcf_csi), file('step1.rda'), file('step1.varianceRatio.txt') from ch_saige_step2_spa_tests_in

      output:
      set val(ancestry_group), val(gwas_tag), file("*.saige_gwas_out.txt"), file("*saige_step2.log") into ch_saige_output

      script:
      saige_step2_analysis_type = params.saige_container == 'finngen/saige:0.39.1.fg' ? "--analysisType=${params.saige_step2_analysis_type}" : ""
      """
      step2_SPAtests.R \
        --vcfFile=${vcf_file} \
        --vcfFileIndex=${vcf_csi} \
        --vcfField=GT \
        --chrom=${chrom} \
        --minMAC=20 \
        --GMMATmodelFile=step1.rda \
        --varianceRatioFile=step1.varianceRatio.txt \
        --SAIGEOutputFile="${ancestry_group}-${gwas_tag}-${chrom}.saige_gwas_out.txt" \
        --numLinesOutput=2 \
        --IsOutputAFinCaseCtrl=TRUE \
        --IsDropMissingDosages=FALSE \
        --IsOutputNinCaseCtrl=TRUE \
        --IsOutputHetHomCountsinCaseCtrl=TRUE \
        ${saige_step2_analysis_type} \
        > ${ancestry_group}-${gwas_tag}-${chrom}-saige_step2.log

      # add metadata to output table
      pheno_name=\$(awk 'NR==1{print \$3}' phenofile.phe)
      covar_names=\$(awk 'NR==1{for(i=4; i <= NF; i++){printf("%s, ", \$i)}}' phenofile.phe)

      if [ ${trait_type}  == 'binary' ]; then
        cases=\$(sed -n -E '/^Analyzing/ {s/Analyzing +([0-9]+) +cases and +([0-9]+) +controls.*/\\1/ p;q}' ${ancestry_group}-${gwas_tag}-${chrom}-saige_step2.log)
        controls=\$(sed -n -E '/^Analyzing/ {s/Analyzing +([0-9]+) +cases and +([0-9]+) +controls.*/\\2/ p;q}' ${ancestry_group}-${gwas_tag}-${chrom}-saige_step2.log)
      else
        cases=\$(sed -n -E '/samples were used/ {s/([0-9]+) +samples .*/\\1/ p;q}' ${ancestry_group}-${gwas_tag}-${chrom}-saige_step2.log)
        controls=0
      fi

      echo "##AnalysisType\tGWAS" >> header.txt
      echo "##StudyTag\t${gwas_tag}" >> header.txt
      echo "##StudyType\t${trait_type == "binary" ? 'CaseControl' : 'Continuous'}" >> header.txt
      echo "##PhenoName\t\${pheno_name}" >> header.txt
      echo "##CovarNames\t\${covar_names}" >> header.txt
      echo "##Population\t${ancestry_group}" >> header.txt
      echo "##TotalCases\t\${cases}" >> header.txt
      echo "##TotalControls\t\${controls}" >> header.txt
      echo "##Method\tSAIGE" >> header.txt
      echo "##GeneticModel\t${params.saige_step2_analysis_type}" >> header.txt
      echo "##gwas_pipeline_params\t${all_params}" >> header.txt

      cat header.txt ${ancestry_group}-${gwas_tag}-${chrom}.saige_gwas_out.txt > saige_out.tmp
      mv saige_out.tmp ${ancestry_group}-${gwas_tag}-${chrom}.saige_gwas_out.txt
      """
    }

    process concat_saige {
      label 'micro_resources'
      tag "${ancestry_group} ${gwas_tag}"
      publishDir "${params.outdir}/${ancestry_group}/${gwas_tag}/saige", mode: 'copy'

      input:
      set val(ancestry_group), val(gwas_tag), file(saige_output_files), file(saige_log_files) from ch_saige_output.groupTuple(by:[0,1])

      output:
      set file("${ancestry_group}-${gwas_tag}-saige.txt"), file("*-allchroms-saige_step2.log")

      script:
      """
      # concat table
      sed -e '/^CHR /q' *.saige_gwas_out.txt > header.txt

      for gwas_table in *.saige_gwas_out.txt; do
        sed -e '1,/^CHR / d' \$gwas_table
      done \
      | cat header.txt - \
      > ${ancestry_group}-${gwas_tag}-saige.txt

      # concat log
      for log_file in *-saige_step2.log; do
        echo -e \$log_file "\\n" >> all_chroms.log
        cat \$log_file >> all_chroms.log
        echo -e "\\n------------\\n" >> all_chroms.log
      done
      mv all_chroms.log ${ancestry_group}-${gwas_tag}-allchroms-saige_step2.log
      """
    }
  }

}

/*--------------------------------------------------
  GWAS using Hail
---------------------------------------------------*/

if (params.hail) {
    process hail_gwas {
    label 'hail'
    label 'large_resources'
    publishDir "${params.outdir}/hail_gwas", mode: 'copy'

    input:
    file('phenofile.phe') from ch_pheno_hail
    file(hail_matrix) from ch_user_input_hail_matrix
    file(hail_gwas_script) from ch_hail_gwas_script

    output:
    file ("*_hail_GWAS.tsv")

    script:
    """
    # remove leading '#' in phenofile header
    sed '1 s/^#//' phenofile.phe > phenofile.phe_1 && mv phenofile.phe_1 phenofile.phe
    # get pheno col name
    phenocol=\$(head -n 1 phenofile.phe | cut -f3 )
    # get covar columns
    covars=\$(head -n 1 phenofile.phe | cut --complement -f 1-3 | tr '\\t' ',')

    python ${hail_gwas_script} \
        --hail ${hail_matrix} \
        --phe phenofile.phe \
        --id-col 'IID' \
        --response \$phenocol \
        --cov \$covars \
        --pca ${params.number_pcs} \
        --call-rate-thr ${params.hail_call_rate_thr} \
        --maf-thr ${params.maf} \
        --output ${hail_matrix.simpleName}_hail_GWAS.tsv

    # add metadata to output table
    pheno_name=\$(awk 'NR==1{print \$3}' phenofile.phe)
    covar_names=\$(awk 'NR==1{for(i=4; i <= NF; i++){printf("%s, ", \$i)}}' phenofile.phe)
    genome_build=\$(cat genome_build)

    # get trait_type
    uniquevals=\$(cut -f 3 phenofile.phe | tail -n +2 | sort -u | wc -l)
    if [ \$uniquevals -gt 2 ]; then
      trait_type="Continuous"
      cases=\$(awk 'NR>1{smpls++}END{print smpls}' phenofile.phe)
      controls=0
    else
      trait_type="CaseControl"
      cases=\$(awk '\$3==2{cases++}END{print cases}' phenofile.phe)
      controls=\$(awk '\$3==1{cntrls++}END{print cntrls}' phenofile.phe)
    fi

    echo "##AnalysisType\tGWAS" >> header.txt
    echo "##StudyTag\tnotransform" >> header.txt
    echo "##StudyType\t\$trait_type" >> header.txt
    echo "##PhenoName\t\${pheno_name}" >> header.txt
    echo "##CovarNames\t\${covar_names}" >> header.txt
    echo "##Population\tallancs" >> header.txt
    echo "##TotalCases\t\${cases}" >> header.txt
    echo "##TotalControls\t\${controls}" >> header.txt
    echo "##Method\tHail-GWAS" >> header.txt
    echo "##GeneticModel\tadditive" >> header.txt
    echo "##GenomeBuild\t\${genome_build}" >> header.txt
    echo "##gwas_pipeline_params\t${all_params}" >> header.txt

    cat header.txt ${hail_matrix.simpleName}_hail_GWAS.tsv > hail_out.tmp
    mv hail_out.tmp ${hail_matrix.simpleName}_hail_GWAS.tsv
    """
    }
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

// userName = workflow.userName

// if ( userName == "ubuntu" || userName == "ec2-user") {
//   workflow.onComplete {

//   def trace_timestamp = new java.util.Date().format( 'yyyy-MM-dd_HH-mm-ss')

//   traceReport = file("/home/${userName}/nf-out/trace.txt")
//   traceReport.copyTo("results/pipeline_info/execution_trace_${trace_timestamp}.txt")
//   }
// }