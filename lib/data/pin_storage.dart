import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class PinStorage {
  Future<String?> read(String account);
  Future<void> write(String account, String value);
  Future<void> delete(String account);
}

class SecurePinStorage implements PinStorage {
  static const _storage = FlutterSecureStorage();
  String _key(String account) => 'bachat_device_pin_v1_$account';
  @override
  Future<String?> read(String account) => _storage.read(key: _key(account));
  @override
  Future<void> write(String account, String value) =>
      _storage.write(key: _key(account), value: value);
  @override
  Future<void> delete(String account) => _storage.delete(key: _key(account));
}
