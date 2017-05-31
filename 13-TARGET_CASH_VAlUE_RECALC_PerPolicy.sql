--计算单个保单的重算
--清空该保单的计算标志位
update DC_CONTRACT_PRODUCT_CASHVALUE a set a.processed='N', error_msg=null,passed='Y' where a.policy_id=&Policy_id;
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

merge into dc_contract_product_cashvalue a  using 
 t_contract_master  b
on (a.policy_id=b.policy_id) 
  when matched then 
    update set a.policy_no=b.policy_code;
commit;
update  dc_contract_product_cashvalue a  set a.old_cashvalue=
(select distinct b.old_cashvalue from dc_legacy_cashvalue b where /*b.prod_cd=a.prod_cd and*/ a.item_id=b.item_id);
commit;
update dc_contract_product_cashvalue a set a.passed='N' where a.error_msg is not null;
commit;
update dc_contract_product_cashvalue a set a.passed='N' where 
      ABS(a.o_value - a.old_cashvalue ) >5  
 and a.product_id<>434 and a.liability_state<>3;
commit;
