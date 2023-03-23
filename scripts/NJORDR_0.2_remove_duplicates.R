# this script is made to reduce the database. The intention is to delete sequences
# that are duplicated but that have the same tax_id. There can be sequences that 
# exactly the same but with different tax_id's and those don't have to be merged
# also this process has to be done after the trimming so two sequences with the 
# same tax_id can be different for a larger fragment and identical for a shorter.


options(scipen=999)

library("optparse")

option_list = list(
  make_option(c("-s", "--sequences"), type="character", default=NULL, metavar="character"),
  make_option(c("-c", "--cores"), type="numeric", default=1, metavar="numeric")
); 

opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);

if (is.null(opt$sequences)){
  print_help(opt_parser)
  stop("input_file needed", call.=FALSE)
}

input_seqs <- read.table(opt$sequences,header = T)
occur_taxids <- table(input_seqs$taxID)
sing_seqs <- input_seqs[input_seqs$taxID %in% as.integer(names(occur_taxids[occur_taxids==1])),]
input_seqs <- input_seqs[!input_seqs$taxID %in% as.integer(names(occur_taxids[occur_taxids==1])),]

if (dim(input_seqs)[1]>1) {
  if (opt$cores == 1) {
    dereplicated_seqs <- lapply(X = unique(input_seqs$taxID), FUN = function(x){
      seqs_small <- input_seqs[input_seqs$taxID==x,]
      seqs_small <- seqs_small[!duplicated(seqs_small$sequence),]
      return(seqs_small)
    })
  } else { 
    dereplicated_seqs <- parallel::mclapply(X = unique(input_seqs$taxID), FUN = function(x){
      seqs_small <- input_seqs[input_seqs$taxID==x,]
      seqs_small <- seqs_small[!duplicated(seqs_small$sequence),]
      return(seqs_small)
    },mc.cores = opt$cores)
  }
}

dereplicated_seqs <- do.call(rbind, dereplicated_seqs)
out_seqs <- rbind(dereplicated_seqs,sing_seqs)

write.table(out_seqs,gsub(".","_dereplicated.",opt$sequences),row.names = F,col.names = T, quote = F)
