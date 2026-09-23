/*====================================================================
Program Name: dm.sas
Study: CDISC Pilot 01 
Domain: DM (Demographics 人口学SDTM域)
Description: Create SDTM DM domain from raw xpt source data
CDISC SDTM IG version: 3.2
====================================================================*/

%let rawpath = E:\CDISC_Pilot_Project_SAS\raw_data;
%let outpath = E:\CDISC_Pilot_Project_SAS\output;

libname rawdm xport "&rawpath./dm.xpt";

data dm;
    set rawdm.dm;
    keep STUDYID DOMAIN USUBJID SUBJID SITEID AGE AGEU SEX RACE ETHNIC;
    DOMAIN = 'DM';
run;

/*变量标签，仅保留实际存在变量*/
data dm;
    set dm;
    label
        STUDYID = "Study Identifier"
        DOMAIN  = "Domain Abbreviation"
        USUBJID = "Unique Subject Identifier"
        SUBJID  = "Subject Identifier"
        SITEID  = "Study Site Identifier"
        AGE     = "Age"
        AGEU    = "Age Units"
        SEX     = "Sex"
        RACE    = "Race"
        ETHNIC  = "Ethnicity";
run;

/*输出SDTM DM永久数据集*/
libname out "&outpath.";
data out.dm;
    set dm;
run;

title "SDTM DM Domain Metadata";
proc contents data=out.dm varnum;
run;
