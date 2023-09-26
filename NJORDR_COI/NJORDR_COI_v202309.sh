#!/bin/bash/

# this scritp started in sept 2023 will create a database containing COInr, DUFA, CESC, NIS and AWI sequences. 
# The number of sequences that will remain for each taxid will be a maximum of ten.

# define some variables
cores=3

# I create a folder with all the scripts that will be used
if [ ! -d scripts ]
 then
 mkdir scripts
fi

# Then I copy all the scripts that I will use
cp ../NJORDR_scripts/NJORDR0.1/COI/NJORDR0.1*COInr* scripts/.
cp ../NJORDR_scripts/NJORDR*_* scripts/.

# First download COInr data.
# This way also the tax tree is downloaded.
# bash scripts/NJORDR0.1_download_COInr.sh -a 'Manual_Curated_Sequences.tsv'

# separate the taxonomy tree

if [ ! -d TAXONOMY_TREE ]
 then
 mkdir TAXONOMY_TREE
 mv COInr/taxonomy.tsv TAXONOMY_TREE/.
fi


if [ ! -d COMPLETE_DB ]
 then
 mkdir COMPLETE_DB
fi

# complete the taxonomy file
# Rscript scripts/NJORDR0.2_complete_taxonomy.R -t TAXONOMY_TREE/taxonomy.tsv -i NJORDR0.1_output/NJORDR0.1_sequences.rds -c ${cores} -o COMPLETE_DB/NJORDR_format_completed.tsv -r -R

# once we have the whole database now we are going to select region and build the obitools3 database 

#### Main NJORDR pipeline

# 1 split the Data into 2 different files. the sequences and the taxonomic tree

# Rscript scripts/NJORDR1_split.R -s COMPLETE_DB/NJORDR_format_completed.rds -r -t TAXONOMY_TREE/taxonomy.tsv -T taxdump_202309 -n 1000000000


if [ ! -d SEQ_FORMATING ]
 then
 mkdir SEQ_FORMATING
fi

# 2 select the region within the Leray-XT primers -f GGWACWRGWTGRACWNTNTAYCCYCC -r TANACYTCNGGRTGNCCRAARAAYCA. However in this case we are going to use the Manual Curated Sequences to align the database and trim the sequences.

bash scripts/NJORDR2_select_region.sh -s ../mkCOInr/scripts/ -c COMPLETE_DB/NJORDR_sequences.tsv -d SEQ_FORMATING/ -B 'ManCurSeq_'
