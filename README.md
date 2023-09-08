# NJORDR-MJOLNIR3
Names Joining into Ordered Database with R for MJOLNIR3 pipeline

This project to create a Reference DataBase for THOR-MJOLNIR3 function to perform the taxonomic assignment of metabarcoding Data.

This project is intended to create a pipeline extrapolable to any barcode but we provide both the databases and the scripts to create them for the following barcodes:
- COI
  - Leray-XT segment of the COI marker.
      - DUFA v202305

        This database is created with sequences from BOLD, NCBI and local sequences of four different projects. Initial files contain the following sequences
        - DUFA -> 174,544 sequences
        - AWI -> 306 sequences
        - CESC -> 764 sequences
        - NIS -> 6,008 sequences
        
        The total number of sequences was 181,622 sequences. However, after cleaning steps, it ended up in 148,932 sequences.

        https://drive.google.com/drive/folders/1ZFKwXjAlhUy-6ChN5hqGjM6LLUi9JPNn?usp=drive_link

        Instructions: download the full TAXO_DUFA directory and set the following parameters from mjolnir5_THOR function to:
        - tax_dir = 'PATH/TO/DIRECTORY/TAXO_DUFA'
        - tax_dms_name = 'COI_NJORDR'
        - minimum_circle = 0.7
     - NJODRD_COI -> Under developing
- 18S
  - v7 with All_shorts primers (Guardiola et al. 2015)  
    - NJORDR_18Sv7 -> Under developing
  - v1v2 with primers SSU_F04 (Blaxter et al., 1998) and SSURmod (Sinniger et al., 2016)
    - NJORDR_18Sv1v2 -> Future project
- 12S
  - MiFish fragment with MiFish primers (Miya et al. 2015)
    - NJORDR_12S -> Future project

<H2>The NJORDR Workflow</H2>

This is a simplified scheme of the NJORDR workflow:

<p align="center" width="400">
  <img src="https://github.com/adriantich/NJORDR-MJOLNIR3/blob/main/workflow_NJORDR.png">
</p>

<H3>DESCRIPTION</H3>
The forkflow of the NJORDR pipeline consists in 5 steps descrived below. However, as NJORDR is intended to be a package to create reference databases for different markers, there are some steps that will be standard for all markers but the first part of the step-0 and the step-2 will require special adaptation to each case.

