options nodate nonumber nocenter;

/* E盘项目路径 */
libname raw "E:\CDISC_Pilot_Project_SAS\raw_data";

libname xp_dm xport "E:\CDISC_Pilot_Project_SAS\raw_data\DM.xpt";
proc copy in=xp_dm out=raw; 
run;

libname xp_vs xport "E:\CDISC_Pilot_Project_SAS\raw_data\VS.xpt";
proc copy in=xp_vs out=raw; 
run;

libname xp_lb xport "E:\CDISC_Pilot_Project_SAS\raw_data\LB.xpt";
proc copy in=xp_lb out=raw; 
run;

libname xp_ae xport "E:\CDISC_Pilot_Project_SAS\raw_data\AE.xpt";
proc copy in=xp_ae out=raw; 
run;

libname xp_cm xport "E:\CDISC_Pilot_Project_SAS\raw_data\CM.xpt";
proc copy in=xp_cm out=raw; 
run;

/* 清理xport逻辑库 */
libname xp_dm clear; libname xp_vs clear; libname xp_lb clear;
libname xp_ae clear; libname xp_cm clear;



/* 查看所有导入数据集的变量、标签、长度 */
proc contents data=raw._all_ varnum;
run;


/* 核查DM：重复USUBJID，找出重复受试者，生成query清单 */
proc sql;
    create table raw.qc_dup_usubjid as
        select USUBJID, count(*) as cnt
        from raw.DM
        group by USUBJID
        having count(*) >1;
quit;

/* VS异常值核查：血压/身高体重逻辑异常，生成QC query */
data raw.qc_vs_invalid;
    set raw.VS;
    where 
        (VSTESTCD="HEIGHT" and VSSTRESN <=0) 
        or (VSTESTCD="WEIGHT" and VSSTRESN <=0);
run;

data raw.qc_ae_missing;
    set raw.AE;
    where AEDECOD = "";
run;



data raw.qc_lb_missing;
    set raw.LB;
    where LBSTRESN = . and LBTEST ne "";
run;


data raw.all_qc;
    length DOMAIN $20 USUBJID $40 QCTEXT $200;
    set 
        raw.qc_dup_usubjid (in=a)
        raw.qc_vs_invalid (in=b)
        raw.qc_ae_missing (in=c)
        raw.qc_lb_missing (in=d);
    if a then do; DOMAIN="DM"; QCTEXT="受试者USUBJID重复"; end;
    if b then do; DOMAIN="VS"; QCTEXT="生命体征数值不合理"; end;
    if c then do; DOMAIN="AE"; QCTEXT="不良事件AEDECOD缺失"; end;
    if d then do; DOMAIN="LB"; QCTEXT="实验室结果缺失"; end;
run;



/* 跨域核查：VS中存在，但DM不存在的受试者ID */
proc sql;
create table raw.qc_vs_not_in_dm as
select distinct USUBJID
from raw.VS
where USUBJID not in (select USUBJID from raw.DM);
quit;

/* 跨域核查：AE中存在，但DM不存在的受试者ID */
proc sql;
create table raw.qc_ae_not_in_dm as
select distinct USUBJID
from raw.AE
where USUBJID not in (select USUBJID from raw.DM);
quit;

/* 跨域核查：LB中存在，但DM不存在的受试者ID */
proc sql;
create table raw.qc_lb_not_in_dm as
select distinct USUBJID
from raw.LB
where USUBJID not in (select USUBJID from raw.DM);
quit;



