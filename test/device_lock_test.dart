import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:bachat_mobile/application/device_lock.dart';
import 'package:bachat_mobile/data/pin_storage.dart';

class MemoryPinStorage implements PinStorage {
  final values = <String, String>{};
  bool failRead = false, failWrite = false;
  @override
  Future<String?> read(String account) async {
    if (failRead) throw StateError('Storage unavailable');
    return values[account];
  }

  @override
  Future<void> write(String account, String value) async {
    if (failWrite) throw StateError('Storage full');
    values[account] = value;
  }

  @override
  Future<void> delete(String account) async {
    values.remove(account);
  }
}

void main() {
  test(
    'PINs are salted per device, survive restart and stay account scoped',
    () async {
      final store = MemoryPinStorage(), otherDevice = MemoryPinStorage();
      final first = DeviceLock(store), second = DeviceLock(otherDevice);
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      await first.bind('teen');
      expect(first.needsSetup, isTrue);
      expect(await first.createPin('12345'), isFalse);
      expect(await first.createPin('654321'), isTrue);
      expect(first.locked, isFalse);
      expect(store.values['teen'], isNot(contains('654321')));
      await second.bind('teen');
      expect(second.needsSetup, isTrue);
      await second.createPin('654321');
      expect(
        jsonDecode(store.values['teen']!)['salt'],
        isNot(jsonDecode(otherDevice.values['teen']!)['salt']),
      );
      await first.bind('teen');
      expect(first.locked, isTrue);
      expect(await first.unlock('654321'), isTrue);
      await first.bind('someone-else');
      expect(first.needsSetup, isTrue);
      expect(first.locked, isTrue);
    },
  );

  test(
    'failed attempts persist across restart and enforce a cooldown',
    () async {
      final store = MemoryPinStorage();
      var time = DateTime.utc(2026, 10, 21);
      final lock = DeviceLock(store, now: () => time);
      addTearDown(lock.dispose);
      await lock.bind('teen');
      await lock.createPin('654321');
      lock.lock();
      for (var i = 0; i < 5; i++) {
        expect(await lock.unlock('000000'), isFalse);
      }
      expect(lock.waitSeconds, 30);
      await lock.bind('teen');
      expect(lock.waitSeconds, 30);
      expect(await lock.unlock('654321'), isFalse);
      time = time.add(const Duration(seconds: 31));
      expect(await lock.unlock('654321'), isTrue);
      expect(lock.waitSeconds, 0);
    },
  );

  test(
    'read/write failures fail closed and changing PIN requires the old one',
    () async {
      final store = MemoryPinStorage();
      final lock = DeviceLock(store);
      addTearDown(lock.dispose);
      await lock.bind('teen');
      await lock.createPin('654321');
      lock.lock(changePin: true);
      expect(lock.needsSetup, isFalse);
      expect(await lock.createPin('112233'), isFalse);
      await lock.unlock('654321');
      expect(lock.needsSetup, isTrue);
      store.failWrite = true;
      expect(await lock.createPin('112233'), isFalse);
      expect(lock.locked, isTrue);
      store.failWrite = false;
      expect(await lock.createPin('112233'), isTrue);
      lock.unbind();
      expect(lock.locked, isTrue);
      expect(lock.account, isNull);
      store.failRead = true;
      await lock.bind('teen');
      expect(lock.unavailable, isTrue);
      expect(await lock.createPin('000000'), isFalse);
      expect(lock.locked, isTrue);
    },
  );
}
