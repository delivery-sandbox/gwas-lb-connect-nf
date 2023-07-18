#!/usr/bin/env Rscript

####################################################################################################################################
# This script generates a phenofile for all cohorts in the cohort_table specified using the covariate_spec provided. 
####################################################################################################################################

######################
# Importing packages #
######################

suppressPackageStartupMessages({
  library(tidyverse)
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
    --phenofile_name          The name for the output phenofile
	  Optional arguments:
    --help          This help message.
    Usage:
    ./generatePhenofile.R --connection_details=connectionDetails.json --cohort_counts=cohort_counts.csv --cohort_table=cohort_table_name.txt --covariate_spec=covariate_spec.json
    \n")
  
  q(save="no")
}

# Parsing arguments
parseArgs    <- function(x) strsplit(sub("^--", "", x), "=")
argsL        <- as.list(as.character(as.data.frame(do.call("rbind", parseArgs(args)))$V2))
names(argsL) <- as.data.frame(do.call("rbind", parseArgs(args)))$V1
args         <- argsL
rm(argsL)

iid_col <- args$original_ids_column_name
replacement_col <- args$genotypic_ids_column_name 
pheno_label <- args$pheno_label

phenofile <- select(read_tsv(args$phenofile), -`#FID`)

if(iid_col == "false") iid_col <- colnames(read_csv(args$linkage))[1]
if(replacement_col == "false") linkage <- distinct(select(read_csv(args$linkage), IID = sym(iid_col), `#FID` = sym(iid_col), everything()))
if(replacement_col != "false") linkage <- distinct(select(read_csv(args$linkage), IID = sym(iid_col), `#FID` = sym(replacement_col), everything()))
    
phenofile <- left_join(phenofile, linkage) %>%
  mutate(IID = `#FID`) %>% 
  select(`#FID`, IID, everything()) %>%
  filter(!is.na(IID))

write_tsv(phenofile, str_c('linked_',tools::file_path_sans_ext(args$phenofile), ".phe"))

group_by(phenofile, !! sym(pheno_label)) %>%
  summarise(countSubjects = n()) %>%
  rename(cohortName = sym(pheno_label)) %>%
  mutate(cohortName = case_when(cohortName == 1 ~ str_c("controls_", pheno_label), cohortName == 2 ~ str_c("cases_", pheno_label),)) %>%
  select(cohortName, countSubjects) %>%
  write_csv("linked_cohort_counts.csv")