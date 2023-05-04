#!/bin/bash/

# This script will create a taxo_DMS that will be the version uploaded to DUFA repository.


Help()
{
   # Display Help
   echo "Creating a DMS object from Obitools3 for the Taxonomic assignment by THOR function from MJOLNIR3 from the COIrn DataDase"
   echo
   echo "Syntax: bash from_COInr_to_dms.sh [-h] [help] [-c] [coinr] [-t] [taxonomy] [-m] [taxdump] [-d] [out_dir] [-o] [obidms] [-n] [new_taxids]"
   echo "options:"
   echo "-h --help	  Print this Help."
   echo ""
   echo "-f --fasta_file  Fasta file path from with sequences for the database"
   echo ""
   echo "-t --taxdump	  name of the taxdump that will be used as taxonomic tree"
   echo ""
   echo "-o --obidms	  name of the obidms object for the THOR function from MJOLNIR3 'COI_NJORDR' by default"
   echo ""
}

while getopts hc:t:m:d:o:n: flag
do
    case "${flag}" in
	h) Help
		exit;;
	f) fasta_file="$( cd -P "$( dirname "${OPTARG}" )" >/dev/null 2>&1 && pwd )/$( echo ${OPTARG} | rev | cut -f1 -d '/' | rev )";;
	t) taxdump="${OPTARG}";;
	o) obidms="${OPTARG}";;
	\?) echo "usage: bash NJORDR_5_create_obidms.sh [-h|f|t|o]"
		exit;;
    esac
done

if [ -z "${coinr}" ]
 then
 echo 'ERROR! coinr (-c) needed'
 Help
 exit
 fi
if [ -z "${taxonomy}" ]
 then
 echo 'ERROR! taxonomy (-t) needed'
 Help
 exit
 fi
if [ -z "${taxdump}" ]
 then
 NEW_TAXDUMP=${out_dir}taxdump_$( date +"%Y%m%d" )/
 #echo 'ERROR! taxdump (-m) needed'
 # Help
 # exit
 else
 NEW_TAXDUMP=${out_dir}${taxdump}/
 fi
if [ -z "${out_dir}" ]
 then
 out_dir=$( pwd )/
 echo "output files will be printed in the ${out_dir} directory"
 fi
if [ -z "${obidms}" ]
 then
 obidms=${out_dir}COI_NJORDR
 echo "final obidms object will be named COI_NJORDR.obidms"
 else
 obidms=${out_dir}${obidms}
fi
if [ -z "${new_taxids}" ]
 then
 new_taxids=1000000000 # the highest taxid cannot exced 2,147,483,647
 echo "negative taxids will be turned into positive and added 1000000000"
fi

echo "coinr set as ${coinr}"
echo "taxonomy set as ${taxonomy}"
# echo "taxdump set as ${taxdump}"
echo "taxdump set as ${NEW_TAXDUMP}"
echo "out_dir set as ${out_dir}"
echo "obidms set as ${obidms}"
echo "new_taxids set as ${new_taxids}"



# see if the environment for Obitools is activated
# create try function
function try()
{
    [[ $- = *e* ]]; SAVED_OPT_E=$?
    set +e
}
# create catch function
function catch()
{
    export ex_code=$?
    (( $SAVED_OPT_E )) && set +e
    return $ex_code
}
# call obi --help and if does not work returns and error and exits
{ try; ( obi --help &>/dev/null &&  echo "obitools activated";  ); catch || {  echo "ERROR! obitools not activated"; exit ; }; }


echo "import fasta data into the obidms"
# now you can import the data
obi import --fasta-input ${COInr_FASTA} ${obidms}/ref_seqs

echo "fasta data imported into the obidms"
echo "import taxdump data into the obidms"

# import the taxdump (this can not be done if the DMS is not created)
obi import --taxdump ${NEW_TAXDUMP} ${obidms}/taxonomy/my_tax

echo "taxdump data imported into the obidms"

# taxdump information can be printed in txt format using obi less
# obi less DUFA_COI/taxonomy/my_tax >my_tax20210714.txt

# now we keep the sequences with taxid that are lower or equal rank to family
obi grep --require-rank=species --require-rank=genus --require-rank=family --taxonomy ${obidms}/taxonomy/my_tax ${obidms}/ref_seqs ${obidms}/ref_seqs_clean

echo "greped ref_seqs_clean"

# build the taxonomic reference database
obi build_ref_db -t 0.95 --taxonomy ${obidms}/taxonomy/my_tax ${obidms}/ref_seqs_clean ${obidms}/ref_db



