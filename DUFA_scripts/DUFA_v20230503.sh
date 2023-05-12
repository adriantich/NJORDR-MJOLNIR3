#!/bin/bash/

# this script shows how the current version of DUFA was obtained

# date 20230314

# activate conda

conda activate mkcoinr

# scripts_COInr=~/SOFT/mkCOInr/scripts/
scripts_COInr=~/mkCOInr/scripts/
# scripts_DUFA=~/NJORDR-MJOLNIR3/DUFA_scripts/
scripts_DUFA=~/Nextcloud/2_PROJECTES/NJORDR-MJOLNIR3/DUFA_scripts/
forward=GGWACWRGWTGRACWNTNTAYCCYCC
forward="-fw \"${forward}\""
# reverse=TANACYTCNGGRTGNCCRAARAAYCA
reverse=''
Date=2022_05_06
# add_seqs=DUFA_scripts/Additional_seqs.tsv
add_seqs=Additional_seqs.tsv
out_dir=~/TAXO/

# first download the COInr database. In this case only the taxonomy file will be used.

cd ${out_dir}

wget https://zenodo.org/record/6555985/files/COInr_${Date}.tar.gz
tar -zxvf COInr_${Date}.tar.gz
rm COInr_${Date}.tar.gz

mv COInr_${Date} COInr

# create new files in the correct format
Rscript ${scripts_DUFA}NJORDR_0.1_format_additional_seqs.R -i ${scripts_DUFA} -o ~/TAXO/
cat COInr/taxonomy.tsv ${add_seqs_dir}taxo_2join.tsv >taxonomy.tsv

# select region
perl ${scripts_COInr}select_region.pl -tsv DUFA.tsv -outdir . -e_pcr 1 ${forward} ${reverse} -identity 0 -tcov 0 -min_amplicon_length 299 -max_amplicon_length 320

# remove duplicates
Rscript ${scripts_DUFA}NJORDR_0.2_remove_duplicates.R -s trimmed.tsv -o trimmed_dereplicated.tsv


bash ${scripts_DUFA}NJORDR_1_from_COInr_to_dms.sh -c ~/TAXO/trimmed_dereplicated.tsv -t ~/TAXO/taxonomy.tsv -d ~/TAXO/DUFA -o COI_NJORDR
