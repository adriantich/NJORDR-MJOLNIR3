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
  make_option(c("-s", "--silva_db"), type="character", default=NULL, 
              metavar="character", help = "silva database in fasta format"),
  make_option(c("-p", "--pr2_db"), type="character", default=NULL, 
              metavar="character", help = "PR2 dababase in merged xlsx format"),
  make_option(c("-t", "--taxonomy_input"), type="character", default=NULL, 
              metavar="character", help = "taxonomy tab file with colnames [tax_id	parent_tax_id	rank	name_txt	old_tax_id	taxlevel	synonyms]"),
  make_option(c("-c", "--cores"), type="numeric", default=1, 
              metavar="character", help = "number or cores to run the process in parallel. 1 default"),
  make_option(c("-o", "--sequence_output"), type="character", default=NULL, 
              metavar="character", help = "name of the output file for the sequences in tsv format"),
  make_option(c("-T", "--taxonomy_output"), type="character", default=NULL,  
              metavar="character", help = "output taxonomy tsv file name")
); 

opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);
par_silva <- opt$silva_db
par_pr2 <- opt$pr2_db
par_taxonomy_input <- opt$taxonomy_input
par_cores <- opt$cores
par_sequence_output <- opt$sequence_output
par_taxonomy_output <- opt$taxonomy_output


par_silva <- "~/TAXO/NJORDR_18S/SILVA_db.fasta"
par_pr2 <- "~/Nextcloud/2_PROJECTES/NJORDR-MJOLNIR3/NJORDR_18Sv7/PR2_db.xlsx"
par_taxonomy_input <- "~/Nextcloud/2_PROJECTES/NJORDR-MJOLNIR3/NJORDR_18Sv7/taxonomy.tsv"
par_cores <- 2
par_sequence_output <- "~/Nextcloud/2_PROJECTES/NJORDR-MJOLNIR3/NJORDR_18Sv7/seqs18S.csv"
par_taxonomy_output <- "~/Nextcloud/2_PROJECTES/NJORDR-MJOLNIR3/NJORDR_18Sv7/taxonomy.tsv"

if (is.null(par_silva)){
  print_help(opt_parser)
  stop("Silva database input file needed", call.=FALSE)
}
if (is.null(par_pr2)){
  print_help(opt_parser)
  stop("PR2 database input file needed", call.=FALSE)
}
if (is.null(par_taxonomy_input)){
  print_help(opt_parser)
  stop("taxonomy input file needed", call.=FALSE)
}
if (is.null(par_sequence_output)){
  print_help(opt_parser)
  stop("Sequences output file name needed", call.=FALSE)
}
if (is.null(par_taxonomy_output)){
  print_help(opt_parser)
  stop("taxonomy output file name needed", call.=FALSE)
}

print(paste0("Loading data from ",par_taxonomy_input))
input_taxonomy <- read.csv(par_taxonomy_input, sep="\t",comment.char = '"')
print(paste0("Data from ",par_taxonomy_input," loaded"))

print(paste0("Loading data from ",par_silva))
silva_db <- Biostrings::readRNAStringSet(par_silva)
silva_names <- silva_db@ranges@NAMES

find_taxids_silva <- function(seq, input_taxonomy = input_taxonomy,silva_names = silva_names, pr2 = F) {
  # for (seq in 1:length(silva_names)) {
  # seq <- 1
  taxid <- NULL
  rank <- NULL
  parent_taxid <- NULL
  if (pr2) {
    line <- seq
  } else {
    line <- silva_names[seq]
    line <- sub(" ",";",line)
  }
  line <- strsplit(line,";")
  seq_name <- line[[1]][1]
  taxid_present <- T
  for (i in length(line[[1]]):2) {
    if (line[[1]][i] %in% input_taxonomy$name_txt) {
      taxid <- input_taxonomy$tax_id[input_taxonomy$name_txt %in% line[[1]][i]]
      taxid <- taxid[1]
      rank <- input_taxonomy$rank[input_taxonomy$tax_id == taxid]
      rank <- rank[1]
      parent_taxid  <- input_taxonomy$parent_tax_id[input_taxonomy$tax_id == taxid]
      parent_taxid <- parent_taxid[1]
      break
    } else if (sum(grepl(line[[1]][i], input_taxonomy$synonyms))>0) {
      taxid <- input_taxonomy$tax_id[grepl(line[[1]][i], input_taxonomy$synonyms)]
      taxid <- taxid[1]
      rank <- input_taxonomy$rank[input_taxonomy$tax_id == taxid]
      rank <- rank[1]
      parent_taxid  <- input_taxonomy$parent_tax_id[input_taxonomy$tax_id == taxid]
      parent_taxid <- parent_taxid[1]
      break
    } else {
      taxid_present <- F
    }
  }
  if (taxid_present) {
    out <- data.frame("seq_id" = seq_name,
                      "name_txt" = line[[1]][length(line[[1]])],
                      "tax_id" = taxid,
                      "parent_tax_id" = parent_taxid,
                      "rank" = rank,
                      "sequence" = T)
  } else {
    if (is.null(taxid)) {
      out <- data.frame("seq_id" = seq_name,
                        "name_txt" = paste0(line[[1]][2:length(line[[1]])],collapse = ";"),
                        "tax_id" = NA,
                        "parent_tax_id" = NA,
                        "rank" = NA,
                        "sequence" = F)
    } else {
      out <- data.frame("seq_id" = seq_name,
                        "name_txt" = paste0(line[[1]][2:length(line[[1]])],collapse = ";"),
                        "tax_id" = NA,
                        "parent_tax_id" = taxid,
                        "rank" = (length(line[[1]])-i),
                        "sequence" = F)
    }
  }
  # print(out)
  return(out)
}

