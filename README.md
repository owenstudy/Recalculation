# Recalculation
# ��������

### ��������ű��ļ�˵��
####
		��ʼ���������ݣ���һ������ʱ������Ҫȫ���������¼���ʱ��Ҫ��������ű�
		12-TARGET_PREM_RECALC_InitialData.sql
		���㲻ͨ���ı�����¼�������ظ��������
		12-TARGET_PREM_RECALC.sql
		��������ı�������
		12-TARGET_PREM_RECALC_PerPolicy.sql
		��ѯ����Ľ���ܽ�
		12-TARGET_PREM_RECALC_QueryResult.sql
		
# CV����

### CV�ű���Ҫ��ת��֮ǰ��ʼ����Դϵͳ��CVֵ�ڱ�dc_legacy_cashvalue��
####
		policy_id number(10), 
		item_id number(10), 
		policy_no varchar2(20),
		old_cashvalue number(12,2), 
		cashvalue_date date,
		prod_cd varchar2(10)
		
### CV����ű��ļ�˵��
####
		����ȫ�����ݵ�CV
		13-TARGET_CASH_VAlUE_RECALC.sql
		���㱣�������CV
		13-TARGET_CASH_VAlUE_RECALC_PerPolicy.sql  
		������Ľ�����в�ѯ
		13-TARGET_CASH_VAlUE_RECALC_QueryResult.sql
