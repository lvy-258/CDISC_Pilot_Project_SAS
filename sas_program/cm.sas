/*====================================================================
Program Name: cm.sas 
Study: CDISC Pilot 01
Domain: CM (Concomitant Medications 合并用药SDTM域)
Description: Create SDTM CM domain from raw xpt source data
CDISC SDTM IG version: 3.2
====================================================================*/

%let rawpath = E:\CDISC_Pilot_Project_SAS\raw_data;
%let outpath = E:\CDISC_Pilot_Project_SAS\output;

libname rawcm xport "&rawpath./cm.xpt";

data cm;
    set rawcm.cm;
    keep STUDYID DOMAIN USUBJID CMSEQ CMTRT CMDECOD
         CMSTDTC CMENDTC CMROUTE CMDOSE CMDOSU;
    DOMAIN = 'CM';
run;

/*变量标签，符合SDTM标准，只保留实际存在的变量*/
data cm;
    set cm;
    label
        STUDYID = "Study Identifier"
        DOMAIN  = "Domain Abbreviation"
        USUBJID = "Unique Subject Identifier"
        CMSEQ   = "Sequence Number"
        CMTRT   = "Reported Name of Drug, Therapy, or Procedure"
        CMDECOD = "Dictionary-Derived Term"
        CMSTDTC = "Start Date of Medication"
        CMENDTC = "End Date of Medication"
        CMROUTE = "Route of Administration"
        CMDOSE  = "Dose"
        CMDOSU  = "Dose Units";
run;

/*输出SDTM CM永久数据集*/
libname out "&outpath.";
data out.cm;
    set cm;
run;

title "SDTM CM Domain Metadata";
proc contents data=out.cm varnum;
run;
