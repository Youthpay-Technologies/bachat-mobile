import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import '../data/pin_storage.dart';

Future<String> _pinDigest(Map<String, String> value) async {
  final key =
      await Pbkdf2(
        macAlgorithm: Hmac.sha256(),
        iterations: 210000,
        bits: 256,
      ).deriveKey(
        secretKey: SecretKey(utf8.encode(value['pin']!)),
        nonce: base64Decode(value['salt']!),
      );
  return base64Encode(await key.extractBytes());
}

class DeviceLock extends ChangeNotifier {
  DeviceLock(this.storage, {DateTime Function()? now})
    : now = now ?? DateTime.now;
  final PinStorage storage;
  final DateTime Function() now;
  String? account;
  Map<String, dynamic>? _record;
  bool loading = true, locked = true, busy = false, unavailable = false;
  bool _changeRequested = false, _changeVerified = false, _disposed = false;
  int _epoch = 0, _lockCycle = 0;
  String? error;
  bool get needsSetup => _record == null || _changeVerified;
  DateTime? get blockedUntil => _record?['blocked_until'] == null
      ? null
      : DateTime.parse(_record!['blocked_until'] as String);
  int get waitSeconds {
    final millis = (blockedUntil?.difference(now()).inMilliseconds ?? 0);
    return millis > 0 ? (millis / 1000).ceil() : 0;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void unbind() {
    _epoch++;
    account = null;
    _record = null;
    locked = true;
    loading = true;
    busy = false;
    _changeRequested = false;
    _changeVerified = false;
    _notify();
  }

  Future<void> bind(String id) async {
    final epoch = ++_epoch;
    account = id;
    loading = true;
    locked = true;
    busy = false;
    unavailable = false;
    error = null;
    _record = null;
    _changeRequested = false;
    _changeVerified = false;
    _notify();
    try {
      final raw = await storage.read(id);
      if (epoch != _epoch || _disposed) return;
      if (raw != null) {
        final record = jsonDecode(raw) as Map<String, dynamic>;
        if (record['version'] != 1 ||
            base64Decode(record['salt'] as String).length != 16 ||
            base64Decode(record['hash'] as String).length != 32 ||
            record['failures'] is! int ||
            (record['failures'] as int) < 0) {
          throw const FormatException('Invalid PIN record');
        }
        if (record['blocked_until'] != null) {
          DateTime.parse(record['blocked_until'] as String);
        }
        _record = record;
      }
    } catch (_) {
      if (epoch == _epoch) {
        unavailable = true;
        error = 'Unable to open your device lock. Try again.';
      }
    } finally {
      if (epoch == _epoch) {
        loading = false;
        _notify();
      }
    }
  }

  void lock({bool changePin = false}) {
    _lockCycle++;
    locked = true;
    _changeRequested = changePin;
    _changeVerified = false;
    error = null;
    _notify();
  }

  Future<bool> createPin(String pin) async {
    if (busy || loading || unavailable || !needsSetup || account == null) {
      return false;
    }
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      error = 'Use a 6-digit PIN.';
      _notify();
      return false;
    }
    final id = account!, epoch = _epoch, cycle = _lockCycle;
    busy = true;
    error = null;
    _notify();
    try {
      final salt = base64Encode(
        List.generate(16, (_) => Random.secure().nextInt(256)),
      );
      final digest = await compute(_pinDigest, {'pin': pin, 'salt': salt});
      if (epoch != _epoch || _disposed) return false;
      final record = <String, dynamic>{
        'version': 1,
        'salt': salt,
        'hash': digest,
        'failures': 0,
        'blocked_until': null,
      };
      await storage.write(id, jsonEncode(record));
      if (epoch != _epoch || _disposed) return false;
      _record = record;
      _changeRequested = false;
      _changeVerified = false;
      locked = cycle != _lockCycle;
      return !locked;
    } catch (_) {
      if (epoch == _epoch) error = 'Unable to save your PIN. Try again.';
      return false;
    } finally {
      if (epoch == _epoch) {
        busy = false;
        _notify();
      }
    }
  }

  Future<bool> unlock(String pin) async {
    if (busy ||
        loading ||
        unavailable ||
        needsSetup ||
        waitSeconds > 0 ||
        account == null) {
      return false;
    }
    final id = account!, epoch = _epoch, cycle = _lockCycle;
    busy = true;
    error = null;
    _notify();
    try {
      final digest = await compute(_pinDigest, {
        'pin': pin,
        'salt': _record!['salt'] as String,
      });
      if (epoch != _epoch || _disposed) return false;
      final expected = base64Decode(_record!['hash'] as String),
          actual = base64Decode(digest);
      var difference = expected.length ^ actual.length;
      for (var i = 0; i < expected.length && i < actual.length; i++) {
        difference |= expected[i] ^ actual[i];
      }
      final correct = difference == 0;
      final failures = correct ? 0 : (_record!['failures'] as int) + 1;
      final next = {
        ..._record!,
        'failures': failures,
        'blocked_until': !correct && failures >= 5
            ? now()
                  .add(Duration(seconds: min(300, 30 * (failures - 4))))
                  .toIso8601String()
            : null,
      };
      await storage.write(id, jsonEncode(next));
      if (epoch != _epoch || _disposed) return false;
      _record = next;
      if (!correct) {
        error = waitSeconds > 0
            ? 'Too many attempts. Try again shortly.'
            : 'Incorrect PIN. Try again.';
        return false;
      }
      if (cycle != _lockCycle) return false;
      if (_changeRequested) {
        _changeVerified = true;
      } else {
        locked = false;
      }
      return true;
    } catch (_) {
      if (epoch == _epoch) error = 'Unable to unlock. Try again.';
      return false;
    } finally {
      if (epoch == _epoch) {
        busy = false;
        _notify();
      }
    }
  }

  // Used only after the app has signed out and cleared that account's cache.
  Future<void> forget(String id) => storage.delete(id);
  @override
  void dispose() {
    _disposed = true;
    _epoch++;
    super.dispose();
  }
}
