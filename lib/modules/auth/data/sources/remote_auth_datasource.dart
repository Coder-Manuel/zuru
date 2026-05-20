import 'package:supabase_flutter/supabase_flutter.dart';

abstract class RemoteAuthDatasource {
  Future<AuthResponse> loginWithPassword({required Map<String, dynamic> data});
  Future<AuthResponse> verifyOTP({
    required Map<String, dynamic> data,
    OtpType otpType = OtpType.email,
  });
  Future<AuthResponse> signupWithOAuth({
    required Map<String, dynamic> data,
    OAuthProvider provider = OAuthProvider.google,
  });
  Future<AuthResponse> signUp({required Map<String, dynamic> data});
  Future<UserResponse> updatePhone(String phone);
  Future<Map<String, dynamic>?> updateNames(Map<String, dynamic> data);
  Future<void> logout();

  // ── Password reset ─────────────────────────────────────────────────────────
  Future<void> sendPasswordResetOtp(String email);
  Future<AuthResponse> verifyPasswordResetOtp({
    required String email,
    required String otp,
  });
  Future<UserResponse> updatePassword(String newPassword);
}

class RemoteAuthDatasourceImpl extends RemoteAuthDatasource {
  final SupabaseClient client;

  RemoteAuthDatasourceImpl({required this.client});

  @override
  Future<AuthResponse> loginWithPassword({required Map<String, dynamic> data}) {
    return client.auth.signInWithPassword(
      email: data['email'],
      phone: data['phone'],
      password: data['password'],
    );
  }

  @override
  Future<AuthResponse> signupWithOAuth({
    required Map<String, dynamic> data,
    OAuthProvider provider = OAuthProvider.google,
  }) {
    return client.auth.signInWithIdToken(
      provider: provider,
      idToken: data['idToken'],
      accessToken: data['accessToken'],
    );
  }

  @override
  Future<AuthResponse> signUp({required Map<String, dynamic> data}) {
    return client.auth.signUp(
      password: data['password'],
      email: data['email'],
      data: data['meta'],
    );
  }

  @override
  Future<AuthResponse> verifyOTP({
    required Map<String, dynamic> data,
    OtpType otpType = OtpType.email,
  }) {
    return client.auth.verifyOTP(
      type: otpType,
      email: data['email'],
      phone: data['phone'],
      token: data['otp'],
    );
  }

  @override
  Future<UserResponse> updatePhone(String phone) {
    return client.auth.updateUser(UserAttributes(phone: phone));
  }

  @override
  Future<Map<String, dynamic>?> updateNames(Map<String, dynamic> data) {
    return client
        .from('users')
        .update(data)
        .eq('id', client.auth.currentUser?.id ?? '')
        .select()
        .single();
  }

  @override
  Future<void> logout() {
    return client.auth.signOut();
  }

  // ── Password reset ─────────────────────────────────────────────────────────

  @override
  Future<void> sendPasswordResetOtp(String email) {
    return client.auth.resetPasswordForEmail(email);
  }

  @override
  Future<AuthResponse> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) {
    return client.auth.verifyOTP(
      email: email,
      token: otp,
      type: OtpType.recovery,
    );
  }

  @override
  Future<UserResponse> updatePassword(String newPassword) {
    return client.auth.updateUser(UserAttributes(password: newPassword));
  }
}
