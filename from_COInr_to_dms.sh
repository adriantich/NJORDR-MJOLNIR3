#!/bin/bash/

# This script will create a taxo_DMS that will be the version uploaded to DUFA repository.


Help()
{
   # Display Help
   echo "Creating a DMS object from Obitools3 for the Taxonomic assignment by THOR function from MJOLNIR3 from the COIrn DataDase"
   echo
   echo "Syntax: bash from_COInr_to_dms.sh [-h] [help] [-c] [coinr] [-t] [taxonomy] [-m] [taxdump] [-d] [out_dir] [-o] [obidms]"
   echo "options:"
   echo "-h --help	  Print this Help."
   echo ""
   echo "-c --coinr	  COInr.tsv file path from the COInr database"
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
	c) coinr="$( cd -P "$( dirname "${OPTARG}" )" >/dev/null 2>&1 && pwd )/${OPTARG}";;
	t) taxonomy="$( cd -P "$( dirname "${OPTARG}" )" >/dev/null 2>&1 && pwd )/${OPTARG}";;
	m) taxdump="$( cd -P "$( dirname "${OPTARG}" )" >/dev/null 2>&1 && pwd )/${OPTARG}/";;
	d) out_dir="$( cd -P "$( dirname "${OPTARG}" )" >/dev/null 2>&1 && pwd )/${OPTARG}/";;
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

script_dir="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )/"

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

# First activate OBITOOLS3 environment
# source ~/obi3-env/bin/activate

# delete the first line which is the colnames
awk 'NR>1' ${coinr} > ${COInr_TAXO}

# add '>' symbol at the beginning of each line
sed -i 's/^/>/' ${COInr_TAXO}

# add the taxid= tag
sed -i 's/\t/ taxid=/' ${COInr_TAXO}

# jump to next line each sequence
sed -i 's/\t/;\n/' ${COInr_TAXO}

# apply some changes to the file just in case
# note that at the end of the sequence there can not be any space otherwise it will not upload the sequence.
sed -i -e 's/ $//g' ${COInr_TAXO}

# we can run the following command to count all sequences and lines and be sure the sum is coherent
# for i in DUFA_COLR_20210723* ; do echo $i ; grep '>' $i | wc -l ; wc -l $i ; done

# The negative taxid have to be added to the taxdump
# The script COInr_negTaxid_to_taxdump.R will take the taxonomy file and retrieve two files that have to be concatenated to nodes.dmp and names.dmp from the taxdump
Rscript ${script_dir}COInr_negTaxid_to_taxdump.R -t ${COInr_TAXO} -d ${out_dir}

# Create the new taxdump with only the required files for Obitools3; names.dmp nodes.dmp delnodes.dmp & merged.dmp
# Join the created files in the previous step to the originals
if [ ! -d ${NEW_TAXDUMP} ]
 then
 mkdir ${NEW_TAXDUMP} 
fi

cp ${taxdump}merged.dmp ${NEW_TAXDUMP}.
cp ${taxdump}delnodes.dmp ${NEW_TAXDUMP}.
cat ${taxdump}nodes.dmp ${out_dir}nodes_2join.dmp >${NEW_TAXDUMP}nodes.dmp
cat ${taxdump}names.dmp ${out_dir}names_2join.dmp >${NEW_TAXDUMP}names.dmp

exit

# now you can import the data
obi import --fasta-input ${COInr_TAXO} ${obidms}/ref_seqs


# import the taxdump (this can not be done if the DMS is not created)
obi import --taxdump ${NEW_TAXDUMP} ${obidms}/taxonomy/my_tax

# taxdump information can be printed in txt format using obi less
# obi less DUFA_COI/taxonomy/my_tax >my_tax20210714.txt

# now we keep the sequences with taxid that are lower or equal rank to family
obi grep --require-rank=species --require-rank=genus --require-rank=family --taxonomy ${obidms}/taxonomy/my_tax ${obidms}/ref_seqs ${obidms}/ref_seqs_clean

# build the taxonomic reference database
obi build_ref_db -t 0.95 --taxonomy ${obidms}/taxonomy/my_tax ${obidms}/ref_seqs_clean DUFA_COI/ref_db



