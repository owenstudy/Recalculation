set timing on;
spool 12-TARGET_PREM_RECALC.log
whenever oserror exit commit;
whenever sqlerror exit commit;
set feedback on
set echo on
set define off
set sqlblanklines on
select to_char(sysdate,'YYYY/MM/DD HH:MI:SS') from dual;
insert into dc_module_run_time(pro_id,module_name) values(2,'TARGET_PREM_RECALC');
update dc_module_run_time set begin_time=to_char(sysdate,'YYYY/MM/DD HH:MI:SS')  where pro_id=2 and module_name='TARGET_PREM_RECALC';
/*=======================================================================Begin module level  section */
/*=======================================================================End   module level  section */

/*=======================================================================Begin table initial script  section */
/*=======================================================================End   table initial script  section */

/*=======================================================================Begin table check error script  section */
/*=======================================================================End   table check error script  section */

/*=======================================================================Begin table level: T_CONTRACT_PRODUCT(1)  before insert section */
/*=======================================================================End   table level: T_CONTRACT_PRODUCT(1)  before insert section */

/*=======================================================================Begin column level: T_CONTRACT_PRODUCT(1)  before insert section */
/*=======================================================================End   column level: T_CONTRACT_PRODUCT(1)  before insert section */

/*=======================================================================Begin column level: T_CONTRACT_PRODUCT(1)  after insert section */
/*=======================================================================End   column level: T_CONTRACT_PRODUCT(1)  after insert section */

/*=======================================================================Begin table level: T_CONTRACT_PRODUCT(1)  after insert section */
--comments:---create table table 
--module name:TARGET_PREM_RECALC,table name:T_CONTRACT_PRODUCT,table sequence:1,--script seq:1
------------calculate prem
CREATE TABLE DC_CONTRACT_PRODUCT (
	ITEM_ID            NUMBER(10),
	POLICY_ID          NUMBER(10),
	PRODUCT_ID         NUMBER(10),
	Master_id          NUMBER(10),
	MONEY_ID         NUMBER(10),
	LIABILITY_STATE    NUMBER(2),
	PROCESSED          VARCHAR2(1) DEFAULT 'N',             
	PASSED               VARCHAR2(1) DEFAULT 'Y',             
	IO_AMOUNT          NUMBER(18,3) ,
	STD_PREM_BF        NUMBER(18,2), 
	O_STD_PREM_BF      NUMBER(18,3) ,
	STD_PREM_AF        NUMBER(18,2),
	O_STD_PREM_AF      NUMBER(18,3) ,
	GROSS_PREM_AF      NUMBER(18,2),
	O_GROSS_PREM_AF    NUMBER(18,3) ,
	TOTAL_PREM_AF      NUMBER(18,2),
	O_TOTAL_PREM_AF    NUMBER(18,3) ,
	DISCNTED_PREM_BF   NUMBER(18,2),
	O_DISCNT_PREM_BF1  NUMBER(18,3) ,
	DISCNTED_PREM_AF   NUMBER(18,2),
	O_DISCNT_PREM_AF1  NUMBER(18,3) ,
	EXTRA_PREM_BF      NUMBER(18,2),
	O_EXTRA_PREM_BF1   NUMBER(18,3) ,
	EXTRA_PREM_AF      NUMBER(18,2),
	O_EXTRA_PREM_AF    NUMBER(18,3) ,
	O_DISCNT_PREM_BF2  NUMBER(18,3) ,
	O_DISCNT_PREM_BF3  NUMBER(18,3) ,
	O_DISCNT_PREM_BF4  NUMBER(18,3) ,
	O_DISCNT_PREM_BF5  NUMBER(18,3) ,
	O_DISCNT_PREM_AF2  NUMBER(18,3) ,
	O_DISCNT_PREM_AF3  NUMBER(18,3) ,
	O_DISCNT_PREM_AF4  NUMBER(18,3) ,
	O_DISCNT_PREM_AF5  NUMBER(18,3) ,
	O_DISCNT_PREM_BF   NUMBER(18,3) ,
	O_DISCNT_PREM_AF   NUMBER(18,3) ,
	O_DISCNTED_PREM_BF NUMBER(18,3) ,
	O_DISCNTED_PREM_AF NUMBER(18,3) ,
	O_POLICY_FEE_AF    NUMBER(18,3) ,
	O_EXTRA_PREM_BF2   NUMBER(18,3) ,
	O_EXTRA_PREM_BF3   NUMBER(18,3) ,
	O_EXTRA_PREM_BF4   NUMBER(18,3) ,
	O_EXTRA_PREM_BF5   NUMBER(18,3) ,
	O_EXTRA_PREM_BF    NUMBER(18,3) ,
	ERROR_MSG          VARCHAR2(2000),
	error_type         number(2),
	analysis_result    VARCHAR2(4000),
	refer_script       VARCHAR2(4000)
);

