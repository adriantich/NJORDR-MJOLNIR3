#!/bin/bash/

# this script is meant to download the COInr database and trimm the fragments

Help()
{
   # Display Help
   echo "Creating a DMS object from Obitools3 for the Taxonomic assignment by THOR function from MJOLNIR3 from the COIrn DataDase"
   echo
   echo "Syntax: bash from_COInr_to_dms.sh [-h] [help] [-c] [coinr] [-t] [taxonomy] [-m] [taxdump] [-d] [out_dir] [-o] [obidms]"
   echo "options:"
   echo "-h --help	  Print this Help."
   echo ""
   echo "-c --coinr	  trimmed.tsv or COInr.tsv file path from the COInr database"
   echo ""
   echo "-t --taxonomy	  taxonomy.tsv file path from the COInr database"
   echo ""
   echo "-m --taxdump	  decompresed taxdump directory from NCBI"
   echo ""
   echo "-d --out_dir	  optional, directory path of the output files. If not specified, ouput files will be "
   echo "		  printed in the current directory"
   echo ""
   echo "-o --obidms	  name of the obidms object for the THOR function from MJOLNIR3 'COI_NJORDR' by default"
   echo
}

while getopts hc:t:m:d:o: flag
do
    case "${flag}" in
	h) Help
		exit;;
	c) coinr="$( cd -P "$( dirname "${OPTARG}" )" >/dev/null 2>&1 && pwd )/$( echo ${OPTARG} | rev | cut -f1 -d '/' | rev )";;
	t) taxonomy="$( cd -P "$( dirname "${OPTARG}" )" >/dev/null 2>&1 && pwd )/$( echo ${OPTARG} | rev | cut -f1 -d '/' | rev )";;
	m) taxdump="$( cd -P "$( dirname "${OPTARG}" )" >/dev/null 2>&1 && pwd )/$( echo ${OPTARG} | rev | cut -f1 -d '/' | rev )/";;
	d) out_dir="$( cd -P "$( dirname "${OPTARG}" )" >/dev/null 2>&1 && pwd )/$( echo ${OPTARG} | rev | cut -f1 -d '/' | rev )/";;
	o) obidms="$( cd -P "$( dirname "${OPTARG}" )" >/dev/null 2>&1 && pwd )/${OPTARG}";;
	\?) echo "usage: bash MOTUs_from_SWARM.sh [-h|c|t|m|d|o]"
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
 echo 'ERROR! taxdump (-m) needed'
 Help
 exit
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
fi

echo "coinr set as ${coinr}"
echo "taxonomy set as ${taxonomy}"
echo "taxdump set as ${taxdump}"
echo "out_dir set as ${out_dir}"
echo "obidms set as ${obidms}"



SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  TARGET="$(readlink "$SOURCE")"
  if [[ $TARGET == /* ]]; then
    SOURCE="$TARGET"
  else
    DIR="$( dirname "$SOURCE" )"
    SOURCE="$DIR/$TARGET" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
  fi
done

script_dir="$( cd -P "$( dirname "${SOURCE}" )" >/dev/null 2>&1 && pwd )/"

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


if [ ! -d ${out_dir} ]
 then
 mkdir ${out_dir} 
fi

COInr_TAXO=${out_dir}COInr.fasta
NEW_TAXDUMP=${out_dir}taxdump_$( date +"%Y%m%d" )/

if [ ${taxdump} == ${NEW_TAXDUMP} ]
 then
 NEW_TAXDUMP=${NEW_TAXDUMP//taxdump_/taxdump_new_}
 echo "WARNING! The new taxdump will be ${NEW_TAXDUMP}"
fi 

