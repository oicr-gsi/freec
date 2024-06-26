# freec

FREEC 2.0

## Dependencies

* [samtools 0.1.19](https://github.com/samtools/samtools/archive/0.1.19.tar.gz)
* [bedtools 2.27](https://bedtools.readthedocs.io/en/latest/)
* [freec 11.5](https://github.com/BoevaLab/FREEC/archive/v11.5.tar.gz)


## Usage

### Cromwell
```
java -jar cromwell.jar run freec.wdl --inputs inputs.json
```

### Inputs

#### Required workflow parameters:
Parameter|Value|Description
---|---|---
`inputTumor`|File|Input .bam file for analysis sample
`sequencingType`|String|One of WG, EX or TS
`reference`|String|Reference assembly id


#### Optional workflow parameters:
Parameter|Value|Default|Description
---|---|---|---
`inputNormal`|File?|None|Optional input .bam file for control sample
`bedgraphOutput`|Boolean|true|String that says TRUE or FALSE, determines if we need BedGraph output or not
`outputFileNamePrefix`|String|""|Prefix for outputs


#### Optional task parameters:
Parameter|Value|Default|Description
---|---|---|---
`runFreec.intervalFile`|String?|None|Optional path to an interval .bed file, for targeted sequencing like EX, TS
`runFreec.coefficientOfVariation`|Float|0.05|Parameter for CNV calling, default is 0.05
`runFreec.breakPointThreshold`|Float|0.8|Parameter for CNV calling, default is 0.8
`runFreec.contaminationAdjustment`|String?|None|informs FREEC about expected degree of contamination with normal tissue
`runFreec.contaminationFraction`|Float|0.0|Contaminating fraction, by default is 0
`runFreec.window`|Int|1000|Defines the resolution of the analysis, default:1000
`runFreec.jobMemory`|Int|20|Memory in Gb for this job
`runFreec.maxThreads`|Int|4|Maximum threads for the process, default is 4
`runFreec.telocentromeric`|Int|50000|For human, we need 50000 (default)
`runFreec.inputFormat`|String|"BAM"|Maybe SAM, BAM, pileup, bowtie, eland, arachne, psl (BLAT), BED. We use BAM
`runFreec.mateOrientation`|String|"FR"|For paired-end Illumina we need FR, other types are also supported
`runFreec.configFile`|String|"config_freec.conf"|config_freec.conf
`runFreec.logPath`|String|"freec_run.log"|We have a log file which is not provisioned but can be examined if anything goes wrong
`runFreec.timeout`|Int|72|Timeout in hours, needed to override imposed limits


### Outputs

Output | Type | Description | Labels
---|---|---|---
`infoFile`|File|Info file for the calls|vidarr_label: infoFile
`regionFile`|File|Region File|vidarr_label: regionFile
`ratioFile`|File|Ratio File|vidarr_label: ratioFile
`cnvTumor`|File|CNV for tumor file|vidarr_label: cnvTumor
`cnvNormal`|File?|CNV for normal file|vidarr_label: cnvNormal
`gcProfile`|File?|GC profile data|vidarr_label: gcProfile
`ratioBedGraph`|File?|Retio BedGraph data|vidarr_label: ratioBedGraph


## Commands
This section lists command(s) run by freec workflow
 
* Running freec
 
FREEC is a CNV-calling tool which may run in a control-free (Tumor-only) mode.
This workflow runs a custom python script which assembles a config file using
the provided inputs
 
```
  
  Writing a config file given the inputs
 
  ...
 
  freec --conf iCONFIG_FILE >> LOG_PATH
 
  ...
 
  Post-processing and renaming of files
 
```
## Support

For support, please file an issue on the [Github project](https://github.com/oicr-gsi) or send an email to gsi@oicr.on.ca .

_Generated with generate-markdown-readme (https://github.com/oicr-gsi/gsi-wdl-tools/)_
