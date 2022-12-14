#!/usr/bin/env Rscript

####################################################################################################################################
# This script 
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