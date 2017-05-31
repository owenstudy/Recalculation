----运行时直接@这个文件名称即可
----在command窗口     @d:\12-TARGET_PREM_RECALC_PerPolicy.sql   然后输入policy_id即可对该保单进行重算
----更新要计算的保单号
 
update DC_CONTRACT_PRODUCT a set a.PROCESSED='N'，error_msg=null where policy_id=&policy_id;

declare
  cursor c_product is select item_id,liability_state from DC_CONTRACT_PRODUCT where PROCESSED='N' ;
v_error varchar2(4000);
begin
pkg_pub_app_context.P_SET_APP_USER_ID(401);
  for v_product in c_product loop
        v_error:=f_calc_prem(v_product.item_id);
        exit when instr(v_error,'maximum open cursors exceededstack trace')>0;
        commit;
  end loop;
  exception when others then
  --dbms_output.put_line(sqlerrm);
  null;
end;
/
--comments:--restore the parameter and analyze table
--module name:TARGET_PREM_RECALC,table name:T_CONTRACT_PRODUCT,table sequence:1,--script seq:5
update t_para_def set single_para_value= '1' where para_id = 1000164001;

---Update the unpassed records.
update dc_contract_product a set a.passed='N' where a.error_msg is not null;

---定义通过的标准
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
 and derivation=2
 and a.product_id<>434 and a.liability_state<>3;
commit;