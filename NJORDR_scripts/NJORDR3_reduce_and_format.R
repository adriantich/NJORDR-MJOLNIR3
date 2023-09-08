# this script is made to reduce the database. The intention is to delete sequences
# that are duplicated but that have the same tax_id. There can be sequences that 
# exactly the same but with different tax_id's and those don't have to be merged
# also this process has to be done after the trimming so two sequences with the 
# same tax_id can be different for a larger fragment and identical for a shorter.


options(scipen=999)

library("optparse")
library("dplyr")
library("stringi")

option_list = list(
  make_option(c("-s", "--sequence_input"), type="character", default=NULL, 
              metavar="character", help = "sequence tab file with colnames [seqID	taxID	sequence]"),
  make_option(c("-t", "--taxonomy_input"), type="character", default=NULL, 
              metavar="character", help = "taxonomy tab file with colnames [tax_id	parent_tax_id	rank	name_txt	old_tax_id	taxlevel	synonyms]"),
  make_option(c("-c", "--cores"), type="numeric", default=1, 
              metavar="character", help = "number or cores to run the process in parallel. 1 default"),
  make_option(c("-f", "--fasta_output"), type="character", default=NULL, 
              metavar="character", help = "output fasta file reduced"),
  make_option(c("-T", "--taxdump_output"), type="character", default=NULL,  
              metavar="character", help = "output taxdump"),
  make_option(c("-n", "--seqs_taxids"), type="numeric", default=NULL,  
              metavar="character", help = "maximum number of sequences per taxid"),
  make_option(c("-x", "--new_taxids"), type="numeric", default=1000000000, 
              metavar="character", help = paste("Number from which start the notation for new taxids.",
                                                "Since new taxids (not represented in NCBI) are set as negative,",
                                                "they must be turned into positive and to be sure they",
                                                "do not have the same number as an existing taxid,",
                                                "they will be higher than this value. However,",
                                                "the highest taxid cannot exced 2,147,483,647")) ,
  make_option(c("-k", "--keep_tag"), type="character", default="NS_", 
              metavar="character", help = paste("Initial pattern for which a sequence must be",
                                                "retained. If Additional sequences are meant",
                                                "to be retained, they must have this pattern",
                                                "at the beggining of the sequence Id. The default pattern is 'NS_'")) 
); 

opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);
par_sequence <- opt$sequence_input
par_taxonomy <- opt$taxonomy_input
par_cores <- opt$cores
par_fasta <- opt$fasta_output
par_taxdump <- opt$taxdump_output
par_seqs_taxid <- opt$seqs_taxids
par_new_taxids <- opt$new_taxids
keep_tag <- opt$keep_tag

# par_sequence <- "~/TAXO/COInr/COInr.tsv"
# par_taxonomy <- "~/TAXO/COInr/taxonomy.tsv"
# par_cores <- 2
# par_fasta <- "../COInr/COInr.fasta"
# par_taxdump <- "../COInr/COInr_taxdump"
# par_seqs_taxid <- 10
# par_new_taxids <- 1000000000
# keep_tag <- "NS_"

if (is.null(par_sequence)){
  print_help(opt_parser)
  stop("sequence input file needed", call.=FALSE)
}
if (is.null(par_taxonomy)){
  print_help(opt_parser)
  stop("taxonomy input file needed", call.=FALSE)
}
if (is.null(par_fasta)){
  print_help(opt_parser)
  stop("fasta output file needed", call.=FALSE)
}
if (is.null(par_taxdump)){
  print_help(opt_parser)
  stop("taxdump output file needed", call.=FALSE)
}
if (is.null(par_seqs_taxid)){
  message("no number of sequences per taxid specified. All will be retained.")
  par_seqs_taxid <- 0
}

print(paste0("Loading data from ",par_sequence))
input_seqs <- read.table(par_sequence,header = T)
occur_taxids <- table(input_seqs$taxID)

# remove duplicates and keep n seqs per taxid
print("Separating singleton taxids")
sing_seqs <- input_seqs[input_seqs$taxID %in% as.integer(names(occur_taxids[occur_taxids==1])),]
input_seqs <- input_seqs[!input_seqs$taxID %in% as.integer(names(occur_taxids[occur_taxids==1])),]

