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
	library(SqlRender)
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
generateCohortsFromJson <- function(connectionDetails, cohortTableName = stringr::str_c("cohort_", stringi::stri_rand_strings(n=1, length = 10)), cohortJsonFiles, cdmDatabaseSchema, cohortDatabaseSchema = cdmDatabaseSchema, cohortJsonFilesToReorder, limitType = "random"){
	
	cohortsToCreate <- CohortGenerator::createEmptyCohortDefinitionSet()
	
	for (i in 1:length(cohortJsonFiles)) {
		cohortJsonFileName <- cohortJsonFiles[i]
		
		cohortName <- tools::file_path_sans_ext(basename(cohortJsonFileName))
		cohort_id <- case_when(str_detect(cohortName, "^cases") ~ 2, str_detect(cohortName, "^controls") ~ 1)
		cohortJson <- readChar(cohortJsonFileName, file.info(cohortJsonFileName)$size)
		cohortExpression <- CirceR::cohortExpressionFromJson(cohortJson)
		cohortSql <- CirceR::buildCohortQuery(cohortExpression, options = CirceR::createGenerateOptions(generateStats = FALSE))
		if(cohortJsonFileName %in% cohortJsonFilesToReorder & limitType %in% c("random", "last")){
			reorder_fn <- case_when(limitType == "random" ~ "random()", TRUE ~ "E.sort_date DESC")
			cohortSql <- str_replace(cohortSql, "E.sort_date ASC", reorder_fn)
			cohortSql <- str_c("SELECT setseed(0.5);", cohortSql)
		}
		writeSql(cohortSql, str_c(cohortName,".sql"))
		cohortsToCreate <- rbind(cohortsToCreate, data.frame(cohortId = cohort_id, cohortName = cohortName,  sql = cohortSql, stringsAsFactors = FALSE))
	}
	
	cohortTableNames <- CohortGenerator::getCohortTableNames(cohortTable = cohortTableName)
	
	tables <- CohortGenerator::createCohortTables(
		connectionDetails = connectionDetails,
		cohortDatabaseSchema = cohortDatabaseSchema,
		cohortTableNames = cohortTableNames)
	
	cohortsGenerated <- CohortGenerator::generateCohortSet(
		connectionDetails = connectionDetails,
		cdmDatabaseSchema = cdmDatabaseSchema,
		cohortDatabaseSchema = cohortDatabaseSchema,
		cohortTableNames = cohortTableNames,
		cohortDefinitionSet = cohortsToCreate)
	
	return(list(cohort_table = cohortTableName))
	
}

# Parsing arguments
parseArgs    <- function(x) strsplit(sub("^--", "", x), "=")
argsL        <- as.list(as.character(as.data.frame(do.call("rbind", parseArgs(args)))$V2))
names(argsL) <- as.data.frame(do.call("rbind", parseArgs(args)))$V1
args         <- argsL
rm(argsL)


cases_json <- args$cases
controls_json <- args$controls
pheno_label <- args$pheno_label

connectionDetailsFull <- jsonlite::read_json(args$connection_details)
control_index <- args$control_index_date

## Database Connection Jars
Sys.setenv(DATABASECONNECTOR_JAR_FOLDER = getwd())
unzip(args$db_jars)

## Database Connection Jars
connectionDetails <- discard(connectionDetailsFull, names(connectionDetailsFull) %in% c('cohortDatabaseSchema', 'cdmDatabaseSchema'))
connectionDetails <- exec(DatabaseConnector::createConnectionDetails, !!! connectionDetails)

## Write cases
cohorts_generated <- generateCohortsFromJson(connectionDetails, cohortJsonFiles = c(controls_json, cases_json), cdmDatabaseSchema = connectionDetailsFull$cdmDatabaseSchema, cohortDatabaseSchema = connectionDetailsFull$cohortDatabaseSchema, cohortJsonFilesToReorder = controls_json, limitType = control_index)

connection <- connect(connectionDetails)

sql <- glue::glue("
SELECT cohort_definition_id as cohort_id, count(distinct subject_id) as cohort_subjects
FROM {cohort_database_schema}.{cohort_table} 
GROUP BY cohort_definition_id
", 
	cohort_table = cohorts_generated$cohort_table,  
	cohort_database_schema = connectionDetailsFull$cohortDatabaseSchema
	)

cohort_counts <- querySql(connection, sql, snakeCaseToCamelCase = T) %>%
	mutate(cohortName = case_when(cohortId == 1 ~ str_c("controls_", pheno_label), cohortId == 2 ~ str_c("cases_", pheno_label)))

write_csv(cohort_counts, "cohort_counts_full.csv")

writeLines(cohorts_generated$cohort_table, con = "cohort_table_name.txt")