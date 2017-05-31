whenever sqlerror exit commit;-----end
set timing on;
spool 13-TARGET_CASH_VAlUE_RECALC.log
select to_char(sysdate,'YYYY/MM/DD HH:MI:SS') from dual;
--comments:Create the table to keep the recalculated value
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------cash value calculation
whenever sqlerror continue commit;-----begin
drop table DC_CONTRACT_PRODUCT_CASHVALUE; 
CREATE table DC_CONTRACT_PRODUCT_CASHVALUE (
         ITEM_ID                   NUMBER(10),
         POLICY_ID                 NUMBER(10),
         PRODUCT_ID                NUMBER(10),
         LIABILITY_STATE              NUMBER(2),
         END_DATE                        DATE,                 -- CASH VALUE OF CALCULATION DATE
         PROCESSED                        VARCHAR2(1) DEFAULT 'N',
         PASSED         VARCHAR2(2)       DEFAULT 'Y',
         AMOUNT                                                                                     NUMBER(18,4) ,
         O_VALUE                                                   NUMBER(18,4) , -- SA surrender value
         O_SV_REV_BONUS            NUMBER(18,4) , -- SV of reversionary bonus
         O_SV_TERMINAL_BONUS       NUMBER(18,4) , -- SV of terminal bonus
         O_SV_GROSS                                   NUMBER(18,4),  -- Gross SV=O_VALUE + O_SV_REV_BONUS + O_SV_TERMINAL_BONUS + O_SV_INT_BONUS
         O_SV_INT_BONUS            NUMBER(18,4),  -- SV of interim bonus
         OA_VALUE         NUMBER(18,4) , -- current sum assured
         OA_REV_BONUS              NUMBER(18,4) , -- accumulated bonus
         OA_TERMINAL_BONUS         NUMBER(18,4) , -- terminal bonus
         OA_GROSS                                   NUMBER(18,4),  -- adjusted bonus amout
         OA_INT_BONUS              NUMBER(18,4),  -- interim bonus
         OS_VALUE        NUMBER(18,4) , 
         OS_REV_BONUS            NUMBER(18,4) , 
         OS_TERMINAL_BONUS         NUMBER(18,4) , 
         OS_GROSS            NUMBER(18,4),  
         OS_INT_BONUS              NUMBER(18,4),  
         o_fact_paidup1   NUMBER(18,4),---ui paid up factor without survival benefit
         o_fact_paidup2   NUMBER(18,4),---ui paid up factor with survival benefit
         o_fact_sv1   NUMBER(18,4),---ui sv factor without survival benefit
         o_fact_sv2   NUMBER(18,4),---ui sv factor with survival benefit
         o_fact_bonus   NUMBER(18,4),---ui bonus factor
         o_fact_terminal_bonus   NUMBER(18,4),---ui terminal bonus factor
         o_duration varchar2(100),  --ui policy/benefit duration
         ERROR_MSG                      VARCHAR2(2000),
         error_type         number(12),
         analysis_result    VARCHAR2(4000),
         refer_script    VARCHAR2(4000),
         prem_status   char(1)
);
--comments:Generte the recalculated data
--module name:TARGET_CASH_VAlUE_RECALC,table name:T_CONTRACT_PRODUCT,table sequence:1,--script seq:2
whenever sqlerror exit commit;-----end
insert into   DC_CONTRACT_PRODUCT_CASHVALUE
(ITEM_ID            ,       
  POLICY_ID          ,       
  PRODUCT_ID         ,       
  LIABILITY_STATE    ,             
  END_DATE           ,        
  PROCESSED          ,         
  AMOUNT                                                       )
select 
a.ITEM_ID              ,                                
a.POLICY_ID            ,     
PRODUCT_ID           ,     
LIABILITY_STATE      ,       
to_date(&CV_Recalc_Date_yyyy_mm_dd,'YYYY/MM/DD'),
'N'                       ,
AMOUNT                                  
from t_contract_product a,t_contract_extend b
where a.item_id=b.item_id
and liability_state in (1)
AND exists(select 1 from t_product_life b where a.product_id=b.product_id and SURR_PERMIT<>0) 
and a.derivation=2
--a.count_way <> '3' 
and product_id NOT in (434)
;
whenever sqlerror continue commit;-----begin
create index idx_CONTRACT_PRODUCT_CASHVALUE on DC_CONTRACT_PRODUCT_CASHVALUE(item_id);

