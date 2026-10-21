-- Transactional fixtures only: all test accounts and records roll back.
begin;
insert into auth.users(id,instance_id,aud,role,email,email_confirmed_at,is_anonymous,created_at,updated_at)
values
 ('10000000-0000-4000-a000-000000000001','00000000-0000-0000-0000-000000000000','authenticated','authenticated','rls-a@example.invalid',now(),false,now(),now()),
 ('10000000-0000-4000-a000-000000000002','00000000-0000-0000-0000-000000000000','authenticated','authenticated','rls-b@example.invalid',now(),false,now(),now()),
 ('10000000-0000-4000-a000-000000000003','00000000-0000-0000-0000-000000000000','authenticated','authenticated','rls-unverified@example.invalid',null,false,now(),now());
insert into public.profiles(id,name,role,age) values
 ('10000000-0000-4000-a000-000000000002','Other teen','teen',15),
 ('10000000-0000-4000-a000-000000000003','Unverified teen','teen',16);
set local role authenticated;
select set_config('request.jwt.claims','{"sub":"10000000-0000-4000-a000-000000000001","role":"authenticated","is_anonymous":false}',true);
insert into public.profiles(id,name,role,age) values('10000000-0000-4000-a000-000000000001','Test teen','teen',16);
insert into public.transactions(id,owner_id,merchant,amount_minor,direction,category,occurred_at) values
 ('20000000-0000-4000-a000-000000000001','10000000-0000-4000-a000-000000000001','Test',12550,'expense','Other',now());
insert into public.budgets(id,owner_id,category,limit_minor,month) values
 ('30000000-0000-4000-a000-000000000001','10000000-0000-4000-a000-000000000001','Other',100000,date_trunc('month',now())::date);
insert into public.savings_goals(id,owner_id,title,target_minor,saved_minor) values
 ('40000000-0000-4000-a000-000000000001','10000000-0000-4000-a000-000000000001','Goal',10000,100);
do $$begin
 if (select count(*) from public.profiles)<>1 then raise exception 'Other profile leaked'; end if;
 if (select count(*) from public.transactions)<>1 then raise exception 'Owner access without parent failed'; end if;
 begin
  insert into public.transactions(id,owner_id,merchant,amount_minor,direction,category,occurred_at) values(gen_random_uuid(),'10000000-0000-4000-a000-000000000002','Spoof',100,'expense','Other',now());
  raise exception 'Ownership spoof accepted';
 exception when insufficient_privilege then null; end;
 begin
  update public.transactions set owner_id='10000000-0000-4000-a000-000000000002';
  raise exception 'Owner reassignment accepted';
 exception when others then
  if sqlerrm='Owner reassignment accepted' then raise; end if;
 end;
 begin
  update public.profiles set age=19;
  raise exception 'Immutable age changed';
 exception when others then
  if sqlerrm='Immutable age changed' then raise; end if;
 end;
 begin
  insert into public.budgets(id,owner_id,category,limit_minor,month) values(gen_random_uuid(),'10000000-0000-4000-a000-000000000001','Other',100,date_trunc('month',now())::date);
  raise exception 'Duplicate category accepted';
 exception when unique_violation then null; end;
 begin
  update public.transactions set amount_minor=0;
  raise exception 'Zero amount accepted';
 exception when check_violation then null; end;
 begin
  update public.transactions set category='Invalid';
  raise exception 'Unknown category accepted';
 exception when check_violation then null; end;
 begin
  update public.savings_goals set saved_minor=target_minor+1;
  raise exception 'Goal overflow accepted';
 exception when check_violation then null; end;
end$$;
update public.transactions set amount_minor=12600,deleted=true;
update public.budgets set limit_minor=150000;
update public.savings_goals set saved_minor=500;
select set_config('request.jwt.claims','{"sub":"10000000-0000-4000-a000-000000000002","role":"authenticated"}',true);
do $$begin
 if exists(select 1 from public.transactions) or exists(select 1 from public.budgets) or exists(select 1 from public.savings_goals) then raise exception 'Cross-account records leaked'; end if;
end$$;
select set_config('request.jwt.claims','{"sub":"10000000-0000-4000-a000-000000000003","role":"authenticated"}',true);
do $$begin
 begin
  insert into public.transactions(id,owner_id,merchant,amount_minor,direction,category,occurred_at) values(gen_random_uuid(),'10000000-0000-4000-a000-000000000003','Test',100,'expense','Other',now());
  raise exception 'Unverified user wrote data';
 exception when insufficient_privilege then null; end;
end$$;
reset role;
-- Parent profile creation is rejected even through a direct authenticated request.
insert into auth.users(id,instance_id,aud,role,email,email_confirmed_at,is_anonymous,created_at,updated_at) values
 ('10000000-0000-4000-a000-000000000004','00000000-0000-0000-0000-000000000000','authenticated','authenticated','rls-parent@example.invalid',now(),false,now(),now());
set local role authenticated;
select set_config('request.jwt.claims','{"sub":"10000000-0000-4000-a000-000000000004","role":"authenticated"}',true);
do $$begin
 begin
  insert into public.profiles(id,name,role) values('10000000-0000-4000-a000-000000000004','Parent','parent');
  raise exception 'Parent registration accepted';
 exception when insufficient_privilege then null; end;
 if has_function_privilege('authenticated','public.claim_family_code(text)','execute') then raise exception 'Family RPC remains enabled'; end if;
end$$;
rollback;
select 'Teen ownership, isolation, verification, validation and CRUD checks passed' as result;
