----��ѯ����Ľ��

---���ڲ�Ʒ��ͨ����
-------check the product level recalculation result
  select  aa.product_id, bb.internal_id, pass_amt, total_amt, total_amt-pass_amt failed_amt, round(pass_amt/total_amt,2) passrate  from (
 select product_id,  sum(decode(a.passed,'Y',1,0)) Pass_Amt,count(*) total_amt from dc_contract_product a group by a.product_id
 ) aa, t_product_life bb where aa.product_id=bb.product_id
 order by failed_amt desc ;

--���н���ܵ�pass rate
-----------total pass rate
 select   pass_amt, total_amt, round(pass_amt/total_amt,2) passrate  from (
  select  sum(decode(a.passed,'Y',1,0)) Pass_Amt,count(*) total_amt from dc_contract_product a
 );
