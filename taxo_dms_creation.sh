#!/bin/bash/

# This script will create a taxo_DMS that will be the version uploaded to DUFA repository.

# First load OBITOOLS3 environment

source ~/obi3-env/bin/activate


# import the reference database. 
# note that at the end of the sequence there can not be any space otherwise it will not upload the sequence.
sed -i -e 's/ $//g' DUFA_COLR_20210723.fasta

# also species name can not be a number
sed -i -e 's/ species_name=[0-9]*;//g' DUFA_COLR_20210723.fasta

# If it is the first time and no taxid has been added to the phylo-tree, all taxids from the ref. DB. have to be in the taxdump.
# this means that all sequences from DUFA_COLR_20210723.fasta with taxid>1,000,000,000 have to be in a separated file and to be added by obi addtaxid
grep -A 1 -P '=\d{10};' DUFA_COLR_20210723.fasta >DUFA_COLR_20210723_more_10digits.fasta
# it creates some '--' lines that have to be removed
sed -i -e '/--$/,+0d' DUFA_COLR_20210723_more_10digits.fasta

# then get the ones with taxids less than it
sed -e '/=[0-9]\{10\};/,+1d' DUFA_COLR_20210723.fasta >DUFA_COLR_20210723_less_10digits.fasta

# we can run the following command to count all sequences and lines and be sure the sum is coherent
# for i in DUFA_COLR_20210723* ; do echo $i ; grep '>' $i | wc -l ; wc -l $i ; done

# now you can import the data
obi import --fasta-input DUFA_COLR_20210723_less_10digits.fasta DUFA_COI/ref_seqs


# import the taxdump (this can not be done if the DMS is not created)
obi import --taxdump taxdump20210714.tar.gz DUFA_COI/taxonomy/my_tax

# taxdump information can be printed in txt format using obi less
obi less DUFA_COI/taxonomy/my_tax >my_tax20210714.txt

# now we keep the sequences with taxid that are lower or equal rank to family
obi grep --require-rank=species --require-rank=genus --require-rank=family --taxonomy DUFA_COI/taxonomy/my_tax DUFA_COI/ref_seqs DUFA_COI/ref_seqs_clean

# build the taxonomic reference database
obi build_ref_db -t 0.95 --taxonomy DUFA_COI/taxonomy/my_tax DUFA_COI/ref_seqs_clean DUFA_COI/ref_db



