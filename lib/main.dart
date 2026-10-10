import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'application/controller.dart';
import 'data/database.dart';
import 'data/repository.dart';
import 'design/theme.dart';
import 'presentation/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = AppController(
    BachatRepository(await openDatabase(), null),
  );
  runApp(
    ProviderScope(
      overrides: [controllerProvider.overrideWith((ref) => controller)],
      child: const BachatApp(),
    ),
  );
  await controller.initialize();
}

class BachatApp extends ConsumerWidget {
  const BachatApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(controllerProvider);
    return MaterialApp(
      title: 'Bachat',
      debugShowCheckedModeBanner: false,
      theme: BachatTheme.build(Brightness.light),
      darkTheme: BachatTheme.build(Brightness.dark),
      themeMode: controller.themeMode,
      home: const AppGate(),
    );
  }
}
