#!/bin/bash/

# this script shows how the current version of DUFA was obtained

# date 20230314

# activate conda

conda activate mkcoinr

scripts_COInr=~/SOFT/mkCOInr/scripts/
scripts_DUFA=~/NJORDR-MJOLNIR3/DUFA_scripts/
forward=GGWACWRGWTGRACWNTNTAYCCYCC
forward="-fw \"${forward}\""
# reverse=TANACYTCNGGRTGNCCRAARAAYCA
reverse=''
Date=2022_05_06
out_dir=~/TAXO/TAXO_DUFA/

# first download the COInr database. In this case only the taxonomy file will be used.

cd ${out_dir}

wget https://zenodo.org/record/6555985/files/COInr_${Date}.tar.gz
tar -zxvf COInr_${Date}.tar.gz
rm COInr_${Date}.tar.gz

mv COInr_${Date} COInr

# create new files in the correct format
Rscript ${scripts_DUFA}NJORDR_0.1_format_additional_seqs.R -i ${scripts_DUFA} -o ${out_dir}
# cat COInr/taxonomy.tsv ${add_seqs_dir}taxo_2join.tsv >taxonomy.tsv
cat ../COInr/taxonomy.tsv ${out_dir}taxo_2join.tsv >taxonomy.tsv

# select region
perl ${scripts_COInr}select_region.pl -tsv DUFA.tsv -outdir . -e_pcr 1 ${forward} ${reverse} -identity 0 -tcov 0 -min_amplicon_length 299 -max_amplicon_length 320

# remove duplicates
Rscript ${scripts_DUFA}NJORDR_0.2_remove_duplicates.R -s trimmed.tsv -o trimmed_dereplicated.tsv


bash ${scripts_DUFA}NJORDR_1_from_COInr_to_dms.sh -c ${out_dir}trimmed_dereplicated.tsv -t ${out_dir}taxonomy.tsv -d ${out_dir}DUFA_07 -o COI_NJORDR


### to reduce size
cd ${out_dir}

obi cat -c ${out_dir}DUFA_07/COI_NJORDR/ref_db ${out_dir}COI_NJORDR/ref_db
obi import --taxdump ${out_dir}DUFA_07/taxdump_20230517 ${out_dir}COI_NJORDR/taxonomy/my_tax
# he hagut de copiar manualment al view el threshold
sed -i -e 's/"version":\t"3.0.1b23",/"version":\t"3.0.1b23",\n\t"ref_db_threshold":\t"0.70",/g' ${out_dir}COI_NJORDR.obidms/VIEWS/ref_db.obiview

cp ${scripts_DUFA}family_to_order.csv ${out_dir}.
cp ${scripts_DUFA}order.complete.csv ${out_dir}.
cp ${scripts_DUFA}genus_to_family.csv ${out_dir}.

echo FINISHED
