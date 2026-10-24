"""Read-only app checks and location-only secret scanning; no hosted mutations."""
from __future__ import annotations

import argparse
import base64
import json
from pathlib import Path
import re
import subprocess
import sys
import tomllib
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
ANDROID = ROOT / 'android/app/src/main'
NS = '{http://schemas.android.com/apk/res/android}'
DOMAINS = {'root', 'file', 'database', 'sharedpref', 'external'}
failures = 0


def check(label, passed, detail=None):
    global failures
    if not passed:
        failures += 1
    result = {'check': label, 'result': 'pass' if passed else 'fail'}
    if detail is not None:
        result['detail'] = detail
    print(json.dumps(result), flush=True)


def has_exclusions(element):
    return element is not None and DOMAINS <= {
        node.attrib.get('domain') for node in element.findall('exclude')
        if node.attrib.get('path') == '.'
    }


def scan_secrets():
    tracked = subprocess.check_output(['git', 'ls-files', '-z'], cwd=ROOT).decode().split('\0')
    paths = {ROOT / name for name in tracked if name}
    for folder in ['build/web', '.claude/forge-runs']:
        path = ROOT / folder
        if path.exists():
            paths.update(p for p in path.rglob('*') if p.is_file())
    patterns = {
        'private_key': re.compile(r'-----BEGIN (?:RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----'),
        'supabase_secret': re.compile(r'\bsb_secret_[A-Za-z0-9_-]{20,}'),
        'github_token': re.compile(r'\b(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,})'),
        'aws_access_key': re.compile(r'\b(?:AKIA|ASIA)[A-Z0-9]{16}\b'),
        'stripe_secret': re.compile(r'\bsk_live_[A-Za-z0-9]{20,}'),
    }
    jwt = re.compile(r'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+')
    findings = []
    sources = artifacts = 0
    suffixes = {'.dart', '.py', '.md', '.json', '.jsonl', '.js', '.map', '.html', '.txt', '.yaml', '.yml', '.toml', '.xml', '.sql', '.kts', '.ps1', '.cjs', '.mjs', '.example'}
    for path in sorted(paths):
        if path.suffix not in suffixes or not path.is_file():
            continue
        try:
            text = path.read_text(encoding='utf-8-sig')
        except (UnicodeError, OSError):
            continue
        relative = path.relative_to(ROOT).as_posix()
        if relative.startswith(('build/', '.claude/forge-runs/')):
            artifacts += 1
        else:
            sources += 1
        for kind, pattern in patterns.items():
            for match in pattern.finditer(text):
                findings.append({'file': relative, 'line': text.count('\n', 0, match.start()) + 1, 'kind': kind})
        for match in jwt.finditer(text):
            try:
                encoded = match.group().split('.')[1]
                payload = json.loads(base64.urlsafe_b64decode(encoded + '=' * (-len(encoded) % 4)))
                if payload.get('role') == 'service_role':
                    findings.append({'file': relative, 'line': text.count('\n', 0, match.start()) + 1, 'kind': 'service_role_jwt'})
            except (ValueError, UnicodeError, TypeError):
                pass
    check('source_and_runtime_secret_scan', not findings,
          {'source_files': sources, 'runtime_files': artifacts, 'locations_only': findings})


def public_backend_checks():
    config = (ROOT / 'lib/data/backend_config.dart').read_text()
    defaults = re.findall(r"defaultValue: '([^']+)'", config)
    url, key = defaults[:2]
    headers = {'apikey': key}
    try:
        request = urllib.request.Request(url + '/auth/v1/settings', headers=headers)
        settings = json.load(urllib.request.urlopen(request, timeout=20))
        check('public_auth_settings', settings.get('external', {}).get('email') is True
              and settings.get('disable_signup') is False
              and settings.get('mailer_autoconfirm') is False
              and settings.get('external', {}).get('anonymous_users') is False)
        for table in ['profiles', 'transactions', 'budgets', 'savings_goals']:
            request = urllib.request.Request(url + f'/rest/v1/{table}?select=id&limit=1', headers=headers)
            try:
                rows = json.load(urllib.request.urlopen(request, timeout=20))
                check('anonymous_' + table + '_isolated', rows == [])
            except urllib.error.HTTPError as error:
                check('anonymous_' + table + '_isolated', error.code in (401, 403))
        class NoRedirect(urllib.request.HTTPRedirectHandler):
            def redirect_request(self, *args):
                return None
        callback = 'com.getyouthpay.bachat://auth/callback'
        query = urllib.parse.urlencode({'token': 'readiness-invalid-fixture-not-a-real-token', 'type': 'signup', 'redirect_to': callback})
        request = urllib.request.Request(url + '/auth/v1/verify?' + query, headers=headers)
        try:
            urllib.request.build_opener(NoRedirect()).open(request, timeout=20)
            check('native_auth_redirect_allowed', False, 'No redirect returned')
        except urllib.error.HTTPError as error:
            target = urllib.parse.urlsplit(error.headers.get('Location', ''))
            destination = urllib.parse.urlunsplit((target.scheme, target.netloc, target.path, '', ''))
            check('native_auth_redirect_allowed', error.code in (302, 303) and destination == callback,
                  {'destination_without_tokens': destination})
    except (urllib.error.URLError, ValueError, TimeoutError, OSError) as error:
        check('public_backend_reachable', False, type(error).__name__)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check-backend', action='store_true', help='Read public Auth/REST settings and probe redirects without sending email or creating users')
    options = parser.parse_args()
    manifest = ET.parse(ANDROID / 'AndroidManifest.xml').getroot()
    application = manifest.find('application')
    check('android_backup_disabled', application.get(NS + 'allowBackup') == 'false')
    check('android_backup_rules_wired', application.get(NS + 'fullBackupContent') == '@xml/backup_rules'
          and application.get(NS + 'dataExtractionRules') == '@xml/data_extraction_rules')
    check('legacy_private_data_excluded', has_exclusions(ET.parse(ANDROID / 'res/xml/backup_rules.xml').getroot()))
    extraction = ET.parse(ANDROID / 'res/xml/data_extraction_rules.xml').getroot()
    check('cloud_private_data_excluded', has_exclusions(extraction.find('cloud-backup')))
    check('device_transfer_private_data_excluded', has_exclusions(extraction.find('device-transfer')))
    release = tomllib.loads((ROOT / 'config/release/supabase/config.toml').read_text(encoding='utf-8-sig'))['auth']
    callback = 'com.getyouthpay.bachat://auth/callback'
    check('prepared_release_native_redirects', release['site_url'] == callback
          and release['additional_redirect_urls'] == [callback])
    check('prepared_release_auth_security', release['enable_signup'] is True
          and release['enable_anonymous_sign_ins'] is False
          and release['minimum_password_length'] >= 10
          and release['email']['enable_confirmations'] is True)
    sources = [(path, path.read_text(encoding='utf-8')) for path in (ROOT / 'lib').rglob('*.dart')]
    check('no_localhost_app_urls', not any(re.search(r'https?://(?:localhost|127\.0\.0\.1)(?=[:/\s\x27\x22])', text) for _, text in sources))
    check('no_mock_http_in_app', not any('MockClient(' in text or '/test/' in text or '/tool/' in text for _, text in sources))
    scan_secrets()
    if options.check_backend:
        public_backend_checks()
    print(json.dumps({'automated_failures': failures, 'manual_requirements': 'docs/SHIP-READINESS.md'}))
    return 1 if failures else 0


if __name__ == '__main__':
    sys.exit(main())
