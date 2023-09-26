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
   echo "Syntax: bash NJORDR_1_download_COInr.sh [-h] [help] [-D] [Date] [-d] [out_dir]"
   echo "options:"
   echo "-h --help	  Print this Help."
   echo ""
   echo "-D --Date	  Date of the COInr database update <year>_<month>_<day>. Default 2022_05_06"
   echo ""
   echo "-d --out_dir	  Optional, directory path of the output files. If not specified, ouput files will be "
   echo "		  printed in the current directory"
   echo ""
   echo "-a --add_seq	  Optional, additional sequences to add. Set file paths separated by commas. No column names allowed. Set the string within \"\""
   echo
}

while getopts hD:d:a: flag
do
    case "${flag}" in
	h) Help
		exit;;
	D) Date="${OPTARG}";;
	d) out_dir="$( cd -P "$( dirname "${OPTARG}" )" >/dev/null 2>&1 && pwd )/$( echo ${OPTARG%\/} | rev | cut -f1 -d '/' | rev )/";;
	a) add_seq=${OPTARG};;
	\?) echo "usage: bash NJORDR_1_download_COInr.sh [-h|D|d|a]"
		exit;;
    esac
done

# Get the path of the script
SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
RUN_PATH="$( pwd )"

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
if [ -z "${add_seq}" ]
 then
 add_sequences=""
 echo "no manual curated sequences added."
 else
 add_sequences="-a $( echo ${add_seq} | tr ' ' ',') -A ${RUN_PATH}"
 echo "the following sequences will be added"
 echo "$( ls $( echo ${add_seq} | tr ',' ' ' )) "
 fi

echo "Date set as ${Date}"
echo "out_dir set as ${out_dir}"


if [ ! -d ${out_dir} ]
 then
 mkdir ${out_dir} 
fi

# move to the output directory
cd ${out_dir}

if [ ! -d COInr ]
  then 
  # download COInr database
  wget https://zenodo.org/record/6555985/files/COInr_${Date}.tar.gz
  tar -zxvf COInr_${Date}.tar.gz
  rm COInr_${Date}.tar.gz
  mv COInr_${Date} COInr
else
  echo "COInr already exists"
fi

if [ ! -d NJORDR0.1_output ]
 then
 mkdir NJORDR0.1_output 
fi

Rscript ${SCRIPT_PATH}/NJORDR0.1.1_format_COInr.R ${add_sequences} -i COInr/COInr.tsv -o NJORDR0.1_output -r 
