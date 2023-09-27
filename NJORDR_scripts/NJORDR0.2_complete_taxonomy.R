# this script is made to reduce the database. The intention is to delete sequences
# that are duplicated but that have the same tax_id. There can be sequences that 
# exactly the same but with different tax_id's and those don't have to be merged
# also this process has to be done after the trimming so two sequences with the 
# same tax_id can be different for a larger fragment and identical for a shorter.

print("Starting NJORDR0.2_complete_taxoomy.R")
options(scipen=999)

library("optparse")
library("dplyr")
library("stringi")

option_list = list(
  make_option(c("-t", "--taxonomy_input"), type="character", default=NULL,
              metavar="character", help = "taxonomy tab file with colnames [tax_id	parent_tax_id	rank	name_txt	old_tax_id	taxlevel	synonyms]"),
  make_option(c("-i", "--sequence_input"), type="character", default=NULL,
              metavar="character", help = "name of the input file for the sequences in tsv format to be completed"),
  make_option(c("-r", "--rds_input_format"), action="store_true", default=F, 
              help = paste("Input file in rds format.")),
  make_option(c("-R", "--rds_output_format"), action="store_true", default=F, 
              help = paste("Output file in rds format.")),
  make_option(c("-c", "--cores"), type="numeric", default=1,
              metavar="character", help = "number or cores to run the process in parallel. 1 default"),
  make_option(c("-o", "--sequence_output"), type="character", default=NULL,
              metavar="character", help = "name of the output file for the sequences in tsv format")
);

opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);
par_taxonomy_input <- opt$taxonomy_input
par_sequence_input <- opt$sequence_input
par_cores <- opt$cores
par_sequence_output <- opt$sequence_output

# par_taxonomy_input <- "~/Nextcloud/2_PROJECTES/NJORDR-MJOLNIR3/NJORDR_COI/TAXONOMY_TREE/taxonomy.tsv"
# par_sequence_input <- "~/Nextcloud/2_PROJECTES/NJORDR-MJOLNIR3/NJORDR_COI/NJORDR0.1_output/NJORDR0.1_sequences.rds"
# par_cores <- 1
# opt <- c()
# opt$rds_input_format <- T
# par_sequence_output <- "~/Nextcloud/2_PROJECTES/NJORDR-MJOLNIR3/NJORDR_COI/COMPLETE_DB/NJORDR_format_completed.tsv"


if (is.null(par_taxonomy_input)){
  print_help(opt_parser)
  stop("taxonomy input file needed", call.=FALSE)
}
if (is.null(par_sequence_input)){
  print_help(opt_parser)
  stop("Sequences input file name needed", call.=FALSE)
}
if (is.null(par_sequence_output)){
  print_help(opt_parser)
  stop("Sequences output file name needed", call.=FALSE)
}

print(paste0("Loading data from ",par_taxonomy_input))
input_taxonomy <- read.csv(par_taxonomy_input, sep="\t",comment.char = '"')
print(paste0("Data from ",par_taxonomy_input," loaded"))

print(paste0("Loading data from ",par_sequence_input))
if (opt$rds_input_format) {
  input_db <- readRDS(par_sequence_input)
} else {
  input_db <- read.csv(par_sequence_input, sep = "\t")
}

input_db$tax_id <- as.numeric(input_db$tax_id)

input_db_taxid <- input_db[!is.na(input_db$tax_id),]
input_db <- input_db[is.na(input_db$tax_id),]
input_db$name_txt <- gsub("_"," ",input_db$name_txt, fixed = T)