silva_names <- do.call(rbind,parallel::mclapply(1:length(silva_names),find_taxids_silva,input_taxonomy = input_taxonomy,silva_names = silva_names,mc.cores = par_cores))
silva_db  <- paste0(silva_db)

save.image("~/Nextcloud/2_PROJECTES/NJORDR-MJOLNIR3/NJORDR_18Sv7/dbformat2tsv.RData")

####
# PR2
####

pr2_db <- readxl::read_xlsx(par_pr2)

pr2_db <- pr2_db[pr2_db$gene == "18S_rRNA",]

save.image("~/Nextcloud/2_PROJECTES/NJORDR-MJOLNIR3/NJORDR_18Sv7/dbformat2tsv2.RData")

pr2_db <- pr2_db[,c("pr2_accession","species","silva_taxonomy","gb_organism","sequence")]

# pr2_db <- pr2_db[,c("pr2_accession","species","taxo_id","sequence")]
# colnames(pr2_db) <- c("seq_id","name_txt","tax_id", "sequence")


save.image("~/Nextcloud/2_PROJECTES/NJORDR-MJOLNIR3/NJORDR_18Sv7/dbformat2tsv3.RData")

find_taxids_pr2 <- function(name, input_taxonomy = input_taxonomy,pr2_db = pr2_db) {
  # for (name in unique(pr2_db$gb_organism)) {
  # name <- unique(pr2_db$gb_organism)[1]
  if (!is.na(name)){
    data <- pr2_db[pr2_db$gb_organism == name,]
    seq_id <- data$pr2_accession
    name_txt <- data$gb_organism
    if (name %in% input_taxonomy$name_txt) {
      taxid <- input_taxonomy$tax_id[input_taxonomy$name_txt %in% name]
      taxid <- taxid[1]
      rank <- input_taxonomy$rank[input_taxonomy$tax_id == taxid]
      rank <- rank[1]
      parent_taxid  <- input_taxonomy$parent_tax_id[input_taxonomy$tax_id == taxid]
      parent_taxid <- parent_taxid[1]
      break
    } else if (sum(grepl(name, input_taxonomy$synonyms))>0) {
      taxid <- input_taxonomy$tax_id[grepl(line[[1]][i], input_taxonomy$synonyms)]
      taxid <- taxid[1]
      rank <- input_taxonomy$rank[input_taxonomy$tax_id == taxid]
      rank <- rank[1]
      parent_taxid  <- input_taxonomy$parent_tax_id[input_taxonomy$tax_id == taxid]
      parent_taxid <- parent_taxid[1]
    } else {
      out1 <- lapply(paste(data$silva_taxonomy,gsub("_"," ",data$species),sep=";"), FUN = find_taxids_silva, input_taxonomy = input_taxonomy,silva_names = NULL, pr2 = T)
      tax_id <- out1[[1]]$tax_id
      rank <- out1[[1]]$rank
      parent_taxid <- out1[[1]]$parent_tax_id
    }
  } else {
    data <- pr2_db[is.na(pr2_db$gb_organism),]
    out1 <- lapply(paste(data$silva_taxonomy,gsub("_"," ",data$species),sep=";"), FUN = find_taxids_silva, input_taxonomy = input_taxonomy,silva_names = NULL, pr2 = T)
    seq_id <- data$pr2_accession
    name_txt <- data$species
    tax_id <- out1[[1]]$tax_id
    rank <- out1[[1]]$rank
    parent_taxid <- out1[[1]]$parent_tax_id
  }
  out <- data.frame("seq_id" = seq_id,
                    "name_txt" = name_txt,
                    "tax_id" = tax_id, 
                    "parent_tax_id" = parent_tax_id,
                    "rank" = rank,
                    "sequence" = sequence)
  # print(out)
  return(out)
}

pr2_db_parents <- do.call(rbind,parallel::mclapply(unique(pr2_db$gb_organism)[1],find_taxids_pr2,input_taxonomy = input_taxonomy,pr2_db = pr2_db,mc.cores = par_cores))

# save.image("~/Nextcloud/2_PROJECTES/NJORDR-MJOLNIR3/NJORDR_18Sv7/dbformat2tsv.RData")
# q(save = 'no')

load("dbformat2tsv2.RData")
