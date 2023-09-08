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
      - To obtain the taxonomic tree you can [create it](https://mkcoinr.readthedocs.io/en/latest/content/tutorial.html#create-coinr-from-bold-and-ncbi) or download it directly (recomended). NJORDR will follow the format of mkCOInr taxonomy.tsv file to only use an standardised intitial file. This format also allows to distinguish between tax_id's that are in the NCBI and the new tax_id's that are not present (at this point, negative tax_id's)

      
      
      


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
