#!/bin/bash/

# this script shows how the current version of NJORDR_COI was obtained

# date 202305

# activate conda
conda activate mkcoinr

##############################
### download COInr ###
##############################

# obtain files downloading COInr:
bash NJORDR_download_COInr.sh -D 2022_05_06 -d ~/TAXO/

##############################
### add sequences ###
##############################

# important files:
#
# COInr.tsv
# columns ->  seqID	taxID	sequence
#
# taxonomy.tsv
# columns ->  tax_id*	parent_tax_id*	rank*	name_txt*	old_tax_id	taxlevel	synonyms
# * mandatory fields

# upgrade the files with additional sequences
# in this case the Additional sequences have to follow a certain format
# The file also has to meet taxonomy.tsv taxids in case that some would have changed 
#
# A- tab separated columns
# B- no column names
# C- columns have to be:
#	1- sequence ID. suggested to begin with 'NS_' (New Sequence)
#	2- scientific name. suggested to begin with 'NS_' (New Sequence)
#	3- tax_id from NCBI or new. The latter has to be unique and lower than -10,000,000
#	4- parent_id from NCBI. If new parent_tax_id this will require manual editing of taxonomy.tsv file
#	5- rank. 'species' suggested
#	6- sequence
Rscript NJORDR_split_additional_seqs.R -a Additional_seqs.tsv
cat seqs_2join.tsv >>~/TAXO/COInr/COInr.tsv
cat taxo_2join.tsv >>~/TAXO/COInr/taxonomy.tsv

##############################
### prepare data ###
##############################

# select the region within primers
bash NJORDR_select_region.sh -s ~/SOFT/mkCOInr/scripts/ -f GGWACWRGWTGRACWNTNTAYCCYCC -r TANACYTCNGGRTGNCCRAARAAYCA -c ~/TAXO/COInr/COInr.tsv -d ~/TAXO/COInr/

# reduce data and format to obitools3
# - remove duplicates
# - select n sequences per taxid
# - addapt to obitools3
Rscript NJORDR_reduce_and_format.R -s ~/TAXO/COInr/trimmed.tsv -t ~/TAXO/COInr/taxonomy.tsv -c 19 -f ~/TAXO/COInr_v202305.fasta -T ~/TAXO/taxdump_COInr_v202305 -n 10 -x 1000000000


##############################
### create database.obidms ###
##############################

# obitools3 part to create the obidms object
bash NJORDR_create_obidms.sh -f ~/TAXO/COInr_v202305.fasta -t ~/TAXO/taxdump_COInr_v202305 -o ~/TAXO/COI_NJORDR -T 0.7





