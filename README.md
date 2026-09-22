README.md
# CDISC Pilot 01 Alzheimer Clinical Project
> SAS临床数据分析项目 | CDISC SDTM → ADaM → TLF Table1

#项目简介
基于CDISC官方Pilot01阿兹海默试验公开数据集（254受试者），模拟药企/CRO统计编程完整工作流。
**项目目标**：SDTM原始数据导入 → 数据QC核查生成Query报告 → 构建ADaM数据集(ADSL,ADLB) → 生成基线人口统计表Table1。
> 仅使用公开示范数据集，无任何真实患者隐私数据，合规。

#目录结构
CDISC_Pilot_Project_SAS
├── raw_data/ # SDTM 原始 xpt 文件 
│ ├── ae.xpt 
│ ├── cm.xpt 
│ ├── dm.xpt 
│ ├── lb.xpt 
│ └── vs.xpt 
├── sas_program/ # SAS 源代码 
│ ├── import_qc.sas # 导入 SDTM+QC 核查，输出 query 报告 
│ ├── qc.sas 
│ ├── adam.sas # 构建 ADSL、ADLB ADaM 数据集 
│ ├── tlf_table.sas # 生成 Table1 基线人口统计表 
│ ├── dm.sas/vs.sas/ae.sas/cm.sas/lb.sas 
│ └── full_demo.sas 
└── README.md







#运行顺序
1. `import_qc.sas`：读取XPT，SDTM单域+跨域QC检查，输出all_qc查询报告
2. `adam.sas`：基于SDTM派生ADSL（人口学）、ADLB（实验室）ADaM数据集
3. `tlf_table.sas`：基于ADSL生成Table1基线人口学汇总表

#技术栈
SAS 9.4，CDISC SDTM IG、ADaM IG，XPORT引擎读取xpt文件，QC逻辑、TLF制表。

#项目产出
1. SDTM域数据集DM/VS/LB/AE/CM
2. QC核查报告（all_qc，识别重复ID、不合理数值、缺失项、跨域不一致）
3. ADaM数据集：ADSL、ADLB
4. TLF：Table 1.1 基线人口统计学表

#项目说明
项目为学习用途，模拟CRO统计编程完整工作流程，用于求职SAS程序员岗位作品集。

本项目使用CDISC官方Pilot01公开临床试验数据，用SAS完成从SDTM原始数据导入、数据核查QC，构建ADaM数据集，最后生成基线人口统计TLF表格，完整复刻药企SAS统计程序员日常工作链路。
