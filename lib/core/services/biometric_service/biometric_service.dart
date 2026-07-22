import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:zuru/core/services/storage_service/storage.service.dart';
import 'package:zuru/core/utils/error_wrapper.dart';

typedef Credentials = ({String email, String password});

/// Biometric login: device auth ([local_auth]) + securely-cached sign-in
/// credentials ([flutter_secure_storage]). The enabled flag lives in local
/// (device-only) storage; the credentials live in the Keychain / Keystore.
class BiometricService {
  BiometricService._();

  static const _library = 'BiometricService';
  static final LocalAuthentication _auth = LocalAuthentication();
  static const FlutterSecureStorage _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _emailKey = 'biometric_email';
  static const _passwordKey = 'biometric_password';

  // ── Capability ──────────────────────────────────────────────────────────

  static Future<bool> isSupported() async {
    final result = await ErrorWrapper.async<bool>(
      () async {
        final supported = await _auth.isDeviceSupported();
        final canCheck = await _auth.canCheckBiometrics;
        return supported && canCheck;
      },
      onError: (_) => false,
      library: _library,
      description: 'while checking biometric support',
    );
    return result ?? false;
  }

  static Future<bool> authenticate({
    String reason = 'Verify your identity to continue',
  }) async {
    final result = await ErrorWrapper.async<bool>(
      () => _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      ),
      onError: (_) => false,
      library: _library,
      description: 'while authenticating with biometrics',
    );
    return result ?? false;
  }

  // ── Enabled flag (local, device-only) ─────────────────────────────────────

  static Future<bool> isEnabled() async =>
      await StorageService.get<bool>(StorageKeys.biometricsKey) ?? false;

  /// Persists the flag; clearing it also wipes the cached credentials.
  static Future<void> setEnabled(bool value) async {
    await StorageService.save<bool>(StorageKeys.biometricsKey, value: value);
    if (!value) await clearCredentials();
  }

  // ── Secure credentials ────────────────────────────────────────────────────

  static Future<void> saveCredentials({
    required String email,
    required String password,
  }) async {
    await ErrorWrapper.async<void>(
      () async {
        await _secure.write(key: _emailKey, value: email);
        await _secure.write(key: _passwordKey, value: password);
      },
      library: _library,
      description: 'while saving credentials',
    );
  }

  static Future<Credentials?> readCredentials() async {
    return ErrorWrapper.async<Credentials?>(
      () async {
        final email = await _secure.read(key: _emailKey);
        final password = await _secure.read(key: _passwordKey);
        if (email == null || password == null) return null;
        return (email: email, password: password);
      },
      onError: (_) => null,
      library: _library,
      description: 'while reading credentials',
    );
  }

  static Future<bool> hasCredentials() async => await readCredentials() != null;

  static Future<void> clearCredentials() async {
    await ErrorWrapper.async<void>(
      () async {
        await _secure.delete(key: _emailKey);
        await _secure.delete(key: _passwordKey);
      },
      library: _library,
      description: 'while clearing credentials',
    );
  }
}
