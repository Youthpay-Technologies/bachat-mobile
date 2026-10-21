-- Account deletion is outside this release; remove its unused capability.
drop function if exists public.delete_my_account();
drop function if exists private.delete_my_account();
