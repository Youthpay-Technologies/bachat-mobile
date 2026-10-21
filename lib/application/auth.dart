part of 'controller.dart';

String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.length > 254 ||
      !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
    return 'Enter a valid email address.';
  }
  return null;
}

String? validatePassword(String? value) {
  if ((value ?? '').length < 10) return 'Use at least 10 characters.';
  if (value!.length > 128) return 'Use no more than 128 characters.';
  return null;
}

String authMessage(AuthException error) => switch (error.code) {
  'invalid_credentials' =>
    'Email or password is incorrect. Try again or reset your password.',
  'email_not_confirmed' =>
    'Verify your email before signing in. You can resend the confirmation below.',
  'over_email_send_rate_limit' || 'over_request_rate_limit' =>
    'Too many requests. Wait a few minutes and try again.',
  'email_address_not_authorized' =>
    'Email delivery is not configured for this address yet. Please contact Bachat support.',
  'weak_password' => 'Choose a stronger password with at least 10 characters.',
  'user_already_exists' =>
    'Check your email, or sign in if you already have an account.',
  'signup_disabled' =>
    'New accounts are temporarily unavailable. Try again later.',
  'otp_expired' => 'This email link has expired. Request a new one.',
  'session_not_found' ||
  'refresh_token_not_found' ||
  'refresh_token_already_used' =>
    'Your session has expired. Please sign in again.',
  _ =>
    'We could not complete this request. Check your connection and try again.',
};

extension TeenAuthentication on AppController {
  String get authRedirect => kIsWeb
      ? Uri.base.replace(path: '/', query: '', fragment: '').toString()
      : 'com.getyouthpay.bachat://auth/callback';

  void clearAuthFeedback() {
    error = null;
    authNotice = null;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) => run(() async {
    if (validateEmail(email) != null || password.isEmpty) {
      throw const FormatException('Enter your email and password.');
    }
    if (client == null)
      throw const FormatException(
        'Authentication is unavailable. Restart the app and try again.',
      );
    await client!.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    pendingEmail = null;
    await repository.savePendingEmail(null);
    await _hydrate();
    await refresh();
  });

  Future<bool> signUp(String email, String password) => run(() async {
    if (validateEmail(email) != null)
      throw const FormatException('Enter a valid email address.');
    final invalid = validatePassword(password);
    if (invalid != null) throw FormatException(invalid);
    if (client == null)
      throw const FormatException(
        'Authentication is unavailable. Restart the app and try again.',
      );
    final result = await client!.auth.signUp(
      email: email.trim(),
      password: password,
      emailRedirectTo: authRedirect,
    );
    pendingEmail = email.trim();
    await repository.savePendingEmail(pendingEmail);
    authNotice =
        'Open the confirmation link in your email, then sign in. If you already have an account, sign in instead.';
    if (result.session != null) {
      pendingEmail = null;
      await repository.savePendingEmail(null);
      await _hydrate();
      await refresh();
    }
  });

  Future<bool> resendConfirmation(String email) => run(() async {
    if (validateEmail(email) != null)
      throw const FormatException('Enter a valid email address.');
    await client!.auth.resend(
      type: OtpType.signup,
      email: email.trim(),
      emailRedirectTo: authRedirect,
    );
    authNotice =
        'If this address needs verification, a new confirmation link is on its way.';
  });

  Future<bool> requestPasswordReset(String email) => run(() async {
    if (validateEmail(email) != null)
      throw const FormatException('Enter a valid email address.');
    await client!.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: authRedirect,
    );
    authNotice =
        'If an account exists for this email, a password reset link is on its way.';
  });

  Future<bool> finishPasswordRecovery(String password) => run(() async {
    final invalid = validatePassword(password);
    if (invalid != null) throw FormatException(invalid);
    if (client?.auth.currentSession == null) {
      throw const FormatException(
        'This reset link has expired. Request a new one.',
      );
    }
    await client!.auth.updateUser(UserAttributes(password: password));
    recoveringPassword = false;
    await repository.saveRecovery(false);
    authNotice = 'Password updated.';
    await _hydrate();
    await refresh();
  });

  Future<bool> updateName(String name) => run(() async {
    final clean = name.trim();
    if (clean.isEmpty || clean.length > 60)
      throw const FormatException('Enter a name between 1 and 60 characters.');
    final id = accountId;
    if (id == null || preview)
      throw const FormatException('Sign in again to update your profile.');
    final updated = await client!
        .from('profiles')
        .update({'name': clean})
        .eq('id', id)
        .select()
        .single();
    if (accountId != id) return;
    profile = Profile.fromJson(updated);
    await repository.save(id, snapshot());
  });
}
