#!/usr/bin/env Rscript

######################
# Importing packages #
######################

##############################################################################################################
# This script generates cohorts in the database using all json cohort definitions in the working directory. 
##############################################################################################################

suppressPackageStartupMessages({
	library(tidyverse)
	library(CohortGenerator)
	library(ROhdsiWebApi)
	library(FeatureExtraction)
	library(jsonlite)
	library(RJSONIO)
})

options(scipen = 99999)

# Collecting arguments
args <- commandArgs(TRUE)
args

# Default setting when not all arguments passed or help is needed
if("--help" %in% args | "help" %in% args | (length(args) == 0) ) {

	cat("
	This script generates cohorts in the database using all json cohort definitions in the working directory. 
    
	Mandatory arguments:
    --connection_details     	A json containing database connection details
	
	Optional arguments:
    --help          This help message.
    
	Usage:
    generateCohorts.R --connection_details=connectionDetails.json
    \n")

	q(save="no")
}

#' Title Insert cohorts into the database
#'
#' @param connectionDetails Connection details to connect to the database via DatabaseConnector
#' @param cohortTableName The table name to insert cohorts into
#' @param cohortJsonFiles The OHDSI cohort definition json files to populate
#' @param cdmDatabaseSchema The name of the schema with clinical data
#' @param cohortDatabaseSchema The name of the schema to insert the cohort table
#'
#' @return
#' @export
#'
generateCohortsFromJson <- function(connectionDetails, cohortTableName = stringr::str_c("cohort_", stringi::stri_rand_strings(n=1, length = 10)), cohortJsonFiles, cdmDatabaseSchema, cohortDatabaseSchema = cdmDatabaseSchema){
	
	cohortsToCreate <- CohortGenerator::createEmptyCohortDefinitionSet()
	
	for (i in 1:length(cohortJsonFiles)) {
		cohortJsonFileName <- cohortJsonFiles[i]
		cohortName <- tools::file_path_sans_ext(basename(cohortJsonFileName))
		cohortJson <- readChar(cohortJsonFileName, file.info(cohortJsonFileName)$size)
		cohortExpression <- CirceR::cohortExpressionFromJson(cohortJson)
		cohortSql <- CirceR::buildCohortQuery(cohortExpression, options = CirceR::createGenerateOptions(generateStats = FALSE))
		cohortsToCreate <- rbind(cohortsToCreate, data.frame(cohortId = i, cohortName = cohortName,  sql = cohortSql, stringsAsFactors = FALSE))
	}
	
	cohortTableNames <- CohortGenerator::getCohortTableNames(cohortTable = cohortTableName)
	
	tables <- CohortGenerator::createCohortTables(connectionDetails = connectionDetails,
																								cohortDatabaseSchema = cohortDatabaseSchema,
																								cohortTableNames = cohortTableNames)
	
	cohortsGenerated <- CohortGenerator::generateCohortSet(connectionDetails = connectionDetails,
																												 cdmDatabaseSchema = cdmDatabaseSchema,
																												 cohortDatabaseSchema = cohortDatabaseSchema,
																												 cohortTableNames = cohortTableNames,
																												 cohortDefinitionSet = cohortsToCreate)
	
	cohortCounts <- CohortGenerator::getCohortCounts(connectionDetails = connectionDetails,
																									 cohortDatabaseSchema = cohortDatabaseSchema,
																									 cohortTable = cohortTableNames$cohortTable)
	
	return(list(cohort_table = cohortTableName, cohort_counts = cohortCounts))
	
}

# Parsing arguments
parseArgs    <- function(x) strsplit(sub("^--", "", x), "=")
argsL        <- as.list(as.character(as.data.frame(do.call("rbind", parseArgs(args)))$V2))
names(argsL) <- as.data.frame(do.call("rbind", parseArgs(args)))$V1
args         <- argsL
rm(argsL)

jsonFiles <- list.files(pattern = "\\.json")
cohortJsonFiles <- jsonFiles[jsonFiles != args$connection_details]
connectionDetailsFull <- jsonlite::read_json(args$connection_details)

Sys.setenv(DATABASECONNECTOR_JAR_FOLDER = getwd())

DatabaseConnector::downloadJdbcDrivers('postgresql')

connectionDetails <- discard(connectionDetailsFull, names(connectionDetailsFull) %in% c('cohortDatabaseSchema', 'cdmDatabaseSchema'))

connectionDetails <- exec(DatabaseConnector::createConnectionDetails, !!! connectionDetails)

cohorts_generated <- generateCohortsFromJson(connectionDetails, cohortJsonFiles = cohortJsonFiles, cdmDatabaseSchema = connectionDetailsFull$cdmDatabaseSchema, cohortDatabaseSchema = connectionDetailsFull$cohortDatabaseSchema)

writeLines(cohorts_generated$cohort_table, con = "cohort_table_name.txt")
write_csv(cohorts_generated$cohort_counts, "cohort_counts.csv")