complete_from_taxid <- function(tax_id, input_db_taxid = input_db_taxid, input_taxonomy = input_taxonomy) {
  # for (tax_id in unique(input_db_taxid$tax_id)) {
  # tax_id = unique(input_db_taxid$tax_id)[1]
  # tax_id=-10000003
  
  lines <- input_db_taxid[which(tax_id == input_db_taxid$tax_id),]

  # check if the tax_id is updated
  if (!(tax_id %in% input_taxonomy$tax_id) & (tax_id %in% input_taxonomy$old_tax_id)) {
    tax_id <- input_taxonomy$tax_id[tax_id == input_taxonomy$old_tax_id]
  } else if (!(tax_id %in% input_taxonomy$tax_id) & !(tax_id %in% input_taxonomy$old_tax_id)){
    tax_id <- paste0(tax_id,"_correct_manually")
    lines$tax_id <- tax_id
  }
  if (is.numeric(tax_id)) {
    lines$name_txt <- input_taxonomy$name_txt[tax_id == input_taxonomy$tax_id][1]
    lines$parent_tax_id <- input_taxonomy$parent_tax_id[tax_id == input_taxonomy$tax_id][1]
    lines$rank <- input_taxonomy$rank[tax_id == input_taxonomy$tax_id][1]
  } 
  
  # print(lines)
  return(lines)
}

input_db_taxid <- parallel::mclapply(X = unique(input_db_taxid$tax_id), FUN = complete_from_taxid, input_db_taxid = input_db_taxid, input_taxonomy = input_taxonomy, mc.cores = par_cores)

save.image('After_complete_from_taxid.RData')
input_db_taxid <- do.call(rbind, input_db_taxid)

input_db <- rbind(input_db,input_db_taxid[grepl("correct_manually",input_db_taxid$tax_id),])
input_db_taxid <- input_db_taxid[!grepl("correct_manually",input_db_taxid$tax_id),]

# remove sequences that have no name_txt. at this point, those sequences that 
# don't have it, can't be assigned to any taxa thus the tax_id has been found as
# incorrect if the sequence is still in input_db
input_db <- input_db[!is.na(input_db$name_txt),]

save.image('Before_complete_name.RData')

