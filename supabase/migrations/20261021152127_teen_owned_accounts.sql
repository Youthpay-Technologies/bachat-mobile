-- Teen-only release. Preserve existing family data while disabling family access.
create or replace function private.can_write(p_owner uuid) returns boolean
language sql stable security definer set search_path='' as $$
 select p_owner = (select auth.uid()) and exists (
   select 1 from public.profiles p join auth.users u on u.id=p.id
   where p.id=p_owner and p.role='teen' and u.email_confirmed_at is not null
     and coalesce(u.is_anonymous,false)=false
 );
$$;
create or replace function private.can_read(p_owner uuid) returns boolean
language sql stable security definer set search_path='' as $$
 select p_owner = (select auth.uid()) and private.can_write(p_owner);
$$;
revoke all on function private.can_write(uuid),private.can_read(uuid) from public,anon;
grant execute on function private.can_write(uuid),private.can_read(uuid) to authenticated;

drop policy profile_read on public.profiles;
create policy profile_read on public.profiles for select to authenticated
 using(id=(select auth.uid()));
drop policy profile_insert on public.profiles;
create policy profile_insert on public.profiles for insert to authenticated
 with check(id=(select auth.uid()) and role='teen' and exists (
   select 1 from (select auth.jwt()) j where coalesce((j.jwt->>'is_anonymous')::boolean,false)=false
 ));
drop policy family_read on public.family_links;
create policy family_read on public.family_links for select to authenticated using(false);
revoke execute on function public.generate_family_code(), public.claim_family_code(text),
 public.decide_family_link(uuid,boolean), public.revoke_family_link(uuid) from authenticated;
revoke execute on function private.generate_family_code(), private.claim_family_code(text),
 private.decide_family_link(uuid,boolean), private.revoke_family_link(uuid) from authenticated;

alter table public.transactions add constraint transactions_category_known
 check(category in ('Food & dining','Transport','Shopping','Entertainment','Education','Health','Utilities','Transfer','Other'));
alter table public.budgets add constraint budgets_category_known
 check(category in ('Food & dining','Transport','Shopping','Entertainment','Education','Health','Utilities','Transfer','Other'));

create or replace function private.stamp_update() returns trigger language plpgsql set search_path='' as $$
 begin
  if tg_op='UPDATE' and (new.owner_id<>old.owner_id or new.id<>old.id) then
   raise exception 'Record identity and ownership cannot change.';
  end if;
  new.updated_at=clock_timestamp(); return new;
 end;
$$;

-- Account deletion is restricted to the caller and immediately removes access.
create function private.delete_my_account() returns boolean
language plpgsql security definer set search_path='' as $$
 declare caller uuid := (select auth.uid());
 begin
  if caller is null then raise exception 'Authentication required.'; end if;
  delete from auth.sessions where user_id=caller;
  delete from auth.users where id=caller;
  return found;
 end;
$$;
revoke all on function private.delete_my_account() from public,anon;
grant execute on function private.delete_my_account() to authenticated;
create function public.delete_my_account() returns boolean
language sql security invoker set search_path='' as $$select private.delete_my_account();$$;
revoke all on function public.delete_my_account() from public,anon;
grant execute on function public.delete_my_account() to authenticated;
