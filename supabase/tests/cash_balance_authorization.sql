begin;
create temporary table balance_fixture_ids(label text primary key,id uuid not null);
insert into balance_fixture_ids values ('owner',gen_random_uuid()),('other',gen_random_uuid()),('unverified',gen_random_uuid()),('parent',gen_random_uuid());
insert into auth.users(id,aud,role,email,email_confirmed_at,is_anonymous)
 select id,'authenticated','authenticated','balance-test-'||id||'@example.invalid',
 case when label='unverified' then null else now() end,false from balance_fixture_ids;
insert into public.profiles(id,name,role,age)
 select id,label,case when label='parent' then 'parent' else 'teen' end,
 case when label='parent' then null else 16 end from balance_fixture_ids;
select set_config('test.balance_owner',(select id::text from balance_fixture_ids where label='owner'),true);
select set_config('test.balance_other',(select id::text from balance_fixture_ids where label='other'),true);
select set_config('test.balance_unverified',(select id::text from balance_fixture_ids where label='unverified'),true);
select set_config('test.balance_parent',(select id::text from balance_fixture_ids where label='parent'),true);
do $$begin
 if has_table_privilege('anon','public.cash_balances','select') or
 has_table_privilege('anon','public.cash_balances','insert') or
 has_table_privilege('authenticated','public.cash_balances','delete') then
 raise exception 'Unexpected table grants'; end if;
end$$;
set local role authenticated;
select set_config('request.jwt.claims',json_build_object('sub',current_setting('test.balance_owner'),'role','authenticated')::text,true);
insert into public.cash_balances(id,owner_id,amount_minor,ledger_net_minor)
 values(auth.uid(),auth.uid(),0,-12345);
update public.cash_balances set amount_minor=123456 where id=auth.uid();
do $$begin
 if (select amount_minor from public.cash_balances where id=auth.uid())<>123456 then raise exception 'Owner read/update failed'; end if;
 begin
 update public.cash_balances set amount_minor=-1 where id=auth.uid();
 raise exception 'Negative checkpoint accepted'; exception when check_violation then null; end;
 begin
 update public.cash_balances set owner_id=current_setting('test.balance_other')::uuid where id=auth.uid();
 raise exception 'Ownership reassignment accepted'; exception when others then
 if sqlerrm='Ownership reassignment accepted' then raise; end if; end;
end$$;
select set_config('request.jwt.claims',json_build_object('sub',current_setting('test.balance_other'),'role','authenticated')::text,true);
do $$declare n int;begin
 if (select count(*) from public.cash_balances)<>0 then raise exception 'Other owner balance leaked'; end if;
 update public.cash_balances set amount_minor=1; get diagnostics n=row_count;
 if n<>0 then raise exception 'Other owner balance changed'; end if;
 begin
 insert into public.cash_balances(id,owner_id,amount_minor,ledger_net_minor)
 values(current_setting('test.balance_owner')::uuid,current_setting('test.balance_owner')::uuid,1,0);
 raise exception 'Spoofed insert accepted'; exception when insufficient_privilege then null; end;
end$$;
select set_config('request.jwt.claims',json_build_object('sub',current_setting('test.balance_unverified'),'role','authenticated')::text,true);
do $$begin
 begin
 insert into public.cash_balances(id,owner_id,amount_minor,ledger_net_minor) values(auth.uid(),auth.uid(),1,0);
 raise exception 'Unverified balance accepted'; exception when insufficient_privilege then null; end;
end$$;
select set_config('request.jwt.claims',json_build_object('sub',current_setting('test.balance_parent'),'role','authenticated')::text,true);
do $$begin
 if (select count(*) from public.cash_balances)<>0 then raise exception 'Parent balance leaked'; end if;
 begin
 insert into public.cash_balances(id,owner_id,amount_minor,ledger_net_minor) values(auth.uid(),auth.uid(),1,0);
 raise exception 'Parent balance accepted'; exception when insufficient_privilege then null; end;
end$$;
rollback;
