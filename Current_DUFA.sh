#!/bin/bash/

# this script shows how the current version of DUFA was obtained

# date 20230314

# activate conda
__conda_setup="$('/home/usuaris/aantich/SOFT/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/usuaris/aantich/SOFT/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/home/usuaris/aantich/SOFT/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/usuaris/aantich/SOFT/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup

conda activate mkcoinr

bash download_COInr_20220506.sh -s ~/SOFT/mkCOInr/scripts/ -f GGWACWRGWTGRACWNTNTAYCCYCC -d ~/TAXO/

bash from_COI_to_dms.sh -c ~/TAXO/COInr/trimmed.tsv -t ~/TAXO/COInr/taxonomy.tsv -m TAXO/taxdmp_2022-05-01 -d ~/TAXO/DUFA -o COI_NJORDR
