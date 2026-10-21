import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data/backend_config.dart';
import 'application/controller.dart';
import 'data/database.dart';
import 'data/repository.dart';
import 'design/theme.dart';
import 'presentation/app.dart';

bool _backendReady = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (!_backendReady) {
      await Supabase.initialize(
        url: BackendConfig.url,
        publishableKey: BackendConfig.publishableKey,
        authOptions: const FlutterAuthClientOptions(
          localStorage: SecureSessionStorage(),
          detectSessionInUri: false,
        ),
      );
      _backendReady = true;
    }
    final controller = AppController(
      BachatRepository(await openDatabase(), Supabase.instance.client),
    );
    runApp(
      ProviderScope(
        overrides: [controllerProvider.overrideWith((ref) => controller)],
        child: const BachatApp(),
      ),
    );
    await controller.initialize();
  } catch (_) {
    runApp(
      MaterialApp(
        theme: BachatTheme.build(Brightness.light),
        home: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Unable to start Bachat'),
                  const SizedBox(height: 16),
                  const Text(
                    'Check your connection and available storage, then try again.',
                  ),
                  const SizedBox(height: 24),
                  FilledButton(onPressed: main, child: const Text('Try again')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
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
      themeAnimationDuration: Duration.zero,
      home: const AppGate(),
    );
  }
}
