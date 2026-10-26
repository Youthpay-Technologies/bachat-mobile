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

String authMessage(AuthException error) {
  final code = error.code?.toLowerCase();
  final msg = error.message.toLowerCase();
  if (code == 'user_already_exists' ||
      code == 'email_exists' ||
      code == 'user_already_registered' ||
      msg.contains('already registered') ||
      msg.contains('already exists') ||
      msg.contains('user with this email') ||
      msg.contains('email already in use')) {
    return 'This email is already registered. Please sign in or reset your password.';
  }
  if (code == 'invalid_credentials' ||
      msg.contains('invalid login credentials') ||
      msg.contains('invalid credentials')) {
    return 'Email or password is incorrect. Try again or reset your password.';
  }
  if (code == 'email_not_confirmed' || msg.contains('email not confirmed')) {
    return 'Verify your email before signing in. You can resend the confirmation below.';
  }
  if (code == 'over_email_send_rate_limit' ||
      code == 'over_request_rate_limit' ||
      msg.contains('rate limit')) {
    return 'Too many requests. Wait a few minutes and try again.';
  }
  if (code == 'email_address_not_authorized' ||
      msg.contains('not authorized')) {
    return 'Email delivery is not configured for this address yet. Please contact Bachat support.';
  }
  if (code == 'weak_password' || msg.contains('password should be at least')) {
    return 'Choose a stronger password with at least 10 characters.';
  }
  if (code == 'signup_disabled' || msg.contains('signups not allowed')) {
    return 'New accounts are temporarily unavailable. Try again later.';
  }
  if (code == 'otp_expired' || msg.contains('expired')) {
    return 'This email link has expired. Request a new one.';
  }
  if (code == 'session_not_found' ||
      code == 'refresh_token_not_found' ||
      code == 'refresh_token_already_used') {
    return 'Your session has expired. Please sign in again.';
  }
  if (error.message.isNotEmpty &&
      !error.message.startsWith('{') &&
      !error.message.toLowerCase().contains('unexpected') &&
      !error.message.toLowerCase().contains('null')) {
    return error.message;
  }
  return 'We could not complete this request. Check your connection and try again.';
}

extension TeenAuthentication on AppController {
  String get authRedirect => kIsWeb
      ? Uri.base.replace(path: '/', query: '', fragment: '').toString()
      : 'com.getyouthpay.bachat://auth/callback';

  Future<void> handleAuthLink(Uri uri) async {
    if (_handledLink == uri.toString()) return;
    if (kIsWeb
        ? uri.origin != Uri.base.origin
        : (uri.scheme != 'com.getyouthpay.bachat' ||
              uri.host != 'auth' ||
              uri.path != '/callback')) {
      return;
    }
    var recognized = false;
    var opened = false;
    try {
      // Email links are external input, including their percent-encoded text.
      final parameters = {
        ...uri.queryParameters,
        ...Uri.splitQueryString(uri.fragment),
      };
      if (!parameters.containsKey('code') &&
          !parameters.containsKey('access_token') &&
          !parameters.containsKey('error')) {
        return;
      }
      recognized = true;
      _handledLink = uri.toString();
      final response = await client!.auth.getSessionFromUrl(uri);
      if (response.redirectType == AuthChangeEvent.passwordRecovery.name ||
          response.redirectType == 'recovery') {
        recoveringPassword = true;
        await repository.saveRecovery(true);
      }
      pendingEmail = null;
      await repository.savePendingEmail(null);
      error = null;
      opened = true;
    } on AuthException catch (e) {
      error = authMessage(e);
    } catch (_) {
      recognized = true;
      error =
          'Unable to open this email link. Try opening it on the device where you requested it, or request a new link.';
    } finally {
      // Deduplicate successful/in-flight exchanges, but permit a failed link to
      // be opened again after connectivity recovers. PKCE is still server-checked.
      if (!opened && _handledLink == uri.toString()) _handledLink = null;
      if (kIsWeb && recognized) {
        final clean = uri.replace(query: '', fragment: '');
        await SystemNavigator.routeInformationUpdated(
          uri: clean,
          replace: true,
        );
      }
      notifyListeners();
    }
  }

  void clearAuthFeedback() {
    error = null;
    authNotice = null;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) => run(() async {
    if (validateEmail(email) != null || password.isEmpty) {
      throw const FormatException('Enter your email and password.');
    }
    if (client == null) {
      throw const FormatException(
        'Authentication is unavailable. Restart the app and try again.',
      );
    }
    await client!.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    recoveringPassword = false;
    await repository.saveRecovery(false);
    pendingEmail = null;
    await repository.savePendingEmail(null);
    await _hydrate();
    await refresh();
  });

  Future<bool> signUp(String email, String password) => run(() async {
    if (validateEmail(email) != null) {
      throw const FormatException('Enter a valid email address.');
    }
    final invalid = validatePassword(password);
    if (invalid != null) throw FormatException(invalid);
    if (client == null) {
      throw const FormatException(
        'Authentication is unavailable. Restart the app and try again.',
      );
    }
    final result = await client!.auth.signUp(
      email: email.trim(),
      password: password,
      emailRedirectTo: authRedirect,
    );
    if (result.user != null &&
        result.user!.identities != null &&
        result.user!.identities!.isEmpty) {
      throw const AuthException(
        'This email is already registered. Please sign in or reset your password.',
        statusCode: '400',
        code: 'user_already_exists',
      );
    }
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
    if (validateEmail(email) != null) {
      throw const FormatException('Enter a valid email address.');
    }
    await client!.auth.resend(
      type: OtpType.signup,
      email: email.trim(),
      emailRedirectTo: authRedirect,
    );
    authNotice =
        'If this address needs verification, a new confirmation link is on its way.';
  });

  Future<bool> requestPasswordReset(String email) => run(() async {
    if (validateEmail(email) != null) {
      throw const FormatException('Enter a valid email address.');
    }
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
    if (clean.isEmpty || clean.length > 60) {
      throw const FormatException('Enter a name between 1 and 60 characters.');
    }
    final id = accountId;
    if (id == null || preview) {
      throw const FormatException('Sign in again to update your profile.');
    }
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
