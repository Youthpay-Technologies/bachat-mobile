import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:bachat_mobile/data/repository.dart';
import 'package:bachat_mobile/application/controller.dart';
import 'package:bachat_mobile/domain/models.dart';

void main() {
  test('outbox coalesces edits and isolates accounts atomically', () async {
    final db = await databaseFactoryMemory.openDatabase('queue');
    addTearDown(db.close);
    final r = BachatRepository(db, null);
    await r.queue(
      'teen-a',
      'transactions',
      {'id': 'entry', 'amount_minor': 100},
      {'version': 1},
    );
    await r.queue(
      'teen-a',
      'transactions',
      {'id': 'entry', 'amount_minor': 250},
      {'version': 2},
    );
    await r.queue(
      'teen-b',
      'transactions',
      {'id': 'entry', 'amount_minor': 999},
      {'version': 3},
    );
    expect((await r.pending('teen-a')).single.value['row'], {
      'id': 'entry',
      'amount_minor': 250,
    });
    expect((await r.load('teen-a'))!['version'], 2);
    await r.clearAccount('teen-a');
    expect(await r.pending('teen-a'), isEmpty);
    expect((await r.pending('teen-b')).length, 1);
    expect(await r.load('teen-a'), isNull);
  });
  test('parent cannot mutate a child record even through controller', () async {
    final db = await databaseFactoryMemory.openDatabase('read-only');
    addTearDown(db.close);
    final c = AppController(BachatRepository(db, null));
    addTearDown(c.dispose);
    c.startPreview(UserRole.parent);
    await expectLater(
      c.saveGoal(
        const SavingsGoal(
          id: 'attack',
          ownerId: 'preview-teen',
          title: 'Attempt',
          targetMinor: 100,
        ),
      ),
      throwsFormatException,
    );
  });
  test('teen cannot edit after last parent is revoked', () async {
    final db = await databaseFactoryMemory.openDatabase('revoked');
    addTearDown(db.close);
    final c = AppController(BachatRepository(db, null));
    addTearDown(c.dispose);
    c.startPreview(UserRole.teen);
    await c.revokeLink(c.links.first);
    await expectLater(
      c.saveBudget(
        CategoryBudget(
          id: 'attempt',
          ownerId: c.profile!.id,
          category: 'Other',
          limitMinor: 100,
          month: monthKey(DateTime.now()),
        ),
      ),
      throwsFormatException,
    );
  });
}
