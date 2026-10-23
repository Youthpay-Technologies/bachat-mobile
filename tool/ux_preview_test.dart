// Explicit visual check: flutter test tool/ux_preview_test.dart
// Uses isolated preview records; never authenticates or changes cloud data.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bachat_mobile/application/controller.dart';
import 'package:bachat_mobile/data/repository.dart';
import 'package:bachat_mobile/domain/models.dart';
import 'package:bachat_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  for (final dark in [false, true]) {
    for (final large in [false, true]) {
      testWidgets(
        'render ${dark ? 'dark' : 'light'} ${large ? 'large text' : 'normal'} journeys',
        (tester) async {
          tester.view.physicalSize = Size(large ? 320 : 390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final db = await databaseFactoryMemory.openDatabase('ux-preview');
          final controller = AppController(BachatRepository(db, null))
            ..ready = true
            ..theme = dark ? 'dark' : 'light';
          addTearDown(db.close);
          await tester.runAsync(() async {
            final icons = FontLoader('MaterialIcons')
              ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
            await icons.load();
            for (final font in {
              'Instrument Sans': 'InstrumentSans.ttf',
              'Instrument Serif': 'InstrumentSerif-Italic.ttf',
              'Inter': 'Inter-Regular.ttf',
            }.entries) {
              final loader = FontLoader(font.key)
                ..addFont(
                  File(
                    'assets/fonts/${font.value}',
                  ).readAsBytes().then(ByteData.sublistView),
                );
              await loader.load();
            }
          });
          const boundaryKey = ValueKey('ux-capture');
          await tester.pumpWidget(
            ProviderScope(
              overrides: [controllerProvider.overrideWith((ref) => controller)],
              child: MaterialApp(
                home: MediaQuery(
                  data: MediaQueryData(
                    size: Size(large ? 320 : 390, 844),
                    textScaler: TextScaler.linear(large ? 2 : 1),
                    disableAnimations: true,
                  ),
                  child: const RepaintBoundary(
                    key: boundaryKey,
                    child: BachatApp(),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          Future<void> capture(String name) async {
            expect(tester.takeException(), isNull);
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(boundaryKey),
            );
            await tester.runAsync(() async {
              final image = await boundary.toImage();
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              final output = File(
                'docs/screenshots/ux/$name-${dark ? 'dark' : 'light'}${large ? '-large' : ''}.png',
              );
              await output.parent.create(recursive: true);
              await output.writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }

          for (var step = 0; step < 3; step++) {
            await capture('introduction-${step + 1}');
            if (step < 2) {
              await tester.ensureVisible(find.text('Continue'));
              await tester.tap(find.text('Continue'));
              await tester.pumpAndSettle();
              await tester.drag(
                find.byType(SingleChildScrollView).first,
                const Offset(0, 3000),
              );
              await tester.pumpAndSettle();
            }
          }
          controller.startPreview(UserRole.teen);
          await tester.pumpAndSettle();
          await capture('home');
          for (final tab in ['Activity', 'Plan', 'Learn', 'You']) {
            await tester.tap(find.text(tab).last);
            await tester.pumpAndSettle();
            await capture(tab.toLowerCase());
          }
        },
      );
    }
  }
}
