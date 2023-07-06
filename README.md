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


Previous versions: 

https://drive.google.com/drive/folders/1GUmPjNlBobIv4OMdB1i1Yf0_HKVkN0T6?usp=share_link

- v20210723 -> 139,082 sequences 
- DUFA_COLR_20210723 -> 140,638 sequences

WARNING! This project is under developing. In future versions it is expected to be a Tutorial to run the scripts for any barcode
