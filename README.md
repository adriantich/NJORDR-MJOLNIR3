# NJORDR-MJOLNIR3
Names Joining into Ordered Database with R for MJOLNIR3 pipeline

This is a pipeline to create a Reference DataBase for THOR-MJOLNIR3 function to perform the taxonomic assignment of metabarcoding Data.

This pipeline will be focused on the Leray-XT segment of the COI marker.
The intention however is provide a sequence of steps that can be performed with any marker.

DUFA_db available (COI_NJORDR.obidms).

- v20230503
140638 sequences 
https://drive.google.com/drive/folders/1dVfZYCwoIK6D2V7adhF4xt85WdxzUys7?usp=share_link

Previous versions: 

https://drive.google.com/drive/folders/1GUmPjNlBobIv4OMdB1i1Yf0_HKVkN0T6?usp=share_link

- v20210723 -> 139082 sequences 

We should describe the motivations of the following steps and the outputs that we want to get. 

Taxo-DMS: this is the object that MJOLNIR3 will use to perform the taxonomic assignment using ecotag from OBITOOLS3 
(see https://git.metabarcoding.org/obitools/obitools3). To construct this object two other objects are required, the taxdump from NCBI and a reference DataBase.

taxdump: object downloaded from NCBI with the philogenetic information of all the taxid from NCBI. 

Reference DataBase: fasta file with the all the sequences with their id and taxid. The scientific name is not mandatory if the taxid are correct, 
however it is recommended to retain this information so taxid from NCBI could change and thus all the information lost.

