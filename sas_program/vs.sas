/*====================================================================
Program Name: vs.sas
Study: CDISC Pilot 01 
Domain: VS (Vital Signs 生命体征SDTM域)
Description: Create SDTM VS domain from raw xpt source data
CDISC SDTM IG version: 3.2
====================================================================*/

%let rawpath = E:\CDISC_Pilot_Project_SAS\raw_data;
%let outpath = E:\CDISC_Pilot_Project_SAS\output;

libname rawvs xport "&rawpath./vs.xpt";

data vs;
    set rawvs.vs;
    keep STUDYID DOMAIN USUBJID VSSEQ VSTEST VSTESTCD VSORRES VSORRESU VSDTC;
    DOMAIN = 'VS';
run;

/*变量标签，仅保留实际存在变量*/
data vs;
    set vs;
    label
        STUDYID  = "Study Identifier"
        DOMAIN   = "Domain Abbreviation"
        USUBJID  = "Unique Subject Identifier"
        VSSEQ    = "Sequence Number"
        VSTESTCD = "Vital Signs Test Code"
        VSTEST   = "Vital Signs Test Name"
        VSORRES  = "Result or Finding in Original Units"
        VSORRESU = "Original Units"
        VSDTC    = "Date/Time of Vital Signs Measurement";
run;

/*输出SDTM VS永久数据集*/
libname out "&outpath.";
data out.vs;
    set vs;
run;

title "SDTM VS Domain Metadata";
proc contents data=out.vs varnum;
run;
