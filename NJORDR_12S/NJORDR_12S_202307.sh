#!/bin/bash/

# this script is the one used to obtain the reference database for 12S barcode

scripts_COInr=~/SOFT/mkCOInr/scripts/
scripts_12S=~/NJORDR-MJOLNIR3/NJORDR_12S/
forward=GCCGGTAAAACTCGTGCCAGC
forward="-fw \"${forward}\""
reverse=CATAGTGGGGTATCTAATCCCAGTTTG
reverse="-rv \"${reverse}\""
Date=2022_05_06
out_dir=~/TAXO/TAXO_12S/
cores=19
min_lentgh=140
max_length=190

# first download the COInr database. In this case only the taxonomy file will be used.

cd ${out_dir}

wget https://zenodo.org/record/6555985/files/COInr_${Date}.tar.gz
tar -zxvf COInr_${Date}.tar.gz
rm COInr_${Date}.tar.gz

mv COInr_${Date} COInr

# create new files in the correct format
Rscript ${scripts_12S}NJORDR0.1_Local_format.R -s ${scripts_12S}MiFish_owen/DUFA_MiFish_20220106.fasta -o ${scripts_12S}Local_formated.tsv
Rscript ${scripts_12S}NJORDR0.1_MiFish_format.R -s ${scripts_12S}mitogeno_and_partial/mito-all -o ${scripts_12S}MiFish_formated.tsv
Rscript ${scripts_12S}NJORDR0.1_MareMage_format.R -s ${scripts_12S}mare_mage/12sDB.fasta -t ${scripts_12S}mare_mage/12sDB_taxonomy.txt -o ${scripts_12S}MareMage_formated.tsv
# join all of them into only one
cat ${scripts_12S}Local_formated.tsv >${scripts_12S}NJORDR_format.tsv
tail -n+2 ${scripts_12S}MiFish_formated.tsv >>${scripts_12S}NJORDR_format.tsv
tail -n+2 ${scripts_12S}MareMage_formated.tsv >>${scripts_12S}NJORDR_format.tsv

Rscript ${scripts_12S}NJORDR0.2_complete_taxonomy.R -t ${out_dir}COInr/taxonomy.tsv -i ${out_dir}NJORDR_format.tsv -c ${cores} -o ${out_dir}NJORDR_format_completed.tsv

Rscript ${scripts_12S}NJORDR1_split.R -s ${out_dir}NJORDR_format_completed.tsv -t ${out_dir}COInr/taxonomy.tsv -T ${out_dir}taxdump

bash ${scripts_12S}NJORDR2_select_region.sh -s ${scripts_COInr} -f GGWACWRGWTGRACWNTNTAYCCYCC -r TANACYTCNGGRTGNCCRAARAAYCA -c ~/TAXO/TAXO_12S/NJORDR_sequences.tsv -d ~/TAXO/TAXO_12S/ -m ${min_lentgh} -M ${max_length}


