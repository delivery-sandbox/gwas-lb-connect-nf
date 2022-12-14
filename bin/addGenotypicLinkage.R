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

phenofile <- read_tsv(args$phenofile)
linkage <- distinct(select(read_delim(args$linkage), IID = sym(iid_col), sym(replacement_col)))

phenofile <- left_join(phenofile, linkage) %>%
  select(-`#FID`, -`IID`) %>% 
  rename(`#FID` = sym(replacement_col)) %>% 
  mutate(IID = `#FID`) %>% 
  select(`#FID`, IID, everything()) %>%
  filter(!is.na(IID))

write_tsv(phenofile, str_c(tools::file_path_sans_ext(args$phenofile), "_linked.phe"))