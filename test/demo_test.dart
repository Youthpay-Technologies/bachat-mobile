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
    expect(teen.entries, isEmpty);
    expect(teen.budgets, isEmpty);
    expect(teen.goals, isEmpty);
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
      expect(c.entries, isEmpty);
      expect(c.budgets, isEmpty);
      expect(c.goals, isEmpty);
      await c.startDemo(UserRole.teen);
      await c.decideLink(c.links.single, true);
      expect(c.approved, isTrue);
      await c.startDemo(UserRole.parent);
      expect(c.children.single.teenName, 'Ayesha');
    },
  );

  test('local demo Gmail sync explains the missing OAuth setup', () async {
    final db = await databaseFactoryMemory.openDatabase('demo-gmail-config');
    addTearDown(db.close);
    final c = AppController(BachatRepository(db, null));
    addTearDown(c.dispose);
    await c.startDemo(UserRole.teen);

    await expectLater(
      c.syncEmailTransactions(),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('GOOGLE_SERVER_CLIENT_ID'),
        ),
      ),
    );
  });

  test(
    'opening an existing demo removes its preloaded sample records',
    () async {
      final db = await databaseFactoryMemory.openDatabase(
        'demo-sample-migration',
      );
      addTearDown(db.close);
      final repository = BachatRepository(db, null);
      final original = AppController(repository);
      addTearDown(original.dispose);
      await original.startDemo(UserRole.teen);
      original.allEntries.add(
        MoneyEntry(
          id: 'preview-2',
          ownerId: original.profile!.id,
          merchant: 'Foodpanda',
          amountMinor: 86500,
          direction: EntryDirection.expense,
          category: 'Food & dining',
          occurredAt: DateTime.now(),
        ),
      );
      original.allEntries.add(
        MoneyEntry(
          id: 'my-entry',
          ownerId: original.profile!.id,
          merchant: 'My lunch',
          amountMinor: 10000,
          direction: EntryDirection.expense,
          category: 'Food & dining',
          occurredAt: DateTime.now(),
        ),
      );
      await repository.save(AppController.demoKey, original.snapshot());

      final reopened = AppController(repository);
      addTearDown(reopened.dispose);
      await reopened.initialize();
      expect(reopened.entries.map((entry) => entry.id), ['my-entry']);
    },
  );
}
