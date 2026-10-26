"""Run a scoped, self-cleaning two-writer savings-capacity probe.

Uses the CLI's existing authenticated Management API session. It creates one
verified synthetic account without sending email, then deletes that exact UUID
in a finally block. Never targets or prints real account data.
"""
from __future__ import annotations
import argparse
from concurrent.futures import ThreadPoolExecutor
import json
from pathlib import Path
import subprocess
import tempfile
import uuid


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--cli', required=True, type=Path)
    parser.add_argument('--project-ref', required=True)
    args = parser.parse_args()
    owner, goal, first, second = (str(uuid.uuid4()) for _ in range(4))
    with tempfile.TemporaryDirectory(prefix='receipt-capacity-') as directory:
        def query(sql: str, *, allow_error: bool = False):
            file = Path(directory) / f'{uuid.uuid4()}.sql'
            file.write_text(sql, encoding='utf-8')
            result = subprocess.run([str(args.cli), '--yes', 'db', 'query', '--linked',
                '--project-ref', args.project_ref, '--file', str(file)],
                input='', capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=45)
            if result.returncode and not allow_error:
                raise RuntimeError('Scoped SQL probe failed: ' + (result.stderr or result.stdout))
            return result
        try:
            query(f"""begin;
insert into auth.users(id,aud,role,email,email_confirmed_at,is_anonymous)
 values('{owner}','authenticated','authenticated','receipt-capacity-{owner}@example.invalid',now(),false);
insert into public.profiles(id,name,role,age) values('{owner}','Receipt capacity fixture','teen',16);
insert into public.savings_goals(id,owner_id,title,target_minor,saved_minor) values('{goal}','{owner}','Concurrent fixture',10000,0);
commit;""")
            def compete(receipt: str):
                return query(f"""begin;
set local role authenticated;
select set_config('request.jwt.claims','{{"sub":"{owner}","role":"authenticated"}}',true);
insert into public.transactions(id,owner_id,merchant,amount_minor,direction,category,occurred_at,savings_goal_id,savings_amount_minor)
 values('{receipt}','{owner}','Receipt capacity fixture',10000,'income','Gift',now(),'{goal}',6000);
select pg_sleep(2);
commit;""", allow_error=True)
            with ThreadPoolExecutor(max_workers=2) as pool:
                results = list(pool.map(compete, [first, second]))
            if sum(result.returncode == 0 for result in results) != 1:
                raise RuntimeError('Expected exactly one writer to fit the remaining target.')
            failed = next(result for result in results if result.returncode)
            if 'Savings goal target would be exceeded' not in failed.stdout + failed.stderr:
                raise RuntimeError('Second writer failed for an unexpected reason.')
            # Replay the successful receipt to prove retries never double-credit.
            query(f"""begin;
set local role authenticated;
select set_config('request.jwt.claims','{{"sub":"{owner}","role":"authenticated"}}',true);
select public.apply_money_changes((select jsonb_agg(jsonb_build_object('table','transactions','row',to_jsonb(t))) from public.transactions t where owner_id='{owner}'));
select public.apply_money_changes((select jsonb_agg(jsonb_build_object('table','transactions','row',to_jsonb(t))) from public.transactions t where owner_id='{owner}'));
do $$begin
 if (select count(*) from public.transactions where owner_id='{owner}')<>1 or
    (select sum(savings_amount_minor) from public.transactions where owner_id='{owner}')<>6000 then
  raise exception 'Concurrent capacity or idempotency failed'; end if;
end$$;
commit;""")
            print(json.dumps({'concurrent_capacity': 'pass', 'idempotent_replay': 'pass'}), flush=True)
        finally:
            result = query(f"""delete from auth.users where id='{owner}';
select (select count(*) from auth.users where id='{owner}') +
 (select count(*) from public.profiles where id='{owner}') +
 (select count(*) from public.savings_goals where owner_id='{owner}') +
 (select count(*) from public.transactions where owner_id='{owner}') as remaining;""")
            if json.loads(result.stdout)['rows'][0]['remaining'] != 0:
                raise RuntimeError('Synthetic fixture cleanup incomplete.')
            print(json.dumps({'synthetic_fixture_cleanup': 'pass'}), flush=True)


if __name__ == '__main__':
    main()
