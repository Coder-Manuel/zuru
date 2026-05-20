import 'package:zuru/core/entities/user.entity.dart';
import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/modules/auth/data/models/auth.inputs.dart';

abstract class AuthRepository {
  // ─── Login ─────────────────────────────────────────────────────────────────
  Future<RepoResponse<User>> login(LoginInput input);
  Future<RepoResponse<User>> loginWithOAuth(OAuthInput input);

  // ─── Signup ────────────────────────────────────────────────────────────────
  /// Creates the account and triggers a Supabase email OTP.
  Future<RepoResponse<User>> signup(SignupInput input);

  // ─── Email verification ────────────────────────────────────────────────────
  Future<RepoResponse<User>> verifyEmailOtp(VerifyOtpInput input);

  // ─── Phone setup & verification ────────────────────────────────────────────
  /// Calls Supabase updateUser(phone) which triggers an SMS OTP.
  Future<RepoResponse<bool>> setupPhone(PhoneSetupInput input);
  Future<RepoResponse<User>> verifyPhoneOtp(VerifyOtpInput input);

  // ─── Names setup ───────────────────────────────────────────────────────────
  Future<RepoResponse<bool>> setupNames(NamesInput input);

  // ─── Logout ────────────────────────────────────────────────────────────────
  Future<RepoResponse<bool>> logout();

  // ─── Password reset ────────────────────────────────────────────────────────
  /// Sends a recovery OTP to [input.email] via Supabase.
  Future<RepoResponse<bool>> sendPasswordResetOtp(ResetPasswordInput input);

  /// Scout-side alias: sends a password reset email link.
  Future<RepoResponse<bool>> sendPasswordResetEmail(ForgotPasswordInput input);

  /// Verifies the recovery OTP — establishes a session required for [updatePassword].
  Future<RepoResponse<bool>> verifyPasswordResetOtp(VerifyOtpInput input);

  /// Updates the authenticated user's password. Call after [verifyPasswordResetOtp].
  Future<RepoResponse<bool>> updatePassword(UpdatePasswordInput input);
}
