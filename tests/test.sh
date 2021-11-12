#!/bin/bash
if [[ -n "/u/pruzanov/Data/GSI/WDL/FREEC/cromwell-executions/freec/4102868c-80b7-4315-b15a-84a06f2b3fa0/call-runFreec/inputs/-449406560/SWID_14950709_PCSI_1106_Ly_R_PE_619_WG_190819_A00827_0025_BHKC7JDSXX_TGACTACT-CCTTACAG_L002_001.annotated.bam" ]]; then
   NORM=$(echo "/u/pruzanov/Data/GSI/WDL/FREEC/cromwell-executions/freec/4102868c-80b7-4315-b15a-84a06f2b3fa0/call-runFreec/inputs/-449406560/SWID_14950709_PCSI_1106_Ly_R_PE_619_WG_190819_A00827_0025_BHKC7JDSXX_TGACTACT-CCTTACAG_L002_001.annotated.bam" | sed s!.*/!!)
   echo  $NORM"control.cpn"
fi
