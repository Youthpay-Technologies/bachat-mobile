import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:bachat_mobile/application/controller.dart';
import 'package:bachat_mobile/data/repository.dart';
import 'package:bachat_mobile/domain/models.dart';

void main() {
  test('demo edits survive switching personas and restarting', () async {
    final db = await databaseFactoryMemory.openDatabase('demo-persistence');
    addTearDown(db.close);
    final repo = BachatRepository(db, null);
    final teen = AppController(repo);
    addTearDown(teen.dispose);
    await teen.initialize();
    await teen.startDemo(UserRole.teen);
    await teen.saveEntry(
      MoneyEntry(
        id: 'lunch',
        ownerId: teen.profile!.id,
        merchant: 'School lunch',
        amountMinor: 12550,
        direction: EntryDirection.expense,
        category: 'Food & dining',
        occurredAt: DateTime.now(),
      ),
    );
    await teen.startDemo(UserRole.parent);
    expect(teen.entries.any((e) => e.id == 'lunch'), isTrue);
    await expectLater(
      teen.saveEntry(teen.entries.first),
      throwsFormatException,
    );
    final reopened = AppController(repo);
    addTearDown(reopened.dispose);
    await reopened.initialize();
    expect(reopened.isParent, isTrue);
    expect(reopened.entries.any((e) => e.id == 'lunch'), isTrue);
    expect(await repo.pending('preview-teen'), isEmpty);
    await reopened.resetDemo();
    expect(reopened.entries.any((e) => e.id == 'lunch'), isFalse);
  });
  test(
    'demo family requires code and mutual confirmation across personas',
    () async {
      final db = await databaseFactoryMemory.openDatabase('demo-consent');
      addTearDown(db.close);
      final c = AppController(BachatRepository(db, null));
      addTearDown(c.dispose);
      await c.startDemo(UserRole.teen);
      await c.revokeLink(c.links.single);
      expect(c.needsApproval, isTrue);
      await c.generateCode();
      final code = c.familyCode!;
      await c.startDemo(UserRole.parent);
      expect(await c.claimCode('wrong'), isFalse);
      expect(await c.claimCode(code), isTrue);
      expect(c.children, isEmpty);
      await c.startDemo(UserRole.teen);
      await c.decideLink(c.links.single, true);
      expect(c.approved, isTrue);
      await c.startDemo(UserRole.parent);
      expect(c.children.single.teenName, 'Ayesha');
    },
  );
}