<H4>STEP-0 - To obtain a formated sequence database and the phylogenetic tree.</H4>
In this step the final goal is to obtain a uniq .tsv file that contains the taxonomic information of the database based on the tax_id and parent_tax_id to assign each sequence to a branch of the phylogenetic tree. The whole taxonomic tree is then used both for the following steps to create the Taxdump object (The object with all the tree in the required format dor obitools3) and to complete or correct the information in our database.

  - To obtain the taxonomic tree you can [create it](https://mkcoinr.readthedocs.io/en/latest/content/tutorial.html#create-coinr-from-bold-and-ncbi) or download it directly (recomended). NJORDR will follow the format of mkCOInr taxonomy.tsv file to only use an standardised intitial file. This format also allows to distinguish between tax_id's that are in the NCBI and the new tax_id's that are not present (at this point, negative tax_id's). You can download the [taxonomy.csv from drive](https://drive.google.com/drive/folders/1JIFiPtvwMzk6S8zYnjNU251UbMwg6cSF?usp=sharing) or as specified in mkCOInr.

        cd NJORDR-MJOLNIR3
        mkdir TAXONOMY_TREE
        cd TAXONOMY_TREE
        wget https://zenodo.org/record/6555985/files/COInr_2022_05_06.tar.gz
        tar -zxvf COInr_2022_05_06.tar.gz
        rm COInr_2022_05_06.tar.gz
        mv COInr_2022_05_06/taxonomy.tsv .
        rm -r COInr_2022_05_06

 - To format the prefered database. This point consists in two separate substeps.
     * The first, **NJORDR0.1**, has to be adjusted to each database but can be done also manually. See readme of each one of them for more detail. This process consist on creating a csv file with the following columns *seq_id / name_txt / tax_id / parent_tax_id / rank / sequence*. This fields can be empty for some sequences but don't worry, during the following substep this will be completed. However, be aware that seq_id must be a unique identifier for each sequence.
     * The second, **NJORDR0.2**, is a standard script for all markers. Here, if one sequence has the tax_id but misses the name_txt, the parent_tax_id or the rank, those will be completed. Also if the tax_id has been deprecated, it will be updated to the version of the taxonomy.tsv file. If the tax_id is missing, this script will use the name to find the tax_id in the taxonomic tree or will create a new tax_id and attach it to the genus tax_id. If no match is found, then the output file will have the sufix *_to_correct.tsv* and it will require checking for **correct_manually** tags and correct them manually. At the end is possible that some rows contains only the fields *name_txt / tax_id / parent_tax_id / rank*; these are intermediate taxonomic levels.

           # help
           -t --taxonomy_input    taxonomy tab file with colnames [tax_id	parent_tax_id	rank	name_txt	old_tax_id	taxlevel	synonyms]
           -i --sequence_input    name of the input file for the sequences in tsv format to be completed
           -c --cores             number or cores to run the process in parallel. 1 default
           -o --sequence_output   name of the output file for the sequences in tsv format


<H4>STEP-1 - To obtain two separated files, the sequence file and the taxdump.</H4>
This step is the number one because from here on, the database will be build on the obitools3 format but no more sequences will be added. This means that the previous step can be seen as the standarisation of the reference database into a single file and the folloring steps as the ones to build the database to be used. Until new updates, all changes to the database will have to be done in the step-0 and then run the following four.

  - **NJORDR1** will take the database_taxonomy_complete.tsv file and the taxonomy.tsv file with the phylogenetic tree and will create the sequence_db.tsv, with only the sequences, their seq_id and their tax_id, and the Taxdump object, this contains four files required by obitools3 to build the taxonomy tree.

        # help
        -s --sequence_input      sequence tab file in NJORDR format.
                                        colnames: seq_id name_txt tax_id parent_tax_id parent_name_txt(optional) rank sequence
        -t --taxonomy_input      taxonomy tab file with colnames [tax_id	parent_tax_id	rank	name_txt	old_tax_id	taxlevel	synonyms]
        -T --taxdump_output      output taxdump
        -n --new_taxids          Number from which start the notation for new taxids. Since new taxids (not represented in NCBI) are set as negative,
                                        they must be turned into positive and to be sure they do not have the same number as an existing taxid, they
                                        will be higher than this value. However, the highest taxid cannot exced 2,147,483,647 (obitools3 limitations)

<H4>STEP-2 - To select the region of the fragment.</H4>
This step is still in development. However, it has to have special inputs depending on the primers used. 

  - **NJORDR2** has as input the sequence_db.tsv file and will retrieve a trimmed version of it, sequence_db_trimmed.tsv

        



<H2>INSTALLATION</H2>

NJORDR runs on linux using conda environment. Most of the code is in R and bash. To install the depencies follow the next steps:

- Create a conda environment ([click here to see how to install miniconda](https://docs.conda.io/en/latest/miniconda.html)). If you have installed [MJOLNIR3](https://github.com/adriantich/MJOLNIR3) following the tutorial, you can use the same environment.

      # with conda previously installed
      # Create conda enviroment
      conda create -n mjolnir3 python=3.9
      # to activate the environment tipe
      conda activate mjolnir3

- Clone NJORDR repository

      git clone https://github.com/adriantich/NJORDR-MJOLNIR3.git

- Install [mkCOInr](https://mkcoinr.readthedocs.io/en/latest/content/installation.html) and dependencies

      cd NJORDR-MJOLNIR3
      python3 -m pip install cutadapt
      conda install -c bioconda blast -y
      conda install -c bioconda vsearch -y
      pip install nsdpy
      git clone https://github.com/meglecz/mkCOInr.git


Previous versions: 

https://drive.google.com/drive/folders/1GUmPjNlBobIv4OMdB1i1Yf0_HKVkN0T6?usp=share_link

- v20210723 -> 139,082 sequences 
- DUFA_COLR_20210723 -> 140,638 sequences

WARNING! This project is under developing. In future versions it is expected to be a Tutorial to run the scripts for any barcode
