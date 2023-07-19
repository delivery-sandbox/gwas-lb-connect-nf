#!/usr/bin/env Rscript

################################################################################################################
# This script generates simple cohort_specs from a codelist.
################################################################################################################

######################
# Importing packages #
######################

suppressPackageStartupMessages({
	library(tidyverse)
	library(jsonlite)
	library(Capr)
})

options(scipen = 99999)

# Collecting arguments
args <- commandArgs(TRUE)
args

# Default setting when not all arguments passed or help is needed
if("--help" %in% args | "help" %in% args | (length(args) == 0) ) {

	cat("
	This script generates OHDSI JSON cohort definitions based on the codelist provided
    
	Mandatory arguments:
    --codelist
    --connection_details
	
	Optional arguments:
    --help          This help message.

    Usage:
    generateCohortJsonFromCodelist.R --codelist=P000001.csv
    \n")

	q(save="no")
}

# Parsing arguments
parseArgs    <- function(x) strsplit(sub("^--", "", x), "=")
argsL        <- as.list(as.character(as.data.frame(do.call("rbind", parseArgs(args)))$V2))
names(argsL) <- as.data.frame(do.call("rbind", parseArgs(args)))$V1
args         <- argsL
rm(argsL)

########################################################################
### Create exclusion events using exclusion concepts
########################################################################
write_cohort_json <- function(all_inclusion_codes, all_exclusion_codes, cohort_name, limit = "First", include_descendants){
  
  null_codeset <- getConceptIdDetails(conceptIds = 0, connection = connection, vocabularyDatabaseSchema = vocabularyDatabaseSchema, mapToStandard = F)  %>%
    createConceptSetExpression(Name = "Null Codeset", includeDescendants = include_descendants)
  
  index_components <- list()
  
  iwalk(all_inclusion_codes, function(index_codes, domain_id){
    domain <- case_when(domain_id == "Condition" ~ "ConditionOccurrence", domain_id == "Drug" ~ "DrugExposure", domain_id == "Procedure" ~ "ProcedureOccurrence", domain_id == "Observation" ~ "Observation", TRUE ~ "Observation")
    attribute_list <- list()
    if(nrow(index_codes) > 0){
      index_codeset <- createConceptSetExpression(conceptSet = index_codes, Name = str_c("Index ",domain_id), includeDescendants = include_descendants)
      index_components <<- append(index_components, Capr:::createQuery(Component = index_codeset, Domain = domain, attributeList = list()))
      attribute_list[[1]] <- createSourceConceptAttribute(Domain = domain, ConceptSetExpression = index_codeset)
    }
    index_components <<- append(index_components, Capr:::createQuery(Component = null_codeset, Domain = domain, attributeList = attribute_list)) 
  }) 
  
  primary <- createPrimaryCriteria(Name = "Primary Criteria", ComponentList = index_components, ObservationWindow = createObservationWindow(0L,0L), Limit =  limit)
  additional <- createAdditionalCriteria(Name = "Limiter", Limit = limit)
  
  ### Create exclusion events using exclusion concepts
  exclusion_rules <- list()
  iwalk(all_exclusion_codes, function(exclusion_codes, domain_id){  
    domain <- case_when(domain_id == "Condition" ~ "ConditionOccurrence", domain_id == "Drug" ~ "DrugExposure", domain_id == "Procedure" ~ "ProcedureOccurrence", domain_id == "Observation" ~ "Observation", TRUE ~ "Observation")
    timeline <- createTimeline(StartWindow = createWindow(StartDays = "All", StartCoeff = "Before", EndDays = "All", EndCoeff = "After"))
    attribute_list <- list()
    if(nrow(exclusion_codes) > 0){
        exclusion_codeset <- createConceptSetExpression(exclusion_codes, Name = str_c("Exclusion ",domain_id), includeDescendants = include_descendants)
        exclusion_components <- Capr:::createQuery(Component = exclusion_codeset, Domain = domain, attributeList = attribute_list)
        exclusion_rules <<- append(exclusion_rules, createCount(Query = exclusion_components, Logic = "exactly", Count = 0, Timeline = timeline))
        attribute_list[[1]] <- createSourceConceptAttribute(domain, exclusion_codeset)
    }
    exclusion_components <- Capr:::createQuery(Component = null_codeset, Domain = domain, attributeList = attribute_list)
    exclusion_rules <<- append(exclusion_rules, createCount(Query = exclusion_components, Logic = "exactly", Count = 0, Timeline = timeline))
  })
  
  endStrategy <- createDateOffsetEndStrategy(0, eventDateOffset = "StartDate")
  
  if(length(exclusion_rules) > 0){
    exclusion_rules_group <- list(createGroup(Name = str_c("Exclusions"), type = "ALL", criteriaList = exclusion_rules, demographicCriteriaList = NULL, Groups = NULL))
    cd <- createCohortDefinition(Name = "My cohort", Description = "My cohort", PrimaryCriteria = primary, AdditionalCriteria = additional, InclusionRules = createInclusionRules(Name = "Inclusion Rules", Contents = exclusion_rules_group, Limit = limit), EndStrategy = endStrategy)
  }  
  
  if(length(exclusion_rules) == 0) cd <- createCohortDefinition(Name = "My cohort", Description = "My cohort", PrimaryCriteria = primary, AdditionalCriteria = additional, EndStrategy = endStrategy)
  
  jsonlite::fromJSON(Capr::compileCohortDefinition(cd), simplifyVector = F) %>%
    fix_package_issues %>%
    jsonlite::write_json(stringr::str_c(cohort_name, ".json"), auto_unbox = T, pretty = T)
  
}

fix_package_issues <- function(cohort_json){
  null_cs_ids <- unique(map_int(cohort_json$ConceptSets, function(cs) if(cs$name == "Null Codeset"){ return(as.integer(cs$id)) }else{ return(as.integer(-1)) }))
  removeCodeSetId <- function(cohortDefinition, null_cs_ids){
    if(class(cohortDefinition) != "list") return(cohortDefinition)
    if("ConditionOccurrenceSourceConcept" %in% names(cohortDefinition)) names(cohortDefinition)[names(cohortDefinition) == "ConditionOccurrenceSourceConcept"] <- "ConditionSourceConcept"
    if("DrugExposureSourceConcept" %in% names(cohortDefinition)) names(cohortDefinition)[names(cohortDefinition) == "DrugExposureSourceConcept"] <- "DrugSourceConcept"
    if("CodesetId" %in% names(cohortDefinition))
      if(cohortDefinition[["CodesetId"]] %in% null_cs_ids) cohortDefinition[["CodesetId"]] <- NULL
    map(cohortDefinition, removeCodeSetId, null_cs_ids)
  }
  cohort_json <- removeCodeSetId(cohort_json, null_cs_ids)
  codesets_to_remove <- which(map_lgl(cohort_json$ConceptSets, ~.x$name == "Null Codeset"))
  if(length(codesets_to_remove) > 0) cohort_json$ConceptSets[codesets_to_remove] <- NULL
  return(cohort_json)
}
########################################################################

# Generate Codelist dataframe
codes_to_include <- unlist(strsplit(args$codes_to_include, ","))
codes_to_exclude <- unlist(strsplit(args$codes_to_exclude, ","))
codes_vocabulary <- args$codes_vocabulary
pheno_label <- args$pheno_label
codelist <- data.frame(Phenotype_Short = pheno_label,
                       Criteria_Ontology = codes_vocabulary,
                       Criteria = c(codes_to_include, codes_to_exclude),
                       Is_Inclusion_Criteria = c(rep("TRUE", length(codes_to_include)),
                                                 rep("FALSE", length(codes_to_exclude))),
                       Is_Exclusion_Criteria = c(rep("FALSE", length(codes_to_include)),
                                                 rep("TRUE", length(codes_to_exclude)))
                      )
codelist <- as.tibble(data.frame(lapply(codelist, as.character), stringsAsFactors=FALSE))
                       

connectionDetailsFull <- jsonlite::read_json(args$connection_details)
vocabularyDatabaseSchema <- connectionDetailsFull$cdmDatabaseSchema
include_descendants = as.logical(args$include_descendants)

## Database Connection Jars
Sys.setenv(DATABASECONNECTOR_JAR_FOLDER = getwd())
unzip(args$db_jars)

## Database Connection
connectionDetails <- discard(connectionDetailsFull, names(connectionDetailsFull) %in% c('cohortDatabaseSchema', 'cdmDatabaseSchema'))
connectionDetails <- exec(DatabaseConnector::createConnectionDetails, !!! connectionDetails)
connection <- connect(connectionDetails)

input_file <- codelist  %>%
  select(Phenotype_Short, Criteria_Ontology, Criteria, Is_Inclusion_Criteria, Is_Exclusion_Criteria) %>%
  mutate(across(c(Is_Inclusion_Criteria, Is_Exclusion_Criteria), as.logical))

input_file_split <- input_file %>%
  split(.$Criteria_Ontology)

### add this workaround to take concepts from both ICD10 and ICD10CM which are both used in OMOP
input_file_split$ICD10CM <- input_file_split$ICD10

cohort_definition_codes <- map2_df(input_file_split, names(input_file_split), ~ mutate(getConceptCodeDetails(conceptCode = .x$Criteria, vocabulary = .y, connection = connection, vocabularyDatabaseSchema = vocabularyDatabaseSchema, mapToStandard = FALSE), Criteria_Ontology = unique(.x$Criteria_Ontology))) %>%
  select(Criteria_Ontology, Criteria = conceptCode, conceptId) %>%
  mutate(across(everything(), as.character)) %>%
  left_join(input_file)

if(n_distinct(cohort_definition_codes$Phenotype_Short) > 1) stop("Only one phenotype per run support in this version")

inclusion_concept_ids <- as.integer(cohort_definition_codes$conceptId[cohort_definition_codes$Is_Inclusion_Criteria])
exclusion_concept_ids <- as.integer(cohort_definition_codes$conceptId[cohort_definition_codes$Is_Exclusion_Criteria])

all_inclusion_codes <- getConceptIdDetails(conceptIds = inclusion_concept_ids, connection = connection, vocabularyDatabaseSchema = vocabularyDatabaseSchema, mapToStandard = F) %>%
  split(.$domainId)

if(length(exclusion_concept_ids) == 0) all_exclusion_codes <- list()
if(length(exclusion_concept_ids) > 0)  all_exclusion_codes <- getConceptIdDetails(conceptIds = exclusion_concept_ids, connection = connection, vocabularyDatabaseSchema = vocabularyDatabaseSchema, mapToStandard = F) %>% split(.$domainId)

write_cohort_json(all_inclusion_codes, all_exclusion_codes, str_c("cases_",input_file$Phenotype_Short[1]), include_descendants = include_descendants)

domains_for_control <- map(all_inclusion_codes, ~slice(.x, 0))

write_cohort_json(domains_for_control, all_inclusion_codes, str_c("controls_",input_file$Phenotype_Short[1]), include_descendants = include_descendants)