print("Dereplicating. This will take a while.")
if (dim(input_seqs)[1]>1) {
  if (par_cores == 1) {
    dereplicated_seqs <- lapply(X = unique(input_seqs$taxID), FUN = function(x){
      seqs_small <- input_seqs[input_seqs$taxID==x,]
      keep_sequences <- seqs_small[grepl(keep_tag,seqs_small$seqID),]
      seqs_small <- seqs_small[!grepl(keep_tag,seqs_small$seqID),]
      seqs_small <- seqs_small[!duplicated(seqs_small$sequence),]
      if (par_seqs_taxid>0 & dim(seqs_small)[1]>par_seqs_taxid) {
        seqs_small <- slice_sample(seqs_small, n = par_seqs_taxid, replace = FALSE)
      }
      seqs_small <- rbind(keep_sequences,seqs_small)
      seqs_small <- seqs_small[!duplicated(seqs_small$sequence),]
      return(seqs_small)
    })
  } else { 
    dereplicated_seqs <- parallel::mclapply(X = unique(input_seqs$taxID), FUN = function(x){
      seqs_small <- input_seqs[input_seqs$taxID==x,]
      keep_sequences <- seqs_small[grepl(keep_tag,seqs_small$seqID),]
      seqs_small <- seqs_small[!grepl(keep_tag,seqs_small$seqID),]
      seqs_small <- seqs_small[!duplicated(seqs_small$sequence),]
      if (par_seqs_taxid>0 & dim(seqs_small)[1]>par_seqs_taxid) {
        seqs_small <- slice_sample(seqs_small, n = par_seqs_taxid, replace = FALSE)
      }
      seqs_small <- rbind(keep_sequences,seqs_small)
      seqs_small <- seqs_small[!duplicated(seqs_small$sequence),]
      return(seqs_small)
    },mc.cores = par_cores)
  }
  dereplicated_seqs <- do.call(rbind, dereplicated_seqs)
} else {
  dereplicated_seqs <- data.frame()
}
print("Dereplicated")
out_seqs <- rbind(dereplicated_seqs,sing_seqs)
rm(input_seqs,dereplicated_seqs)
no_IUPAC_seqs <- grepl("E",out_seqs$sequence)
out_seqs <- out_seqs[!no_IUPAC_seqs,]

# convert negative taxids into positive taxids
print("turning taxids into positives")

# change the taxids from the sequences
negative_taxids <- out_seqs$taxID<=0
out_seqs$taxID[negative_taxids] <- abs(out_seqs$taxID[negative_taxids]) + par_new_taxids

# change taxids from the taxonomy:
print(paste0("Loading data from ",par_taxonomy))
input_taxonomy <- read.csv(par_taxonomy, sep="\t",comment.char = '"')
print(paste0("Data from ",par_taxonomy," loaded"))
# taxids
negative_taxids <- input_taxonomy$tax_id<=0
input_taxonomy$tax_id[negative_taxids] <- abs(input_taxonomy$tax_id[negative_taxids]) + par_new_taxids
# parent_taxids
negative_taxids <- input_taxonomy$parent_tax_id<=0
input_taxonomy$parent_tax_id[negative_taxids] <- abs(input_taxonomy$parent_tax_id[negative_taxids]) + par_new_taxids

print("taxids turned into positives")

# create taxdump
print("creating taxdump")

# create directory
dir.create(par_taxdump)

# create merged.dmp
file.create(paste0(par_taxdump,"/merged.dmp"))
# create delnodes.dmp
file.create(paste0(par_taxdump,"/delnodes.dmp"))

# create nodes.dmp
nodes_dmp <- input_taxonomy[,c("tax_id","parent_tax_id","rank")]
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
# write ouput
writeLines(nodes_dmp, paste(par_taxdump,"nodes.dmp",sep="/"))
rm(nodes_dmp)

# create names.dmp
names_dmp <- input_taxonomy[,c("tax_id","name_txt")]
names_dmp$name_txt <- stri_trans_general(str = names_dmp$name_txt, id = "Latin-ASCII")
# remove duplicates
names_dmp <- names_dmp[!duplicated(names_dmp$tax_id),]
# sort the taxids
names_dmp <- names_dmp[order(names_dmp$tax_id),]
names_dmp$unique_names <- ""
names_dmp$name_class <- "scientific name\t|"
# join all fields
names_dmp <- paste(names_dmp$tax_id,names_dmp$name_txt,names_dmp$unique_names,names_dmp$name_class, sep = '\t|\t')
# write ouput
writeLines(names_dmp, paste(par_taxdump,"names.dmp",sep="/"))
rm(names_dmp)

print("taxdump created")

# create fasta output
# add taxid flag
out_seqs$seqID <- paste(paste0(">",out_seqs$seqID),paste0("taxid=",out_seqs$taxID,";"))
out_seqs <- paste(out_seqs$seqID,out_seqs$sequence,sep = "\n")

print(paste0("writing output in ",par_fasta))
writeLines(out_seqs, par_fasta)





