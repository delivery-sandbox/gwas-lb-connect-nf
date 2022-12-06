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

	full_cohort <- DatabaseConnector::querySql(connection, glue::glue("SELECT CAST(COHORT_DEFINITION_ID as character), SUBJECT_ID FROM {cohort_table}", cohort_table = cohort_table), snakeCaseToCamelCase = T)

	all_covs <- map(covariate_spec, function(cov){

		covariates_to_report <- filter(covariate_data$covariateRef, str_detect(covariateName, cov$covariate))

		if(!is.null(cov$concept_ids)) covariates_to_report <- filter(covariates_to_report, conceptId %in% cov$concept_ids)

		covariates <- filter(covariate_data$covariates , covariateId %in% !! covariates_to_report$covariateId) %>% collect

		if(is.null(cov$transformation)){
			tmp <- left_join(full_cohort, rename(covariates, subjectId = rowId)) %>%
				left_join(select(covariates_to_report, covariateId, covariateName)) %>%
				select(-covariateId) %>%
				mutate(covariateName = str_c(cov$covariate_name, ": ", coalesce(covariateName, "Unknown"))) %>%
				pivot_wider(names_from = covariateName, values_from = covariateValue, values_fill = 0)
		}

		if(!is.null(cov$transformation)){
			if(cov$transformation == "binary"){
				tmp <- left_join(full_cohort, rename(covariates, subjectId = rowId)) %>%
					group_by(cohortDefinitionId, subjectId) %>%
					summarise(!! cov$covariate_name := coalesce(max(covariateValue), 0)) %>%
					return()
			}

			if(cov$transformation == "categorical"){
				tmp <- left_join(full_cohort, rename(covariates, subjectId = rowId)) %>%
					left_join(select(covariates_to_report, covariateId, covariateName)) %>%
					group_by(cohortDefinitionId, subjectId) %>%
					summarise(!! cov$covariate_name := str_c(sort(unique(str_remove(covariateName[covariateValue==1], "^[^=]*= ")))))
			}

			if(str_detect(cov$transformation, "^function")){

				transformation_fn <- eval(parse_expr(cov$transformation))

				tmp <- left_join(full_cohort, rename(covariates, subjectId = rowId)) %>%
					group_by(cohortDefinitionId, subjectId) %>%
					summarise(!! cov$covariate_name := transformation_fn(covariateValue)) %>%
					return()
			}
		}

		return(tmp)

	})

	reduce(all_covs, left_join)

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

Sys.setenv(DATABASECONNECTOR_JAR_FOLDER = getwd())

DatabaseConnector::downloadJdbcDrivers('postgresql')

connectionDetails <- discard(connectionDetailsFull, names(connectionDetailsFull) %in% c('cohortDatabaseSchema', 'cdmDatabaseSchema'))

connectionDetails <- exec(DatabaseConnector::createConnectionDetails, !!! connectionDetails)

phenofile <- get_covariate_data(connectionDetails, cohortCounts, cohortTable, covariateSpec, cdmDatabaseSchema = connectionDetailsFull$cdmDatabaseSchema, cohortDatabaseSchema = connectionDetailsFull$cohortDatabaseSchema)

connection <- DatabaseConnector::connect(connectionDetails)

DatabaseConnector::dbExecute(connection, str_c("DROP TABLE IF EXISTS ",  str_c(str_c(cohortTable, c("","_inclusion_result", "_inclusion_stats", "_summary_stats", "_censor_stats")), collapse = ", ")))

DatabaseConnector::disconnect(connection)

write_csv(phenofile, "phenofile.csv")