

# primer a la terminal he pasat de fasta a csv
# awk '/;$/ { printf("%s ", $0); next } 1' DUFA_COLR_20210723.fasta >DUFA_COLR_20210723.csv 
# sed -i 's/ former_id=/\t/g' DUFA_COLR_20210723.csv 
# sed -i 's/; species_name=/\t/g' DUFA_COLR_20210723.csv 
# sed -i 's/; taxid=/\t/g' DUFA_COLR_20210723.csv 
# sed -i 's/; /\t/g' DUFA_COLR_20210723.csv 
# sed -i 's/>//g' DUFA_COLR_20210723.csv
# ara ho edito des de l'excel per crear les columnes adients
# canvio manualment Aglaozonia per Cutleria
# elimino els ' de totes les files
# sed -i "s/'//g" Additional_sequences_DUFA.csv



# disable scientific notation
options(scipen=999)

EXP <- 'DUFA'
# carrego la taula
new_seqs <- read.table(paste0('Additional_sequences_',EXP,'.csv'),header = T,sep = ',')

# elimino la ultima columna 
new_seqs <- new_seqs[,-7]

# Carrego la taxonomy table de COInr
taxonomy <- read.csv('../COInr/taxonomy.tsv', sep="\t",comment.char = '"')

# els taxids que no existèixen els haig de editar
# si hi ha algun taxid NA el converteixo a -10000000 i seguint cap abaix

# busco que els taxid estiguin al taxonomy, tenint en compte que es una 
# versió antiga:
dim(new_seqs[!new_seqs$tax_id %in% taxonomy$tax_id,])
# [1] 3461    7
# hi ha 3461 que s'han de modificar
dufa_taxids <- 1000000000
dufa_news <- -1000000

# cambio els taxids majors a dufa_news a negatius però menors que -1000000
new_seqs$tax_id[new_seqs$tax_id>=dufa_taxids]  <- -(new_seqs$tax_id[new_seqs$tax_id>=dufa_taxids] - dufa_taxids) + dufa_news


# # s'haurà de crear un avís per si s'ha de modificat manualment
# manual_editing <- F
# manual_editing2 <- F


list_taxids <- unique(new_seqs$tax_id)
new_seqs$new_taxonomy <- F
new_seqs$manual_editing <- F

complete_taxids <- function(new_seqs,taxonomy,i){
  if (i %in% taxonomy$tax_id) {
    # suposit de que el tax_id està a taxonomy
    new_seqs$parent_tax_id <- taxonomy$parent_tax_id[taxonomy$tax_id == i][1]
    new_seqs$rank <- taxonomy$rank[taxonomy$tax_id == i][1]
  } else if (i %in% taxonomy$old_tax_id) {
    new_seqs$tax_id <- taxonomy$tax_id[which(taxonomy$old_tax_id == i)][1]
    new_seqs$parent_tax_id <- taxonomy$parent_tax_id[which(taxonomy$old_tax_id == i)][1]
    new_seqs$rank <- taxonomy$rank[which(taxonomy$old_tax_id == i)][1]
  } else {
    # si no està 
    # busca si tot el nom fa grep amb algun nom
    if (new_seqs$name_txt[1] %in% taxonomy$name_txt) {
      name_txt <- new_seqs$name_txt[1]
      new_seqs$parent_tax_id <- taxonomy$parent_tax_id[taxonomy$name_txt == name_txt][1]
      new_seqs$rank <- taxonomy$rank[taxonomy$name_txt == name_txt][1]
      new_seqs$tax_id <- taxonomy$tax_id[taxonomy$name_txt == name_txt][1]
    } else if (stringr::word(new_seqs$name_txt[1]) %in% taxonomy$name_txt) {
      # la primera paraula fa grep amb algun nom
      name_txt <- stringr::word(new_seqs$name_txt[1])
      new_seqs$parent_tax_id <- taxonomy$tax_id[taxonomy$name_txt == name_txt][1]
      new_seqs$rank <- ifelse(stringr::str_count(new_seqs$name_txt,"\\S+")>1,
                              "species",
                              "edit_manually")
      new_seqs$manual_editing <- T
    } else {
      # no hi ha track del parent
      message('no parent track for ',i)
      family_taxid <- suppressWarnings(as.numeric(new_seqs$name_txt[1]))
      if (!is.na(family_taxid) & family_taxid %in% taxonomy$tax_id) {
        new_seqs$parent_tax_id <- family_taxid
        new_seqs$rank <- "species"
      } else {
        new_seqs$parent_tax_id <- NA
        new_seqs$rank <- ifelse(stringr::str_count(new_seqs$name_txt,"\\S+")>1,
                                "species",
                                "edit_manually")
        new_seqs$new_taxonomy <- T
      }
    }
  }
  return(new_seqs)
}

