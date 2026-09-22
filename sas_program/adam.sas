/*=============================================================
Program: adam.sas
Project: CDISC Pilot 01 Alzheimer
Purpose: Create ADaM ADSL & ADLB datasets
Input: raw.DM, raw.LB  
Output: work.adsl, work.adlb
=============================================================*/
options nodate nonumber nocenter ls=120 ps=60;

libname raw "E:\CDISC_Pilot_Project_SAS\raw_data";

/* 清理旧数据集 */
proc datasets library=work nolist;
    delete adsl adlb adlb_tmp;
run;
quit;

/* ====================== 1. 构建ADSL 人口学ADaM ====================== */
data work.adsl;
    set raw.DM;  
    length USUBJID $20 AGEGR1 $20 TRTA $40;
    AGE     = AGE;
    AGEU    = AGEU;
    SEX     = SEX;
    RACE    = RACE;
    ETHNIC  = ETHNIC;
    TRTA    = ARM;
    if AGE ne . then do;
        if AGE < 65 then AGEGR1 = "<65 years";
        else if AGE < 75 then AGEGR1 = "65-74 years";
        else                 AGEGR1 = ">=75 years";
    end;
    keep USUBJID AGE AGEU AGEGR1 SEX RACE ETHNIC TRTA;
run;

proc contents data=work.adsl varnum;
run;

title "ADSL Preview 前20例受试者";
proc print data=work.adsl(obs=20) noobs;
run;
title;

/* ====================== 2. 构建ADLB 实验室ADaM ====================== */
proc sql;
    create table work.adlb_tmp as
        select
            lb.USUBJID,
            adsl.TRTA,
            lb.LBTEST,
            lb.LBTESTCD,
            lb.LBORRES,
            lb.LBORRESU,
            lb.LBSTRESN,
            lb.LBSTRESU,
            lb.LBSTNRHI,
            lb.LBSTNRLO,
            lb.LBSEQ,
            lb.LBDTC,
            case
                when lb.LBSTRESN > lb.LBSTNRHI then "H"
                when lb.LBSTRESN < lb.LBSTNRLO then "L"
                when lb.LBSTRESN ne .          then "N"
                else                                 ""
            end as AVALCAT1 label="Lab Result Category H/L/N"
        from raw.LB lb  
        left join work.adsl adsl
            on lb.USUBJID = adsl.USUBJID
        order by lb.USUBJID, lb.LBSEQ;
quit;

data work.adlb;
    length AVALCAT1 $2;
    set work.adlb_tmp;
run;

proc contents data=work.adlb varnum;
run;

title "ADLB Preview 前25条实验室记录";
proc print data=work.adlb(obs=25) noobs;
run;
title;

title "ADLB 实验室结果分类统计 H/L/N";
proc freq data=work.adlb;
    tables AVALCAT1 / nocum nopercent;
run;
title;
