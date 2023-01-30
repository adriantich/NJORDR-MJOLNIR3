#!/bin/bash/

# This script will create a taxo_DMS that will be the version uploaded to DUFA repository.

# First load OBITOOLS3 environment

source ~/obi3-env/bin/activate


# import the reference database. If it is the first time and no taxid has been added to the phylo-tree, all taxids from the ref. DB. have to be in the taxdump.
# note that at the end of the sequence there can not be any space otherwise it will not upload the sequence.
# also species name can not be a number

# import the taxdump (this can not be done if the DMS is not created)

obi import --taxdump taxdump20210714.tar.gz DUFA_COI/taxonomy/my_tax

# following DUFA nomenclature until 2022, all taxid higher than 10,000,000 is not in the genebank so must be deleted at the beggining so it has to be added by obi addtaxids
# taxdump information can be printed in txt format using obi less

obi less DUFA_COI/taxonomy/my_tax >my_tax20210714.txt