taxonomy <- taxonomy[,c("tax_id","parent_tax_id","rank","name_txt","old_tax_id")]
library(parallel)
new_seqs_list <- mclapply(1:length(list_taxids),FUN = function(j) complete_taxids(new_seqs[new_seqs$tax_id==list_taxids[j],],taxonomy,i=list_taxids[j]),mc.cores = 4)
# no parent track for 51115
# no parent track for 6059
# no parent track for -1000064
# no parent track for -1000031
# no parent track for -1000035
# no parent track for -1000054
# no parent track for -1000222

print('new_seqs_list done')

save(file = 'data_DUFA.RData',list = c('new_seqs_list','taxonomy','new_seqs'))
# load('data_DUFA.RData')
new_seqs <- do.call('rbind',new_seqs_list)

# s'haurà de crear un avís per si s'ha de modificat manualment
manual_editing <- sum(new_seqs$manual_editing) >0
manual_editing2 <- sum(new_seqs$new_taxonomy) >0

# creo també el df new_taxonomy per afegir els taxids que vagi creant i que no tenen seq
new_taxonomy <- data.frame()
start <- -10000001
for (i in unique(new_seqs$tax_id[new_seqs$new_taxonomy])) {
  new_taxonomy <- rbind(new_taxonomy,
                        data.frame("tax_id"=c(start),
                                   "parent_tax_id"=c("edit_manually"),
                                   "rank"=c("genus"),
                                   "name_txt"=ifelse(is.na(new_seqs$name_txt[new_seqs$tax_id==i][1]),
                                                     i,
                                                     stringr::word(new_seqs$name_txt[new_seqs$tax_id==i][1]))))
  new_seqs$parent_tax_id[new_seqs$tax_id == i] <- start
  start <- start - 1
}


# for (j in 1:length(list_taxids)) {
#   i <- list_taxids[j]
#   if (c(j/100-trunc(j/100))==0) {
#     print(j)
#   }
#   if (i %in% taxonomy$tax_id) {
#     # suposit de que el tax_id està a taxonomy
#     new_seqs$parent_tax_id[new_seqs$tax_id==i] <- taxonomy$parent_tax_id[taxonomy$tax_id == i][1]
#     new_seqs$rank[new_seqs$tax_id==i] <- taxonomy$rank[taxonomy$tax_id == i][1]
#   } else {
#     # si no està 
#     # busca si tot el nom fa grep amb algun nom
#     if (new_seqs$name_txt[new_seqs$tax_id==i][1] %in% taxonomy$name_txt) {
#       name_txt <- new_seqs$name_txt[new_seqs$tax_id==i][1]
#       new_seqs$parent_tax_id[new_seqs$tax_id==i] <- taxonomy$parent_tax_id[taxonomy$name_txt == name_txt][1]
#       new_seqs$rank[new_seqs$tax_id==i] <- taxonomy$rank[taxonomy$name_txt == name_txt][1]
#       new_seqs$tax_id[new_seqs$tax_id==i] <- taxonomy$tax_id[taxonomy$name_txt == name_txt][1]
#     } else if (stringr::word(new_seqs$name_txt[new_seqs$tax_id==i][1]) %in% taxonomy$name_txt) {
#       # la primera paraula fa grep amb algun nom
#       name_txt <- stringr::word(new_seqs$name_txt[new_seqs$tax_id==i][1])
#       new_seqs$parent_tax_id[new_seqs$tax_id==i] <- taxonomy$tax_id[taxonomy$name_txt == name_txt][1]
#       new_seqs$rank[new_seqs$tax_id==i] <- ifelse(stringr::str_count(new_seqs$name_txt[new_seqs$tax_id==i],"\\S+")>1,
#                                                   "species",
#                                                   "edit_manually")
#       manual_editing <- T
#     } else {
#       # no hi ha track del parent
#       message('no parent track for ',i)
#       family_taxid <- suppressWarnings(as.numeric(new_seqs$name_txt[new_seqs$tax_id==i][1]))
#       if (!is.na(family_taxid) & family_taxid %in% taxonomy$tax_id) {
#         new_seqs$parent_tax_id[new_seqs$tax_id==i] <- family_taxid
#         new_seqs$rank[new_seqs$tax_id==i] <- "species"
#       } else {
#         new_seqs$parent_tax_id[new_seqs$tax_id==i] <- start
#         new_seqs$rank[new_seqs$tax_id==i] <- ifelse(stringr::str_count(new_seqs$name_txt[new_seqs$tax_id==i],"\\S+")>1,
#                                                     "species",
#                                                     "edit_manually")
#         new_taxonomy <- rbind(new_taxonomy,
#                               data.frame("tax_id"=c(start),
#                                          "parent_tax_id"=c("edit_manually"),
#                                          "rank"=c("genus"),
#                                          "name_txt"=ifelse(is.na(new_seqs$name_txt[new_seqs$tax_id==i][1]),
#                                                            i,
#                                                            stringr::word(new_seqs$name_txt[new_seqs$tax_id==i][1]))))
#         start <- start - 1
#         manual_editing2 <- T
#       }
#     }
#   }
# }
# taxids <- new_taxonomy$name_txt
# for (i in taxids) {
#   name <- new_taxonomy$tax_id[new_taxonomy$name_txt == i]
#   new_seqs$parent_tax_id[new_seqs$tax_id == i] <- name
# }
# aquelles seqs amb parent_rank es comprova que potser son especie
# for (i in which(grepl('parent_rank_',new_seqs$rank))) {
#   if (stringr::str_count(new_seqs$name_txt[i],"\\S+")>1) {
#     new_seqs$rank[i] <- "species"
#   }
# }
new_seqs$name_txt[which(new_seqs$rank=="edit_manually")]
# new_seqs$rank[which(new_seqs$name_txt=="Ophiurida")] <- "order"
library(worms)
for (i in which(new_seqs$rank=="edit_manually")) {
  if (!(new_seqs$name_txt[i] == "")) {
    new_seqs$rank[i] <- tryCatch(tolower(wormsbymatchnames(new_seqs$name_txt[i])[1,"rank"]),error = function(e) return(c("edit_manually")))
  }
}

