/*====================================================================
Program Name: lb.sas 
Study: CDISC Pilot 01
Domain: LB (Laboratory Test Results 实验室检查SDTM域)
Description: Create SDTM LB domain from raw xpt source data
CDISC SDTM IG version: 3.2
====================================================================*/

%let rawpath = E:\CDISC_Pilot_Project_SAS\raw_data;
%let outpath = E:\CDISC_Pilot_Project_SAS\output;

libname rawlb xport "&rawpath./lb.xpt";

data lb;
    set rawlb.lb;
    keep STUDYID DOMAIN USUBJID LBSEQ LBTEST LBTESTCD LBNRIND;
    DOMAIN = 'LB';
run;

/*变量标签，仅保留实际存在变量*/
data lb;
    set lb;
    label
        STUDYID  = "Study Identifier"
        DOMAIN   = "Domain Abbreviation"
        USUBJID  = "Unique Subject Identifier"
        LBSEQ    = "Sequence Number"
        LBTESTCD = "Lab Test Code"
        LBTEST   = "Lab Test Name"
        LBNRIND  = "Reference Range Indicator";
run;

/*输出SDTM LB永久数据集*/
libname out "&outpath.";
data out.lb;
    set lb;
run;

title "SDTM LB Domain Metadata";
proc contents data=out.lb varnum;
run;
