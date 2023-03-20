# 
# This script converts negative taxids into positives and adds a certain number
# to them

library("optparse")

option_list = list(
  make_option(c("-i", "--input_file"), type="character", default=NULL, metavar="character"),
  make_option(c("-n", "--new_taxids"), type="numeric", default=100000000000000, metavar="character")
); 

opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);

if (is.null(opt$input_file)){
  print_help(opt_parser)
  stop("input_file needed", call.=FALSE)
}

df <- read.table(opt$input_file)
df$V2[df$V2 < 0] <- abs(df$V2[df$V2 < 0]) + opt$new_taxids

write.table(df,gsub("negative.fasta","new_taxids.fasta",opt$input_file),row.names = F,col.names = F,quote = F)
