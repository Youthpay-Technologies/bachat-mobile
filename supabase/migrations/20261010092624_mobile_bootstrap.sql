-- Bachat mobile: isolated schema, mutual consent, and owner-scoped money data.
create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated;
create extension if not exists pgcrypto with schema extensions;

create table public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 name text not null check (length(trim(name)) between 1 and 60),
 role text not null check (role in ('teen','parent')),
 age smallint,
 created_at timestamptz not null default now(),
 check ((role='teen' and age is not null and age between 13 and 18) or (role='parent' and age is null))
);
create table public.family_links (
 id uuid primary key default gen_random_uuid(),
 teen_id uuid not null references public.profiles(id) on delete cascade,
 parent_id uuid not null references public.profiles(id) on delete cascade,
 status text not null default 'parent_approved' check (status in ('parent_approved','approved','revoked')),
 expires_at timestamptz not null default now()+interval '24 hours',
 created_at timestamptz not null default now(),
 check (teen_id <> parent_id)
);
create unique index family_active_pair on public.family_links(teen_id,parent_id) where status <> 'revoked';
create index family_parent_status on public.family_links(parent_id,status);
create index family_teen_status on public.family_links(teen_id,status);
create table private.family_codes (
 code_hash text primary key,
 teen_id uuid not null unique references public.profiles(id) on delete cascade,
 expires_at timestamptz not null default now()+interval '24 hours'
);
create table private.code_attempts (
 user_id uuid primary key references auth.users(id) on delete cascade,
 failures int not null default 0,
 locked_until timestamptz
);
alter table private.family_codes enable row level security;
alter table private.code_attempts enable row level security;

create function private.has_parent(p_teen uuid) returns boolean
 language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and exists(select 1 from public.family_links where teen_id=p_teen and status='approved');
$$;
create function private.can_read(p_owner uuid) returns boolean
 language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and (
  (p_owner=auth.uid() and private.has_parent(p_owner)) or
  exists(select 1 from public.family_links where teen_id=p_owner and parent_id=auth.uid() and status='approved')
 );
$$;
create function private.can_write(p_owner uuid) returns boolean
 language sql stable security definer set search_path='' as $$
 select p_owner=auth.uid() and private.has_parent(p_owner) and exists(select 1 from public.profiles where id=auth.uid() and role='teen');
$$;
create function private.profile_visible(p_id uuid) returns boolean
 language sql stable security definer set search_path='' as $$
 select p_id=auth.uid() or exists(select 1 from public.family_links where status in ('parent_approved','approved') and ((teen_id=auth.uid() and parent_id=p_id) or (parent_id=auth.uid() and teen_id=p_id)));
$$;
create function private.protect_profile() returns trigger language plpgsql set search_path='' as $$
 begin
  if new.id<>old.id or new.role<>old.role or new.age is distinct from old.age then
   raise exception 'Account role and signup age cannot be changed.';
  end if;
  return new;
 end;
$$;
create trigger protect_profile before update on public.profiles for each row execute function private.protect_profile();

create table public.transactions (
 id uuid primary key,
 owner_id uuid not null references public.profiles(id) on delete cascade,
 merchant text not null check(length(trim(merchant)) between 1 and 120),
 amount_minor bigint not null check(amount_minor between 1 and 999999999999),
 direction text not null check(direction in ('expense','income')),
 category text not null check(length(category) between 1 and 40),
 occurred_at timestamptz not null,
 note text not null default '' check(length(note)<=500),
 deleted boolean not null default false,
 updated_at timestamptz not null default now()
);
create index transactions_owner_date on public.transactions(owner_id,occurred_at desc);
create table public.budgets (
 id uuid primary key,
 owner_id uuid not null references public.profiles(id) on delete cascade,
 category text not null check(length(category) between 1 and 40),
 limit_minor bigint not null check(limit_minor between 1 and 999999999999),
 month date not null check(extract(day from month)=1),
 deleted boolean not null default false,
 updated_at timestamptz not null default now()
);
create unique index budgets_active_category on public.budgets(owner_id,month,category) where not deleted;
create table public.savings_goals (
 id uuid primary key,
 owner_id uuid not null references public.profiles(id) on delete cascade,
 title text not null check(length(trim(title)) between 1 and 80),
 target_minor bigint not null check(target_minor between 1 and 999999999999),
 saved_minor bigint not null default 0 check(saved_minor>=0 and saved_minor<=target_minor),
 deleted boolean not null default false,
 updated_at timestamptz not null default now()
);
create index goals_owner on public.savings_goals(owner_id);

create function private.stamp_update() returns trigger language plpgsql set search_path='' as $$
 begin
  if tg_op='UPDATE' and new.owner_id<>old.owner_id then raise exception 'Ownership cannot change.'; end if;
  new.updated_at=clock_timestamp(); return new;
 end;
$$;
create trigger transactions_updated before insert or update on public.transactions for each row execute function private.stamp_update();
create trigger budgets_updated before insert or update on public.budgets for each row execute function private.stamp_update();
create trigger goals_updated before insert or update on public.savings_goals for each row execute function private.stamp_update();

