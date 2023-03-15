
# this script will take the information of those negative taxids and convert
# them to the Taxdump format of the files nodes.dmp and names.dmp

# Things to take into account:
# taxdump uses \t|\t to separate each column and the end of the line is \t|
# 1- nodes.dmp the first three columns correspond are equivalent to the first three
# of the taxonomy.txt file. The 4th and the 13th must be void and the rest (from
# the 5th to 12th) set to 0
# 2- for the names.dmp the new lines have to be in the form of 
# <tax_id>\t|\t<name>\t|\t\t|\tscientific name\t|

library("optparse")

option_list = list(
  make_option(c("-t", "--taxonomy_file"), type="character", default=NULL, metavar="character"),
  make_option(c("-d", "--output_directory"), type="character", default='.', metavar="character"),
  make_option(c("-D", "--delnodes"), type="character", default=NULL, metavar="character"),
  make_option(c("-m", "--merged"), type="character", default=NULL, metavar="character"),
  make_option(c("-n", "--new_taxids"), type="numeric", default=100000000000000, metavar="character")
); 

opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);

if (is.null(opt$taxonomy_file)){
  print_help(opt_parser)
  stop("input_file needed", call.=FALSE)
}
if (is.null(opt$delnodes)){
  print_help(opt_parser)
  stop("delnodes file needed", call.=FALSE)
}
if (is.null(opt$merged)){
  print_help(opt_parser)
  stop("merged file needed", call.=FALSE)
}

# read the taxonomy.txt file
coinr_data <- read.csv(opt$taxonomy_file, sep="\t",comment.char = '"')
delnodes_dmp <- read.table(opt$delnodes,
                           header = F)
merged_dmp <- read.table(opt$merged,
                           header = F)
print(paste("dimensions :",dim(coinr_data)))

# take only the negative Taxids
coinr_data_neg <- coinr_data[coinr_data$tax_id <= 0,]
coinr_data <- coinr_data[coinr_data$tax_id > 0,]
print(paste(dim(coinr_data_neg)[1],"negative taxids"))
coinr_data_neg$tax_id <- abs(coinr_data_neg$tax_id) + opt$new_taxids
coinr_data_neg$parent_tax_id[coinr_data_neg$parent_tax_id<0] <- abs(coinr_data_neg$parent_tax_id[coinr_data_neg$parent_tax_id<0]) + opt$new_taxids

coinr_data <- rbind(coinr_data,coinr_data_neg)
rm(coinr_data_neg)

# nodes
nodes_dmp <- coinr_data[,c("tax_id","parent_tax_id","rank")]
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

# names
names_dmp <- coinr_data[,c("tax_id","name_txt")]
# remove duplicates
names_dmp <- names_dmp[!duplicated(names_dmp$tax_id),]
# sort the taxids
names_dmp <- names_dmp[order(names_dmp$tax_id),]
names_dmp$unique_names <- ""
names_dmp$name_class <- "scientific name\t|"

# modify merged and delnodes
delnodes_dmp <- delnodes_dmp[-which(delnodes_dmp$V1 %in% nodes_dmp$tax_id),]
merged_dmp <- merged_dmp[-which(merged_dmp$V1 %in% nodes_dmp$tax_id),]
merged_dmp <- merged_dmp[which(merged_dmp$V3 %in% nodes_dmp$tax_id),]

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
names_dmp <- paste(names_dmp$tax_id,
                   names_dmp$name_txt,
                   names_dmp$unique_names,names_dmp$name_class, sep = '\t|\t')

writeLines(nodes_dmp, paste(opt$output_directory,"nodes.dmp",sep="/"))
writeLines(names_dmp, paste(opt$output_directory,"names.dmp",sep="/"))
write.table(delnodes_dmp,paste(opt$output_directory,"delnodes.dmp",sep="/"), col.names = F,quote = F,row.names = F)
write.table(merged_dmp,paste(opt$output_directory,"merged.dmp",sep="/"), col.names = F,quote = F,row.names = F)
