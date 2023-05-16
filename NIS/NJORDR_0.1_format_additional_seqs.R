
# This script takes the additional sequences and splits the file into two to 
# be added to the COInr database

# Things to take into account for the input files:
# 1- the sequence file has no header 
# 2- is a tab separated column
# 3- the order of the columns in input is mandatory and as follows
# [1] "seq_id"        "name_txt"      "tax_id"        "parent_tax_id" "rank"          "sequence" 

# for the ouput:
# in this case will have because it wont be attached to any other
# it will have the colnames : [1] "seq_id"      "tax_id"        "sequence" 

# disable scientific notation
options(scipen=999)
library("optparse")

option_list = list(
  make_option(c("-i", "--in_dir"), type="character", default=NULL, metavar="character"),
  make_option(c("-o", "--out_dir"), type="character", default=NULL, metavar="character")
); 

opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);


# additional_seqs_AWI <- read.table(paste0(opt$in_dir,"Additional_seqs_AWI.tsv"),header = F,quote = NULL,sep = '\t')
additional_seqs_NIS <- read.table(paste0(opt$in_dir,"Additional_seqs_NIS.tsv"),header = F,quote = NULL,sep = '\t')
# for DUFA we need to add the forward primer to the sequences
# additional_seqs_DUFA <- read.table(paste0(opt$in_dir,"Additional_seqs_DUFA.csv"),header = F,sep = '\t')
# additional_seqs_CESC <- read.table(paste0(opt$in_dir,"Additional_seqs_CESC.tsv"),header = F,sep = '\t',fill = T)
# additional_seqs_DUFA$V6[additional_seqs_DUFA$V6!=""] <- paste0("GGWACWRGWTGRACWNTNTAYCCYCC",additional_seqs_DUFA$V6[additional_seqs_DUFA$V6!=""])


# additional_seqs <- rbind(additional_seqs_AWI,
#                          additional_seqs_NIS,
#                          additional_seqs_DUFA[,1:6],
#                          additional_seqs_CESC[,1:6])
additional_seqs <- additional_seqs_NIS

taxonomy <- additional_seqs[,c(3,4,5,2)]
taxonomy$old_tax_id <- NA
taxonomy$taxlevel <- NA
taxonomy$synonyms <- NA

additional_seqs <- additional_seqs[additional_seqs$V6!="",c(1,3,6)]
colnames(additional_seqs) <-  c("seq_id","tax_id","sequence")

write.table(additional_seqs, paste0(opt$out_dir,"NIS.tsv"),row.names = F,col.names = T,quote = F,sep = "\t")
write.table(taxonomy, paste0(opt$out_dir,"taxo_2join.tsv"),row.names = F,col.names = F,quote = F,sep = "\t")
