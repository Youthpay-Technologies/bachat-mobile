import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'application/controller.dart';
import 'data/database.dart';
import 'data/repository.dart';
import 'design/theme.dart';
import 'presentation/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  SupabaseClient? cloud;
  if (url.isNotEmpty && key.isNotEmpty) {
    await Supabase.initialize(
      url: url,
      publishableKey: key,
      authOptions: const FlutterAuthClientOptions(
        localStorage: SecureSessionStorage(),
      ),
    );
    cloud = Supabase.instance.client;
  }
  final controller = AppController(
    BachatRepository(await openDatabase(), cloud),
  );
  await controller.initialize();
  runApp(
    ProviderScope(
      overrides: [controllerProvider.overrideWith((ref) => controller)],
      child: const BachatApp(),
    ),
  );
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
