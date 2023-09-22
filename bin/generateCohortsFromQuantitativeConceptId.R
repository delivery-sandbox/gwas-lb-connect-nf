#!/usr/bin/env Rscript

######################
# Importing packages #
######################

##############################################################################################################
# This script generates cohorts in the database using all json cohort definitions in the working directory. 
##############################################################################################################

suppressPackageStartupMessages({
	library(tidyverse)
	library(DatabaseConnector)
	library(SqlRender)
	library(jsonlite)
})

options(scipen = 99999)

# Collecting arguments
args <- commandArgs(TRUE)
args

# Default setting when not all arguments passed or help is needed
if("--help" %in% args | "help" %in% args | (length(args) == 0) ) {

	cat("
	This script generates cohorts in the database using the SQL query provided. 
    
	Mandatory arguments:
    --connection_details     	A json containing database connection details
	
	Optional arguments:
    --help          This help message.
    
	Usage:
    generateCohortsFromQuantitativeCohortId.R --connection_details=connectionDetails.json
    \n")

	q(save="no")
}

# Parsing arguments
message(args)
parseArgs    <- function(x) strsplit(sub("^--", "", x), "=")
argsL        <- as.list(as.character(as.data.frame(do.call("rbind", parseArgs(args)))$V2))
names(argsL) <- as.data.frame(do.call("rbind", parseArgs(args)))$V1
args         <- argsL
rm(argsL)

pheno_label <- args$pheno_label
connectionDetailsFull <- jsonlite::read_json(args$connection_details)
quantitative_concept_id <- args$quantitative_concept_id
quantitative_occurrence <- case_when(args$quantitative_occurrence == "first" ~ "min", args$quantitative_occurrence == "last" ~ "max", TRUE ~ "missing")

## Database Connection Jars
Sys.setenv(DATABASECONNECTOR_JAR_FOLDER = getwd())
unzip(args$db_jars)

## Database Connection Jars
connectionDetails <- discard(connectionDetailsFull, names(connectionDetailsFull) %in% c('cohortDatabaseSchema', 'cdmDatabaseSchema'))
connectionDetails <- exec(DatabaseConnector::createConnectionDetails, !!! connectionDetails)
cohortTableName <- stringr::str_c("cohort_", stringi::stri_rand_strings(n=1, length = 10))
cdmDatabaseSchema <- connectionDetailsFull$cdmDatabaseSchema
cohortDatabaseSchema <- connectionDetailsFull$cohortDatabaseSchema

connection <- connect(connectionDetails)

quantitative_domain <- dbGetQuery(connection, glue::glue("SELECT domain_id FROM {cdmDatabaseSchema}.concept WHERE concept_id = {quantitative_concept_id}"))

if(nrow(quantitative_domain) == 0) stop("quantitative concept not found")
if(!quantitative_domain$domain_id %in% c("Observation", "Measurement")) stop("quantitative concept must be an observation or a measurement")

table_name <- tolower(quantitative_domain$domain_id)

sql <- glue::glue("
SET search_path TO {cdmDatabaseSchema};
DROP TABLE IF EXISTS  {cohortDatabaseSchema}.{cohortTableName};
CREATE TABLE {cohortDatabaseSchema}.{cohortTableName} AS
WITH CTE AS (
	SELECT person_id, max(observation_period_end_date) as max_observation_period_end_date, min(observation_period_start_date) as min_observation_period_start_date
	FROM {cdmDatabaseSchema}.observation_period
	GROUP BY person_id
),
CTE2 AS (
	SELECT person_id, {quantitative_occurrence}({table_name}_date) as cohort_start_date
	FROM {table_name} t
	WHERE {table_name}_concept_id = {quantitative_concept_id}
	GROUP BY person_id

)
SELECT 2 as cohort_definition_id, CTE2.person_id as subject_id, CTE2.cohort_start_date, CTE.max_observation_period_end_date as cohort_end_date
FROM CTE2
LEFT JOIN CTE on CTE.person_id = CTE2.person_id
")

writeSql(sql, str_c(cohortTableName,".sql"))

executeSql(connection, sql)

sql <- glue::glue("
SELECT cohort_definition_id as cohort_id, count(distinct subject_id) as cohort_subjects
FROM {cohortDatabaseSchema}.{cohortTableName} 
GROUP BY cohort_definition_id
")

cohort_counts <- querySql(connection, sql, snakeCaseToCamelCase = T) %>%
  mutate(cohortName = pheno_label)

write_csv(cohort_counts, "cohort_counts_full.csv")

writeLines(cohortTableName, con = "cohort_table_name.txt")

