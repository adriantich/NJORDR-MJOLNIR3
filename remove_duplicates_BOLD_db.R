
cores <- 15
# read BOLD tsv
bold_db <- read.csv('~/Downloads/BOLD_Public.27-Jan-2023.tsv',sep='\t')

message("database loaded")

## first get the non duplicated sequences
# get the number of occurrences of each sequence in the db
occurrences <- table(bold_db$nucraw)
# take those that appear only one time
occurrences <- names(occurrences)[occurrences==1]
# bold_db$revise_manually <- NA
# bold_db$revise_manually[which(bold_db$nucraw %in% occurrences)] <- F
# rm(occurrences)
bold_db_reduced <- bold_db[which(bold_db$nucraw %in% occurrences),]
bold_db_reduced$revise_manually <- F

message("sigle sequences retained")

# delete them from the bold_db
bold_db <- bold_db[-which(bold_db$nucraw %in% occurrences),]

# message("sigle sequences removed from initial db")

sequences_left <- unique(bold_db$nucraw)
# sequences_left <- unique(bold_db$nucraw[-which(!bold_db$revise_manually)])
leng_sl <- length(sequences_left)
message(paste(leng_sl,"sequences left"))

# create dataframe with information for each sequence which has to be removed (select column)
# and which have to be revised manually (revise_manually)
small_db <- do.call("rbind",parallel::mclapply(sequences_left,function(x,bold_db){
  seq_pos <- which(bold_db$nucraw==x)
  seq_selected <- which(!duplicated(bold_db$bin_uri[seq_pos]))
  if (sum(seq_selected)>1) {
    small_db <- data.frame(seq = seq_pos, select = seq_selected, revise_manually = T)
  } else {
    small_db <- data.frame(seq = seq_pos, select = seq_selected, revise_manually = F)
  }
  return(small_db)
},mc.cores = cores,bold_db=bold_db))

bold_db$revise_manually <- F
bold_db$revise_manually[small_db$seq] <- small_db$revise_manually
bold_db <- bold_db[small_db$seq_selected,]

bold_db <- rbind(bold_db_reduced,bold_db)
rm(bold_db_reduced,small_db)

bold_db_revise <- bold_db[bold_db$revise_manually,]
bold_db <- bold_db[-bold_db$revise_manually,]

bold_db_revise <- bold_db_revise[,-"revise_manually"]
bold_db <- bold_db[,-"revise_manually"]


write.csv(bold_db,"BOLD_reduced.tsv", sep = "\t", row.names = F)
write.csv(bold_db_revise,"BOLD_reduced_to_revise.tsv", sep = "\t", row.names = F)
