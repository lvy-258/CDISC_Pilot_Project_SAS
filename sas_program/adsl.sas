/*====================================================================
Program Name: adsl.sas
Study: CDISC Pilot 01
Domain: ADSL (ADaM Subject-Level Analysis Dataset)
Description: Create ADSL from SDTM DM
CDISC ADaM IG version: 1.1
====================================================================*/

%let rawpath = E:\CDISC_Pilot_Project_SAS\raw_data;
%let outpath = E:\CDISC_Pilot_Project_SAS\output;
libname out "&outpath.";

data adsl;
    set out.dm;
    length TRTA $20 TRTAN 8 AGEGR1 $20;

    /* 本试验无试验药物分组，TRTA赋值为NOT ASSIGNED */
    TRTA = "NOT ASSIGNED";
    TRTAN = .;

    /* 年龄分组 AGEGR1 */
    if AGE <65 then AGEGR1 = "<65";
    else if AGE >=65 then AGEGR1 = ">=65";

    keep USUBJID STUDYID SITEID SUBJID AGE AGEU SEX RACE ETHNIC TRTA TRTAN AGEGR1;
run;

/* 变量标签 */
data adsl;
    set adsl;
    label
        USUBJID = "Unique Subject Identifier"
        STUDYID = "Study Identifier"
        SITEID  = "Study Site Identifier"
        SUBJID  = "Subject Identifier"
        AGE     = "Age"
        AGEU    = "Age Units"
        SEX     = "Sex"
        RACE    = "Race"
        ETHNIC  = "Ethnicity"
        TRTA    = "Actual Treatment"
        TRTAN   = "Actual Treatment (N)"
        AGEGR1  = "Age Group";
run;

/* 输出永久ADSL数据集 */
data out.adsl;
    set adsl;
run;

proc contents data=out.adsl varnum;
    title "ADSL Metadata";
run;
