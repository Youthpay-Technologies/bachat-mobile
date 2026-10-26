begin;
create temporary table receipt_fixture_ids(label text primary key,id uuid not null);
insert into receipt_fixture_ids values ('owner',gen_random_uuid()),('other',gen_random_uuid()),('unverified',gen_random_uuid()),('goal_a',gen_random_uuid()),('goal_b',gen_random_uuid()),('foreign_goal',gen_random_uuid()),('receipt_a',gen_random_uuid()),('receipt_b',gen_random_uuid());
insert into auth.users(id,aud,role,email,email_confirmed_at,is_anonymous)
 select id,'authenticated','authenticated','receipt-test-'||id||'@example.invalid',
 case when label='unverified' then null else now() end,false from receipt_fixture_ids where label in ('owner','other','unverified');
insert into public.profiles(id,name,role,age) select id,label,'teen',16 from receipt_fixture_ids where label in ('owner','other','unverified');
select set_config('test.receipt_owner',(select id::text from receipt_fixture_ids where label='owner'),true);
select set_config('test.receipt_other',(select id::text from receipt_fixture_ids where label='other'),true);
select set_config('test.receipt_unverified',(select id::text from receipt_fixture_ids where label='unverified'),true);
select set_config('test.goal_a',(select id::text from receipt_fixture_ids where label='goal_a'),true);
select set_config('test.goal_b',(select id::text from receipt_fixture_ids where label='goal_b'),true);
select set_config('test.foreign_goal',(select id::text from receipt_fixture_ids where label='foreign_goal'),true);
select set_config('test.receipt_a',(select id::text from receipt_fixture_ids where label='receipt_a'),true);
select set_config('test.receipt_b',(select id::text from receipt_fixture_ids where label='receipt_b'),true);
insert into public.savings_goals(id,owner_id,title,target_minor,saved_minor) values
 (current_setting('test.goal_a')::uuid,current_setting('test.receipt_owner')::uuid,'Goal A',10000,1000),
 (current_setting('test.goal_b')::uuid,current_setting('test.receipt_owner')::uuid,'Goal B',10000,0),
 (current_setting('test.foreign_goal')::uuid,current_setting('test.receipt_other')::uuid,'Other goal',10000,0);
set local role authenticated;
select set_config('request.jwt.claims',json_build_object('sub',current_setting('test.receipt_owner'),'role','authenticated')::text,true);
insert into public.transactions(id,owner_id,merchant,amount_minor,direction,category,occurred_at,savings_goal_id,savings_amount_minor)
 values(current_setting('test.receipt_a')::uuid,auth.uid(),'Gift A',10000,'income','Gift',now(),current_setting('test.goal_a')::uuid,3000);
update public.transactions set savings_amount_minor=4000 where id=current_setting('test.receipt_a')::uuid;
do $$begin
 if (select saved_minor from public.savings_goals where id=current_setting('test.goal_a')::uuid)<>1000 then raise exception 'Receipt duplicated the manual goal counter'; end if;
 begin update public.transactions set savings_amount_minor=10001 where id=current_setting('test.receipt_a')::uuid; raise exception 'Receipt amount overflow accepted'; exception when check_violation then null; end;
 begin update public.transactions set savings_amount_minor=9500 where id=current_setting('test.receipt_a')::uuid; raise exception 'Goal overflow accepted'; exception when check_violation then null; end;
 begin update public.transactions set savings_goal_id=current_setting('test.foreign_goal')::uuid where id=current_setting('test.receipt_a')::uuid; raise exception 'Foreign goal accepted'; exception when check_violation then null; end;
 begin update public.transactions set direction='expense' where id=current_setting('test.receipt_a')::uuid; raise exception 'Expense allocation accepted'; exception when check_violation then null; end;
 begin update public.savings_goals set target_minor=4000 where id=current_setting('test.goal_a')::uuid; raise exception 'Target below funding accepted'; exception when check_violation then null; end;
 begin update public.savings_goals set deleted=true where id=current_setting('test.goal_a')::uuid; raise exception 'Funded goal removal accepted'; exception when check_violation then null; end;
