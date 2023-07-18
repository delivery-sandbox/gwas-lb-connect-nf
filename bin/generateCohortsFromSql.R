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
    generateCohortsFromSql.R --connection_details=connectionDetails.json
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

## Database Connection Jars
Sys.setenv(DATABASECONNECTOR_JAR_FOLDER = getwd())
unzip(args$db_jars)


## Read query and work out if it's a json
full_query_text <- readChar(args$query,file.info(args$query)$size)

## If the query starts with a bracket assume it is a json
if(str_sub(full_query_text,nchar(full_query_text),nchar(full_query_text)) == "\n") full_query_text <- str_sub(full_query_text,1,nchar(full_query_text)-1)
## If the query starts with a bracket assume it is a json
if(str_sub(full_query_text,1,1) == "{") sql_query <- jsonlite::read_json(args$query)$sql
## Otherwise assume it is a raw SQL query (no guarantees this will work)
if(str_sub(full_query_text,1,1) != "{") sql_query <- readSql(args$query)

## Database Connection Jars
connectionDetails <- discard(connectionDetailsFull, names(connectionDetailsFull) %in% c('cohortDatabaseSchema', 'cdmDatabaseSchema'))
connectionDetails <- exec(DatabaseConnector::createConnectionDetails, !!! connectionDetails)
cohortTableName <- stringr::str_c("cohort_", stringi::stri_rand_strings(n=1, length = 10))
cdmDatabaseSchema <- connectionDetailsFull$cdmDatabaseSchema
cohortDatabaseSchema <- connectionDetailsFull$cohortDatabaseSchema

connection <- connect(connectionDetails)

sql <- glue::glue("
SET search_path TO {cdmDatabaseSchema};
DROP TABLE IF EXISTS  {cohortDatabaseSchema}.{cohortTableName};
CREATE TABLE {cohortDatabaseSchema}.{cohortTableName} AS
WITH CTE AS (
	{sql_query}
),
CTE2 AS (
	SELECT person_id, max(observation_period_end_date) as max_observation_period_end_date, min(observation_period_start_date) as min_observation_period_start_date
	FROM observation_period
	GROUP BY person_id
),
CTE3 AS (
	SELECT 1 as cohort_definition_id, person_id FROM CTE
  UNION ALL
	SELECT 2 as cohort_definition_id, person_id FROM person WHERE person_id NOT IN (SELECT person_id FROM CTE)
)
SELECT cohort_definition_id, CTE3.person_id as subject_id, max_observation_period_end_date as cohort_start_date, max_observation_period_end_date as cohort_end_date
FROM CTE3
LEFT JOIN CTE2 on CTE3.person_id = CTE2.person_id")

sql <- gsub("\\\\", "", sql)

writeSql(sql, str_c(cohortTableName,".sql"))

executeSql(connection, sql)

sql <- glue::glue("
SELECT cohort_definition_id as cohort_id, count(distinct subject_id) as cohort_subjects
FROM {cohortDatabaseSchema}.{cohortTableName} 
GROUP BY cohort_definition_id
")

cohort_counts <- querySql(connection, sql, snakeCaseToCamelCase = T) %>%
  mutate(cohortName = case_when(cohortId == 1 ~ str_c("controls_", pheno_label), cohortId == 2 ~ str_c("cases_", pheno_label)))

write_csv(cohort_counts, "cohort_counts_full.csv")

writeLines(cohortTableName, con = "cohort_table_name.txt")