complete_from_name <- function(name_txt, input_db = input_db, input_taxonomy = input_taxonomy) {
  # for (name_txt in unique(input_db$name_txt)) {
  # name_txt <- unique(input_db$name_txt)[1]
  lines <- input_db[which(name_txt == input_db$name_txt),]
  if (name_txt %in% input_taxonomy$name_txt) { 
    # the name is in the taxonomy as it is
    position <- which(input_taxonomy$name_txt %in% name_txt)[1]
    lines$tax_id <- input_taxonomy$tax_id[position]
    lines$parent_tax_id <- input_taxonomy$parent_tax_id[position]
    lines$rank <- input_taxonomy$rank[position]
  } else if (name_txt %in% input_taxonomy$synonyms) {
    # the name is in the taxonomy but as a synonym
    position <- which(input_taxonomy$synonyms %in% name_txt)[1]
    lines$tax_id <- input_taxonomy$tax_id[position]
    lines$parent_tax_id <- input_taxonomy$parent_tax_id[position]
    lines$rank <- input_taxonomy$rank[position]
  } else {
    # break
    # the name is not in the taxonomy database
    # search for higher ranks
    species_name <- strsplit(name_txt," ")[[1]]
    if (sum(!is.na(lines$parent_name_txt))>0){
      # there is information of the parents
      # now take the largest
      taxa_complete <- lines$parent_name_txt[!is.na(lines$parent_name_txt)]
      taxa_complete <- taxa_complete[stri_length(taxa_complete) == max(stri_length(taxa_complete))]
      taxa_complete <- taxa_complete[1]
      taxa_complete <- strsplit(taxa_complete,";")[[1]]
    } else {
      taxa_complete <- c()
    }
    taxa_complete <- unique(c(taxa_complete, species_name[1]))
    new_taxa_name_txt <- c()
    new_taxa_tax_id <- c()
    new_taxa_rank <- c()
    tax_id_found <- F
    for (i in length(taxa_complete):1) {
      # do a loop for as many times as the max number of names that parent_name_txt 
      # until a parent tax_id is found
      taxa <- taxa_complete[i]
      if (i == length(taxa_complete)) {
        lines$tax_id <- paste0("taxid_",name_txt)
      }
      if (taxa %in% input_taxonomy$name_txt) { 
        # the name is in the taxonomy as it is
        position <- which(input_taxonomy$name_txt %in% taxa)[1]
        new_taxa_name_txt <- c(new_taxa_name_txt,input_taxonomy$name_txt[position])
        new_taxa_tax_id <- c(new_taxa_tax_id,input_taxonomy$tax_id[position])
        new_taxa_rank <- c(new_taxa_rank,input_taxonomy$rank[position])
        tax_id_found <- T
      } else if (taxa %in% input_taxonomy$synonyms) {
        # the name is in the taxonomy but as a synonym
        position <- which(input_taxonomy$synonyms %in% taxa)[1]
        new_taxa_name_txt <- c(new_taxa_name_txt,input_taxonomy$name_txt[position])
        new_taxa_tax_id <- c(new_taxa_tax_id,input_taxonomy$tax_id[position])
        new_taxa_rank <- c(new_taxa_rank,input_taxonomy$rank[position])
        tax_id_found <- T
      } else {
        new_taxa_name_txt <- c(new_taxa_name_txt,taxa)
        new_taxa_tax_id <- c(new_taxa_tax_id,paste0("taxid_",taxa))
        new_taxa_rank <- c(new_taxa_rank,'correct_manually')
      }
      if (tax_id_found) {
        new_taxa <- data.frame("seq_id"=NA,
                               "name_txt"=new_taxa_name_txt,
                               "tax_id"=new_taxa_tax_id,
                               "parent_tax_id"=c(new_taxa_tax_id[-1],NA),
                               "parent_name_txt"=NA,
                               "rank"=new_taxa_rank,
                               "sequence"= NA)
        new_taxa <- new_taxa[-dim(new_taxa)[1],]
        lines$parent_tax_id <- new_taxa_tax_id[1]
        lines <- rbind(lines,new_taxa)
        break
      } else if (i == 1) {
        new_taxa_tax_id <- paste0("correct_mannually_",new_taxa_tax_id)
        new_taxa <- data.frame("seq_id"=NA,
                               "name_txt"=new_taxa_name_txt,
                               "tax_id"=new_taxa_tax_id,
                               "parent_tax_id"=c(new_taxa_tax_id[-1],"correct_mannually_parent_tax_id"),
                               "parent_name_txt"=NA,
                               "rank"=new_taxa_rank,
                               "sequence"= NA)
        lines$parent_tax_id <- new_taxa_tax_id[1]
        lines <- rbind(lines,new_taxa)
      }
    }
    
  }
  # print(lines)
  return(lines)
}

#####
#####
input_db <- parallel::mclapply(X = unique(input_db$name_txt), FUN = complete_from_name, input_db = input_db, input_taxonomy = input_taxonomy, mc.cores = par_cores)
input_db <- do.call(rbind,input_db)
save.image('AFTER_complete_name.RData')

input_db <- rbind(input_db,input_db_taxid)

# by now if a rank is in correct_manually I will fix it as no rank
input_db$rank[grepl('correct_manually',input_db$rank)] <- 'no rank'

for_correction <- F
for (col in 1:dim(input_db)[2]) {
  to_correct <- input_db[grepl('correct_manually',input_db[,col]),]
  input_db <- rbind(to_correct, input_db[!grepl('correct_manually',input_db[,col]),])
  if (dim(to_correct)[1]>0) {
    for_correction <- T
  }
}
if (for_correction) {
  par_sequence_output <- sub(".[tc]sv","_to_correct.tsv",par_sequence_output)
}
write.table(input_db,file = par_sequence_output,quote = F,row.names = F,sep = "\t")
message("Please, check manually te word 'correct_manually' for fields where to correct manually the information.")
saveRDS(input_db,file = sub(".[tc]sv",".rds",par_sequence_output))
q(save = 'no')