end$$;
update public.savings_goals set saved_minor=0,target_minor=4000 where id=current_setting('test.goal_a')::uuid;
update public.savings_goals set target_minor=6000 where id=current_setting('test.goal_b')::uuid;
insert into public.transactions(id,owner_id,merchant,amount_minor,direction,category,occurred_at,savings_goal_id,savings_amount_minor)
 values(current_setting('test.receipt_b')::uuid,auth.uid(),'Gift B',10000,'income','Gift',now(),current_setting('test.goal_b')::uuid,6000);
-- A receipt swap and both target edits require one atomic final-state check.
select public.apply_money_changes(jsonb_build_array(
 jsonb_build_object('table','savings_goals','row',(select to_jsonb(g)||jsonb_build_object('target_minor',6000) from public.savings_goals g where id=current_setting('test.goal_a')::uuid)),
 jsonb_build_object('table','savings_goals','row',(select to_jsonb(g)||jsonb_build_object('target_minor',4000) from public.savings_goals g where id=current_setting('test.goal_b')::uuid)),
 jsonb_build_object('table','transactions','row',(select to_jsonb(t)||jsonb_build_object('savings_goal_id',current_setting('test.goal_b')) from public.transactions t where id=current_setting('test.receipt_a')::uuid)),
 jsonb_build_object('table','transactions','row',(select to_jsonb(t)||jsonb_build_object('savings_goal_id',current_setting('test.goal_a')) from public.transactions t where id=current_setting('test.receipt_b')::uuid))));
insert into public.cash_balances(id,owner_id,amount_minor,ledger_net_minor) values(auth.uid(),auth.uid(),20000,0);
do $$begin
 if (select sum(savings_amount_minor) from public.transactions where savings_goal_id=current_setting('test.goal_a')::uuid)<>6000 then raise exception 'Atomic swap failed'; end if;
 begin
 perform public.apply_money_changes(jsonb_build_array(
  jsonb_build_object('table','cash_balances','row',jsonb_build_object('id',auth.uid(),'owner_id',auth.uid(),'amount_minor',99999,'ledger_net_minor',0)),
  jsonb_build_object('table','transactions','row',(select to_jsonb(t)||jsonb_build_object('savings_amount_minor',7000) from public.transactions t where id=current_setting('test.receipt_b')::uuid))));
 raise exception 'Invalid atomic batch accepted'; exception when check_violation then null; end;
 if (select amount_minor from public.cash_balances where id=auth.uid())<>20000 then raise exception 'Atomic failure partially changed cash'; end if;
 if (select savings_amount_minor from public.transactions where id=current_setting('test.receipt_b')::uuid)<>6000 then raise exception 'Atomic failure partially changed receipt'; end if;
end$$;
-- Unassigning a receipt and removing its goal sync together without FK races.
select public.apply_money_changes(jsonb_build_array(
 jsonb_build_object('table','transactions','row',(select to_jsonb(t)||jsonb_build_object('savings_goal_id',null,'savings_amount_minor',0) from public.transactions t where id=current_setting('test.receipt_a')::uuid)),
 jsonb_build_object('table','savings_goals','row',(select to_jsonb(g)||jsonb_build_object('deleted',true) from public.savings_goals g where id=current_setting('test.goal_b')::uuid))));
select set_config('request.jwt.claims',json_build_object('sub',current_setting('test.receipt_other'),'role','authenticated')::text,true);
do $$begin
 if exists(select 1 from public.transactions where owner_id=current_setting('test.receipt_owner')::uuid) then raise exception 'Other owner rows leaked'; end if;
 begin perform public.apply_money_changes(jsonb_build_array(jsonb_build_object('table','cash_balances','row',jsonb_build_object('id',current_setting('test.receipt_owner'),'owner_id',current_setting('test.receipt_owner'),'amount_minor',1,'ledger_net_minor',0)))); raise exception 'Spoofed atomic owner accepted'; exception when insufficient_privilege then null; end;
end$$;
select set_config('request.jwt.claims',json_build_object('sub',current_setting('test.receipt_unverified'),'role','authenticated')::text,true);
do $$begin
 begin perform public.apply_money_changes('[]'::jsonb); raise exception 'Unverified atomic access accepted'; exception when insufficient_privilege then null; end;
end$$;
rollback;
