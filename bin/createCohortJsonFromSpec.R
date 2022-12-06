#!/usr/bin/env Rscript

################################################################################################################
# This script generates OHDSI JSON cohort definitions based on the simple cohort_specs provided.
################################################################################################################

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
})

options(scipen = 99999)

# Collecting arguments
args <- commandArgs(TRUE)
args

# Default setting when not all arguments passed or help is needed
if("--help" %in% args | "help" %in% args | (length(args) == 0) ) {

	cat("
	This script generates OHDSI JSON cohort definitions based on the simple cohort_specs provided.
    
	Mandatory arguments:
    --cohort_specs     	A json containing one or more cohort specifications
	--cohort_skeleton   A json containing a cohort skeleton
	
	Optional arguments:
    --help          This help message.

    Usage:
    cohortJsonFromSpec.R --cohort_specs=cohorts_spec.json
    \n")

	q(save="no")
}

#' Title Add concepts to concept sets in a cohort definitions
#'
#' @param cohortDefinition The cohort definition from JSON read as a list
#' @param conceptSetId The id of the concept set to add concepts to
#' @param conceptId The concept set to add
#' @param includeDescendants  Whether descendants should be included
#' @param includeMapped Whether mapped concepts should be included
#' @param exclude Whether to exclude the concept
#'
#' @return The cohort definition with an added concept_id
#' @export
#'
addConceptToExpression <- function(cohortDefinition, conceptSetId, conceptId, includeDescendants, includeMapped = T, exclude = F){
	
	item <- list(concept = list(CONCEPT_ID = conceptId), isExcluded = F, includeDescendants = includeDescendants, includeMapped = includeMapped)
	
	if(conceptSetId %in% purrr::map_dbl(cohortDefinition$ConceptSets, ~.x$id)){
		
		cohortDefinition$ConceptSets <- map(cohortDefinition$ConceptSets, function(conceptSet){
			
			if(conceptSet$id != conceptSetId) return(conceptSet)
			
			conceptSet$expression$items <- c(conceptSet$expression$items, list(item))
			
			return(conceptSet)
			
		})
		
	}
	
	if(!conceptSetId %in% purrr::map_dbl(cohortDefinition$ConceptSets, ~.x$id)) cohortDefinition$ConceptSets <- c(cohortDefinition$ConceptSets, list(list(id = conceptSetId, expression = list(items = list(item)))))
	
	return(cohortDefinition)
	
}

#' Title Generate a cohort json from a simple user-made specification
#'
#' @param cohortName The name of the cohort to generate
#' @param ancestorConditionConceptsToInclude Ancestor condition_concept_ids to include patients based on
#' @param ancestorConditionConceptsToExclude Ancestor condition_concept_ids to exclude patients based on
#' @param conditionConceptsToInclude condition_concept_ids to include patients based on
#' @param conditionConceptsToExclude condition_concept_ids to exclude patients based on
#' @param gender The gender of patients to include
#' @param age The age condition to filter patients based on (for example list(Value = c(18, 30), Operator = 'bt'))
#' @param jsonTemplate The template cohort json to populate
#' @param save If true, the cohort json is saved. If false, it is returned as an R list
#'
#' @return An OHDSI JSON cohort definition, either saved or returned as a list
#' @export
#'
#' @examples
#' generateCohortJson("Test Cohort", ancestorConditionConceptsToInclude = 254761, jsonTemplate = "Template.json", save = T)
#' 
generateCohortJson <- function(cohortName, ancestorConditionConceptsToInclude = NULL, ancestorConditionConceptsToExclude = NULL, conditionConceptsToInclude = NULL, conditionConceptsToExclude = NULL, gender = NULL, age = NULL, jsonTemplate = "Template.json", save = T){
	
	jsonTemplate <- jsonlite::read_json(jsonTemplate)
	CriteriaList <- list()
	DemographicCriteriaList <- list()
	
	if(!identical(NULL, c(ancestorConditionConceptsToInclude, conditionConceptsToInclude))){
		
		conceptSetId <- max(c(0, map_dbl(jsonTemplate$ConceptSets, ~.x$id)+1))
		
		for(i in ancestorConditionConceptsToInclude) jsonTemplate <- addConceptToExpression(jsonTemplate, conceptSetId, i, TRUE)
		for(i in conditionConceptsToInclude) jsonTemplate <- addConceptToExpression(jsonTemplate, conceptSetId, i, FALSE)
		
		CriteriaList <- c(CriteriaList,
											list(list(
												Criteria = list(ConditionOccurrence = list(CodesetId = conceptSetId, ConditionTypeExclude = FALSE)),
												StartWindow = list(Start = list(Coeff = -1), End = list(Coeff = 1), UseIndexEnd = FALSE, UseEventEnd = FALSE),
												RestrictVisit = FALSE,
												IgnoreObservationPeriod = TRUE,
												Occurrence = list(Type = 2, Count = 1, IsDistinct = FALSE)
											)))
		
	}
	
	if(!identical(NULL, c(ancestorConditionConceptsToExclude, conditionConceptsToExclude))){
		
		conceptSetId <- max(c(0,map_dbl(jsonTemplate$ConceptSets, ~.x$id)+1))
		
		for(i in ancestorConditionConceptsToExclude) jsonTemplate <- addConceptToExpression(jsonTemplate, conceptSetId, i, TRUE)
		for(i in conditionConceptsToExclude) jsonTemplate <- addConceptToExpression(jsonTemplate, conceptSetId, i, FALSE)
		
		CriteriaList <- c(CriteriaList,
											list(list(
												Criteria = list(ConditionOccurrence = list(CodesetId = conceptSetId, ConditionTypeExclude = FALSE)),
												StartWindow = list(Start = list(Coeff = -1), End = list(Coeff = 1), UseIndexEnd = FALSE, UseEventEnd = FALSE),
												RestrictVisit = FALSE,
												IgnoreObservationPeriod = TRUE,
												Occurrence = list(Type = 0, Count = 0, IsDistinct = FALSE)
											)))
		
	}
	
	if(!identical(NULL, gender)){
		
		names(gender) = rep("CONCEPT_ID", length(gender))
		
		DemographicCriteriaList <- c(DemographicCriteriaList,
																 list(list(
																 	Gender = list(as.list(gender))
																 )))
	}
	
	if(!identical(NULL, age)){
		
		if(length(age$Value) == 1) age_element = list(Value = age$Value, Op = age$Operator)
		if(length(age$Value) == 2) age_element = list(Value = age$Value[1], Extent = age$Value[2], Op = age$Operator)
		
		
		DemographicCriteriaList <- c(DemographicCriteriaList,
																 list(Age = age_element))
	}
	
	InclusionRule <- list(name = "Inclusion rule 1", expression = list(Type = "ALL", CriteriaList = CriteriaList, DemographicCriteriaList = DemographicCriteriaList, Groups = list()))
	
	jsonTemplate$InclusionRules <- c(jsonTemplate$InclusionRules, list(InclusionRule))
	
	if(save){
		writeLines(RJSONIO::toJSON(jsonTemplate, pretty = T), stringr::str_c(cohortName, ".json"))
		message(str_c("Writing: ", stringr::str_c(cohortName, ".json")))
		jsonTemplate <- stringr::str_c(cohortName, ".json")
	}
	
	return(jsonTemplate)
	
}

# Parsing arguments
parseArgs    <- function(x) strsplit(sub("^--", "", x), "=")
argsL        <- as.list(as.character(as.data.frame(do.call("rbind", parseArgs(args)))$V2))
names(argsL) <- as.data.frame(do.call("rbind", parseArgs(args)))$V1
args         <- argsL
rm(argsL)

cohort_definitions_spec_input <- jsonlite::read_json(args$cohort_specs, simplifyVector = F)

map_chr(cohort_definitions_spec_input, ~do.call(generateCohortJson, c(.x, jsonTemplate = args$cohort_skeleton)))