create or replace synonym DC_CONTRACT_PRODUCT for DC_CONTRACT_PRODUCT ;
--comments:----Generate the recalculated data from target table 
--module name:TARGET_PREM_RECALC,table name:T_CONTRACT_PRODUCT,table sequence:1,--script seq:2
Insert into  DC_CONTRACT_PRODUCT nologging (item_id,POLICY_ID,product_id,money_id,LIABILITY_STATE,master_id,
STD_PREM_BF     ,
STD_PREM_AF     ,
GROSS_PREM_AF  , 
TOTAL_PREM_AF   ,
DISCNTED_PREM_BF,
DISCNTED_PREM_AF,
EXTRA_PREM_BF   ,
EXTRA_PREM_AF   
) 
select a.item_id ,a.POLICY_ID,a.product_id,b.money_id,a.LIABILITY_STATE,master_id,
STD_PREM_BF     ,
STD_PREM_AF     ,
GROSS_PREM_AF  , 
TOTAL_PREM_AF   ,
DISCNTED_PREM_BF,
DISCNTED_PREM_AF,
EXTRA_PREM_BF   ,
EXTRA_PREM_AF   
 from t_contract_product a,  t_contract_master b
where exists(select 1 from dm_contract_product b where a.policy_id=b.policy_id) and a.liability_state in(1,2) and product_id<>434
and exists(select 1 from t_contract_extend where item_id=a.item_id and prem_status=1)
and a.policy_id=b.policy_id;

create  index is_contract_product_dc on dc_contract_product(item_id) nologging;
--comments:--Create the recalculated function
--module name:TARGET_PREM_RECALC,table name:T_CONTRACT_PRODUCT,table sequence:1,--script seq:3
create or replace function f_calc_prem(v_item_id in number) RETURN varchar 
 is
  v_due_date              date;
  v_derivation            char(1);
  v_amount                number(18,3);
  v_std_prem_bf           NUMBER(18,3);
  v_std_prem_af           NUMBER(18,3);
  v_discnt_prem_bf1       NUMBER(18,3);
  v_discnt_prem_bf2       NUMBER(18,3);
  v_discnt_prem_bf3       NUMBER(18,3);
  v_discnt_prem_bf4       NUMBER(18,3);
  v_discnt_prem_bf5       NUMBER(18,3);
  v_discnt_prem_af1       NUMBER(18,3);
  v_discnt_prem_af2       NUMBER(18,3);
  v_discnt_prem_af3       NUMBER(18,3);
  v_discnt_prem_af4       NUMBER(18,3);
  v_discnt_prem_af5       NUMBER(18,3);
  v_discnt_prem_bf        NUMBER(18,3);
  v_discnt_prem_af        NUMBER(18,3);
  v_discnted_prem_bf      NUMBER(18,3);
  v_discnted_prem_af      NUMBER(18,3);
  v_policy_fee_af         NUMBER(18,3);
  v_extra_prem_bf1        NUMBER(18,3);
  v_extra_prem_bf2        NUMBER(18,3);
  v_extra_prem_bf3        NUMBER(18,3);
  v_extra_prem_bf4        NUMBER(18,3);
  v_extra_prem_bf5        NUMBER(18,3);
  v_extra_prem_bf         NUMBER(18,3);
  v_extra_prem_af         NUMBER(18,3);
  v_gross_prem_af         NUMBER(18,3);
  v_total_prem_af         NUMBER(18,3);
  v_prem_status char(1);
  v_error varchar2(2000);
