# this script is meant to transform the database downloaded from Mare-Mage into 
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
  make_option(c("-t", "--taxonomy_input"), type="character", default=NULL,
              metavar="character", help = "Taxonomy database"),
  make_option(c("-o", "--sequence_output"), type="character", default=NULL,
              metavar="character", help = "name of the output file for the sequences in tsv format")
);
opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);

par_maremage_seqs <- opt$sequence_input
par_maremage_taxo <- opt$taxonomy_input
par_format_output <- opt$sequence_output

# par_maremage_seqs <- '~/Nextcloud/2_PROJECTES/NJORDR-MJOLNIR3/NJORDR_12S/mare_mage/12sDB.fasta'
# par_maremage_taxo <- '~/Nextcloud/2_PROJECTES/NJORDR-MJOLNIR3/NJORDR_12S/mare_mage/12sDB_taxonomy.txt'
# par_format_output <- '~/Nextcloud/2_PROJECTES/NJORDR-MJOLNIR3/NJORDR_12S/MareMage_formated.tsv'

maremage_db <- Biostrings::readRNAStringSet(par_maremage_seqs)
maremage_taxo <- read.table(par_maremage_taxo,sep = "\t")
colnames(maremage_taxo) <- c("seq_id","taxonomy")

maremage_names <- data.frame(seq_id = maremage_db@ranges@NAMES)
maremage_names$seqs <- paste0(maremage_db)

maremage_names <- inner_join(maremage_names,maremage_taxo,by = 'seq_id')

name_txt <- sub("^.*;","",maremage_names$taxonomy)

if (sum(!grepl(";s_",maremage_taxo$Vf2)) == 0) {
  # parent_name_txt <- sub(";([^;]*)$","",maremage_names$taxonomy)
  parent_name_txt <- sub(";s_(.*)$","",maremage_names$taxonomy)
  rank <- "species"
} else {
  warning("not all sequences have species name. contact to adriantich@gmail.com in case this happen")
  stop()
}

parent_name_txt <- gsub(";._",";",parent_name_txt)
parent_name_txt <- gsub(";.._",";",parent_name_txt)
parent_name_txt <- gsub("._","",parent_name_txt)

df_out <- data.frame("seq_id"=maremage_names$seq_id,
                     "name_txt"=name_txt,
                     "tax_id"=NA,
                     "parent_tax_id"=NA,
                     "parent_name_txt"=parent_name_txt,
                     "rank"=rank,
                     "sequence"=maremage_names$seqs)
write.table(df_out,file = par_format_output,quote = F,row.names = F,sep = "\t")
