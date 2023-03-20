#!/bin/bash/

# this script is meant to download the COInr database and trimm the fragments

Help()
{
   # Display Help
   echo "Creating a DMS object from Obitools3 for the Taxonomic assignment by THOR function from MJOLNIR3 from the COIrn DataDase"
   echo
   echo "Syntax: bash from_COInr_to_dms.sh [-h] [help] [-s] [scripts_dir] [-f] [forward] [-r] [reverse] [-D] [Date] [-d] [out_dir]"
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
   echo "-d --out_dir	  Optional, directory path of the output files. If not specified, ouput files will be "
   echo "		  printed in the current directory"
   echo
}

while getopts hc:t:m:d:o: flag
do
    case "${flag}" in
	h) Help
		exit;;
	s) scripts_dir="$( cd -P "$( dirname "${OPTARG}" )" >/dev/null 2>&1 && pwd )/$( echo ${OPTARG} | rev | cut -f1 -d '/' | rev )/";;
	f) forward="${OPTARG}";;
	r) reverse="${OPTARG}";;
	D) Date="${OPTARG}";;
	d) out_dir="$( cd -P "$( dirname "${OPTARG}" )" >/dev/null 2>&1 && pwd )/$( echo ${OPTARG} | rev | cut -f1 -d '/' | rev )/";;
	\?) echo "usage: bash MOTUs_from_SWARM.sh [-h|s|f|r|D|d]"
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

echo "forward primer set as ${forward}"
echo "reverse primer set as ${reverse}"
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


if [ ! -d ${out_dir} ]
 then
 mkdir ${out_dir} 
fi

# move to the output firectory
cd ${out_dir}

wget https://zenodo.org/record/6555985/files/COInr_${Date}.tar.gz
tar -zxvf COInr_${Date}.tar.gz
rm COInr_${Date}.tar.gz

mv COInr_${Date} COInr


# perl ${script_dir}select_region.pl -tsv COInr/COInr.tsv -outdir COInr -e_pcr 1 -fw GGWACWRGWTGRACWNTNTAYCCYCC -min_amplicon_length 299 -max_amplicon_length 320
perl ${script_dir}select_region.pl -tsv COInr/COInr.tsv -outdir COInr -e_pcr 1 ${forward} ${reverse} -min_amplicon_length 299 -max_amplicon_length 320






