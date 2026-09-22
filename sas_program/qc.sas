/*=============================================================
Program: qc.sas
Project: CDISC Pilot 01 Alzheimer Study
Purpose: SDTM Single-domain & Cross-domain QC, generate query list
Input:  raw DM/VS/LB/AE/CM xpt files
Output: work.all_qc, output/QC_Query_Report.rtf
Author: SAS Programmer Practice
=============================================================*/

options nodate nonumber nocenter ls=120 ps=60;

%let project_root = E:\CDISC_Pilot_Project_SAS;
%let raw_dir      = &project_root.\raw_data;
%let output_dir   = &project_root.\output;

/* 自动创建output文件夹 */
%if %sysfunc(fileexist("&output_dir")) = 0 %then %do;
    %sysfunc(dcreate(output, &project_root.));
%end;

/*=============================================================
  读取XPT，全部数据集存入work临时库
=============================================================*/
%macro read_xpt(domain);
    libname raw_xpt xport "&raw_dir.\&domain..xpt";
    data work.&domain;
        length USUBJID $20;
        set raw_xpt.&domain;
        USUBJID = left(trim(USUBJID));
    run;
    libname raw_xpt clear;
%mend;

%read_xpt(DM);
%read_xpt(VS);
%read_xpt(AE);
%read_xpt(LB);
%read_xpt(CM);

/*===================== 1. 单域QC核查 =====================*/

/*1.1 DM：检查USUBJID重复受试者 */
proc sort data=work.DM out=work.DM_sorted;
    by USUBJID;
run;

data work.qc_dup_usubjid;
    set work.DM_sorted;
    by USUBJID;
    if first.USUBJID and last.USUBJID then delete;
run;

/*1.2 VS：收缩压SYSBP数值超出合理生理范围 */
data work.qc_vs_invalid;
    set work.VS;
    where VSTESTCD = "SYSBP"
      and (VSSTRESN > 300 or VSSTRESN < 20);
run;

/*1.3 AE：AEDECOD首选术语缺失，但存在系统器官分类 */
data work.qc_ae_missing;
    set work.AE;
    where (AEDECOD = "" or AEDECOD = " ")
      and AEBODSYS ne "";
run;

/*1.4 LB：有检验项目名称，但实验室结果LBSTRESN为空 */
data work.qc_lb_missing;
    set work.LB;
    where LBSTRESN = .
      and LBTEST ne "";
run;

/*===================== 2. 跨域QC核查：孤儿记录核查 =====================*/

/* 提取DM全部受试者USUBJID清单 */
proc sort data=work.DM(keep=USUBJID) out=work.dm_usubjid nodupkey;
    by USUBJID;
run;

/*2.1 VS中存在的受试者，DM人口学表不存在（孤儿记录）*/
proc sort data=work.VS(keep=USUBJID) out=work.vs_usubjid nodupkey;
    by USUBJID;
run;

data work.qc_vs_not_in_dm;
    merge work.vs_usubjid(in=a) work.dm_usubjid(in=b);
    by USUBJID;
    if a and not b;
    DOMAIN = "VS";
    keep USUBJID DOMAIN;
run;

/*2.2 AE中存在的受试者，DM人口学表不存在（孤儿记录）*/
proc sort data=work.AE(keep=USUBJID) out=work.ae_usubjid nodupkey;
    by USUBJID;
run;

data work.qc_ae_not_in_dm;
    merge work.ae_usubjid(in=a) work.dm_usubjid(in=b);
    by USUBJID;
    if a and not b;
    DOMAIN = "AE";
    keep USUBJID DOMAIN;
run;

/*2.3 LB中存在的受试者，DM人口学表不存在（孤儿记录）*/
proc sort data=work.LB(keep=USUBJID) out=work.lb_usubjid nodupkey;
    by USUBJID;
run;

data work.qc_lb_not_in_dm;
    merge work.lb_usubjid(in=a) work.dm_usubjid(in=b);
    by USUBJID;
    if a and not b;
    DOMAIN = "LB";
    keep USUBJID DOMAIN;
run;

/*===================== 3. 合并所有QC Query，生成总核查表 =====================*/
data work.all_qc;
    length DOMAIN $20 USUBJID $40 QCTEXT $200;
    set
        work.qc_dup_usubjid(in=a)
        work.qc_vs_invalid(in=b)
        work.qc_ae_missing(in=c)
        work.qc_lb_missing(in=d)
        work.qc_vs_not_in_dm(in=e)
        work.qc_ae_not_in_dm(in=f)
        work.qc_lb_not_in_dm(in=g);

    if a then do;
        DOMAIN = "DM";
        QCTEXT = "受试者USUBJID重复";
    end;
    if b then do;
        DOMAIN = "VS";
        QCTEXT = "生命体征数值不合理（收缩压超出生理范围）";
    end;
    if c then do;
        DOMAIN = "AE";
        QCTEXT = "不良事件AEDECOD缺失，存在AE记录无首选术语";
    end;
    if d then do;
        DOMAIN = "LB";
        QCTEXT = "检验项目存在，但实验室数值LBSTRESN缺失";
    end;
    if e then do;
        QCTEXT = "VS存在受试者，DM人口学表无该受试者（孤儿记录）";
    end;
    if f then do;
        QCTEXT = "AE存在受试者，DM人口学表无该受试者（孤儿记录）";
    end;
    if g then do;
        QCTEXT = "LB存在受试者，DM人口学表无该受试者（孤儿记录）";
    end;
run;

/*===================== 4. 输出RTF格式QC报告 =====================*/
ods rtf file="&output_dir.\QC_Query_Report.rtf" style=Journal;
title "SDTM QC Query Report - CDISC Pilot01";
proc print data=work.all_qc noobs label;
    var DOMAIN USUBJID QCTEXT;
run;
ods rtf close;
title;

/*===================== 5. 日志预览QC结果 =====================*/
proc print data=work.all_qc noobs;
run;
