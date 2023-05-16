
# el primer que he fet es agafar l'arxiu que em pasa el Jesus de 
# NIS_list_database.csv i l'he convertit a tsv amb les columnes 
#  "seq_id"       "species_name" "taxid"        "parent_taxid" "sequence" 
# també he fet que tots els No-id passessin a ser NA i que no posi els caràcters
# entre cometes.
# també he borrat totes les files que no tenien sequencia
# finalment afegeixo també una columna de rank


# disable scientific notation
options(scipen=999)

EXP <- 'NIS'
# carrego la taula
new_seqs <- read.table(paste0('Additional_sequences_',EXP,'.tsv'),header = T,quote = NULL,sep = '\t')

# Carrego la taxonomy table de COInr

taxonomy <- read.csv('../COInr/taxonomy.tsv', sep="\t",comment.char = '"')

# els taxids que no existèixen els haig de editar
# si hi ha algun taxid NA el converteixo a -10000000 i seguint cap abaix

# busco que els taxid estiguin al taxonomy:
dim(new_seqs[is.na(new_seqs$tax_id),])
# [1] 162   5
# hi ha 162 que s'han de modificar
start <- -11000000

# creo també el df new_taxonomy per afegir els taxids que vagi creant i que no tenen seq
new_taxonomy <- data.frame()
# s'haurà de crear un avís per si s'ha de modificat manualment
manual_editing <- F

for (i in unique(new_seqs$name_txt[is.na(new_seqs$tax_id)])) {
  if (i %in% taxonomy$name_txt) {
    # suposit de que el nom està a taxonomy
    new_seqs$tax_id[new_seqs$name_txt==i] <- taxonomy$tax_id[taxonomy$name_txt == i][1]
  } else {
    # si no està afegeix un nou taxid
    new_seqs$tax_id[new_seqs$name_txt==i] <- start
    start <- start - 1
    if (stringr::word(i,1) %in% taxonomy$name_txt) {
      # si el genere està afegeix el parent taxid
      new_seqs$parent_tax_id[new_seqs$name_txt==i] <- taxonomy$tax_id[taxonomy$name_txt == stringr::word(i,1)][1]
    } else {
      # si no està afegeix un nou taxid i a taxonomy crea un nou taxid que s'ha 
      # d'editar manualment 
      new_seqs$parent_tax_id[new_seqs$name_txt==i] <- start
      new_taxonomy <- rbind(new_taxonomy,
                            data.frame("tax_id"=c(start),
                                       "parent_tax_id"=c("edit_manually"),
                                       "rank"=c("genus"),
                                       "name_txt"=c(stringr::word(i,1))))
      start <- start - 1
      manual_editing <- T
    }
  }
}

# ara edito els parent taxids
for (i in unique(new_seqs$tax_id[is.na(new_seqs$parent_tax_id)])) {
  if (i %in% taxonomy$tax_id) {
    # en general els taxids estaran a la taxonomy
    new_seqs$parent_tax_id[new_seqs$tax_id==i] <- taxonomy$parent_tax_id[taxonomy$tax_id==i][1]
  } else {
    # pot ser que el taxid sigui nou o simplement no estigui a la taxonomia
    if (stringr::word(new_seqs$name_txt[new_seqs$tax_id==i][1],1) %in% taxonomy$name_txt) {
      # si el genere està afegeix el parent taxid
      new_seqs$parent_tax_id[new_seqs$tax_id==i] <- taxonomy$tax_id[taxonomy$name_txt == stringr::word(new_seqs$name_txt[new_seqs$tax_id==i][1],1)][1]
    } else {
      # si no està afegeix un nou taxid i a taxonomy crea un nou taxid que s'ha 
      # d'editar manualment 
      new_seqs$parent_tax_id[new_seqs$tax_id==i] <- start
      new_taxonomy <- rbind(new_taxonomy,
                            data.frame("tax_id"=c(start),
                                       "parent_tax_id"=c("edit_manually"),
                                       "rank"=c("genus"),
                                       "name_txt"=c(stringr::word(new_seqs$name_txt[new_seqs$tax_id==i][1],1))))
      start <- start - 1
      manual_editing <- T
    }
  }
  
}

# finalment canvio el nom de les sequencies afegint 'NS_' de New_Sequence al nom de la sequencia

new_seqs$seq_id <- paste0('NS_',new_seqs$seq_id)

# finalment haig d'eliminar els guions de les sequencies
new_seqs$sequence <- gsub("-","",new_seqs$sequence)

# finalment escric la taula
write.table(new_seqs, paste0('Additional_seqs_',EXP,'.tsv'),row.names = F,col.names = F,quote = F,sep = "\t")

if (manual_editing) {
  print("WARNING!!!! s'ha d'editar manualment els nous taxid")
  write.table(new_taxonomy, 'Additional_taxids_manual_editing_NIS.tsv',row.names = F,col.names = T,quote = F,sep = "\t")
}
