import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../application/controller.dart';
import '../application/device_lock.dart';
import '../design/components.dart';

class DevicePrivacyGate extends StatefulWidget {
  const DevicePrivacyGate({
    super.key,
    required this.controller,
    required this.child,
  });
  final AppController controller;
  final Widget child;
  @override
  State<DevicePrivacyGate> createState() => _DevicePrivacyGateState();
}

class _DevicePrivacyGateState extends State<DevicePrivacyGate>
    with WidgetsBindingObserver {
  bool obscured = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    final c = widget.controller;
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      c.deviceLock?.lock();
    }
    setState(() => obscured = state != AppLifecycleState.resumed);
    if (state == AppLifecycleState.resumed) c.requestRefresh();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller, lock = c.deviceLock;
    if (lock == null || c.preview) return widget.child;
    return AnimatedBuilder(
      animation: lock,
      builder: (context, _) {
        final eligible =
            c.signedIn &&
            c.profile != null &&
            !c.isParent &&
            !c.recoveringPassword;
        final needsLock =
            eligible &&
            (lock.account != c.accountId || lock.locked || lock.loading);
        final cover = obscured || needsLock;
        return Stack(
          fit: StackFit.expand,
          children: [
            Offstage(
              offstage: cover,
              child: ExcludeSemantics(
                excluding: cover,
                child: IgnorePointer(ignoring: cover, child: widget.child),
              ),
            ),
            if (obscured)
              ColoredBox(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: const Center(child: Icon(Icons.lock_outline)),
              )
            else if (needsLock)
              _PinSession(
                key: ValueKey(c.accountId),
                controller: c,
                lock: lock,
              ),
          ],
        );
      },
    );
  }
}

class _PinSession extends StatefulWidget {
  const _PinSession({super.key, required this.controller, required this.lock});
  final AppController controller;
  final DeviceLock lock;
  @override
  State<_PinSession> createState() => _PinSessionState();
}

class _PinSessionState extends State<_PinSession> {
  late final Future<void> initialized;
  final form = GlobalKey<FormState>();
  final pin = TextEditingController(), confirm = TextEditingController();
  late final Timer ticker;
  bool signingOut = false, confirmSignOut = false;
  @override
  void initState() {
    super.initState();
    final lock = widget.lock, id = widget.controller.accountId!;
    initialized = lock.account == id
        ? Future.value()
        : Future.microtask(() => lock.bind(id));
    ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    ticker.cancel();
    pin.dispose();
    confirm.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final lock = widget.lock;
    if (signingOut || lock.busy || !form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final wasSetup = lock.needsSetup;
    if (wasSetup) {
      await lock.createPin(pin.text);
    } else {
      await lock.unlock(pin.text);
    }
    if (!mounted) return;
    pin.clear();
    confirm.clear();
    setState(() {});
  }

  Future<void> signOut() async {
    final c = widget.controller, lock = widget.lock, id = c.accountId;
    if (id == null || signingOut || lock.busy) return;
    if (!confirmSignOut) {
      setState(() => confirmSignOut = true);
      return;
    }
    setState(() => signingOut = true);
    try {
      await c.signOut();
      await lock.forget(id);
    } catch (_) {
      if (mounted) setState(() => signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: initialized,
    builder: (context, snapshot) {
      final lock = widget.lock;
      if (snapshot.connectionState != ConnectionState.done || lock.loading) {
        return const Material(
          child: Center(child: CircularProgressIndicator()),
        );
      }
      final setup = lock.needsSetup;
      return Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const BachatMark(),
                      const SizedBox(height: 48),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Icon(Icons.lock_outline, size: 32),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        lock.unavailable
                            ? 'Device lock unavailable'
                            : setup
                            ? 'Create your PIN'
                            : 'Welcome back',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        setup
                            ? 'Choose 6 digits to protect Bachat on this device.'
                            : 'Enter your PIN to open Bachat.',
                      ),
                      const SizedBox(height: 32),
                      if (!lock.unavailable) ...[
                        TextFormField(
                          key: ValueKey('pin-$setup'),
                          controller: pin,
                          enabled:
                              !lock.busy &&
                              lock.waitSeconds == 0 &&
                              !signingOut,
                          obscureText: true,
                          autocorrect: false,
                          enableSuggestions: false,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          decoration: const InputDecoration(
                            labelText: '6-digit PIN',
                            counterText: '',
                          ),
                          validator: (value) =>
                              RegExp(r'^\d{6}$').hasMatch(value ?? '')
                              ? null
                              : 'Enter 6 digits.',
                          textInputAction: setup
                              ? TextInputAction.next
                              : TextInputAction.done,
                          onFieldSubmitted: (_) {
                            if (!setup) submit();
                          },
                        ),
                        if (setup) ...[
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: confirm,
                            enabled: !lock.busy && !signingOut,
                            obscureText: true,
                            autocorrect: false,
                            enableSuggestions: false,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Confirm PIN',
                            ),
                            validator: (value) =>
                                value == pin.text ? null : 'PINs do not match.',
                            onFieldSubmitted: (_) => submit(),
                          ),
                        ],
                      ],
                      if (lock.error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Semantics(
                            liveRegion: true,
                            child: Text(
                              lock.error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ),
                      if (lock.waitSeconds > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text('Try again in ${lock.waitSeconds}s'),
                        ),
                      const SizedBox(height: 28),
                      FilledButton(
                        onPressed:
                            lock.busy || signingOut || lock.waitSeconds > 0
                            ? null
                            : lock.unavailable
                            ? () => lock.bind(widget.controller.accountId!)
                            : submit,
                        child: Text(
                          lock.busy
                              ? 'Please wait...'
                              : lock.unavailable
                              ? 'Try again'
                              : setup
                              ? 'Save PIN'
                              : 'Unlock',
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (confirmSignOut) ...[
                        Text(
                          widget.controller.pendingCount > 0
                              ? 'Unsynced changes will be discarded. Sign in with your account password to reset this PIN.'
                              : 'Sign in with your account password to reset this device PIN.',
                        ),
                        TextButton(
                          onPressed: signingOut
                              ? null
                              : () => setState(() => confirmSignOut = false),
                          child: const Text('Keep locked'),
                        ),
                      ],
                      TextButton(
                        onPressed: lock.busy || signingOut ? null : signOut,
                        child: Text(
                          confirmSignOut
                              ? 'Sign out'
                              : 'Forgot PIN? Sign in again',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