# encara queda un
# new_seqs[which(grepl('parent_rank_',new_seqs$rank)),]
# seq_id    name_txt tax_id parent_tax_id              rank
# 33770 DUFA-COLR-000000000223488-H00000002 amily=56259 223488         30396 parent_rank_Buteo
# sequence
# 33770 ATTAGCTGGCAACATAGCCCATGCCGGAGCT...
# també es species
# new_seqs$rank[which(grepl('parent_rank_',new_seqs$rank)),] <- "species"

# aquelles seqs amb NA com a rank es comprova que potser son especie
# for (i in which(is.na(new_seqs$rank))) {
#   if (stringr::str_count(new_seqs$name_txt[i],"\\S+")>1) {
#     new_seqs$rank[i] <- "species"
#   }
# }


# finalment canvio el nom de les sequencies afegint 'NS_' de New_Sequence al nom de la sequencia

# new_seqs$seq_id <- paste0('NS_',new_seqs$seq_id)

# finalment haig d'eliminar els guions de les sequencies
new_seqs$sequence <- gsub("-","",new_seqs$sequence)

# finalment escric la taula

if (!c(manual_editing | manual_editing2)) {
  write.table(new_seqs, paste0('Additional_seqs_',EXP,'.tsv'),row.names = F,col.names = F,quote = F,sep = "\t")
} else {
  write.table(new_seqs, paste0('Additional_seqs_',EXP,'_correct_manually.tsv'),row.names = F,col.names = F,quote = F,sep = "\t")
  print("WARNING!!!! s'ha d'editar manualment els nous taxid")
}
if (manual_editing2) {
  write.table(new_taxonomy, paste0('Additional_taxids_manual_editing_',EXP,'.tsv'),row.names = F,col.names = T,quote = F,sep = "\t")
}

"el que faig a continuació és modificar manuelament els arxius i per aixo els 
copio i els canvio el nom afegint un _edited per si acas es sobre escrigués"

# Milleporina 
# Taxid 51115 was deleted on February 11, 2015. A més faig BLAST de la sequencia i em surt que es una Wanella milleporae
# canvio doncs la fila 75224 
# Wanella milleporae	432346	432345	species

# Halichondrida
# Taxid 6059 was deleted on January 13, 2016. 
# unaccepted a worms -> Heteroscleromorpha
# canvio doncs les files 99869 i 99870
# Heteroscleromorpha	1779146	6042	subclass
# Heteroscleromorpha	1779146	6042	subclass

# Pseudomyra mbizi
# cal generar nou tax-id per genere
# -10000003	6800	genus	Pseudomyra

# Ilia spinosa
# cal generar nou tax-id per genere
# -10000004	6800	genus	Ilia

# Colacodasya australica
# el taxonomy de COInr no el té però ja l'han afegit a NCBI aixi que utilitzo els seus taxids
# canvio la fila 174005
# Colacodasya australica	2978435	2978433	species
# cal generar nou tax-id per genere
# 2978433	31386	genus	Colacodasya

# Rodriguezella sp. 1LLG
# cal generar nou tax-id per genere i per la familia
# -10000006	-10000008	genus	Rodriguezella
# -10000008	2803	family	Rhodomelaceae

# Allocybaeina littlewalteri
# cal generar nou tax-id per genere i per la familia
# -10000007	-10000009	genus	Allocybaeina
# -10000009	134569	family	Cybaeidae

# finalment afegeixo les linies dels nous taxons al final:
# Pseudomyra	-10000003	6800	genus
# Ilia	-10000004	6800	genus
# Colacodasya	2978433	31386	genus
# Rodriguezella	-10000006	-10000008	genus
# Rhodomelaceae	-10000008	2803	family
# Allocybaeina	-10000007	-10000009	genus
# Cybaeidae	-10000009	134569	family