alter table public.profiles enable row level security;
alter table public.family_links enable row level security;
alter table public.transactions enable row level security;
alter table public.budgets enable row level security;
alter table public.savings_goals enable row level security;
create policy profile_read on public.profiles for select to authenticated using(private.profile_visible(id));
create policy profile_insert on public.profiles for insert to authenticated with check(id=(select auth.uid()));
create policy profile_update on public.profiles for update to authenticated using(id=(select auth.uid())) with check(id=(select auth.uid()));
create policy family_read on public.family_links for select to authenticated using(teen_id=(select auth.uid()) or parent_id=(select auth.uid()));
create policy transaction_read on public.transactions for select to authenticated using(private.can_read(owner_id));
create policy transaction_insert on public.transactions for insert to authenticated with check(private.can_write(owner_id));
create policy transaction_update on public.transactions for update to authenticated using(private.can_write(owner_id)) with check(private.can_write(owner_id));
create policy budget_read on public.budgets for select to authenticated using(private.can_read(owner_id));
create policy budget_insert on public.budgets for insert to authenticated with check(private.can_write(owner_id));
create policy budget_update on public.budgets for update to authenticated using(private.can_write(owner_id)) with check(private.can_write(owner_id));
create policy goal_read on public.savings_goals for select to authenticated using(private.can_read(owner_id));
create policy goal_insert on public.savings_goals for insert to authenticated with check(private.can_write(owner_id));
create policy goal_update on public.savings_goals for update to authenticated using(private.can_write(owner_id)) with check(private.can_write(owner_id));

create function private.generate_family_code() returns text language plpgsql security definer set search_path='' as $$
 declare v_code text;
 begin
  if not exists(select 1 from public.profiles where id=auth.uid() and role='teen') then raise exception 'A teen account is required.'; end if;
  v_code='BCHT-'||upper(substr(encode(extensions.gen_random_bytes(6),'hex'),1,8));
  insert into private.family_codes(code_hash,teen_id) values(encode(extensions.digest(v_code,'sha256'),'hex'),auth.uid())
   on conflict(teen_id) do update set code_hash=excluded.code_hash,expires_at=now()+interval '24 hours';
  return v_code;
 end;
$$;
create function private.claim_family_code(p_code text) returns jsonb language plpgsql security definer set search_path='' as $$
 declare v_teen uuid; v_link uuid; v_attempt private.code_attempts%rowtype;
 begin
  if not exists(select 1 from public.profiles where id=auth.uid() and role='parent') then return jsonb_build_object('result','parent_required'); end if;
  insert into private.code_attempts(user_id) values(auth.uid()) on conflict do nothing;
  select * into v_attempt from private.code_attempts where user_id=auth.uid() for update;
  if v_attempt.locked_until>now() then return jsonb_build_object('result','locked'); end if;
  if v_attempt.locked_until is not null then update private.code_attempts set failures=0,locked_until=null where user_id=auth.uid(); end if;
  select teen_id into v_teen from private.family_codes where code_hash=encode(extensions.digest(upper(trim(p_code)),'sha256'),'hex') and expires_at>now() for update;
  if v_teen is null then
   update private.code_attempts set failures=failures+1,locked_until=case when failures+1>=5 then now()+interval '15 minutes' else null end where user_id=auth.uid();
   return jsonb_build_object('result','not_found');
  end if;
  update public.family_links set status='revoked' where teen_id=v_teen and parent_id=auth.uid() and status='parent_approved' and expires_at<=now();
  select id into v_link from public.family_links where teen_id=v_teen and parent_id=auth.uid() and status<>'revoked';
  if v_link is not null then return jsonb_build_object('result','already_requested'); end if;
  insert into public.family_links(teen_id,parent_id) values(v_teen,auth.uid()) returning id into v_link;
  delete from private.family_codes where teen_id=v_teen;
  update private.code_attempts set failures=0,locked_until=null where user_id=auth.uid();
  return jsonb_build_object('result','ok','link_id',v_link);
 end;
$$;
create function private.decide_family_link(p_id uuid,p_approve boolean) returns boolean language plpgsql security definer set search_path='' as $$
 declare v_count int;
 begin
  update public.family_links set status=case when p_approve then 'approved' else 'revoked' end
   where id=p_id and teen_id=auth.uid() and status='parent_approved' and expires_at>now();
  get diagnostics v_count=row_count; return v_count=1;
 end;
$$;
create function private.revoke_family_link(p_id uuid) returns boolean language plpgsql security definer set search_path='' as $$
 declare v_count int;
 begin
  update public.family_links set status='revoked' where id=p_id and (teen_id=auth.uid() or parent_id=auth.uid()) and status<>'revoked';
  get diagnostics v_count=row_count; return v_count=1;
 end;
$$;
create function public.generate_family_code() returns text language sql security invoker set search_path='' as $$select private.generate_family_code();$$;
create function public.claim_family_code(p_code text) returns jsonb language sql security invoker set search_path='' as $$select private.claim_family_code(p_code);$$;
create function public.decide_family_link(p_id uuid,p_approve boolean) returns boolean language sql security invoker set search_path='' as $$select private.decide_family_link(p_id,p_approve);$$;
create function public.revoke_family_link(p_id uuid) returns boolean language sql security invoker set search_path='' as $$select private.revoke_family_link(p_id);$$;

revoke all on all tables in schema private from public,anon,authenticated;
revoke all on all functions in schema private from public,anon;
grant execute on function private.has_parent(uuid),private.can_read(uuid),private.can_write(uuid),private.profile_visible(uuid),private.generate_family_code(),private.claim_family_code(text),private.decide_family_link(uuid,boolean),private.revoke_family_link(uuid) to authenticated;
revoke all on function public.generate_family_code(),public.claim_family_code(text),public.decide_family_link(uuid,boolean),public.revoke_family_link(uuid) from public,anon;
grant execute on function public.generate_family_code(),public.claim_family_code(text),public.decide_family_link(uuid,boolean),public.revoke_family_link(uuid) to authenticated;
revoke all on public.profiles,public.family_links,public.transactions,public.budgets,public.savings_goals from anon;
grant select,insert,update on public.profiles to authenticated;
grant select on public.family_links to authenticated;
grant select,insert,update on public.transactions,public.budgets,public.savings_goals to authenticated;
alter publication supabase_realtime add table public.family_links;
