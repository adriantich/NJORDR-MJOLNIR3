#!/bin/bash/

# this script is meant to create download two files that will be the ones used to obtain the database:
#
# COInr.tsv sequences of the reference database
# columns ->  seqID	taxID	sequence
#
# taxonomy.tsv phylogenetic information to create a taxonomic tree
# columns ->  tax_id*	parent_tax_id*	rank*	name_txt*	old_tax_id	taxlevel	synonyms
# * mandatory fields
#
# this files are tab separated.

# these files are downloaded from zenodo but can be created with mkCOInr

Help()
{
   # Display Help
   echo "Creating a DMS object from Obitools3 for the Taxonomic assignment by THOR function from MJOLNIR3 from the COIrn DataDase"
   echo
   echo "Syntax: bash NJORDR_1_download_COInr.sh [-h] [help] [-s] [scripts_dir] [-D] [Date] [-d] [out_dir]"
   echo "options:"
   echo "-h --help	  Print this Help."
   echo ""
   echo "-s --scripts_dir Path to the mkCOInr scripts directory: <PATH>/mkCOInr/scripts"
   echo ""
   echo "-D --Date	  Date of the COInr database update <year>_<month>_<day>. Default 2022_05_06"
   echo ""
   echo "-d --out_dir	  Optional, directory path of the output files. If not specified, ouput files will be "
   echo "		  printed in the current directory"
   echo
}

while getopts hs:D:d: flag
do
    case "${flag}" in
	h) Help
		exit;;
	s) scripts_dir="$( cd -P "$( dirname "${OPTARG}" )" >/dev/null 2>&1 && pwd )/$( echo ${OPTARG%\/} | rev | cut -f1 -d '/' | rev )/";;
	D) Date="${OPTARG}";;
	d) out_dir="$( cd -P "$( dirname "${OPTARG}" )" >/dev/null 2>&1 && pwd )/$( echo ${OPTARG%\/} | rev | cut -f1 -d '/' | rev )/";;
	\?) echo "usage: bash NJORDR_1_download_COInr.sh [-h|s|D|d]"
		exit;;
    esac
done

if [ -z "${scripts_dir}" ]
 then
 echo "ERROR! scripts directory not specified"
 Help
 exit
 fi
if [ -z "${Date}" ]
 then
 echo "Date not given, set as 2022_05_06"
 Date='2022_05_06'
 fi
if [ -z "${out_dir}" ]
 then
 out_dir=$( pwd )/
 echo "output files will be printed in the ${out_dir} directory"
 fi


echo "scripts_dir set as ${scripts_dir}"
echo "Date set as ${Date}"
echo "out_dir set as ${out_dir}"

# see if the environment for mkCOInr is activated trying to obtain the help from cutadapt
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
# call cutadapt --help and if does not work returns and error and exits
{ try; ( cutadapt --help &>/dev/null &&  echo "mkCOInr activated";  ); catch || {  echo "ERROR! mkCOInr not activated"; exit ; }; }


if [ ! -d ${out_dir} ]
 then
 mkdir ${out_dir} 
fi

# move to the output directory
cd ${out_dir}

# download taxonomy as in COInr database
# file created will be named taxonomy.tsv
perl ${scripts_dir}download_taxonomy.pl -outdir ${out_dir}


# download SILVA database
wget https://www.arb-silva.de/fileadmin/silva_databases/current/Exports/SILVA_138.1_SSURef_NR99_tax_silva_trunc.fasta.gz
tar -zxvf SILVA_138.1_SSURef_NR99_tax_silva_trunc.fasta.gz
rm SILVA_138.1_SSURef_NR99_tax_silva_trunc.fasta.gz

mv SILVA_138.1_SSURef_NR99_tax_silva_trunc.fasta SILVA_db.fasta

# download PR2 database
wget https://github.com/pr2database/pr2database/releases/download/v5.0.0/pr2_version_5.0.0_merged.xlsx
mv pr2_version_5.0.0_merged.xlsx PR2_db.xlsx









