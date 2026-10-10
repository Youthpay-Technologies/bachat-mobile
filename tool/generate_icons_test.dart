// Rebuild launcher assets from the same code-native YP mark used in the app.
// Run explicitly: flutter test tool/generate_icons_test.dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('generate Bachat launcher assets', (tester) async {
    final font = FontLoader('DM Sans')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/DMSans.ttf').readAsBytesSync(),
          ),
        ),
      );
    await font.load();
    Future<void> render(String path, int size) async {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
        Paint()..color = const Color(0xFF172D35),
      );
      final text = TextPainter(
        text: TextSpan(
          text: 'YP',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w800,
            fontSize: size * .42,
            color: const Color(0xFFEBDDB5),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(
        canvas,
        Offset((size - text.width) / 2, (size - text.height) / 2),
      );
      final picture = recorder.endRecording();
      final image = await picture.toImage(size, size);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(path).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
      picture.dispose();
    }

    await tester.runAsync(() async {
      for (final entry in {
        'mdpi': 48,
        'hdpi': 72,
        'xhdpi': 96,
        'xxhdpi': 144,
        'xxxhdpi': 192,
      }.entries) {
        await render(
          'android/app/src/main/res/mipmap-${entry.key}/ic_launcher.png',
          entry.value,
        );
      }
      for (final file in Directory(
        'ios/Runner/Assets.xcassets/AppIcon.appiconset',
      ).listSync().whereType<File>().where((f) => f.path.endsWith('.png'))) {
        final name = file.uri.pathSegments.last;
        final match = RegExp(
          r'Icon-App-([\d.]+)x[\d.]+@([123])x',
        ).firstMatch(name)!;
        await render(
          file.path,
          (double.parse(match[1]!) * int.parse(match[2]!)).round(),
        );
      }
      await render('web/favicon.png', 32);
      for (final size in [192, 512]) {
        await render('web/icons/Icon-$size.png', size);
        await render('web/icons/Icon-maskable-$size.png', size);
      }
    });
  });
}
