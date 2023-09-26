#!/usr/bin/R

# this script will read a tsv file with three columns (seqID   taxID   sequence) from COInr database 
# and will retrieve a tsv file with six columns (seq_id  name_txt  tax_id  parent_tax_id  rank  sequence)

# disable scientific notation
options(scipen=999)

library("optparse")
library("stringi")

option_list = list(
  make_option(c("-i", "--input_data"), type="character", default=NULL, 
              metavar="character", help = paste("sequence tab file in NJORDR format.",
                                                "colnames: seq_id name_txt tax_id parent_tax_id parent_name_txt(optional) rank sequence")),
  make_option(c("-o", "--out_dir"), type="character", default=".", 
              metavar="character", help = "taxonomy tab file with colnames [tax_id	parent_tax_id	rank	name_txt	old_tax_id	taxlevel	synonyms]"),
  make_option(c("-a", "--add_seqs"), type="character", default=NULL,  
              metavar="character", help = "additional sequences to add to COInr"),
  make_option(c("-A", "--add_seqs_path"), type="character", default=".",  
              metavar="character", help = "path from which to search for additional sequeneces. These sequences will be added the ManCurSeq_ prefix"),
  make_option(c("-r", "--rds"), action="store_true", default=F, 
              help = paste("Retrive a rds file with the compressed data for sollowing steps."))
); 

opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);

if (is.null(opt$input_data)){
  print_help(opt_parser)
  stop("input_file needed", call.=FALSE)
}
par_input_data <- opt$input_data
par_out_dir <- opt$out_dir
par_add_seqs <- opt$add_seqs
par_add_seqs_path <- opt$add_seqs_path
par_rds <- opt$rds

# par_add_seqs_path <- "../"
# par_add_seqs <- "../DUFA_scripts/Additional_seqs_*"
# read file
message('reading input file')
data <- read.table(par_input_data,header = T,quote = NULL,sep = '\t', fill = TRUE)

message('including missing columns')
# add the missing columns
data <- data.frame(seq_id = data$seqID,
                   name_txt = NA,
                   tax_id = data$taxID,
                   parent_tax_id = NA,
                   rank = NA,
                   sequence = data$sequence)

# for each path in the add_seqs create a file path. This also applies to a general
# patterns that match different files.
if (!is.null(par_add_seqs)) {
  add_files <- paste(par_add_seqs_path,strsplit(par_add_seqs,split = ",")[[1]],sep='/')
  for (path in add_files) {
    for (file in list.files(path= sub("/[^/]*$", "", path), pattern=sub(".*/", "",path),full.names = T)) {
      message(paste('including sequences from', file))
      additional <- read.csv(file,quote = NULL,sep = '\t')
      additional$seq_id[!grepl('ManCurSeq_',additional$seq_id)] <- paste0('ManCurSeq_',additional$seq_id[!grepl('ManCurSeq_',additional$seq_id)])
      data <- rbind(data,additional)
    }
  }
}


write.table(data, paste0(par_out_dir,"/NJORDR0.1_sequences.tsv"),row.names = F,col.names = F,quote = F,sep = "\t",na = "")
if (par_rds) {
  saveRDS(data,paste0(par_out_dir,"/NJORDR0.1_sequences.rds"))
}
