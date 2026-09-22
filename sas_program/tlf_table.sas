
/*=============================================================
Program: tlf_table1.sas
Project: CDISC Pilot 01 Alzheimer
Purpose: Generate Table1 Baseline Demographics TLF
Input: raw.adsl
Output: t1_cat t1_cont
=============================================================*/

options nodate nonumber nocenter;
/*============================= TLF : Table 1.1 Baseline Demographics 基线人口学统计表，基于CDISC Pilot01项目 ==============================*/
proc format;
    value $sexfmt
        "M" = "Male"
        "F" = "Female";
    value agegrpfmt
        low -<65 = "<65 years"
        65 -<75 = "65~74 years"
        75 - high = ">=75 years";
run;

/* 派生年龄分组 */
data adsl_t1;
    set raw.adsl;
    length AGEGR1 $20;
    if AGE ne . then do;
        if AGE <65 then AGEGR1 = "<65 years";
        else if 65<=AGE <75 then AGEGR1 = "65~74 years";
        else AGEGR1 = ">=75 years";
    end;
    format SEX $sexfmt.;
run;

/* ========== Table1 标准TABULATE 【行：指标；列：试验组+合计】 ========== */
proc tabulate data=adsl_t1 out=t1_cat;
    class TRTA SEX AGEGR1;
    table 
        /* 行维度：性别、年龄分层 */
        SEX AGEGR1,
        /* 列维度：分组，输出N(%) */
        TRTA="Treatment Group" * (n*f=3.0 colpctn*f=5.1)
        all="Overall" * (n*f=3.0 colpctn*f=5.1)
        / box=[label="Parameter"] misstext="---";
run;

/* 连续变量：年龄均值标准差 */
proc tabulate data=adsl_t1 out=t1_cont;
    class TRTA;
    var AGE;
    table
        AGE="Age (Years)",
        TRTA="Treatment Group" * (mean="Mean"*f=6.1 std="SD"*f=6.1)
        all="Overall" * (mean="Mean"*f=6.1 std="SD"*f=6.1)
        / box=[label="Parameter"] misstext="---";
run;
