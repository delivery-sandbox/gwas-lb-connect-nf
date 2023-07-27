#!/usr/bin/env Rscript

####################################################################################################################################
# This script generates a phenofile for all cohorts in the cohort_table specified using the covariate_spec provided. 
####################################################################################################################################

######################
# Importing packages #
######################

suppressPackageStartupMessages({
  library(tidyverse)
  library(CohortGenerator)
  library(ROhdsiWebApi)
  library(FeatureExtraction)
  library(jsonlite)
  library(RJSONIO)
  library(rlang)
  library(lubridate)
})

options(scipen = 99999)

# Collecting arguments
args <- commandArgs(TRUE)
args

# Default setting when not all arguments passed or help is needed
if("--help" %in% args | "help" %in% args | (length(args) == 0) ) {
  
  cat("
	This script generates a phenofile for all cohorts in the cohort_table specified using the covariate_spec provided. 
    Mandatory arguments:
    --connection_details     	A json containing database connection details
    --cohort_counts           A csv containing individual cohort counts
    --cohort_table						A text file containing the database location of the cohorts
    --covariate_spec          A json containing covariate specifications
    --phenofile_name          The name for the output phenofile
	  Optional arguments:
    --help          This help message.
    Usage:
    ./generatePhenofile.R --connection_details=connectionDetails.json --cohort_counts=cohort_counts.csv --cohort_table=cohort_table_name.txt --covariate_spec=covariate_spec.json
    \n")
  
  q(save="no")
}

#' Title Create a phenofile from cohorts based on covariate_spec
#'
#' @param connectionDetails Connection details to connect to the database via DatabaseConnector
#' @param cohort_counts A table of cohort counts
#' @param cohort_table THe name of the cohort table
#' @param covariate_spec A covariate specification file
#' @param cdmDatabaseSchema The name of the schema with clinical data
#' @param cohortDatabaseSchema The name of the schema to insert the cohort table
#'
#' @return A phenofile for all cohorts in cohort_table
#' @export
#'
get_covariate_data <- function(connectionDetails, cohort_counts, cohort_table, covariate_spec, cdmDatabaseSchema, cohortDatabaseSchema){
  
  covariate_settings <- FeatureExtraction::createCovariateSettings(
    useDemographicsAge = T,
    useDemographicsGender = T,
    useDemographicsRace = T,
    useConditionOccurrenceLongTerm = T,
    useMeasurementValueLongTerm = T,
    longTermStartDays = -99999,
    endDays = 99999
  )
  
  covariate_data_split <- map(cohort_counts$cohortId, ~FeatureExtraction::getDbCovariateData(connectionDetails, cdmDatabaseSchema = cdmDatabaseSchema, cohortDatabaseSchema = cohortDatabaseSchema, cohortTable = cohort_table, cohortId = .x, covariateSettings = covariate_settings))
  
  names(covariate_data_split) <- cohort_counts$cohortId
  
  covariate_data <- list()
  covariate_data$covariateRef <- map_df(covariate_data_split, ~collect(.x$covariateRef)) %>% distinct
  covariate_data$covariates <- bind_rows(map(covariate_data_split, ~collect(.x$covariates)), .id = "cohortDefinitionId")
  
  connection <- DatabaseConnector::connect(connectionDetails)
  
  full_cohort <- DatabaseConnector::querySql(connection, glue::glue("
    WITH CTE AS (SELECT PERSON_ID, max(OBSERVATION_PERIOD_END_DATE) as MAX_OBSERVATION_PERIOD_END_DATE FROM {cdmDatabaseSchema}.OBSERVATION_PERIOD GROUP BY PERSON_ID) 
    SELECT CAST(COHORT_DEFINITION_ID as character) COHORT_DEFINITION_ID, SUBJECT_ID, PERSON_SOURCE_VALUE, DATE_PART('Year', CTE.MAX_OBSERVATION_PERIOD_END_DATE) - p.YEAR_OF_BIRTH as BIOLOGICAL_AGE, P.YEAR_OF_BIRTH
    FROM {cohort_table} c LEFT JOIN {cdmDatabaseSchema}.PERSON p on c.SUBJECT_ID = p.PERSON_ID 
    LEFT JOIN CTE on c.SUBJECT_ID = CTE.PERSON_ID", cohort_table = cohort_table), snakeCaseToCamelCase = T)

  covariate_spec_ba <- keep(covariate_spec, ~.x$covariate == "biological_age")  

  if(length(covariate_spec_ba) >= 1) full_cohort <- mutate(full_cohort, biologicalAge = coalesce(biologicalAge, year(Sys.Date()) - yearOfBirth)) %>% rename(!! covariate_spec_ba[[1]]$covariate_name := biologicalAge) %>% select(-yearOfBirth)
  if(length(covariate_spec_ba) == 0) full_cohort <- select(full_cohort, -yearOfBirth, -biologicalAge)

  covariate_spec <- discard(covariate_spec, ~.x$covariate == "biological_age")

  all_covs <- map(covariate_spec, function(cov){
    
    covariates_to_report <- covariate_data$covariateRef

    if(is.null(cov$concept_ids) & !is.null(cov$covariate)){
      covariates_to_report <- filter(covariates_to_report, str_detect(covariateName, cov$covariate))
    }
    
    if(!is.null(cov$concept_ids)){
      covariates_to_report <- filter(covariates_to_report, conceptId %in% cov$concept_ids) %>% slice(1)
    }

    covariates <- filter(covariate_data$covariates , covariateId %in% !! covariates_to_report$covariateId) %>% collect

    if(!is.null(cov$valid_range)){
      if(!identical(cov$transformation, "value")) stop("valid_range only supported when covariate transformation is value")
      covariates <- filter(covariates, covariateValue >= cov$valid_range[1], covariateValue <= cov$valid_range[2])
    }
  
    if(is.null(cov$transformation)){
      tmp <- left_join(full_cohort, rename(covariates, subjectId = rowId)) %>%
        left_join(select(covariates_to_report, covariateId, covariateName)) %>%
        group_by(cohortDefinitionId, subjectId, personSourceValue) %>%
        summarise(!! cov$covariate_name := str_c(sort(unique(str_remove(covariateName[covariateValue==1], "^[^=]*= ")))))
    }
    
    if(!is.null(cov$transformation)){
      if(cov$transformation == "value"){
        tmp <- left_join(full_cohort, rename(covariates, subjectId = rowId)) %>%
          group_by(cohortDefinitionId, subjectId, personSourceValue) %>%
          summarise(!! cov$covariate_name := covariateValue) %>%
          return()
      }
      
      if(cov$transformation == "binary"){
        tmp <- left_join(full_cohort, rename(covariates, subjectId = rowId)) %>%
          group_by(cohortDefinitionId, subjectId, personSourceValue) %>%
          summarise(!! cov$covariate_name := coalesce(max(covariateValue), 0)) %>%
          return()
      }
      
      if(cov$transformation == "encoded"){
        tmp <- left_join(full_cohort, rename(covariates, subjectId = rowId)) %>%
          left_join(select(covariates_to_report, covariateId, covariateName)) %>%
          select(-covariateId) %>%
          mutate(covariateName = str_c(cov$covariate_name, ": ", coalesce(covariateName, "Unknown"))) %>%
          pivot_wider(names_from = covariateName, values_from = covariateValue, values_fill = 0)
      }
      
      if(cov$transformation == "categorical"){
        tmp <- left_join(full_cohort, rename(covariates, subjectId = rowId)) %>%
          left_join(select(covariates_to_report, covariateId, covariateName)) %>%
          group_by(cohortDefinitionId, subjectId, personSourceValue) %>%
          summarise(!! cov$covariate_name := str_c(sort(unique(str_remove(covariateName[covariateValue==1], "^[^=]*= ")))))
      }
      
      if(str_detect(cov$transformation, "^function")){
        
        transformation_fn <- eval(parse_expr(cov$transformation))
        
        tmp <- left_join(full_cohort, rename(covariates, subjectId = rowId)) %>%
          group_by(cohortDefinitionId, subjectId, personSourceValue) %>%
          summarise(!! cov$covariate_name := transformation_fn(covariateValue)) %>%
          return()
      }
    }

    if(!is.null(cov$imputation)){   
      if(!identical(cov$transformation, "value")) stop("imputation supported when covariate transformation is value")
      if(cov$imputation == "median") tmp <- group_by(tmp, cohortDefinitionId) %>% mutate(!! cov$covariate_name := coalesce(!! sym(cov$covariate_name), median(!! sym(cov$covariate_name), na.rm = T)))
      if(cov$imputation == "mean") tmp <- group_by(tmp, cohortDefinitionId) %>% mutate(!! cov$covariate_name := coalesce(!! sym(cov$covariate_name), mean(!! sym(cov$covariate_name), na.rm = T)))
    }
    
    return(ungroup(tmp))
    
  })
  
  left_join(full_cohort,reduce(all_covs, left_join))
  
}

# Parsing arguments
parseArgs    <- function(x) strsplit(sub("^--", "", x), "=")
argsL        <- as.list(as.character(as.data.frame(do.call("rbind", parseArgs(args)))$V2))
names(argsL) <- as.data.frame(do.call("rbind", parseArgs(args)))$V1
args         <- argsL
rm(argsL)


connectionDetailsFull <- jsonlite::read_json(args$connection_details)
cohortCounts <- read_csv(args$cohort_counts)
cohortTable <- readLines(args$cohort_table)
covariateSpec <- jsonlite::fromJSON(args$covariate_spec, simplifyVector = F)
pheno_label <- args$pheno_label
phenofile_name <- args$phenofile_name
quantitative_outcome_concept_id <- args$quantitative_outcome_concept_id

if(!is.na(as.integer(quantitative_outcome_concept_id))){
  covariateSpec <- append(covariateSpec, list(list(covariate_name = pheno_label, concept_ids = as.integer(quantitative_outcome_concept_id), transformation = "value")))
}

if(nrow(cohortCounts) == 0) writeLines("Cohorts contain no patients", "empty_phenofile.tsv")

if(nrow(cohortCounts) > 0){
## Database Connection Jars
Sys.setenv(DATABASECONNECTOR_JAR_FOLDER = getwd())
unzip(args$db_jars)

## Database Connection
connectionDetails <- discard(connectionDetailsFull, names(connectionDetailsFull) %in% c('cohortDatabaseSchema', 'cdmDatabaseSchema'))
connectionDetails <- exec(DatabaseConnector::createConnectionDetails, !!! connectionDetails)

phenofile <- get_covariate_data(connectionDetails, cohortCounts, cohortTable, covariateSpec, cdmDatabaseSchema = connectionDetailsFull$cdmDatabaseSchema, cohortDatabaseSchema = connectionDetailsFull$cohortDatabaseSchema)

## Tidy up tables
connection <- DatabaseConnector::connect(connectionDetails)
walk(str_c("DROP TABLE IF EXISTS ", str_c(cohortTable, c("","_inclusion_result", "_inclusion_stats", "_summary_stats", "_censor_stats"))),#
	~DatabaseConnector::dbExecute(connection, .x))
DatabaseConnector::disconnect(connection)

if(!is.na(as.integer(quantitative_outcome_concept_id))) phenofile <- select(phenofile, `#FID` = personSourceValue, IID = personSourceValue, everything(), -subjectId) %>%  mutate(across(matches("SEX|GENDER"), ~case_when(.x == "MALE" ~ "1", .x == "FEMALE" ~ "2", TRUE ~ NA_character_)))
if(is.na(as.integer(quantitative_outcome_concept_id))) phenofile <- select(phenofile, `#FID` = personSourceValue, IID = personSourceValue, everything(), !! pheno_label := cohortDefinitionId, -subjectId) %>%    mutate(across(matches("SEX|GENDER"), ~case_when(.x == "MALE" ~ "1", .x == "FEMALE" ~ "2", TRUE ~ NA_character_)))

write_tsv(filter(phenofile, !is.na(!! sym(pheno_label))), str_c(phenofile_name, ".phe"))}
