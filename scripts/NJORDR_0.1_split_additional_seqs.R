
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

option_list = list(
  make_option(c("-a", "--additional_seqs"), type="character", default=NULL, metavar="character")
); 

opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);

if (is.null(opt$additional_seqs)){
  print_help(opt_parser)
  stop("input_file needed", call.=FALSE)
}

additional_seqs <- read.table(opt$additional_seqs,header = F,quote = NULL,sep = '\t')
taxonomy <- additional_seqs[,c(3,4,5,2)]
taxonomy$old_tax_id <- NA
taxonomy$taxlevel <- NA
taxonomy$synonyms <- NA

directory <- dirname(normalizePath(opt$additional_seqs))

write.table(additional_seqs[,c(1,3,6)], paste0(directory,"/seqs_2join.tsv"),row.names = F,col.names = F,quote = F,sep = "\t")
write.table(taxonomy, paste0(directory,"/taxo_2oin.tsv"),row.names = F,col.names = F,quote = F,sep = "\t")
