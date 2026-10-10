begin;
create temporary table fixture_ids(label text primary key,id uuid not null);
insert into fixture_ids values ('teen',gen_random_uuid()),('parent',gen_random_uuid()),('stranger',gen_random_uuid()),('teen2',gen_random_uuid());
insert into auth.users(id,aud,role,email) select id,'authenticated','authenticated','test-'||id||'@example.invalid' from fixture_ids;
insert into public.profiles(id,name,role,age) select id,label,case when label in ('teen','teen2') then 'teen' else 'parent' end,case when label in ('teen','teen2') then 16 else null end from fixture_ids;
select set_config('test.teen',(select id::text from fixture_ids where label='teen'),true);
select set_config('test.parent',(select id::text from fixture_ids where label='parent'),true);
select set_config('test.stranger',(select id::text from fixture_ids where label='stranger'),true);
select set_config('test.teen2',(select id::text from fixture_ids where label='teen2'),true);
set local role authenticated;
select set_config('request.jwt.claim.sub',current_setting('test.teen'),true);
do $$begin
 if private.can_write(auth.uid()) then raise exception 'Unapproved teen can write';end if;
end$$;
select set_config('test.code',public.generate_family_code(),true);
select set_config('request.jwt.claim.sub',current_setting('test.parent'),true);
select set_config('test.link',(public.claim_family_code(current_setting('test.code'))->>'link_id'),true);
do $$begin
 if private.can_read(current_setting('test.teen')::uuid) then raise exception 'Parent reads before mutual confirmation';end if;
 if public.decide_family_link(current_setting('test.link')::uuid,true) then raise exception 'Parent can self-confirm';end if;
end$$;
select set_config('request.jwt.claim.sub',current_setting('test.teen'),true);
do $$begin
 if not public.decide_family_link(current_setting('test.link')::uuid,true) then raise exception 'Teen approval failed';end if;
end$$;
insert into public.transactions(id,owner_id,merchant,amount_minor,direction,category,occurred_at) values(gen_random_uuid(),auth.uid(),'RLS fixture',12500,'expense','Other',now());
insert into public.budgets(id,owner_id,category,limit_minor,month) values(gen_random_uuid(),auth.uid(),'Other',100000,date_trunc('month',now())::date);
insert into public.savings_goals(id,owner_id,title,target_minor) values(gen_random_uuid(),auth.uid(),'Fixture',100000);
select set_config('request.jwt.claim.sub',current_setting('test.parent'),true);
do $$declare n int;begin
 if (select count(*) from public.transactions)<>1 or (select count(*) from public.budgets)<>1 or (select count(*) from public.savings_goals)<>1 then raise exception 'Approved parent cannot read all three';end if;
 update public.transactions set amount_minor=1; get diagnostics n=row_count;
 if n<>0 then raise exception 'Parent can edit transactions';end if;
 update public.budgets set limit_minor=1;get diagnostics n=row_count;
 if n<>0 then raise exception 'Parent can edit budgets';end if;
 update public.savings_goals set target_minor=1;get diagnostics n=row_count;
 if n<>0 then raise exception 'Parent can edit savings goals';end if;
 begin
  insert into public.transactions(id,owner_id,merchant,amount_minor,direction,category,occurred_at) values(gen_random_uuid(),current_setting('test.teen')::uuid,'Forbidden',100,'expense','Other',now());
  raise exception 'Parent insert succeeded';
 exception when insufficient_privilege then null;end;
end$$;
select set_config('request.jwt.claim.sub',current_setting('test.stranger'),true);
do $$begin
 if (select count(*) from public.transactions)<>0 then raise exception 'Stranger can see money';end if;
 if public.revoke_family_link(current_setting('test.link')::uuid) then raise exception 'Stranger revoked link';end if;
 for i in 1..5 loop perform public.claim_family_code('BCHT-INVALID');end loop;
 if public.claim_family_code('BCHT-INVALID')->>'result'<>'locked' then raise exception 'Rate limit missing';end if;
end$$;
select set_config('request.jwt.claim.sub',current_setting('test.teen2'),true);
select set_config('test.code',public.generate_family_code(),true);
select set_config('request.jwt.claim.sub',current_setting('test.parent'),true);
select set_config('test.link2',public.claim_family_code(current_setting('test.code'))->>'link_id',true);
select set_config('request.jwt.claim.sub',current_setting('test.teen2'),true);
select public.decide_family_link(current_setting('test.link2')::uuid,true);
select set_config('request.jwt.claim.sub',current_setting('test.parent'),true);
do $$begin
 if (select count(*) from public.family_links where status='approved')<>2 then raise exception 'Multiple children failed';end if;
 if not public.revoke_family_link(current_setting('test.link')::uuid) then raise exception 'Revocation failed';end if;
 if private.can_read(current_setting('test.teen')::uuid) then raise exception 'Revoked parent still reads';end if;
end$$;
select set_config('request.jwt.claim.sub',current_setting('test.teen'),true);
do $$begin
 if private.can_write(auth.uid()) then raise exception 'Teen writes after last parent removed';end if;
 if (select count(*) from public.transactions)<>0 then raise exception 'Teen reads after last parent removed';end if;
end$$;
rollback;
