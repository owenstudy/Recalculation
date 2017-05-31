# Recalculation
# 保费重算

### 保费重算脚本文件说明
####
		计算全部数据的保费
		12-TARGET_PREM_RECALC.sql
		保单级别的保费重算
		12-TARGET_PREM_RECALC_PerPolicy.sql
		查询重算的结果总结
		12-TARGET_PREM_RECALC_QueryResult.sql
		
# CV重算

### CV脚本需要在转换之前初始化好源系统的CV值在表dc_legacy_cashvalue中
####
		policy_id number(10), 
		item_id number(10), 
		policy_no varchar2(20),
		old_cashvalue number(12,2), 
		cashvalue_date date,
		prod_cd varchar2(10)
		
### CV重算脚本文件说明
####
		计算全部数据的CV
		13-TARGET_CASH_VAlUE_RECALC.sql
		计算保单级别的CV
		13-TARGET_CASH_VAlUE_RECALC_PerPolicy.sql  
		对重算的结果进行查询
		13-TARGET_CASH_VAlUE_RECALC_QueryResult.sql
