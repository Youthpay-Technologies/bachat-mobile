begin;
insert into auth.users(id,instance_id,aud,role,email,email_confirmed_at,is_anonymous,created_at,updated_at)
values ('51000000-0000-4000-a000-000000000001','00000000-0000-0000-0000-000000000000',
 'authenticated','authenticated','money-flow@example.invalid',now(),false,now(),now());
insert into public.profiles(id,name,role,age) values
 ('51000000-0000-4000-a000-000000000001','Money test','teen',16);
set local role authenticated;
select set_config('request.jwt.claims','{"sub":"51000000-0000-4000-a000-000000000001","role":"authenticated","is_anonymous":false}',true);
insert into public.transactions(id,owner_id,merchant,amount_minor,direction,category,custom_category,occurred_at)
values
 ('52000000-0000-4000-a000-000000000001','51000000-0000-4000-a000-000000000001','Set aside',12550,'expense','Other','  SaViNgS  ',now()),
 ('52000000-0000-4000-a000-000000000002','51000000-0000-4000-a000-000000000001','Cricket',5000,'expense','Other','  Cricket  ',now()),
 ('52000000-0000-4000-a000-000000000003','51000000-0000-4000-a000-000000000001','Birthday',100000,'income','Gift','',now());
do $$begin
 if not exists(select 1 from public.transactions where direction='savings' and category='Savings'
   and custom_category='' and amount_minor=12550) then raise exception 'Savings normalization failed'; end if;
 if not exists(select 1 from public.transactions where custom_category='Cricket') then raise exception 'Custom label lost'; end if;
 if (select sum(amount_minor) from public.transactions where direction='expense')<>5000 then
   raise exception 'Savings counted as spending'; end if;
 begin
  update public.transactions set category='Salary' where direction='expense';
  raise exception 'Receive category accepted as spending';
 exception when check_violation then null; end;
 begin
  update public.transactions set category='Food & dining' where direction='income';
  raise exception 'Spend category accepted as income';
 exception when check_violation then null; end;
 begin
  update public.transactions set custom_category=repeat('x',41) where category='Other';
  raise exception 'Oversized tag accepted';
 exception when check_violation then null; end;
 update public.transactions set amount_minor=15025 where direction='savings';
 if not exists(select 1 from public.transactions where direction='savings' and amount_minor=15025) then
   raise exception 'Savings update failed'; end if;
 update public.transactions set deleted=true where direction='savings';
end$$;
select set_config('request.jwt.claims','{"sub":"51000000-0000-4000-a000-000000000002","role":"authenticated"}',true);
do $$begin
 if exists(select 1 from public.transactions) then raise exception 'Other account records leaked'; end if;
end$$;
rollback;
