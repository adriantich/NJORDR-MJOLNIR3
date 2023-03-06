
# this script will take the information of those negative taxids and convert
# them to the Taxdump format of the files nodes.dmp and names.dmp

# Things to take into account:
# taxdump uses \t|\t to separate each column and the end of the line is \t|
# 1- nodes.dmp the first three columns correspond are equivalent to the first three
# of the taxonomy.txt file. The 4th and the 13th must be void and the rest (from
# the 5th to 12th) set to 0
# 2- for the names.dmp the new lines have to be in the form of 
# <tax_id>\t|\t<name>\t|\t\t|\tscientific name\t|


# read the taxonomy.txt file
coinr_data <- read.csv('taxonomy.tsv', sep="\t",comment.char = '"')

# take only the negative Taxids
coinr_data <- coinr_data[coinr_data$tax_id < 0,]

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
nodes_dmp_pasted <- paste(nodes_dmp$tax_id,
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

names_dmp <- coinr_data[,c("tax_id","name_txt")]
names_dmp$unique_names <- ""
names_dmp$name_class <- "scientific name\t|"

names_dmp_pasted <- paste(names_dmp$tax_id,names_dmp$name_txt,names_dmp$unique_names,names_dmp$name_class, sep = '\t|\t')

writeLines(nodes_dmp_pasted, "nodes_2join.dmp")
writeLines(names_dmp_pasted, "names_2join.dmp")
