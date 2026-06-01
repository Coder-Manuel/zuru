import 'package:zuru/core/models/enums.dart';

class LoginInput {
  final String? email;
  final String? phone;
  final String? password;

  LoginInput({this.email, this.phone, this.password})
    : assert(
        (email != null || phone != null) && password != null,
        'Provide (email or phone) and password',
      );

  Map<String, dynamic> toMap() => {
    'email': email,
    'phone': phone,
    'password': password,
  };
}

class OAuthInput {
  final String idToken;
  final bool isLogin;
  final String? accessToken;

  OAuthInput({required this.idToken, this.isLogin = true, this.accessToken});

  Map<String, dynamic> toMap() => {
    'idToken': idToken,
    'accessToken': accessToken,
  };
}

class SignupInput {
  final String email;
  final String password;
  final UserRole role;

  SignupInput({
    required this.email,
    required this.password,
    required this.role,
  });

  Map<String, dynamic> toMap() => {
    'email': email,
    'password': password,
    'meta': {'role': role.name},
  };
}

class VerifyOtpInput {
  final String otp;
  final String? email;
  final String? phone;

  VerifyOtpInput.email({required this.otp, required String this.email})
    : phone = null;

  VerifyOtpInput.phone({required this.otp, required String this.phone})
    : email = null;

  Map<String, dynamic> toMap() => {'otp': otp, 'email': email, 'phone': phone};
}

class PhoneSetupInput {
  final String phone;

  PhoneSetupInput({required this.phone});
}

class NamesInput {
  final String firstName;
  final String lastName;

  NamesInput({required this.firstName, required this.lastName});

  Map<String, dynamic> toMap() => {
    'first_name': firstName,
    'last_name': lastName,
    'status': 'active',
  };
}

class ResetPasswordInput {
  final String email;
  ResetPasswordInput({required this.email});
}

/// Scout-side password reset input (email link flow).
typedef ForgotPasswordInput = ResetPasswordInput;

class UpdatePasswordInput {
  final String newPassword;
  UpdatePasswordInput({required this.newPassword});
}

/// Scout-side new-password input alias.
typedef NewPasswordInput = UpdatePasswordInput;

class ResetOtpInput {
  final String email;
  final String otp;
  ResetOtpInput({required this.email, required this.otp});
}
