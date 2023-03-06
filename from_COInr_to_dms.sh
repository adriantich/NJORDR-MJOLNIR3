#!/bin/bash/

# This script will create a taxo_DMS that will be the version uploaded to DUFA repository.

# First load OBITOOLS3 environment

source ~/obi3-env/bin/activate

# delete the first line which is the colnames
awk 'NR>1' prova_COInr.tsv > prova_COInr.fasta

# add '>' symbol at the beginning of each line
sed -i 's/^/>/' prova_COInr.fasta

# add the taxid= tag
sed -i 's/\t/ taxid=/' prova_COInr.fasta

# jump to next line each sequence
sed -i 's/\t/;\n/' prova_COInr.fasta

# apply some changes to the file just in case
# note that at the end of the sequence there can not be any space otherwise it will not upload the sequence.
sed -i -e 's/ $//g' prova_COInr.fasta

# we can run the following command to count all sequences and lines and be sure the sum is coherent
# for i in DUFA_COLR_20210723* ; do echo $i ; grep '>' $i | wc -l ; wc -l $i ; done

# The negative taxid have to be added to the taxdump
# The script COInr_negTaxid_to_taxdump.R will take the taxonomy file and retrieve two files that have to be concatenated to nodes.dmp and names.dmp from the taxdump
Rscript COInr_negTaxid_to_taxdump.R

# Join the file to the taxdump


# now you can import the data
obi import --fasta-input DUFA_COLR_20210723_less_10digits.fasta DUFA_COI/ref_seqs


# import the taxdump (this can not be done if the DMS is not created)
obi import --taxdump taxdump20210714.tar.gz DUFA_COI/taxonomy/my_tax

# taxdump information can be printed in txt format using obi less
# obi less DUFA_COI/taxonomy/my_tax >my_tax20210714.txt

# now we keep the sequences with taxid that are lower or equal rank to family
obi grep --require-rank=species --require-rank=genus --require-rank=family --taxonomy DUFA_COI/taxonomy/my_tax DUFA_COI/ref_seqs DUFA_COI/ref_seqs_clean

# build the taxonomic reference database
obi build_ref_db -t 0.95 --taxonomy DUFA_COI/taxonomy/my_tax DUFA_COI/ref_seqs_clean DUFA_COI/ref_db



