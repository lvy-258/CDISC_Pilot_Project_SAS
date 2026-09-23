/*====================================================================
Program Name: ae.sas
Study: CDISC Pilot 01 
Domain: AE (Adverse Event 不良事件SDTM域)
Description: Create SDTM AE domain from raw xpt source data
CDISC SDTM IG version: 3.2
====================================================================*/

%let rawpath = E:\CDISC_Pilot_Project_SAS\raw_data;
%let outpath = E:\CDISC_Pilot_Project_SAS\output;

libname rawae xport "&rawpath./ae.xpt";

data ae;
    set rawae.ae;
    keep STUDYID DOMAIN USUBJID AEBODSYS AEDECOD AESEQ AETERM AESTDTC AEENDTC AESER AESEQ;
    DOMAIN = 'AE';
run;

/*变量标签，仅保留实际存在变量*/
data ae;
    set ae;
    label
        STUDYID  = "Study Identifier"
        DOMAIN   = "Domain Abbreviation"
        USUBJID  = "Unique Subject Identifier"
        AESEQ    = "Sequence Number"
        AETERM   = "Reported Term for the Adverse Event"
        AEDECOD  = "Dictionary-Derived Term"
        AEBODSYS = "Body System or Organ Class"
        AESTDTC  = "Start Date of Adverse Event"
        AEENDTC  = "End Date of Adverse Event"
        AESER    = "Serious Event";
run;

/*输出SDTM AE永久数据集*/
libname out "&outpath.";
data out.ae;
    set ae;
run;

proc contents data=out.ae varnum;
    title "SDTM AE Domain Metadata";
run;
