version 1.0

struct freecResources {
 String refModule
 String refRoot
 String refFai
}

workflow freec {
input {
    # Normally we need only tumor bam, normal bam may be used when available
    File inputTumor
    File? inputNormal
    Boolean bedgraphOutput = true
    String sequencingType
    String outputFileNamePrefix = ""
    String reference
}

String sampleID = if outputFileNamePrefix=="" then basename(inputTumor, ".bam") else outputFileNamePrefix

Map[String,freecResources] resources = {
  "hg19": {"refModule": "hg19/p13",
           "refRoot": "$HG19_ROOT/",
           "refFai": "$HG19_ROOT/hg19_random.fa.fai"
  },
  "hg38": {"refModule": "hg38/p12",
           "refRoot": "$HG38_ROOT/",
           "refFai": "$HG38_ROOT/hg38_random.fa.fai"
  },
  "mm10": {"refModule": "mm10/p6",
           "refRoot": "$MM10_ROOT/",
           "refFai": "$MM10_ROOT/mm10.fa.fai"
  }
}

# Configure and run FREEC
call runFreec { input: inputTumor = inputTumor, 
                       inputNormal = inputNormal,
                       sampleID = sampleID,
                       chrFiles = resources[reference].refRoot,
                       chrLenFile = resources[reference].refFai,
                       modules = "freec/11.5 bedtools/2.27 samtools/0.1.19 ~{resources[reference].refModule}", 
                       sequencingType = sequencingType,
                       bedGraphOutput = if bedgraphOutput then "TRUE" else "FALSE" }

meta {
  author: "Peter Ruzanov"
  email: "peter.ruzanov@oicr.on.ca"
  description: "FREEC performs control-free copy number alteration (CNA) detection using deep-sequencing data. The tool deals with two frequent problems in the analysis of cancer deep-sequencing data: absence of control sample and possible polyploidy of cancer cells. The workflow accepts input BAM file(s) and notably, library design type among other parameters."
  dependencies: [
      {
        name: "samtools/0.1.19",
        url: "https://github.com/samtools/samtools/archive/0.1.19.tar.gz"
      },
      {
        name: "bedtools/2.27",
        url: "https://bedtools.readthedocs.io/en/latest/"
      },
      {
        name: "freec/11.5",
        url: "https://github.com/BoevaLab/FREEC/archive/v11.5.tar.gz"
      }
  ]
    output_meta: {
    infoFile: {
        description: "Info file for the calls",
        vidarr_label: "infoFile"
    },
    regionFile: {
        description: "Region File",
        vidarr_label: "regionFile"
    },
    ratioFile: {
        description: "Ratio File",
        vidarr_label: "ratioFile"
    },
    cnvTumor: {
        description: "CNV for tumor file",
        vidarr_label: "cnvTumor"
    },
    cnvNormal: {
        description: "CNV for normal file",
        vidarr_label: "cnvNormal"
    },
    gcProfile: {
        description: "GC profile data",
        vidarr_label: "gcProfile"
    },
    ratioBedGraph: {
        description: "Retio BedGraph data",
        vidarr_label: "ratioBedGraph"
    }
}
}

parameter_meta {
 inputTumor: "Input .bam file for analysis sample"
 inputNormal: "Optional input .bam file for control sample"
 reference: "Reference assembly id"
 sequencingType: "One of WG, EX or TS"
 bedgraphOutput: "String that says TRUE or FALSE, determines if we need BedGraph output or not"
 outputFileNamePrefix: "Prefix for outputs"
}

output {
  File infoFile   = runFreec.infoFile
  File regionFile = runFreec.regionFile
  File ratioFile  = runFreec.ratioFile
  File cnvTumor   = runFreec.cnvTumor
  File? cnvNormal = runFreec.cnvNormal
  File? gcProfile = runFreec.gcProfile
  File? ratioBedGraph = runFreec.ratioBedGraph
}

}

