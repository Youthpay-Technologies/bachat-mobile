"""Manual live checks for two explicitly approved disposable Auth fixtures.
Credentials are read from stdin and never written or printed. This script does not
create users; cleanup is performed separately against the recorded fixture IDs.
"""
import json
import re
import sys
import uuid
from pathlib import Path
from urllib.request import Request, urlopen, build_opener, HTTPRedirectHandler
from urllib.error import HTTPError
from urllib.parse import urlencode, urlparse, parse_qs

class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None

config = json.loads(sys.stdin.readline())
fixtures = config['fixtures']
assert len(fixtures) == 2 and all(x['email'].startswith('bachat-integration-') and x['email'].endswith('@example.invalid') for x in fixtures)
source = (Path(__file__).resolve().parents[1] / 'lib/data/backend_config.dart').read_text(encoding='utf-8-sig')
base = re.search(r"defaultValue: '(https://[^']+)'", source)[1]
key = re.search(r"defaultValue: '(sb_publishable_[^']+)'", source)[1]

def call(method, path, body=None, token=None, redirect=True):
    headers = {'apikey': key, 'Content-Type': 'application/json'}
    if token:
        headers['Authorization'] = 'Bearer ' + token
    request = Request(base + path, data=None if body is None else json.dumps(body).encode(), headers=headers, method=method)
    try:
        response = (urlopen(request, timeout=30) if redirect else build_opener(NoRedirect).open(request, timeout=30))
    except HTTPError as exc:
        response = exc
    raw = response.read().decode()
    try:
        result = json.loads(raw) if raw else None
    except ValueError:
        result = None
    return response.status, result, response.headers

def check(ok, label, result=None):
    if not ok:
        code = result.get('code') or result.get('error_code') if isinstance(result, dict) else None
        raise RuntimeError(label + ' failed' + (': ' + str(code) if code else ''))
    print(json.dumps({'check': label, 'status': 'pass'}), flush=True)

def login(fixture, password=None):
    status, session, _ = call('POST', '/auth/v1/token?grant_type=password', {'email': fixture['email'], 'password': password or fixture['password']})
    check(status == 200 and session.get('user', {}).get('id') == fixture['id'], 'password_sign_in', session)
    return session

first = login(fixtures[0])
status, unverified, _ = call('POST', '/auth/v1/token?grant_type=password', {'email': fixtures[1]['email'], 'password': fixtures[1]['password']})
check(status == 400 and unverified.get('error_code', unverified.get('code')) == 'email_not_confirmed', 'unverified_sign_in_rejected', unverified)
status, verified, _ = call('POST', '/auth/v1/verify', {'type': 'signup', 'token_hash': config['tokens']['confirmation_token']})
check(status == 200 and verified.get('user', {}).get('email_confirmed_at'), 'confirmation_token_exchange', verified)
second = login(fixtures[1])
for index, session in enumerate([first, second]):
    row = {'id': fixtures[index]['id'], 'name': 'Live test teen ' + str(index+1), 'role': 'teen', 'age': 16}
    if index == 1:
        status, result, _ = call('POST', '/rest/v1/profiles', {**row, 'role': 'parent', 'age': None}, session['access_token'])
        check(status == 403, 'parent_profile_rejected', result)
    status, result, _ = call('POST', '/rest/v1/profiles', row, session['access_token'])
    check(status in [200,201], 'teen_profile_created', result)

owner = fixtures[0]['id']
records = {
    'transactions': {'id': str(uuid.uuid4()), 'owner_id': owner, 'merchant': 'Live REST expense', 'amount_minor': 12550, 'direction': 'expense', 'category': 'Other', 'occurred_at': '2026-10-21T12:00:00Z', 'note': '', 'deleted': False},
    'budgets': {'id': str(uuid.uuid4()), 'owner_id': owner, 'category': 'Other', 'limit_minor': 200000, 'month': '2026-10-01', 'deleted': False},
    'savings_goals': {'id': str(uuid.uuid4()), 'owner_id': owner, 'title': 'Live REST goal', 'target_minor': 500000, 'saved_minor': 0, 'deleted': False},
}
for table, row in records.items():
    status, result, _ = call('POST', '/rest/v1/' + table, row, first['access_token'])
    check(status == 201, table + '_created', result)
    status, result, _ = call('GET', '/rest/v1/' + table + '?select=*', token=first['access_token'])
    check(status == 200 and len(result) == 1 and result[0]['id'] == row['id'], table + '_owner_read', result)
    status, result, _ = call('GET', '/rest/v1/' + table + '?select=*', token=second['access_token'])
    check(status == 200 and result == [], table + '_other_account_isolated', result)
    status, result, _ = call('POST', '/rest/v1/' + table, {**row, 'id': str(uuid.uuid4())}, second['access_token'])
    check(status == 403, table + '_spoof_write_rejected', result)
    update = {'amount_minor':12600} if table == 'transactions' else {'limit_minor':250000} if table == 'budgets' else {'saved_minor':15025}
    status, result, _ = call('PATCH', '/rest/v1/' + table + '?id=eq.' + row['id'], update, first['access_token'])
    check(status == 204, table + '_updated', result)
    status, result, _ = call('PATCH', '/rest/v1/' + table + '?id=eq.' + row['id'], {'deleted':True}, first['access_token'])
    check(status == 204, table + '_soft_deleted', result)

status, recovery, headers = call('GET', '/auth/v1/verify?' + urlencode({'token':config['tokens']['recovery_token'], 'type':'recovery', 'redirect_to':'http://127.0.0.1:8080/'}), redirect=False)
check(status in [302,303], 'recovery_link_verified', recovery)
location = headers.get('Location','')
parts = urlparse(location)
values = {k:v[0] for k,v in parse_qs(parts.fragment).items()}
check('access_token' in values and 'refresh_token' in values, 'recovery_session_issued')
origin = parts.scheme + '://' + parts.netloc
print(json.dumps({'check':'hosted_redirect_destination','origin':origin,'configured':origin=='http://127.0.0.1:8080'}),flush=True)
new_password = fixtures[0]['password'] + '_updated'
status, result, _ = call('PUT', '/auth/v1/user', {'password':new_password}, values['access_token'])
check(status == 200, 'recovered_password_updated', result)
status, result, _ = call('POST', '/auth/v1/token?grant_type=password', {'email':fixtures[0]['email'],'password':fixtures[0]['password']})
check(status == 400, 'old_password_rejected', result)
updated = login(fixtures[0], new_password)
status, refreshed, _ = call('POST','/auth/v1/token?grant_type=refresh_token',{'refresh_token':updated['refresh_token']})
check(status == 200 and refreshed.get('access_token'), 'session_refreshed', refreshed)
status, result, _ = call('POST','/auth/v1/logout?scope=local',token=refreshed['access_token'])
check(status == 204, 'session_signed_out', result)
status, result, _ = call('POST','/auth/v1/token?grant_type=refresh_token',{'refresh_token':refreshed['refresh_token']})
check(status in [400,401,403], 'signed_out_refresh_rejected', result)
print(json.dumps({'result':'live_auth_and_RLS_checks_passed','first_password_updated':True}),flush=True)
