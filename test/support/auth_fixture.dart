import 'dart:convert';

const fixtureAccount = '01d263f0-3e3f-4d2f-aa01-5ea8933b1251';
Map<String, dynamic> fixtureUser([String id = fixtureAccount]) => {
  'id': id,
  'aud': 'authenticated',
  'role': 'authenticated',
  'email': 'fixture@example.invalid',
  'app_metadata': {'provider': 'email'},
  'user_metadata': {},
  'created_at': '2026-01-01T00:00:00Z',
  'email_confirmed_at': '2026-01-01T00:00:00Z',
};
Map<String, dynamic> fixtureSession([String id = fixtureAccount]) {
  String segment(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  final expires = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600;
  return {
    'access_token':
        '${segment({'alg': 'HS256', 'typ': 'JWT'})}.${segment({'sub': id, 'exp': expires})}.signature',
    'refresh_token': 'fixture-refresh',
    'expires_in': 3600,
    'expires_at': expires,
    'token_type': 'bearer',
    'user': fixtureUser(id),
  };
}
