
# This script takes the additional sequences and splits the file into two to 
# be added to the COInr database

# Things to take into account:
# 1- the sequence file has no header
# 2- is a tab separated column
# 3- the order of the columns is mandatory and as follows
# [1] "seq_id"        "name_txt"      "tax_id"        "parent_tax_id" "rank"          "sequence" 


# disable scientific notation
options(scipen=999)

library("optparse")
library("stringi")

option_list = list(
  make_option(c("-s", "--sequence_input"), type="character", default=NULL, 
              metavar="character", help = paste("sequence tab file in NJORDR format.",
                                                "colnames: seq_id name_txt tax_id parent_tax_id parent_name_txt(optional) rank sequence")),
  make_option(c("-t", "--taxonomy_input"), type="character", default=NULL, 
              metavar="character", help = "taxonomy tab file with colnames [tax_id	parent_tax_id	rank	name_txt	old_tax_id	taxlevel	synonyms]"),
  make_option(c("-T", "--taxdump_output"), type="character", default=NULL,  
              metavar="character", help = "output taxdump"),
  make_option(c("-n", "--new_taxids"), type="numeric", default=1000000000, 
              metavar="character", help = paste("Number from which start the notation for new taxids.",
                                                "Since new taxids (not represented in NCBI) are set as negative,",
                                                "they must be turned into positive and to be sure they",
                                                "do not have the same number as an existing taxid,",
                                                "they will be higher than this value. However,",
                                                "the highest taxid cannot exced 2,147,483,647"))
); 

opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);

if (is.null(opt$sequence_input)){
  print_help(opt_parser)
  stop("input_file needed", call.=FALSE)
}
if (is.null(opt$taxonomy_input)){
  print_help(opt_parser)
  stop("input_file needed", call.=FALSE)
}

par_sequence_input <- opt$sequence_input
par_taxonomy_input <- opt$taxonomy_input
par_new_taxids <- opt$new_taxids
par_taxdump <- opt$taxdump_output

# par_sequence_input <- "~/Nextcloud/2_PROJECTES/NJORDR-MJOLNIR3/NJORDR_12S/NJORDR_format_completed.tsv"
# par_taxonomy_input <- "~/Nextcloud/2_PROJECTES/NJORDR-MJOLNIR3/COInr/taxonomy.tsv"
# par_taxdump <- "~/Nextcloud/2_PROJECTES/NJORDR-MJOLNIR3/NJORDR_12S/taxdump"
# par_new_taxids <- 1000000000

input_db <- read.table(par_sequence_input,header = T,quote = NULL,sep = '\t', fill = TRUE)

print(paste0("Loading data from ",par_taxonomy_input))
input_taxonomy <- read.csv(par_taxonomy_input, sep="\t",comment.char = '"')
print(paste0("Data from ",par_taxonomy_input," loaded"))

for (col in 1:dim(input_db)[2]) {
  if (sum(grepl('correct',input_db[,col]))) {
    warning("fields are still not corrected. Search manually for the 'correct' word and correct the fields manually.")
    stop()
  }
}

# change the taxids without numbers to negative from 100.000 (the lowest from COInr is about -35149)
starting_taxid <- -100001
taxids2modify <- input_db$tax_id[grep("taxid",input_db$tax_id)]
taxids2modify <- c(taxids2modify,input_db$parent_tax_id[grep("taxid",input_db$parent_tax_id)])
taxids2modify <- unique(taxids2modify)

for (i in taxids2modify) {
  input_db$tax_id[input_db$tax_id == i] <- starting_taxid
  input_db$parent_tax_id[input_db$parent_tax_id == i] <- starting_taxid
  starting_taxid <- starting_taxid - 1 
}

input_db$tax_id <- as.numeric(input_db$tax_id)
input_db$parent_tax_id <- as.numeric(input_db$parent_tax_id)

# remove sequences without taxid
input_db <- input_db[!is.na(input_db$tax_id),]
input_db <- input_db[!is.na(input_db$parent_tax_id),]

taxonomy <- data.frame(tax_id = as.numeric(input_db$tax_id),
                       parent_tax_id = as.numeric(input_db$parent_tax_id),
                       rank = input_db$rank,
                       name_txt = input_db$name_txt,
                       old_tax_id = NA,
                       taxlevel = NA,
                       synonyms = NA)

