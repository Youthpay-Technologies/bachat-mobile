-- A receipt owns its optional savings allocation. Goal totals are derived,
-- so editing/deleting receipts never needs a second mutable saved counter.
alter table public.transactions
 add column savings_goal_id uuid references public.savings_goals(id)
   deferrable initially deferred,
 add column savings_amount_minor bigint not null default 0,
 add constraint transactions_savings_allocation_check check (
   savings_amount_minor between 0 and amount_minor and
   ((savings_goal_id is null and savings_amount_minor=0) or
    (savings_goal_id is not null and savings_amount_minor>0 and direction='income')));
create index transactions_goal_allocations on public.transactions(owner_id,savings_goal_id)
 where not deleted and savings_goal_id is not null;

-- Serialize this account's related writes before any row locks are acquired.
-- Existing RLS still determines whether the operation itself is permitted.
create function private.lock_savings_account() returns trigger
language plpgsql security invoker set search_path='' as $$
begin
 if (select auth.uid()) is not null then
  perform id from public.profiles where id=(select auth.uid()) for update;
 end if;
 return null;
end;
$$;
revoke all on function private.lock_savings_account() from public,anon,authenticated;
create trigger lock_receipt_account before insert or update on public.transactions
 for each statement execute function private.lock_savings_account();
create trigger lock_goal_account before insert or update on public.savings_goals
 for each statement execute function private.lock_savings_account();

create function private.validate_receipt_goal() returns trigger
language plpgsql security invoker set search_path='' as $$
declare target public.savings_goals%rowtype;
begin
 if new.savings_goal_id is not null then
  select * into target from public.savings_goals where id=new.savings_goal_id;
  if not found or target.owner_id<>new.owner_id or (target.deleted and not new.deleted) then
   raise exception 'Choose an available savings goal owned by this account.' using errcode='23514';
  end if;
 end if;
 return new;
end;
$$;
revoke all on function private.validate_receipt_goal() from public,anon,authenticated;
create trigger b_validate_receipt_goal before insert or update on public.transactions
 for each row execute function private.validate_receipt_goal();

-- Deferred only by the atomic linked-write RPC. Plain REST writes are checked
-- at statement end, including edits/deletions of the goal or its receipts.
create function private.check_goal_funding() returns trigger
language plpgsql security invoker set search_path='' as $$
declare affected uuid[]; goal public.savings_goals%rowtype; allocated numeric;
begin
 if tg_table_name='transactions' then
  if tg_op='UPDATE' then affected:=array[old.savings_goal_id,new.savings_goal_id];
  else affected:=array[new.savings_goal_id]; end if;
 else affected:=array[new.id]; end if;
 for goal in select * from public.savings_goals where id=any(affected) order by id for update loop
  select coalesce(sum(savings_amount_minor),0) into allocated from public.transactions
   where owner_id=goal.owner_id and savings_goal_id=goal.id and not deleted;
  if goal.deleted and allocated>0 then
   raise exception 'Move or remove received allocations before removing this savings goal.' using errcode='23514';
  end if;
  if goal.saved_minor+allocated>goal.target_minor then
   raise exception 'Savings goal target would be exceeded.' using errcode='23514';
  end if;
 end loop;
 return null;
end;
$$;
revoke all on function private.check_goal_funding() from public,anon,authenticated;
create constraint trigger receipt_goal_capacity after insert or update on public.transactions
 deferrable initially immediate for each row execute function private.check_goal_funding();
create constraint trigger goal_receipt_capacity after insert or update on public.savings_goals
 deferrable initially immediate for each row execute function private.check_goal_funding();

-- The existing durable outbox uses this only for linked savings edits. The
-- entire batch commits or rolls back, including offline reassignments, target
-- changes and removal of a goal after its receipts have been unassigned.
create function public.apply_money_changes(p_changes jsonb) returns void
language plpgsql security invoker set search_path='' as $$
declare change jsonb; row_data jsonb; canonical uuid;
begin
 if not private.can_write((select auth.uid())) then
  raise exception 'Verified teen ownership required.' using errcode='42501';
 end if;
 if jsonb_typeof(p_changes)<>'array' then
  raise exception 'Expected an array of money changes.' using errcode='22023';
 end if;
 perform id from public.profiles where id=(select auth.uid()) for update;
 set constraints public.receipt_goal_capacity, public.goal_receipt_capacity deferred;
 for change in select value from jsonb_array_elements(p_changes)
  order by case when value->>'table'='savings_goals' and
   coalesce((value->'row'->>'deleted')::boolean,false) then 3
   when value->>'table'='savings_goals' then 0
   when value->>'table'='transactions' then 1 else 2 end loop
  row_data:=change->'row';
  if (row_data->>'owner_id')::uuid is distinct from (select auth.uid()) then
   raise exception 'Cannot write another account money record.' using errcode='42501';
  end if;
  case change->>'table'
  when 'savings_goals' then
   insert into public.savings_goals select (jsonb_populate_record(null::public.savings_goals,row_data)).*
   on conflict(id) do update set owner_id=excluded.owner_id,title=excluded.title,
    target_minor=excluded.target_minor,saved_minor=excluded.saved_minor,deleted=excluded.deleted;
  when 'transactions' then
   insert into public.transactions select (jsonb_populate_record(null::public.transactions,row_data)).*
   on conflict(id) do update set owner_id=excluded.owner_id,merchant=excluded.merchant,
    amount_minor=excluded.amount_minor,direction=excluded.direction,category=excluded.category,
    occurred_at=excluded.occurred_at,note=excluded.note,custom_category=excluded.custom_category,
    savings_goal_id=excluded.savings_goal_id,savings_amount_minor=excluded.savings_amount_minor,
    deleted=excluded.deleted;
  when 'budgets' then
   select id into canonical from public.budgets where owner_id=(select auth.uid())
    and month=(row_data->>'month')::date and category=row_data->>'category' and not deleted;
   if found then row_data:=jsonb_set(row_data,'{id}',to_jsonb(canonical)); end if;
   insert into public.budgets select (jsonb_populate_record(null::public.budgets,row_data)).*
   on conflict(id) do update set owner_id=excluded.owner_id,category=excluded.category,
    limit_minor=excluded.limit_minor,month=excluded.month,deleted=excluded.deleted;
  when 'cash_balances' then
   insert into public.cash_balances select (jsonb_populate_record(null::public.cash_balances,row_data)).*
   on conflict(id) do update set owner_id=excluded.owner_id,amount_minor=excluded.amount_minor,
    ledger_net_minor=excluded.ledger_net_minor;
  else raise exception 'Unknown money table.' using errcode='22023';
  end case;
 end loop;
 set constraints public.receipt_goal_capacity, public.goal_receipt_capacity immediate;
end;
$$;
revoke all on function public.apply_money_changes(jsonb) from public,anon;
grant execute on function public.apply_money_changes(jsonb) to authenticated;
