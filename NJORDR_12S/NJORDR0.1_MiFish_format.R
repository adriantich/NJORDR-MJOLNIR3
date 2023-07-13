# this script is meant to transform the database downloaded from MitoFish into 
# NJORDR initial format. This is a tsv file (tab separated) containing the following
# columns:
# [1] "seq_id"        "name_txt"      "tax_id"        "parent_tax_id" "parent_name_txt" "rank"          "sequence" 
# it doesn't mind if all the fields are full but some have
# seq_id and sequence are mandatory except for new parent taxids
# at least one of name_txt and tax_id has to be present.
# parent_name_txt stands for taxonomic names of higher ranks that could help to find the parent_tax_id


options(scipen=999)

library("optparse")
library("dplyr")
library("stringi")

option_list = list(
  make_option(c("-s", "--sequence_input"), type="character", default=NULL,
              metavar="character", help = "MiFish database"),
  make_option(c("-o", "--sequence_output"), type="character", default=NULL,
              metavar="character", help = "name of the output file for the sequences in tsv format")
);
opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);

par_mifish <- opt$sequence_input
par_format_output <- opt$sequence_output
# 
# par_mifish <- '~/Nextcloud/2_PROJECTES/NJORDR-MJOLNIR3/NJORDR_12S/mitogeno_and_partial/mito-all'
# par_format_output <- '~/Nextcloud/2_PROJECTES/NJORDR-MJOLNIR3/NJORDR_12S/MiFish_formated.tsv'

mifish_db <- Biostrings::readRNAStringSet(par_mifish)

mifish_names <- mifish_db@ranges@NAMES
# fiels are separated by |
mifish_names <- do.call(rbind, strsplit(mifish_names,'|',fixed = T))
seq_id <- mifish_names[,2]
mifish_names <- do.call(rbind,strsplit(mifish_names[,3]," ([", fixed = T))
name_txt <- mifish_names[,1]
tax_id <- NA
parent_tax_id <- NA
parent_name_txt <- mifish_names[,2]
parent_name_txt <- gsub(" ","",gsub(")","",gsub("]","",gsub("[","",gsub("\"","",parent_name_txt),fixed = T),fixed = T)))
rank <- NA
sequence <- paste0(mifish_db)

df_out <- data.frame("seq_id"=seq_id,
                     "name_txt"=name_txt,
                     "tax_id"=tax_id,
                     "parent_tax_id"=parent_tax_id,
                     "parent_name_txt"=parent_name_txt,
                     "rank"=rank,
                     "sequence"=sequence)
write.table(df_out,file = par_format_output,quote = F,row.names = F,sep = "\t")