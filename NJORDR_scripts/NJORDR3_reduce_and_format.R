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
  make_option(c("-c", "--cores"), type="numeric", default=1, 
              metavar="character", help = "number or cores to run the process in parallel. 1 default"),
  make_option(c("-f", "--fasta_output"), type="character", default=NULL, 
              metavar="character", help = "output fasta file reduced"),
  make_option(c("-n", "--seqs_taxids"), type="numeric", default=NULL,  
              metavar="character", help = "maximum number of sequences per taxid"),
  make_option(c("-k", "--keep_tag"), type="character", default="ManCurSeq_", 
              metavar="character", help = paste("Initial pattern for which a sequence must be",
                                                "retained. If Additional sequences are meant",
                                                "to be retained, they must have this pattern",
                                                "at the beggining of the sequence Id. The default pattern is 'ManCurSeq_'")) 
); 

opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);
par_sequence <- opt$sequence_input
par_cores <- opt$cores
par_fasta <- opt$fasta_output
par_seqs_taxid <- opt$seqs_taxids
keep_tag <- opt$keep_tag

# par_sequence <- "~/TAXO/COInr/COInr.tsv"
# par_cores <- 2
# par_fasta <- "../COInr/COInr.fasta"
# par_seqs_taxid <- 10
# keep_tag <- "NS_"

if (is.null(par_sequence)){
  print_help(opt_parser)
  stop("sequence input file needed", call.=FALSE)
}
if (is.null(par_fasta)){
  print_help(opt_parser)
  stop("fasta output file needed", call.=FALSE)
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


dereplication <- function(x){
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
}

print("Dereplicating. This will take a while.")
if (dim(input_seqs)[1]>1) {
  if (par_cores == 1) {
    dereplicated_seqs <- lapply(X = unique(input_seqs$taxID), 
                                FUN = dereplication)
  } else { 
    dereplicated_seqs <- parallel::mclapply(X = unique(input_seqs$taxID), 
                                            FUN = dereplication, 
                                            mc.cores = par_cores)
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


# create fasta output
# add taxid flag
out_seqs$seqID <- paste(paste0(">",out_seqs$seqID),paste0("taxid=",out_seqs$taxID,";"))
out_seqs <- paste(out_seqs$seqID,out_seqs$sequence,sep = "\n")

print(paste0("writing output in ",par_fasta))
writeLines(out_seqs, par_fasta)





