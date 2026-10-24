import 'package:flutter/material.dart';

import '../design/components.dart';

/// Describes implemented data behavior without inventing legal/contact details.
class DataPrivacyScreen extends StatelessWidget {
  const DataPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Your data')),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Text(
                  'Bachat is a manual money tracker. It does not connect to a bank or move money.',
                ),
                const SectionHeading('Your account'),
                const Text(
                  'Your email is used for sign-in, confirmation and password recovery through Supabase Auth. Your profile stores the name and age you provide.',
                ),
                const SectionHeading('Your money records'),
                const Text(
                  'Transactions, notes, budgets and savings goals are saved in this app\'s private storage and synced to your account. Changes waiting to sync exist only on the device where you entered them.',
                ),
                const SectionHeading('Your device PIN'),
                const Text(
                  'Your PIN stays on this device in secure storage. Each device uses its own PIN. Keep your device passcode enabled too.',
                ),
                const SectionHeading('Editing and deleting records'),
                const Text(
                  'You can edit or delete records in Activity and Plan. Deleted records are hidden from your lists and retained by the sync service so your other devices can apply the deletion.',
                ),
                const SectionHeading('Before signing out'),
                const Text(
                  'Sync first to keep your latest changes. Signing out removes this device\'s cached records and any changes still waiting to sync. Your account and synced records remain available when you sign in again.',
                ),
                const SizedBox(height: 28),
                OutlinedButton.icon(
                  onPressed: () => showLicensePage(
                    context: context,
                    applicationName: 'Bachat',
                  ),
                  icon: const Icon(Icons.code_rounded),
                  label: const Text('Open-source licenses'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
