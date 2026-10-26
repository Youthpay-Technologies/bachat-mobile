-- A manually reconciled cash checkpoint; never a bank-verified balance.
create table public.cash_balances (
 id uuid primary key references public.profiles(id) on delete cascade,
 owner_id uuid not null unique references public.profiles(id) on delete cascade,
 amount_minor bigint not null check(amount_minor between 0 and 999999999999),
 ledger_net_minor bigint not null,
 updated_at timestamptz not null default now(),
 constraint cash_balance_identity check(id=owner_id)
);
alter table public.cash_balances enable row level security;
revoke all on public.cash_balances from public, anon, authenticated;
grant select, insert, update on public.cash_balances to authenticated;
create policy cash_balance_read on public.cash_balances for select to authenticated
 using(owner_id=(select auth.uid()) and private.can_read(owner_id));
create policy cash_balance_insert on public.cash_balances for insert to authenticated
 with check(owner_id=(select auth.uid()) and private.can_write(owner_id));
create policy cash_balance_update on public.cash_balances for update to authenticated
 using(owner_id=(select auth.uid()) and private.can_write(owner_id))
 with check(owner_id=(select auth.uid()) and private.can_write(owner_id));
create trigger stamp_cash_balance before insert or update on public.cash_balances
 for each row execute function private.stamp_update();
alter publication supabase_realtime add table public.cash_balances;
