#!/bin/bash/

# this script is meant to download the COInr database and trimm the fragments

Help()
{
   # Display Help
   echo "Creating a DMS object from Obitools3 for the Taxonomic assignment by THOR function from MJOLNIR3 from the COIrn DataDase"
   echo
   echo "Syntax: bash from_COInr_to_dms.sh [-h] [help] [-s] [scripts_dir] [-f] [forward] [-r] [reverse] [-a] [add_seqs] [-D] [Date] [-d] [out_dir]"
   echo "options:"
   echo "-h --help	  Print this Help."
   echo ""
   echo "-s --scripts_dir Path to the mkCOInr scripts directory: <PATH>/mkCOInr/scripts"
   echo ""
   echo "-f --forward	  Forward primer"
   echo ""
   echo "-r --reverse	  Reverse primer"
   echo ""
   echo "-D --Date	  Date of the COInr database update <year>_<month>_<day>. Default 2022_05_06"
   echo ""
   echo "-a --add_seqs	  Path to the Additional sequences. "
   echo "		  The file MUST:"
   echo "		  	A- tab separated columns"
   echo "		  	B- no column names"
   echo "		  	C- columns have to be:"
   echo "		  		1- sequence ID. suggested to begin with 'NS_' (New Sequence)"
   echo "		  		2- scientific name. suggested to begin with 'NS_' (New Sequence)"
   echo "		  		3- tax_id from NCBI or new. The latter has to be unique and lower than -10,000,000"
   echo "		  		4- parent_id from NCBI. If new parent_tax_id this will require manual editing of taxonomy.tsv file"
   echo "		  		5- rank. 'species' suggested"
   echo "		  		6- sequence"
   echo ""
   echo ""
   echo "-d --out_dir	  Optional, directory path of the output files. If not specified, ouput files will be "
   echo "		  printed in the current directory"
   echo
}

while getopts hs:f:r:D:a:d:o: flag
do
    case "${flag}" in
	h) Help
		exit;;
	s) scripts_dir="$( cd -P "$( dirname "${OPTARG}" )" >/dev/null 2>&1 && pwd )/$( echo ${OPTARG%\/} | rev | cut -f1 -d '/' | rev )/";;
	f) forward="${OPTARG}";;
	r) reverse="${OPTARG}";;
	D) Date="${OPTARG}";;
	a) add_seqs="$( cd -P "$( dirname "${OPTARG}" )" >/dev/null 2>&1 && pwd )/$( echo ${OPTARG} | rev | cut -f1 -d '/' | rev )";;
	d) out_dir="$( cd -P "$( dirname "${OPTARG}" )" >/dev/null 2>&1 && pwd )/$( echo ${OPTARG%\/} | rev | cut -f1 -d '/' | rev )/";;
	\?) echo "usage: bash NJORDR_0_download_COInr.sh [-h|s|f|r|D|a|d]"
		exit;;
    esac
done

if [ -z "${scripts_dir}" ]
 then
 echo "ERROR! scripts directory not specified"
 Help
 exit
 fi
if [ -z "${forward}" ]
 then
 echo "WARING! forward primer not specified. No trimm will be performed at the 5' end"
 forward=''
 else
 forward="-fw ${forward}"
 fi
if [ -z "${reverse}" ]
 then
 echo "WARING! reverse primer not specified. No trimm will be performed at the 3' end"
 reverse=''
 else
 reverse="-rv ${reverse}"
 fi
if [ -z "${add_seqs}" ]
 then
 echo "No Additional sequences"
 ADD_SEQ=false
 else
 ADD_SEQ=true
 add_seqs_dir="$( cd -P "$( dirname "${add_seqs}" )" >/dev/null 2>&1 && pwd )/"
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
echo "forward primer set as ${forward}"
echo "reverse primer set as ${reverse}"
echo "add_seqs set as ${add_seqs}"
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
# call obi --help and if does not work returns and error and exits
{ try; ( cutadapt --help &>/dev/null &&  echo "mkCOInr activated";  ); catch || {  echo "ERROR! mkCOInr not activated"; exit ; }; }

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

script_dir_NJORDR="$( cd -P "$( dirname "${SOURCE}" )" >/dev/null 2>&1 && pwd )/scripts/"

if [ ! -d ${out_dir} ]
 then
 mkdir ${out_dir} 
fi

# move to the output directory
cd ${out_dir}

# download COInr database
wget https://zenodo.org/record/6555985/files/COInr_${Date}.tar.gz
tar -zxvf COInr_${Date}.tar.gz
rm COInr_${Date}.tar.gz

mv COInr_${Date} COInr

# add additional sequences to COInr
if $ADD_SEQ
then
 Rscript ${script_dir_NJORDR}NJORDR_0.1_split_additional_seqs.R -a ${add_seqs}
 cat ${add_seqs_dir}seqs_2join.tsv >>COInr/COInr.tsv
 cat ${add_seqs_dir}taxo_2join.tsv >>COInr/taxonomy.tsv
fi
 
# perl ${script_dir}select_region.pl -tsv COInr/COInr.tsv -outdir COInr -e_pcr 1 -fw GGWACWRGWTGRACWNTNTAYCCYCC -min_amplicon_length 299 -max_amplicon_length 320
perl ${scripts_dir}select_region.pl -tsv COInr/COInr.tsv -outdir COInr -e_pcr 1 ${forward} ${reverse} -min_amplicon_length 299 -max_amplicon_length 320

# remove duplicates
Rscript ${script_dir_NJORDR}NJORDR_0.2_remove_duplicates.R -s COInr/trimmed.tsv -o COInr/trimmed_dereplicated.tsv




