import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

import 'data/backend_http_client.dart';
import 'data/backend_config.dart';
import 'data/pin_storage.dart';
import 'application/device_lock.dart';
import 'application/licenses.dart';
import 'presentation/device_lock_screen.dart';
import 'application/controller.dart';
import 'data/database.dart';
import 'data/repository.dart';
import 'design/theme.dart';
import 'design/components.dart';
import 'presentation/app.dart';

bool _backendReady = false;

Future<void> main() async {
  // Capture email callback parameters before Flutter routing can update the URL.
  final initialAuthLink = Uri.base;
  WidgetsFlutterBinding.ensureInitialized();
  BachatLicenses.register();
  try {
    if (!_backendReady) {
      await Supabase.initialize(
        url: BackendConfig.url,
        publishableKey: BackendConfig.publishableKey,
        httpClient: BackendHttpClient(http.Client()),
        postgrestOptions: const PostgrestClientOptions(
          requestTimeout: Duration(seconds: 15),
        ),
        authOptions: const FlutterAuthClientOptions(
          localStorage: SecureSessionStorage(),
          detectSessionInUri: false,
        ),
      );
      _backendReady = true;
    }
    final controller = AppController(
      BachatRepository(await openDatabase(), Supabase.instance.client),
      deviceLock: DeviceLock(SecurePinStorage()),
    );
    runApp(
      ProviderScope(
        overrides: [controllerProvider.overrideWith((ref) => controller)],
        child: const BachatApp(),
      ),
    );
    await controller.initialize(initialAuthLink: initialAuthLink);
  } catch (_) {
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: BachatTheme.build(Brightness.dark),
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
      builder: (context, child) => BachatBackdrop(
        child: Theme(
          data: Theme.of(context).copyWith(
            scaffoldBackgroundColor: Colors.transparent,
            appBarTheme: Theme.of(
              context,
            ).appBarTheme.copyWith(backgroundColor: Colors.transparent),
          ),
          child: DevicePrivacyGate(controller: controller, child: child!),
        ),
      ),
      home: const AppGate(),
    );
  }
}
