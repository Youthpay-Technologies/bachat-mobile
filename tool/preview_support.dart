import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const previewBoundaryKey = ValueKey('ux-capture');

Future<void> loadPreviewFonts(WidgetTester tester) async {
  await tester.runAsync(() async {
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    for (final font in {
      'Instrument Sans': 'InstrumentSans.ttf',
      'FK Grotesk': 'FKGrotesk-Regular.otf',
      'Instrument Serif': 'InstrumentSerif-Italic.ttf',
      'Inter': 'Inter-Regular.ttf',
    }.entries) {
      await (FontLoader(font.key)..addFont(
            File(
              'assets/fonts/${font.value}',
            ).readAsBytes().then(ByteData.sublistView),
          ))
          .load();
    }
  });
}

Future<void> capturePreview(
  WidgetTester tester,
  String name, {
  required bool dark,
  bool large = false,
}) async {
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(previewBoundaryKey),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File(
      'docs/screenshots/ux/$name-${dark ? 'dark' : 'light'}${large ? '-large' : ''}.png',
    );
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
