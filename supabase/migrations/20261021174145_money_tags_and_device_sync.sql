-- User tags and a distinct savings ledger, with existing ownership RLS retained.
alter table public.transactions add column custom_category text not null default '';
alter table public.transactions drop constraint transactions_direction_check;
alter table public.transactions drop constraint transactions_category_known;

-- Preserve historical income labels while moving them into the receive taxonomy.
update public.transactions set custom_category=category,category='Other'
where direction='income' and category not in
 ('Pocket money','Gift','Salary','Freelance','Refund','Transfer','Other');

create function private.normalize_money_entry() returns trigger
language plpgsql set search_path='' as $$
begin
 new.custom_category=btrim(new.custom_category);
 if new.direction <> 'income' and (new.category='Savings' or
    (new.category='Other' and lower(new.custom_category)='savings')) then
   new.direction='savings'; new.category='Savings'; new.custom_category='';
 end if;
 return new;
end;
$$;
revoke all on function private.normalize_money_entry() from public,anon,authenticated;
create trigger a_normalize_money_entry before insert or update on public.transactions
for each row execute function private.normalize_money_entry();

alter table public.transactions add constraint transactions_direction_check
 check(direction in ('expense','income','savings'));
alter table public.transactions add constraint transactions_category_known check(
 (direction='expense' and category in ('Food & dining','Transport','Shopping',
 'Entertainment','Education','Health','Utilities','Transfer','Other')) or
 (direction='income' and category in ('Pocket money','Gift','Salary','Freelance',
 'Refund','Transfer','Other')) or (direction='savings' and category='Savings'));
alter table public.transactions add constraint transactions_custom_category_check
 check(length(custom_category)<=40 and (category='Other' or custom_category=''));

-- Soft deletions replicate as owner-filterable updates; existing RLS gates delivery.
do $$
declare money_table text;
begin
 foreach money_table in array array['profiles','transactions','budgets','savings_goals'] loop
  if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime'
    and schemaname='public' and tablename=money_table) then
   execute format('alter publication supabase_realtime add table public.%I',money_table);
  end if;
 end loop;
end;
$$;
