import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'design/theme.dart';
import 'design/components.dart';

void main() => runApp(const ProviderScope(child: BachatApp()));

class BachatApp extends StatelessWidget {
  const BachatApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Bachat',
    debugShowCheckedModeBanner: false,
    theme: BachatTheme.build(Brightness.light),
    darkTheme: BachatTheme.build(Brightness.dark),
    home: const Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BachatMark(large: true),
              SizedBox(height: 48),
              Text(
                'A little clarity.\nA better money habit.',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 16),
              Text(
                'Bachat helps teens track spending and save with the support of their parents.',
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
