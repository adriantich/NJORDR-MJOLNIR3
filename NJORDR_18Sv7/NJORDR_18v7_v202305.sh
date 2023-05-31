#!/bin/bash/

# this script shows how the current version of NJORDR_COI was obtained

# date 202305

# activate conda
conda activate mkcoinr

##############################
### download COInr ###
##############################

# obtain files downloading COInr:
bash NJORDR_download_18S.sh -s ~/SOFT/mkCOInr/scripts/ -D 2022_05_06 -d ~/TAXO/TAXO_18S/

##############################
### add sequences ###
##############################


mkdir ~/TAXO/TAXO_COI/
Rscript NJORDR_split_additional_seqs.R -a Additional_seqs.tsv
cat ~/TAXO/COInr/COInr.tsv seqs_2join.tsv >~/TAXO/TAXO_COI/COInr.tsv
cat ~/TAXO/COInr/taxonomy.tsv taxo_2join.tsv >~/TAXO/TAXO_COI/taxonomy.tsv

##############################
### prepare data ###
##############################

# select the region within primers
# set the reverse at it is. The script will perform the reverse-complementary automatically which is the one that cutadapt will use. (TGRTTYTTYGGNCAYCCNGARGTNTA)
bash NJORDR_select_region.sh -s ~/SOFT/mkCOInr/scripts/ -f GGWACWRGWTGRACWNTNTAYCCYCC -r TANACYTCNGGRTGNCCRAARAAYCA -c ~/TAXO/TAXO_COI/COInr.tsv -d ~/TAXO/TAXO_COI/

# reduce data and format to obitools3
# - remove duplicates
# - select n sequences per taxid
# - addapt to obitools3
Rscript NJORDR_reduce_and_format.R -s ~/TAXO/TAXO_COI/trimmed.tsv -t ~/TAXO/TAXO_COI/taxonomy.tsv -c 19 -f ~/TAXO/TAXO_COI/COInr_v202305.fasta -T ~/TAXO/TAXO_COI/taxdump_COInr_v202305 -n 10 -x 1000000000


##############################
### create database.obidms ###
##############################

# obitools3 part to create the obidms object
bash NJORDR_create_obidms.sh -f ~/TAXO/TAXO_COI/COInr_v202305.fasta -t ~/TAXO/TAXO_COI/taxdump_COInr_v202305 -o ~/TAXO/TAXO_COI/COI_NJORDR -T 0.7

# create a smaller version
mkdir ~/TAXO/TAXO_COI/SMALL/
obi cat -c ~/TAXO/TAXO_COI/COI_NJORDR/ref_db ~/TAXO/TAXO_COI/SMALL/COI_NJORDR/ref_db
obi import --taxdump ~/TAXO/TAXO_COI/taxdump_COInr_v202305 ~/TAXO/TAXO_COI/SMALL/COI_NJORDR/taxonomy/my_tax
# he hagut de copiar manualment al view el threshold
sed -i -e 's/"version":\t"3.0.1b23",/"version":\t"3.0.1b23",\n\t"ref_db_threshold":\t"0.70",/g' ~/TAXO/TAXO_COI/SMALL/COI_NJORDR.obidms/VIEWS/ref_db.obiview

# copy additional files for THOR's MJOLNIR3 function
cp order.complete.csv family_to_order.csv genus_to_family.csv ~/TAXO/TAXO_COI/SMALL/.





