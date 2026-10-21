import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/controller.dart';
import '../design/components.dart';
import '../domain/models.dart';
import 'app.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, this.recovery = false});
  final bool recovery;
  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  var form = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  bool create = false, reset = false, visible = false;
  @override
  void initState() {
    super.initState();
    email.text = ref.read(controllerProvider).pendingEmail ?? '';
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final c = ref.read(controllerProvider);
    if (c.busy || !form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    if (widget.recovery) {
      await c.finishPasswordRecovery(password.text);
    } else if (reset) {
      await c.requestPasswordReset(email.text);
    } else if (create) {
      await c.signUp(email.text, password.text);
      if (mounted && c.pendingEmail != null) setState(() => create = false);
    } else {
      await c.signIn(email.text, password.text);
    }
  }

  void mode({bool signUp = false, bool forgot = false}) {
    ref.read(controllerProvider).clearAuthFeedback();
    form = GlobalKey<FormState>();
    password.clear();
    confirm.clear();
    setState(() {
      create = signUp;
      reset = forgot;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(controllerProvider);
    final title = widget.recovery
        ? 'Choose a new password'
        : reset
        ? 'Reset your password'
        : create
        ? 'Make room for your goals'
        : 'Welcome back';
    return Scaffold(
      body: SafeArea(
        child: AutofillGroup(
          child: Form(
            key: form,
            child: PageBody(
              children: [
                const BachatMark(),
                const SizedBox(height: 44),
                Text(title, style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 12),
                Text(
                  widget.recovery
                      ? 'Use a password you have not used before.'
                      : reset
                      ? 'We will email you a link to choose a new password.'
                      : create
                      ? 'Create your teen account to start tracking.'
                      : 'Sign in to pick up where you left off.',
                ),
                const SizedBox(height: 32),
                if (!widget.recovery) ...[
                  TextFormField(
                    controller: email,
                    enabled: !c.busy,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    autocorrect: false,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: validateEmail,
                  ),
                  const SizedBox(height: 20),
                ],
                if (!reset || widget.recovery) ...[
                  TextFormField(
                    controller: password,
                    enabled: !c.busy,
                    obscureText: !visible,
                    autocorrect: false,
                    enableSuggestions: false,
                    autofillHints: [
                      create || widget.recovery
                          ? AutofillHints.newPassword
                          : AutofillHints.password,
                    ],
                    textInputAction: widget.recovery
                        ? TextInputAction.next
                        : TextInputAction.done,
                    onFieldSubmitted: (_) {
                      if (!widget.recovery) submit();
                    },
                    decoration: InputDecoration(
                      labelText: widget.recovery ? 'New password' : 'Password',
                      helperText: create || widget.recovery
                          ? 'At least 10 characters'
                          : null,
                      suffixIcon: IconButton(
                        tooltip: visible ? 'Hide password' : 'Show password',
                        onPressed: () => setState(() => visible = !visible),
                        icon: Icon(
                          visible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                    validator: create || widget.recovery
                        ? validatePassword
                        : (v) =>
                              (v ?? '').isEmpty ? 'Enter your password.' : null,
                  ),
                  const SizedBox(height: 20),
                ],
                if (widget.recovery) ...[
                  TextFormField(
                    controller: confirm,
                    enabled: !c.busy,
                    obscureText: !visible,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      labelText: 'Confirm new password',
                    ),
                    onFieldSubmitted: (_) => submit(),
                    validator: (v) =>
                        v != password.text ? 'Passwords do not match.' : null,
                  ),
                  const SizedBox(height: 20),
                ],
                if (c.authNotice != null) ...[
                  Semantics(
                    liveRegion: true,
                    child: Surface(child: Text(c.authNotice!)),
                  ),
                  const SizedBox(height: 16),
                ],
                AppError(c),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: c.busy ? null : submit,
                    child: Text(
                      c.busy
                          ? 'Please wait...'
                          : widget.recovery
                          ? 'Update password'
                          : reset
                          ? 'Send reset link'
                          : create
                          ? 'Create account'
                          : 'Sign in',
                    ),
                  ),
                ),
                if (!widget.recovery) ...[
                  const SizedBox(height: 12),
                  if (!reset && !create)
                    TextButton(
                      onPressed: c.busy ? null : () => mode(forgot: true),
                      child: const Text('Forgot password?'),
                    ),
                  TextButton(
                    onPressed: c.busy
                        ? null
                        : () => mode(signUp: !create && !reset),
                    child: Text(
                      reset || create ? 'Back to sign in' : 'Create an account',
                    ),
                  ),
                  if (!create && !reset)
                    TextButton(
                      onPressed: c.busy
                          ? null
                          : () async {
                              if (validateEmail(email.text) != null) {
                                form.currentState!.validate();
                                return;
                              }
                              await c.resendConfirmation(email.text);
                            },
                      child: const Text('Resend confirmation email'),
                    ),
                ] else
                  TextButton(
                    onPressed: c.busy ? null : c.signOut,
                    child: const Text('Cancel and sign out'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});
  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupState();
}

class _ProfileSetupState extends ConsumerState<ProfileSetupScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  int? age;
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(controllerProvider);
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: form,
          child: PageBody(
            children: [
              const BachatMark(),
              const SizedBox(height: 44),
              Text(
                'A little about you',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 12),
              const Text(
                'Start your teen profile. Bachat is for ages 13 to 18.',
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: name,
                enabled: !c.busy,
                maxLength: 60,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.givenName],
                decoration: const InputDecoration(labelText: 'Your name'),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Enter your name.' : null,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<int>(
                initialValue: age,
                decoration: const InputDecoration(labelText: 'Age'),
                items: List.generate(
                  6,
                  (i) =>
                      DropdownMenuItem(value: 13 + i, child: Text('${13 + i}')),
                ),
                onChanged: c.busy ? null : (v) => setState(() => age = v),
                validator: (v) => v == null ? 'Choose your age.' : null,
              ),
              const SizedBox(height: 28),
              AppError(c),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: c.busy
                      ? null
                      : () async {
                          if (form.currentState!.validate()) {
                            await c.createProfile(
                              name.text,
                              UserRole.teen,
                              age,
                            );
                          }
                        },
                  child: Text(c.busy ? 'Saving...' : 'Start tracking'),
                ),
              ),
              TextButton(
                onPressed: c.busy ? null : c.signOut,
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AccountDetails extends ConsumerStatefulWidget {
  const AccountDetails(this.controller, {super.key});
  final AppController controller;
  @override
  ConsumerState<AccountDetails> createState() => _AccountDetailsState();
}

class _AccountDetailsState extends ConsumerState<AccountDetails> {
  late final name = TextEditingController(
    text: widget.controller.profile?.name ?? '',
  );
  final form = GlobalKey<FormState>();
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(controllerProvider);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Form(
          key: form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your account',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: name,
                maxLength: 60,
                enabled: !c.busy,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Enter your name.' : null,
              ),
              const SizedBox(height: 16),
              SelectableText(c.client?.auth.currentUser?.email ?? ''),
              const SizedBox(height: 8),
              Text(
                'Teen · ${c.profile?.age}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              AppError(c),
              FilledButton(
                onPressed: c.busy
                    ? null
                    : () async {
                        if (form.currentState!.validate() &&
                            await c.updateName(name.text) &&
                            context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                child: Text(c.busy ? 'Saving...' : 'Save changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AccountActions extends ConsumerWidget {
  const AccountActions(this.controller, {super.key});
  final AppController controller;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(controllerProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (c.pendingCount > 0 || c.offline)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.cloud_upload_outlined),
            title: Text(
              c.pendingCount > 0
                  ? '${c.pendingCount} changes waiting to sync'
                  : 'Connection unavailable',
            ),
            trailing: TextButton(
              onPressed: c.syncing ? null : c.refresh,
              child: Text(c.syncing ? 'Syncing...' : 'Retry'),
            ),
          ),
        OutlinedButton.icon(
          onPressed: c.busy
              ? null
              : () async {
                  final email = c.client?.auth.currentUser?.email;
                  if (email != null &&
                      await c.requestPasswordReset(email) &&
                      context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Check your email for a password reset link.',
                        ),
                      ),
                    );
                  }
                },
          icon: const Icon(Icons.lock_reset),
          label: const Text('Reset password'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: c.busy
              ? null
              : () async {
                  if (await confirmAction(
                    context,
                    title: 'Sign out?',
                    body: c.pendingCount > 0
                        ? 'Your unsynced changes on this device will be discarded. Stay signed in and retry sync to keep them.'
                        : 'You can sign in again with your email and password.',
                    action: c.pendingCount > 0
                        ? 'Discard changes and sign out'
                        : 'Sign out',
                  )) {
                    await c.run(c.signOut);
                  }
                },
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
        ),
      ],
    );
  }
}
