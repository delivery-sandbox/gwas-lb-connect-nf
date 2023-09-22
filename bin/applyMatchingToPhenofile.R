#!/usr/bin/env Rscript

################################################################################################################
# This script applies matching to match the cases to a specified number of controls
################################################################################################################

######################
# Importing packages #
######################

suppressPackageStartupMessages({
	library(tidyverse)
})

options(scipen = 99999)

# Collecting arguments
args <- commandArgs(TRUE)
args

# Default setting when not all arguments passed or help is needed
if("--help" %in% args | "help" %in% args | (length(args) == 0) ) {

	cat("
	This script applies matching to match the cases to a specified number of controls
    
	Mandatory arguments:
    --phenofile
    --pheno_label
    --max_controls_to_match
    --match_age_tolerance
	
	Optional arguments:
    --help          This help message.

    Usage:
    applyMatchingToPhenofile.R --codelist=P000001.csv
    \n")

	q(save="no")
}

# Parsing arguments
parseArgs    <- function(x) strsplit(sub("^--", "", x), "=")
argsL        <- as.list(as.character(as.data.frame(do.call("rbind", parseArgs(args)))$V2))
names(argsL) <- as.data.frame(do.call("rbind", parseArgs(args)))$V1
args         <- argsL
rm(argsL)

set.seed(12345)

phenofile <- read_tsv(args$phenofile) %>%
  arrange(runif(nrow({.})))

pheno_label <- args$pheno_label
controls_to_match <- as.integer(args$controls_to_match)
min_controls_to_match <- as.integer(args$min_controls_to_match)
match_age_tolerance <- as.integer(args$match_age_tolerance)
match_sex <- as.logical(args$match_on_age)
match_age <- as.logical(args$match_on_sex)

if(! match_age){ phenofile$MATCH_AGE <- -1 }else{ phenofile$MATCH_AGE <- phenofile$AGE }

if(! match_sex){ phenofile$MATCH_SEX <- 'U'}else{ phenofile$MATCH_SEX <- phenofile$SEX }

mutate(phenofile, group = if_else(!! sym(pheno_label) == 2, "case", "control")) %>% 
  mutate(index=0) %>% 
  split(.$group) %>%
  list2env(envir = .GlobalEnv)

for(i in seq_len(nrow(case))){
  x <- which(between(control$MATCH_AGE, case$MATCH_AGE[i] - match_age_tolerance, case$MATCH_AGE[i] + match_age_tolerance) & 
               control$MATCH_SEX == case$MATCH_SEX[i] & 
               control$index == 0)
  if(length(x) >= min_controls_to_match){
    case$index[i] <- i 
    control$index[sample(x, min(controls_to_match, length(x)))] <- i
  }
  if(length(x) < min_controls_to_match) case$index[i] <- 0
  
}

phenofile <- rbind(case, control) %>% filter(index > 0) %>%  arrange(index) %>% select(-any_of(c("group", "index", "MATCH_SEX", "MATCH_AGE")))

write_tsv(phenofile, str_c("matched_",args$phenofile))

group_by(phenofile, !! sym(pheno_label)) %>%
  summarise(countSubjects = n()) %>%
  rename(cohortName = sym(pheno_label)) %>%
  mutate(cohortName = case_when(cohortName == 1 ~ str_c("controls_", pheno_label), cohortName == 2 ~ str_c("cases_", pheno_label),)) %>%
  select(cohortName, countSubjects) %>%
  write_csv("matched_cohort_counts.csv")