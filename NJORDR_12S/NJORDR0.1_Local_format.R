# this script is meant to transform the database created locally from sequences self made 
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
library("stringr")

option_list = list(
  make_option(c("-s", "--sequence_input"), type="character", default=NULL,
              metavar="character", help = "local database in fasta format"),
  make_option(c("-o", "--sequence_output"), type="character", default=NULL,
              metavar="character", help = "name of the output file for the sequences in tsv format")
);
opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);

par_local <- opt$sequence_input
par_format_output <- opt$sequence_output

# par_local <- '~/Nextcloud/2_PROJECTES/NJORDR-MJOLNIR3/NJORDR_12S/MiFish_owen/DUFA_MiFish_20220106.fasta'
# par_format_output <- '~/Nextcloud/2_PROJECTES/NJORDR-MJOLNIR3/NJORDR_12S/Local_formated.tsv'

local_db <- Biostrings::readRNAStringSet(par_local)

local_names <- local_db@ranges@NAMES
# fiels are separated by |
seq_id <- sub(" .*$","",local_names)
tax_id <- str_extract(local_names, "taxid=[0-9]*")
tax_id <- sub("taxid=", "", tax_id)

if (sum(!grepl("species",local_names)) == 0) {
  name_txt <- str_extract(local_names, "species([^\ ]*)=([^=]*);")
  name_txt <- sub("spec.*=", "", name_txt)
  name_txt <- sub(";", "", name_txt)
  rank <- "species"
} else {
  warning("not all sequences have species name")
  stop()
}

parent_tax_id <- NA
parent_name_txt <- NA

sequence <- paste0(local_db)

df_out <- data.frame("seq_id"=seq_id,
                     "name_txt"=name_txt,
                     "tax_id"=tax_id,
                     "parent_tax_id"=parent_tax_id,
                     "parent_name_txt"=parent_name_txt,
                     "rank"=rank,
                     "sequence"=sequence)
write.table(df_out,file = par_format_output,quote = F,row.names = F,sep = "\t")