#!/bin/bash/

# this script is meant to download the COInr database and trimm the fragments

Help()
{
   # Display Help
   echo "Creating a DMS object from Obitools3 for the Taxonomic assignment by THOR function from MJOLNIR3 from the COIrn DataDase"
   echo
   echo "Syntax: bash NJORDR_3_select_region.sh [-h] [help] [-s] [scripts_dir] [-f] [forward] [-r] [reverse] [-c] [sequences] [-d] [out_dir] [-m] [min_amplicon_length] [-M] [max_amplicon_length]"
   echo "options:"
   echo "-h --help	  Print this Help."
   echo ""
   echo "-s --scripts_dir Path to the mkCOInr scripts directory: <PATH>/mkCOInr/scripts"
   echo ""
   echo "-f --forward	  Forward primer"
   echo ""
   echo "-r --reverse	  Reverse primer"
   echo ""
   echo "-c --sequences	  File with sequences for the database"
   echo ""
   echo "-d --out_dir	  Optional, directory path of the output files. If not specified, ouput files will be "
   echo "		  printed in the current directory"
   echo ""
   echo "-m		  Minimum length for an amplicon after trimming. 299 default."
   echo "--min_amplicon_length"
   echo ""
   echo "-M		  Maximum length for an amplicon after trimming"
   echo "--max_amplicon_length"
   echo ""
}

while getopts hs:f:r:D:c:d:m:M: flag
do
    case "${flag}" in
	h) Help
		exit;;
	s) scripts_dir="$( cd -P "$( dirname "${OPTARG}" )" >/dev/null 2>&1 && pwd )/$( echo ${OPTARG%\/} | rev | cut -f1 -d '/' | rev )/";;
	f) forward="${OPTARG}";;
	r) reverse="${OPTARG}";;
	D) Date="${OPTARG}";;
	c) sequences="$( cd -P "$( dirname "${OPTARG}" )" >/dev/null 2>&1 && pwd )/$( echo ${OPTARG} | rev | cut -f1 -d '/' | rev )";;
	d) out_dir="$( cd -P "$( dirname "${OPTARG}" )" >/dev/null 2>&1 && pwd )/$( echo ${OPTARG%\/} | rev | cut -f1 -d '/' | rev )/";;
	m) min_amplicon_length="${OPTARG}";;
	M) max_amplicon_length="${OPTARG}";;
	\?) echo "usage: bash NJORDR_3_select_region.sh [-h|s|f|r|D|c|d|m|M]"
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
if [ -z "${sequences}" ]
 then
 echo "ERROR! sequence file not specified"
 Help
 exit
 fi
if [ -z "${out_dir}" ]
 then
 out_dir=$( pwd )/
 echo "output files will be printed in the ${out_dir} directory"
 fi
if [ -z "${min_amplicon_length}" ]
 then
 echo "WARING! min_amplicon_length not specified. 299 as default."
 min_amplicon_length="-min_amplicon_length 299"
 else
 min_amplicon_length="-min_amplicon_length ${min_amplicon_length}"
 fi
if [ -z "${max_amplicon_length}" ]
 then
 echo "WARING! max_amplicon_length not specified. 320 as default."
 max_amplicon_length="-max_amplicon_length 320"
 else
 max_amplicon_length="-max_amplicon_length ${max_amplicon_length}"
 fi

echo "scripts_dir set as ${scripts_dir}"
echo "forward primer set as ${forward}"
echo "reverse primer set as ${reverse}"
echo "min_amplicon_length set as ${min_amplicon_length}"
echo "max_amplicon_length set as ${max_amplicon_length}"
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

mkdir ${out_dir}/first_trimm
# first select from forward to the end
perl ${scripts_dir}select_region.pl -tsv ${sequences} -outdir ${out_dir}/first_trimm -e_pcr 1 ${forward} 

# then from reverse to the forward
perl ${scripts_dir}select_region.pl -tsv ${out_dir}/first_trimm/trimmed.tsv -outdir ${out_dir} -e_pcr 1 ${reverse} ${min_amplicon_length} ${max_amplicon_length}





