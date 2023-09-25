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
# bash scripts/NJORDR0.1_download_COInr.sh -a ../DUFA_scripts/Additional_seqs_*

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
Rscript scripts/NJORDR0.2_complete_taxonomy.R -t TAXONOMY_TREE/taxonomy.tsv -i NJORDR0.1_output/NJORDR0.1_sequences.rds -c ${cores} -o COMPLETE_DB/NJORDR_format_completed.tsv -r -R