# ==========================================
#  configure and run FREEC
# ==========================================
task runFreec {
input {
  File  inputTumor
  String sequencingType
  String sampleID = "TEST"
  File? inputNormal
  String? intervalFile
  String chrFiles 
  String chrLenFile 
  String bedGraphOutput = "TRUE"
  Float  coefficientOfVariation = 0.05
  Float  breakPointThreshold = 0.8
  String? contaminationAdjustment
  Float  contaminationFraction = 0.0
  Int    window = 1000
  Int    jobMemory  = 20
  Int    maxThreads = 4
  Int    telocentromeric = 50000
  String inputFormat = "BAM"
  String mateOrientation = "FR"
  String configFile = "config_freec.conf"
  String logPath = "freec_run.log"
  String modules
  Int    timeout = 72
}

parameter_meta {
 inputTumor: "Input .bam file for analysis sample"
 inputNormal: "Optional input .bam file for control sample"
 sequencingType: "One of WG, EX or TS"
 sampleID: "This is used as a prefix for output files"
 intervalFile: "Optional path to an interval .bed file, for targeted sequencing like EX, TS"
 chrFiles: "Directory with chromosome-specific .fa files"
 chrLenFile: "Path to .fai file, needed for chromosome sizes"
 bedGraphOutput: "String that says TRUE or FALSE, determines if we need BedGraph output or not"
 coefficientOfVariation: "Parameter for CNV calling, default is 0.05"
 breakPointThreshold: "Parameter for CNV calling, default is 0.8"
 contaminationAdjustment: "informs FREEC about expected degree of contamination with normal tissue"
 contaminationFraction: "Contaminating fraction, by default is 0"
 window: "Defines the resolution of the analysis, default:1000"
 jobMemory: "Memory in Gb for this job"
 maxThreads: "Maximum threads for the process, default is 4"
 telocentromeric: "For human, we need 50000 (default)"
 inputFormat: "Maybe SAM, BAM, pileup, bowtie, eland, arachne, psl (BLAT), BED. We use BAM"
 mateOrientation: "For paired-end Illumina we need FR, other types are also supported"
 configFile: "config_freec.conf"
 logPath: "We have a log file which is not provisioned but can be examined if anything goes wrong"
 modules: "Names and versions of modules"
 timeout: "Timeout in hours, needed to override imposed limits"
}

command <<<
 python<<CODE
 import os
 general_lines = []
 sample_lines = []
 control_lines = []
 baf_lines = []
 target_lines = []

 general_lines.append("BedGraphOutput = ~{bedGraphOutput}")
 general_lines.append("bedtools = bedtools")
 general_lines.append("samtools = samtools")
 general_lines.append("breakPointThreshold = ~{breakPointThreshold}")
 general_lines.append("chrFiles = " + os.path.expandvars("~{chrFiles}"))
 general_lines.append("chrLenFile = " + os.path.expandvars("~{chrLenFile}"))
 general_lines.append("coefficientOfVariation = ~{coefficientOfVariation}")
 if "~{contaminationAdjustment}":
     general_lines.append("contamination = ~{contaminationFraction}")
     general_lines.append("contaminationAdjustment = ~{contaminationAdjustment}") 

 seqType = "~{sequencingType}"
 if seqType.startswith('WG'):
     general_lines.append("forceGCcontentNormalization = 0")
     general_lines.append("minCNAlength = 1")
     general_lines.append("readCountThreshold = 10")
     general_lines.append("step = 1000")
     general_lines.append("window = ~{window}")
 else:
     general_lines.append("forceGCcontentNormalization = 1")
     general_lines.append("minCNAlength = 3")
     general_lines.append("noisyData = TRUE")
     general_lines.append("printNA = FALSE")
     general_lines.append("readCountThreshold = 60")
     general_lines.append("window = 0")

 general_lines.append("intercept = " + ('0' if "~{inputNormal}" else '1'))
 general_lines.append("maxThreads = ~{maxThreads}")
 general_lines.append("telocentromeric = ~{telocentromeric}")

 sample_lines.append("mateFile = ~{inputTumor}")
 sample_lines.append("inputFormat = ~{inputFormat}")
 sample_lines.append("mateOrientation = ~{mateOrientation}")

 if "~{inputNormal}":
     control_lines.append("mateFile = ~{inputNormal}")
     control_lines.append("inputFormat = ~{inputFormat}")
     control_lines.append("mateOrientation = ~{mateOrientation}")

 seqType = "~{sequencingType}"
 if not seqType.startswith('WG') and "~{intervalFile}":
     target_lines.append("captureRegions = ~{intervalFile}")

 f = open("~{configFile}", "w+")
 f.write('[general]\n')
 f.write('\n'.join(general_lines) + '\n\n')

 f.write('[sample]\n')
 f.write('\n'.join(sample_lines) + '\n\n')

 f.write('[control]\n')
 f.write('\n'.join(control_lines) + '\n\n')

 f.write('[target]\n')
 f.write('\n'.join(target_lines) + '\n\n')

 f.close()
 CODE
 freec --conf ~{configFile} >> ~{logPath}
 mv ~{basename(inputTumor)}_info.txt ~{sampleID}_info.txt
 mv ~{basename(inputTumor)}_CNVs ~{sampleID}_CNVs
 mv ~{basename(inputTumor)}_ratio.txt ~{sampleID}_ratio.txt
 mv ~{basename(inputTumor)}_sample.cpn ~{sampleID}_sample.cpn
 
 if [[ -n "~{inputNormal}" ]]; then
    NORM=$(echo ~{inputNormal} | sed s!.*/!!)
    mv  $NORM"_control.cpn" ~{sampleID}_control.cpn
 fi

 if [[ -f "~{basename(inputTumor)}_GC_profile.cpn" ]]; then
    mv ~{basename(inputTumor)}_GC_profile.cpn ~{sampleID}_GC_profile.cpn
 fi

 if [[ -f "~{basename(inputTumor)}_ratio.BedGraph" ]]; then
    mv ~{basename(inputTumor)}_ratio.BedGraph ~{sampleID}_ratio.BedGraph
 fi
>>>

runtime {
  memory:  "~{jobMemory} GB"
  modules: "~{modules}"
  timeout: "~{timeout}"
}

output {
  File infoFile = "~{sampleID}_info.txt"
  File regionFile = "~{sampleID}_CNVs"
  File ratioFile = "~{sampleID}_ratio.txt"
  File cnvTumor = "~{sampleID}_sample.cpn"
  File? cnvNormal = "~{sampleID}_control.cpn"
  File? gcProfile = "~{sampleID}_GC_profile.cpn"
  File? ratioBedGraph = "~{sampleID}_ratio.BedGraph"
}
}

