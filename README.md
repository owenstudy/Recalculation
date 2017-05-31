# Recalculation
# 保费重算

---计算全部数据的保费
12-TARGET_PREM_RECALC.sql
---保单级别的保费重算
12-TARGET_PREM_RECALC_PerPolicy.sql
---查询重算的结果总结
12-TARGET_PREM_RECALC_QueryResult.sql

--2017.5.31
优化程序内容，一个批处理可以跑完全部的重算
增加对单个保单进行重算的接口

# CV重算

--CV脚本
需要在转换之前初始化好源系统的CV值在表dc_legacy_cashvalue中

  policy_id number(10), 
  item_id number(10), 
  policy_no varchar2(20),
  old_cashvalue number(12,2), 
  cashvalue_date date,
  prod_cd varchar2(10)
---------------------------------------------------
---计算全部数据的CV
13-TARGET_CASH_VAlUE_RECALC.sql
---计算保单级别的CV
13-TARGET_CASH_VAlUE_RECALC_PerPolicy.sql  
---对重算的结果进行查询
13-TARGET_CASH_VAlUE_RECALC_QueryResult.sql
