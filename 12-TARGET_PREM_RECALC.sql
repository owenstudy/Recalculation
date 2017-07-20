set timing on;
spool 12-TARGET_PREM_RECALC.log
whenever oserror exit commit;
whenever sqlerror exit commit;
set feedback on  --conflict
set echo on
set define off  --nothing to change
set sqlblanklines on
select to_char(sysdate,'YYYY/MM/DD HH:MI:SS') from dual;

-----初始化标志位，对于没有通过的processed='Y',下次再重新跑的时候只跑没有通过的记录
update DC_CONTRACT_PRODUCT a set a.processed='N' where a.passed='N'; 

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
      (ABS(a.std_prem_bf   -  a.o_std_prem_bf ) >decode(a.money_id,4,1,21,5)
    or abs(a.std_prem_af    -  a.o_std_prem_af) > decode(a.money_id,4,1,21,5)
    or abs(a.gross_prem_af - a.o_gross_prem_af) > decode(a.money_id,4,1,21,5)
    or abs(a.total_prem_af  - a.o_total_prem_af) > decode(a.money_id,4,1,21,5)
    or abs(a.discnted_prem_bf - a.o_discnted_prem_bf) > decode(a.money_id,4,1,21,5)
    or abs(a.discnted_prem_af - a.o_discnted_prem_af) > decode(a.money_id,4,1,21,5)
    or abs(a.extra_prem_bf - a.o_extra_prem_bf) > decode(a.money_id,4,1,21,5)
    or abs(a.extra_prem_af - a.o_extra_prem_af) > decode(a.money_id,4,1,21,5)
)
 and  a.liability_state<>3;
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
commit;
spool off