data raw.all_qc;
    length DOMAIN $20 USUBJID $40 QCTEXT $200;
    set 
        raw.qc_dup_usubjid (in=a)
        raw.qc_vs_invalid (in=b)
        raw.qc_ae_missing (in=c)
        raw.qc_lb_missing (in=d)
        raw.qc_vs_not_in_dm(in=e)
        raw.qc_ae_not_in_dm(in=f)
        raw.qc_lb_not_in_dm(in=g);
    if a then do; DOMAIN="DM"; QCTEXT="受试者USUBJID重复"; end;
    if b then do; DOMAIN="VS"; QCTEXT="生命体征数值不合理"; end;
    if c then do; DOMAIN="AE"; QCTEXT="不良事件AEDECOD缺失"; end;
    if d then do; DOMAIN="LB"; QCTEXT="实验室结果缺失"; end;
    if e then do; DOMAIN="VS"; QCTEXT="VS受试者ID在DM中不存在(跨域不一致)"; end;
    if f then do; DOMAIN="AE"; QCTEXT="AE受试者ID在DM中不存在(跨域不一致)"; end;
    if g then do; DOMAIN="LB"; QCTEXT="LB受试者ID在DM中不存在(跨域不一致)"; end;
run;

title "SDTM全部QC Query报告";
proc print data=raw.all_qc noobs;
run;
title; 



/* 构建ADSL 人口学ADaM数据集 */
data raw.adsl;
    set raw.DM;
    AGE = AGE;
    AGEU = AGEU;
    SEX = SEX;
    RACE = RACE;
    ETHNIC = ETHNIC;
    TRTA = ARM; /* 试验分组 */
    TRTAN = ARMCD;
    USUBJID = USUBJID;
    /* 筛选符合数据集规范变量，ADSL核心变量 */
    keep USUBJID AGE AGEU SEX RACE ETHNIC TRTA TRTAN;
run;

/* 查看ADSL内容 */
proc contents data=raw.adsl varnum; 
run;

title "ADSL数据集预览";
proc print data=raw.adsl (obs=20) noobs;
run;
title;




/*构建ADLB：ADaM实验室数据集，SDTM LB左连接ADSL*/
proc sql;
create table raw.adlb as
select 
    a.USUBJID,
    b.TRTA,
    b.TRTAN,
    a.LBTESTCD,
    a.LBTEST,
    a.LBORRES,
    a.LBORRESU,
    a.LBSTRESN,
    a.LBSTRESU,
    a.LBSTNRHI,   /*正常值上限*/
    a.LBSTNRLO,   /*正常值下限*/
    a.LBSEQ
from raw.LB a
left join raw.adsl b
on a.USUBJID = b.USUBJID;
quit;

/*派生变量：标记高于/低于正常范围，AVALCAT1，ADaM标准分类变量*/
data raw.adlb;
    set raw.adlb;
    length AVALCAT1 $20;
    if LBSTRESN ne . then do;
        if LBSTRESN > LBSTNRHI then AVALCAT1 = "HIGH";
        else if LBSTRESN < LBSTNRLO then AVALCAT1 = "LOW";
        else AVALCAT1 = "NORMAL";
    end;
run;

/*预览ADLB*/
title "ADLB数据集预览";
proc print data=raw.adlb (obs=20) noobs;
run;
title;


options nodate nonumber nocenter;

proc format;
    value $sexfmt
        "M" = "Male"
        "F" = "Female";
run;

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

/*第一部分：分类变量 性别、年龄分层，输出N(%) */
proc tabulate data=adsl_t1 out=t1_cat;
    class TRTA SEX AGEGR1;
    table
        (SEX all="Total Sex")
        (AGEGR1 all="Total Age Group")
        ,
        TRTA="Treatment Group" * (n*f=3.0 colpctn*f=5.1)
        all="Overall" * (n*f=3.0 colpctn*f=5.1)
        / box=[label="Parameter"] misstext="--";
run;

/*第二部分：连续变量年龄，输出Mean, SD */
proc tabulate data=adsl_t1 out=t1_cont;
    class TRTA;
    var AGE;
    table
        AGE="Age (Years)" * (mean="Mean"*f=6.1 std="SD"*f=6.1)
        ,
        TRTA="Treatment Group"
        all="Overall"
        / box=[label="Parameter"] misstext="--";
run;

title "Table1 分类变量";
proc print data=t1_cat noobs label; 
run;
title;

title "Table1 连续变量";
proc print data=t1_cont noobs label; 
run;
title;