--comments:Build the recalculated function
--module name:TARGET_CASH_VAlUE_RECALC,table name:T_CONTRACT_PRODUCT,table sequence:1,--script seq:3
create or replace  procedure P_CV_recalc_ByItem(I_Item_id number) is
   v_VALUE number(18,4);
   v_SV_REV_BONUS number(18,4);
   v_SV_TERMINAL_BONUS number(18,4);
   v_SV_GROSS number(18,4);
   v_sv_int_bonus number(18,4);
   v_end_date date;
   v_cnt integer;
   v_sqlerrm varchar2(4000);
begin
   select count(*) into v_cnt from DC_CONTRACT_PRODUCT_CASHVALUE where item_id=I_Item_id and processed='N';
   if v_cnt=1 then 
      select end_date into v_end_date from DC_CONTRACT_PRODUCT_CASHVALUE where item_id=I_Item_id and processed='N';
      PKG_LS_PM_CALC_SURRENDER_VALUE.p_get_surrender_value(i_item_id,v_end_date,1,
                         v_VALUE,v_SV_REV_BONUS,v_SV_TERMINAL_BONUS,v_SV_GROSS,v_sv_int_bonus);
      update DC_CONTRACT_PRODUCT_CASHVALUE SET (o_VALUE,o_SV_REV_BONUS,o_SV_TERMINAL_BONUS,o_SV_GROSS,o_sv_int_bonus,processed)
            =(SELECT v_VALUE,v_SV_REV_BONUS,v_SV_TERMINAL_BONUS,v_SV_GROSS,v_sv_int_bonus,'Y' from dual)
            where item_id=I_Item_id;        
   end if; 
       
exception when others then 
   v_sqlerrm := sqlerrm;
   update DC_CONTRACT_PRODUCT_CASHVALUE SET processed = 'W',error_msg = v_sqlerrm where item_id = I_Item_id;
end ;
/    
--comments:Run the recalculation function.
--module name:TARGET_CASH_VAlUE_RECALC,table name:T_CONTRACT_PRODUCT,table sequence:1,--script seq:4
declare
cursor cur_rec is select * from DC_CONTRACT_PRODUCT_CASHVALUE a where a.processed='N';
begin
         pkg_pub_app_context.P_SET_APP_USER_ID(315);
  for c_rec in cur_rec loop
     P_CV_recalc_ByItem(c_rec.item_id);
     commit;
   end loop;
end ;    
/

--create temp cash value table
--drop table DC_CONTRACT_PRODUCT_CASHVALUE;
whenever sqlerror continue commit;-----begin
alter table dc_contract_product_cashvalue add( policy_no varchar2(16));
whenever sqlerror exit commit;-----end
merge into dc_contract_product_cashvalue a  using 
 t_contract_master  b
on (a.policy_id=b.policy_id) 
  when matched then 
    update set a.policy_no=b.policy_code;
commit;

--drop table DC_CONTRACT_PRODUCT_CASHVALUE;
whenever sqlerror continue commit;-----begin
alter table dc_contract_product_cashvalue add(prod_cd varchar2(100));
whenever sqlerror exit commit;-----end
/*
merge into dc_contract_product_cashvalue a  using 
 dc_gtis_nb_cont_prod  b
on (a.item_id=b.dc_item_id) 
  when matched then 
    update set a.prod_cd=b.prod_cd;
commit;
*/

whenever sqlerror continue commit;-----begin
--这个表需要在重算之前处理好
drop table dc_legacy_cashvalue; 
create table dc_legacy_cashvalue (
  policy_id number(10), 
  item_id number(10), 
  policy_no varchar2(20),
  old_cashvalue number(12,2), 
  cashvalue_date date,
  prod_cd varchar2(10)
  );

create index dc_cashvalue_item_id on dc_contract_product_cashvalue(item_id);
create index dc_cashvalue_prod_cd on dc_contract_product_cashvalue(prod_cd);
create index dc_cash_item_id on dc_legacy_cashvalue(item_id);
create index dc_cash_prod_cd on dc_legacy_cashvalue(prod_cd);
alter table dc_contract_product_cashvalue add(old_cashvalue NUMBER(18,2));
whenever sqlerror exit commit;-----end
update  dc_contract_product_cashvalue a  set a.old_cashvalue=
(select distinct b.old_cashvalue from dc_legacy_cashvalue b where /*b.prod_cd=a.prod_cd and*/ a.item_id=b.item_id);
commit;
update dc_contract_product_cashvalue a set a.passed='N' where a.error_msg is not null;
commit;
update dc_contract_product_cashvalue a set a.passed='N' where 
      ABS(a.o_value - a.old_cashvalue ) >5  
 and a.product_id<>434 and a.liability_state<>3;
commit;

---------------------------------------------The end-----------------------------------
select to_char(sysdate,'YYYY/MM/DD HH:MI:SS') from dual;
commit;
spool off
