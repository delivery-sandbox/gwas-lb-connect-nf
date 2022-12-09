#! /usr/bin/env Rscript

## adapted from king_ancestryplot.R for KING Ancestry plot by Zhennan Zhu and Wei-Min Chen

args <- commandArgs(TRUE)

if("--help" %in% args | "help" %in% args | (length(args) == 0) | (length(args) == 1) ) {
  cat("
      The helper R Script pca_plots.R
      Mandatory arguments:
        --pc_file=path               - Path to King PC file.
        --ref_id_file=path           - Path to file containing IDs of reference samples.
        --help                       - you are reading it
      Optional arguments:
        --eigenval_file=path         - Path to eigenvalue file. If provided will generate a scree plot.
        --cpus=int                   - Number of cpus to use. Default: 2
        --prefix=str                 - Output filename prefix.
      Usage:
        The typical command for running the script is as follows:
        ./Ancestry_Inference.R --pc_file=kingpc.txt --ref_id_file=king_popref.txt --cpus=4
      \n")
  
  q(save="no")
}

## Parse arguments (we expect the form --arg=value)
parseArgs    <- function(x) strsplit(sub("^--", "", x), "=")

argsL        <- as.list(as.character(as.data.frame(do.call("rbind", parseArgs(args)))$V2))
names(argsL) <- as.data.frame(do.call("rbind", parseArgs(args)))$V1
args         <- argsL
rm(argsL)

if(is.null(args$cpus)) {args$cpus <- 2} else {args$cpus <- as.numeric(args$cpus)}
if(is.null(args$prefix)) {args$prefix <- "king"}

# Load packages

suppressPackageStartupMessages({
  library(e1071)
  library(doParallel)
  library(ggplot2)
  library(dplyr)
  library(cowplot)
})

# Load input files
print(paste("Prepare the PC file and the reference file, starts at ", date()))
pc <- read.table(args$pc_file, header = TRUE)
phe <- read.table(args$ref_id_file, header = TRUE)
pop <- phe[, c("IID", "Population")]

# split data into ref individuals and test sample individuals
train.data <- pc[pc$AFF == 1, grep("IID|PC", colnames(pc))]
train.phe <- merge(train.data, pop, by = "IID")
train.x <- train.phe[, !colnames(train.phe) %in% c("Population", "IID")]
train.y <- train.phe[, "Population"]

test.data <- pc[pc$AFF == 2, grep("FID|IID|PC", colnames(pc))]


# carry out SVM-based modelling and predictions

if (require("doParallel", quietly = TRUE) && args$cpus > 2) {
  numCores <- detectCores()
  registerDoParallel(cores = min(round(numCores/2), 41))
  tuneresults <- function(cost) {
    tuneresult <- foreach(cost = cost, .combine = c) %dopar% {
      set.seed(123)
      mod = tune(svm, train.x, as.factor(train.y), kernel = "linear", cost = cost, 
                 probability = TRUE)
      mod$performances[, c("error")]
    }
    best.cost <- cost[which.min(tuneresult)]
    return(best.cost)
  }
} else {
  numCores <- 2
  tuneresults <- function(cost){
    set.seed(123) 
    tune.mod <- tune(svm, train.x, as.factor(train.y), kernel = "linear", ranges=(list(cost=cost)), 
                     probability = TRUE)
    return(tune.mod$best.parameters[1,1])
  }
}

print(paste0("Assign ", min(round(numCores/2), 41), " cores for the grid search."))
print(paste("Grid search with a wide range, starts at", date()))
best.cost <- tuneresults(2^(seq(-10, 10, by = 0.5)))
print(paste("Grid search with a wide range, ends at", date()))
print(paste0("The best cost is ", round(best.cost, 6), " after the wide grid search"))
print(paste("Grid search with a small range, starts at", date()))
more.cost <- 2^seq(log2(best.cost) - 0.5, log2(best.cost) + 0.5, by = 0.05)
best.cost <- tuneresults(more.cost)
print(paste("Grid search with a small range, ends at", date()))
print(paste0("The best cost is ", round(best.cost, 6), " after the small grid search"))
set.seed(123)
mymod <- svm(train.x, as.factor(train.y), cost = best.cost, kernel = "linear", probability = TRUE)
print(paste("Predict ancestry information, start at", date()))
pred.pop <- predict(mymod, test.data[, !colnames(test.data) %in% c("FID", "IID")], probability = TRUE)
class.prob <- attr(pred.pop, "probabilities")

# create output table
print(paste("Prepare the summary file, starts at", date()))
orders <- t(apply(class.prob, 1, function(x) order(x, decreasing = T)))
orders.class <- t(apply(orders, 1, function(x) colnames(class.prob)[x]))
orders.probs <- t(sapply(1:nrow(class.prob), function(x) class.prob[x, orders[x, ]]))
check.cumsum <- t(apply(orders.probs, 1, cumsum))
temp <- apply(check.cumsum, 1, function(x) which(x > 0)[1])
pred.class <- sapply(1:length(temp), function(x) paste(orders.class[x, 1:as.numeric(temp[x])], collapse = ";"))
pred.prob <- sapply(1:length(temp), function(x) paste(round(orders.probs[x, 1:as.numeric(temp[x])], 3), collapse = ";"))
pred.out <- cbind(test.data[, c("FID", "IID", "PC1", "PC2")], pred.class, pred.prob, 
                  orders.class[, 1], orders.class[, 2], round(orders.probs[, 1], 3), round(orders.probs[, 2],3))
colnames(pred.out)[5:10] <- c("Ancestry", "Pr_Anc", "Anc_1st", "Anc_2nd", "Pr_1st", "Pr_2nd")

write.table(pred.out, paste0(args$prefix, "_InferredAncestry.tsv"), sep="\t", quote=F, row.names=F)
print(paste("summary file is ready ", date()))

# Count how many people from each population are observed in the sample
pred.out %>% count(Ancestry,sort = TRUE)  -> count_per_population
print("Population count per ancestry in the sample")
print(count_per_population)
write.table(count_per_population, file=paste0(args$prefix, "_counts.tsv"), sep="\t", quote=F, row.names=F)

# Generating separate tables for each ancestry
list_of_dataframes <- split( pred.out, f = pred.out$Ancestry )

# Writing each file seperately
for (i in 1:length(list_of_dataframes)) {
  ancestry_label <- unique(list_of_dataframes[[i]][["Ancestry"]])
  ancestry_count <- count_per_population[ (count_per_population$Ancestry == ancestry_label), ] [["n"]]
  filename <- paste0(args$prefix, "_", ancestry_label, "_", ancestry_count, "_InferredAncestry.tsv")
  write.table(list_of_dataframes[[i]], file=filename, sep="\t", quote=F, row.names=F)
}
print(paste("Results are saved to", paste0(args$prefix, "_InferredAncestry.tsv")))


print("Generate plots")
plot.df <- rbind(cbind(test.data, Population=orders.class[, 1], Population.prob=orders.probs[, 1], ref=F),
                 cbind(FID=train.phe$IID, train.phe, Population.prob=1.0, ref=T))

# PCA plot
plots <- list()
pc.names <- colnames(plot.df)[grep("PC", colnames(plot.df))]
for (pc.pair in split(pc.names, ceiling(seq_along(pc.names)/2))){
  p <- ggplot(plot.df, aes_string(pc.pair[[1]], pc.pair[[2]], col="Population", shape="ref")) + 
    geom_point(aes(alpha=ref, size=ref)) +
    scale_shape_manual(values = c(4,16), labels = c("Samples", "Reference"), name = "Dataset") + 
    scale_alpha_manual(values = c(0.7,0.2), labels = c("Samples", "Reference"), name = "Dataset") +
    scale_size_manual(values = c(1,0.4), labels = c("Samples", "Reference"), name = "Dataset") +
    theme_minimal() +
    theme(legend.box = "horizontal",
          axis.text.y = element_text(angle=90, hjust=0.5))
  plots <- c(plots, list(p))
}
legend <- get_legend(plots[[1]])
plots <- c(lapply(plots, function(p){return(p + theme(legend.position="none"))}), list(legend))

title <- ggdraw() + 
  draw_label("Inferred Populations PCA", fontface = 'bold', x = 0.5, hjust = 0.5) +
  theme(plot.margin = margin(0, 0, 0, 7))

png(filename=paste0(args$prefix, "_ancestry_pca.png"), width = 10, height = 6, units = 'in', pointsize=12, res = 300)
plot_grid(title, plot_grid(plotlist = plots), 
          ncol=1, rel_heights=c(0.1, 1))
dev.off()


# Scree plot
if (!is.null(args$eigenval_file)){
  eigenvals <- scan(args$eigenval_file)
  pve <- data.frame(PC=factor(pc.names, levels=pc.names), pve = eigenvals/sum(eigenvals))
  p <- ggplot(pve, aes(PC, pve)) +
    geom_col(fill = "#56B4E9", alpha = 0.8) +
    scale_y_continuous(labels = scales::percent_format(scale = 100, accuracy = 1)) +
    theme_minimal_hgrid(12) +
    ylab("percent variance explained") +
    ggtitle("PCA Scree Plot")
  
  png(filename=paste0(args$prefix, "_ancestry_scree.png"), width = 4, height = 4, units = 'in', pointsize=1, res = 300)
  print(p)
  dev.off()
}
