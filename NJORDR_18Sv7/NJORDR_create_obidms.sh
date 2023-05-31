#!/bin/bash/

# This script will create a taxo_DMS that will be the version uploaded to DUFA repository.


Help()
{
   # Display Help
   echo "Creating a DMS object from Obitools3 for the Taxonomic assignment by THOR function from MJOLNIR3 from the COIrn DataDase"
   echo
   echo "Syntax: bash from_COInr_to_dms.sh [-h] [help] [-f] [fasta_file] [-t] [taxdump] [-o] [obidms] [-T] [threshold]"
   echo "options:"
   echo "-h --help	  Print this Help."
   echo ""
   echo "-f --fasta_file  Fasta file path from with sequences for the database"
   echo ""
   echo "-t --taxdump	  name of the taxdump that will be used as taxonomic tree"
   echo ""
   echo "-o --obidms	  name of the obidms object for the THOR function from MJOLNIR3 'COI_NJORDR' by default"
   echo ""
   echo "-T --threshold	  Score threshold as a normalized identity, e.g. 0.95 for an identity of 95%. Default 0.7"
   echo ""
}

while getopts hf:t:o:T: flag
do
    case "${flag}" in
	h) Help
		exit;;
	f) fasta_file="$( cd -P "$( dirname "${OPTARG}" )" >/dev/null 2>&1 && pwd )/$( echo ${OPTARG} | rev | cut -f1 -d '/' | rev )";;
	t) taxdump="${OPTARG}";;
	o) obidms="${OPTARG}";;
	T) threshold=${OPTARG};;
	\?) echo "usage: bash NJORDR_5_create_obidms.sh [-h|f|t|o|T]"
		exit;;
    esac
done

if [ -z "${fasta_file}" ]
 then
 echo 'ERROR! fasta_file (-f) needed'
 Help
 exit
 fi
if [ -z "${taxdump}" ]
 then
 echo 'ERROR! taxdump (-t) needed'
 Help
 exit
 fi
if [ -z "${obidms}" ]
 then
 obidms=COI_NJORDR
 echo "final obidms object will be named COI_NJORDR.obidms"
fi
if [ -z "${threshold}" ]
 then
 threshold=0.7 # the highest taxid cannot exced 2,147,483,647
 echo "the threshold used to build the reference data base will be 0.7"
fi

echo "fasta_file set as ${fasta_file}"
echo "taxdump set as ${taxdump}"
echo "obidms set as ${obidms}"
echo "threshold set as ${threshold}"



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
obi import --fasta-input ${fasta_file} ${obidms}/ref_seqs

echo "fasta data imported into the obidms"
echo "import taxdump data into the obidms"

# import the taxdump (this can not be done if the DMS is not created)
obi import --taxdump ${taxdump} ${obidms}/taxonomy/my_tax

echo "taxdump data imported into the obidms"

# taxdump information can be printed in txt format using obi less
# obi less DUFA_COI/taxonomy/my_tax >my_tax20210714.txt

# now we keep the sequences with taxid that are lower or equal rank to family
# obi grep --require-rank=species --require-rank=genus --require-rank=family --taxonomy ${obidms}/taxonomy/my_tax ${obidms}/ref_seqs ${obidms}/ref_seqs_clean
obi grep --require-rank=family --taxonomy ${obidms}/taxonomy/my_tax ${obidms}/ref_seqs ${obidms}/ref_seqs_clean
# the grep option with require_rank does an and and not and or which makes a loose of some sequences that could be assign only to family or genus

echo "greped ref_seqs_clean"

# build the taxonomic reference database
obi build_ref_db -t ${threshold} --taxonomy ${obidms}/taxonomy/my_tax ${obidms}/ref_seqs_clean ${obidms}/ref_db