begin
 select decode(a.liability_state,0,a.submission_date,b.due_date),a.amount,derivation,b.prem_status
  into v_due_date,v_amount,v_derivation,v_prem_status  from t_contract_product a,t_contract_extend b
   where a.item_id = v_item_id and a.item_id=b.item_id;
   if v_prem_status=2 then
     v_due_date:=v_due_date -1;
    end if;
     pkg_ls_pm_calc.p_calc_main (
         v_item_id,
         v_due_date,
         v_derivation,
         'N',
         'N',
         v_amount,
         v_std_prem_bf       ,
         v_std_prem_af       ,
         v_discnt_prem_bf1   ,
         v_discnt_prem_bf2   ,
         v_discnt_prem_bf3   ,
         v_discnt_prem_bf4   ,
         v_discnt_prem_bf5   ,
         v_discnt_prem_af1   ,
         v_discnt_prem_af2   ,
         v_discnt_prem_af3   ,
         v_discnt_prem_af4   ,
         v_discnt_prem_af5   ,
         v_discnt_prem_bf    ,
         v_discnt_prem_af    ,
         v_discnted_prem_bf  ,
         v_discnted_prem_af  ,
         v_policy_fee_af     ,
         v_extra_prem_bf1    ,
         v_extra_prem_bf2    ,
         v_extra_prem_bf3    ,
         v_extra_prem_bf4    ,
         v_extra_prem_bf5    ,
         v_extra_prem_bf     ,
         v_extra_prem_af     ,
         v_gross_prem_af     ,
         v_total_prem_af     );
         update dc_contract_product set
                     processed = 'Y' ,
                     io_amount = v_amount,
                     o_std_prem_bf      =v_std_prem_bf     ,
                     o_std_prem_af      =v_std_prem_af     ,
                     o_discnt_prem_bf1  =v_discnt_prem_bf1 ,
                     o_discnt_prem_bf2  =v_discnt_prem_bf2 ,
                     o_discnt_prem_bf3  =v_discnt_prem_bf3 ,
                     o_discnt_prem_bf4  =v_discnt_prem_bf4 ,
                     o_discnt_prem_bf5  =v_discnt_prem_bf5 ,
                     o_discnt_prem_af1  =v_discnt_prem_af1 ,
                     o_discnt_prem_af2  =v_discnt_prem_af2 ,
                     o_discnt_prem_af3  =v_discnt_prem_af3 ,
                     o_discnt_prem_af4  =v_discnt_prem_af4 ,
                     o_discnt_prem_af5  =v_discnt_prem_af5 ,
                     o_discnt_prem_bf   =v_discnt_prem_bf  ,
                     o_discnt_prem_af   =v_discnt_prem_af  ,
                     o_discnted_prem_bf =v_discnted_prem_bf,
                     o_discnted_prem_af =v_discnted_prem_af,
                     o_policy_fee_af    =v_policy_fee_af   ,
                     o_extra_prem_bf1   =v_extra_prem_bf1  ,
                     o_extra_prem_bf2   =v_extra_prem_bf2  ,
                     o_extra_prem_bf3   =v_extra_prem_bf3  ,
                     o_extra_prem_bf4   =v_extra_prem_bf4  ,
                     o_extra_prem_bf5   =v_extra_prem_bf5  ,
                     o_extra_prem_bf    =v_extra_prem_bf   ,
                     o_extra_prem_af    =v_extra_prem_af   ,
                     o_gross_prem_af    =v_gross_prem_af   ,
                     o_total_prem_af    =v_total_prem_af
           where item_id = v_item_id;
           commit;
           return '';
         exception when others then
         v_error:=sqlerrm;
         update dc_contract_product set processed = 'W',error_msg = v_error||'stack trace:'||dbms_utility.format_error_backtrace where item_id =v_item_id;
         commit;
         return v_error||'stack trace:'||dbms_utility.format_error_backtrace;