input_taxonomy <- rbind(input_taxonomy,taxonomy)

# remove duplicates
input_taxonomy <- input_taxonomy[!duplicated(input_taxonomy$tax_id),]

# convert negative taxids into positive taxids
print("turning taxids into positives")

# change the taxids from the sequences
negative_taxids <- input_db$tax_id<=0
input_db$tax_id[negative_taxids] <- abs(input_db$tax_id[negative_taxids]) + par_new_taxids

# taxids
negative_taxids <- input_taxonomy$tax_id<=0
input_taxonomy$tax_id[negative_taxids] <- abs(input_taxonomy$tax_id[negative_taxids]) + par_new_taxids
# parent_taxids
negative_taxids <- input_taxonomy$parent_tax_id<=0
input_taxonomy$parent_tax_id[negative_taxids] <- abs(input_taxonomy$parent_tax_id[negative_taxids]) + par_new_taxids

print("taxids turned into positives")

# create taxdump
print("creating taxdump")

# create directory
dir.create(par_taxdump)

# create merged.dmp
file.create(paste0(par_taxdump,"/merged.dmp"))
# create delnodes.dmp
file.create(paste0(par_taxdump,"/delnodes.dmp"))

# create nodes.dmp
nodes_dmp <- input_taxonomy[,c("tax_id","parent_tax_id","rank")]
nodes_dmp$embl_code <- ""
nodes_dmp$division_id <- 0
nodes_dmp$inherited_div_flag <- 0
nodes_dmp$genetic_code_id <- 0
nodes_dmp$inherited_GC_flag <- 0
nodes_dmp$mitochondrial_genetic_code_id <- 0
nodes_dmp$inherited_MGC_flag <- 0
nodes_dmp$GenBank_hidden_flag <- 0
nodes_dmp$hidden_subtree_root_flag <- 0
nodes_dmp$comments <- "\t|"
# remove duplicates
nodes_dmp <- nodes_dmp[!duplicated(nodes_dmp$tax_id),]
# sort the taxids
nodes_dmp <- nodes_dmp[order(nodes_dmp$tax_id),]
# join all fields
nodes_dmp <- paste(nodes_dmp$tax_id,
                   nodes_dmp$parent_tax_id,
                   nodes_dmp$rank,
                   nodes_dmp$embl_code,
                   nodes_dmp$division_id,
                   nodes_dmp$inherited_div_flag,
                   nodes_dmp$genetic_code_id,
                   nodes_dmp$inherited_GC_flag,
                   nodes_dmp$mitochondrial_genetic_code_id,
                   nodes_dmp$inherited_MGC_flag,
                   nodes_dmp$GenBank_hidden_flag,
                   nodes_dmp$hidden_subtree_root_flag,
                   nodes_dmp$comments, sep = '\t|\t')
# write ouput
writeLines(nodes_dmp, paste(par_taxdump,"nodes.dmp",sep="/"))
rm(nodes_dmp)

# create names.dmp
names_dmp <- input_taxonomy[,c("tax_id","name_txt")]
names_dmp$name_txt <- stri_trans_general(str = names_dmp$name_txt, id = "Latin-ASCII")
# remove duplicates
names_dmp <- names_dmp[!duplicated(names_dmp$tax_id),]
# sort the taxids
names_dmp <- names_dmp[order(names_dmp$tax_id),]
names_dmp$unique_names <- ""
names_dmp$name_class <- "scientific name\t|"
# join all fields
names_dmp <- paste(names_dmp$tax_id,names_dmp$name_txt,names_dmp$unique_names,names_dmp$name_class, sep = '\t|\t')
# write ouput
writeLines(names_dmp, paste(par_taxdump,"names.dmp",sep="/"))
rm(names_dmp)

print("taxdump created")

input_db <- input_db[,c("seq_id","tax_id","sequence")]

# remove duplicated sequence id
input_db <- input_db[!duplicated(input_db$seq_id),]

directory <- dirname(normalizePath(par_sequence_input))

write.table(input_db, paste0(directory,"/NJORDR_sequences.tsv"),row.names = F,col.names = F,quote = F,sep = "\t")