end;
/
--comments:Run the recalculated procedure
--module name:TARGET_PREM_RECALC,table name:T_CONTRACT_PRODUCT,table sequence:1,--script seq:4
--flag indicating log calculating process or not
update t_para_def set single_para_value= '0' where para_id = 1000164001;

declare
  cursor c_product is select item_id,liability_state from DC_CONTRACT_PRODUCT where PROCESSED='N' ;
v_error varchar2(4000);
begin
pkg_pub_app_context.P_SET_APP_USER_ID(401);
  for v_product in c_product loop
        v_error:=f_calc_prem(v_product.item_id);
        exit when instr(v_error,'maximum open cursors exceededstack trace')>0;
  end loop;
  exception when others then
  --dbms_output.put_line(sqlerrm);
  null;
end;
/
--comments:--restore the parameter and analyze table
--module name:TARGET_PREM_RECALC,table name:T_CONTRACT_PRODUCT,table sequence:1,--script seq:5
update t_para_def set single_para_value= '1' where para_id = 1000164001;
analyze table dc_contract_product compute statistics;

---Update the unpassed records.
update dc_contract_product a set a.passed='N' where a.error_msg is not null;

update dc_contract_product a set a.passed='N' where 
      (ABS(a.std_prem_bf   -  a.o_std_prem_bf ) >decode(a.money_id,4,1,8,5)
    or abs(a.std_prem_af    -  a.o_std_prem_af) > decode(a.money_id,4,1,8,5)
    or abs(a.gross_prem_af - a.o_gross_prem_af) > decode(a.money_id,4,1,8,5)
    or abs(a.total_prem_af  - a.o_total_prem_af) > decode(a.money_id,4,1,8,5)
    or abs(a.discnted_prem_bf - a.o_discnted_prem_bf) > decode(a.money_id,4,1,8,5)
    or abs(a.discnted_prem_af - a.o_discnted_prem_af) > decode(a.money_id,4,1,8,5)
    or abs(a.extra_prem_bf - a.o_extra_prem_bf) > decode(a.money_id,4,1,8,5)
    or abs(a.extra_prem_af - a.o_extra_prem_af) > decode(a.money_id,4,1,8,5)
)
 and exists(select 1 from dm_contract_product bb where a.policy_id=bb.policy_id)
 and a.product_id<>434 and a.liability_state<>3;
commit;
--comments:--check the recalculated result
--module name:TARGET_PREM_RECALC,table name:T_CONTRACT_PRODUCT,table sequence:1,--script seq:6
----------check sql
-------check the product level recalculation result
/*
  select  aa.product_id, bb.internal_id, pass_amt, total_amt, total_amt-pass_amt failed_amt, round(pass_amt/total_amt,2) passrate  from (
 select product_id,  sum(decode(a.passed,'Y',1,0)) Pass_Amt,count(*) total_amt from dc_contract_product a group by a.product_id
 ) aa, t_product_life bb where aa.product_id=bb.product_id
 order by failed_amt desc ;
*/

-----------total pass rate
/*
 select   pass_amt, total_amt, round(pass_amt/total_amt,2) passrate  from (
  select  sum(decode(a.passed,'Y',1,0)) Pass_Amt,count(*) total_amt from dc_contract_product a
 );
*/
/*=======================================================================End   table level: T_CONTRACT_PRODUCT(1)  after insert section */

/*=======================================================================Begin module level  section */
/*=======================================================================End   module level  section */

---------------------------------------------The end-----------------------------------
select to_char(sysdate,'YYYY/MM/DD HH:MI:SS') from dual;
update dc_module_run_time set end_time=to_char(sysdate,'YYYY/MM/DD HH24:MI:SS')  where pro_id=2 and module_name='TARGET_PREM_RECALC';
commit;
spool off
