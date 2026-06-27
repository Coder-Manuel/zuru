// Unit tests for [AuthRepositoryImpl] in isolation.
//
// The repository is the layer that turns raw Supabase responses into domain
// `RepoResponse`s and maps every thrown error into a friendly [FailureResponse].
// We mock the [RemoteAuthDatasource] (and the Supabase response objects it
// returns) so these tests exercise *only* the repository's mapping / guard /
// error-handling logic — no network, no Supabase client.
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show OtpType;
import 'package:zuru/core/models/enums.dart';
import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/modules/auth/data/models/auth.inputs.dart';
import 'package:zuru/modules/auth/data/models/scout_profile.input.dart';
import 'package:zuru/modules/auth/data/repositories_impl/auth_repository_impl.dart';

import '../../helpers/test_mocks.mocks.dart';

/// Builds a syntactically valid 3-segment JWT whose payload decodes to [claims]
/// — enough for [CommonFunctions.decodeJwtPayload] to succeed.
String _fakeJwt(Map<String, dynamic> claims) {
  String seg(Map<String, dynamic> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m)));
  return '${seg({'alg': 'HS256', 'typ': 'JWT'})}.${seg(claims)}.sig';
}

void main() {
  late MockRemoteAuthDatasource ds;
  late AuthRepositoryImpl repo;

  // Silences MonitorService.report (which short-circuits in test mode), so the
  // error-path tests don't try to reach Firebase.
  setUpAll(() => Get.testMode = true);

  setUp(() {
    ds = MockRemoteAuthDatasource();
    repo = AuthRepositoryImpl(remoteDatasource: ds);
  });

  /// Helper: a mock [AuthResponse] with the given session/user wiring.
  MockAuthResponse authResponse({
    bool withSession = true,
    String accessToken = '',
    Map<String, dynamic>? userJson,
  }) {
    final response = MockAuthResponse();
    if (withSession) {
      final session = MockSession();
      when(session.accessToken).thenReturn(accessToken);
      when(response.session).thenReturn(session);
    } else {
      when(response.session).thenReturn(null);
    }
    if (userJson != null) {
      final user = MockSupaUser();
      when(user.toJson()).thenReturn(userJson);
      when(response.user).thenReturn(user);
    } else {
      when(response.user).thenReturn(null);
    }
    return response;
  }

  String? messageOf(RepoResponse result) =>
      result.fold((l) => l.message, (_) => null);

  // ── login ──────────────────────────────────────────────────────────────────

  group('login', () {
    final input = LoginInput(email: 'a@b.com', password: 'secret');

    test('maps a valid session + user into a User', () async {
      when(ds.loginWithPassword(data: anyNamed('data'))).thenAnswer(
        (_) async => authResponse(
          accessToken: _fakeJwt({'sub': 'u1'}),
          userJson: {'id': 'u1', 'email': 'a@b.com'},
        ),
      );

      final result = await repo.login(input);

      expect(result.isRight(), isTrue);
      expect(result.getOrElse(() => throw 'x').email, 'a@b.com');
      verify(ds.loginWithPassword(data: input.toMap())).called(1);
    });

    test('returns "Invalid credentials" when there is no session', () async {
      when(
        ds.loginWithPassword(data: anyNamed('data')),
      ).thenAnswer((_) async => authResponse(withSession: false));

      final result = await repo.login(input);

      expect(messageOf(result), 'Invalid credentials, kindly retry');
    });

    test('logs out and fails when the JWT claims cannot be decoded', () async {
      when(
        ds.loginWithPassword(data: anyNamed('data')),
      ).thenAnswer((_) async => authResponse(accessToken: 'not-a-jwt'));
      when(ds.logout()).thenAnswer((_) async {});

      final result = await repo.login(input);

      expect(messageOf(result), 'Invalid claims, kindly retry');
      verify(ds.logout()).called(1);
    });

    test(
      'maps a thrown invalid_credentials error to a friendly message',
      () async {
        when(
          ds.loginWithPassword(data: anyNamed('data')),
        ).thenThrow(Exception('invalid_credentials'));

        final result = await repo.login(input);

        expect(messageOf(result), 'Invalid credentials, kindly retry');
      },
    );

    test('maps any other thrown error to the generic message', () async {
      when(
        ds.loginWithPassword(data: anyNamed('data')),
      ).thenThrow(Exception('socket down'));

      final result = await repo.login(input);

      expect(messageOf(result), 'An error occurred, kindly retry');
    });
  });

  // ── loginWithOAuth ───────────────────────────────────────────────────────────

  group('loginWithOAuth', () {
    final input = OAuthInput(idToken: 'id-token');

    test('succeeds when the JWT role claim is client', () async {
      when(ds.signupWithOAuth(data: anyNamed('data'))).thenAnswer(
        (_) async => authResponse(
          accessToken: _fakeJwt({'user_role': 'client'}),
          userJson: {'id': 'u1', 'email': 'c@b.com'},
        ),
      );

      final result = await repo.loginWithOAuth(input);

      expect(result.isRight(), isTrue);
      verify(ds.signupWithOAuth(data: input.toMap())).called(1);
    });

    test('rejects a non-client role and logs back out', () async {
      when(ds.signupWithOAuth(data: anyNamed('data'))).thenAnswer(
        (_) async =>
            authResponse(accessToken: _fakeJwt({'user_role': 'scout'})),
      );
      when(ds.logout()).thenAnswer((_) async {});

      final result = await repo.loginWithOAuth(input);

      expect(
        messageOf(result),
        'This app is for Clients only. Use the Scout app.',
      );
      verify(ds.logout()).called(1);
    });

    test('fails when there is no session', () async {
      when(
        ds.signupWithOAuth(data: anyNamed('data')),
      ).thenAnswer((_) async => authResponse(withSession: false));

      final result = await repo.loginWithOAuth(input);

      expect(messageOf(result), 'OAuth login failed, kindly retry');
    });
  });

  // ── signup ───────────────────────────────────────────────────────────────────

  group('signup', () {
    final input = SignupInput(
      email: 'new@b.com',
      password: 'secret',
      role: UserRole.client,
    );

    test(
      'maps the returned user (no session needed pre-verification)',
      () async {
        when(ds.signUp(data: anyNamed('data'))).thenAnswer(
          (_) async => authResponse(
            withSession: false,
            userJson: {'id': 'u1', 'email': 'new@b.com'},
          ),
        );

        final result = await repo.signup(input);

        expect(result.isRight(), isTrue);
        expect(result.getOrElse(() => throw 'x').email, 'new@b.com');
      },
    );

    test('fails when no user is returned', () async {
      when(
        ds.signUp(data: anyNamed('data')),
      ).thenAnswer((_) async => authResponse(withSession: false));

      final result = await repo.signup(input);

      expect(messageOf(result), 'Unable to create account, kindly retry');
    });
  });

  // ── OTP verification ─────────────────────────────────────────────────────────

  group('verifyEmailOtp', () {
    final input = VerifyOtpInput.email(otp: '123456', email: 'a@b.com');

    test('returns the user on a valid session', () async {
      when(
        ds.verifyOTP(data: anyNamed('data'), otpType: anyNamed('otpType')),
      ).thenAnswer(
        (_) async => authResponse(userJson: {'id': 'u1', 'email': 'a@b.com'}),
      );

      final result = await repo.verifyEmailOtp(input);

      expect(result.isRight(), isTrue);
      verify(
        ds.verifyOTP(data: input.toMap(), otpType: OtpType.email),
      ).called(1);
    });

    test('fails on a missing session (invalid/expired code)', () async {
      when(
        ds.verifyOTP(data: anyNamed('data'), otpType: anyNamed('otpType')),
      ).thenAnswer((_) async => authResponse(withSession: false));

      final result = await repo.verifyEmailOtp(input);

      expect(messageOf(result), 'Invalid or expired code, kindly retry');
    });
  });

  group('verifyPhoneOtp', () {
    final input = VerifyOtpInput.phone(otp: '654321', phone: '+254700000000');

    test('returns the user on a valid session', () async {
      when(
        ds.verifyOTP(data: anyNamed('data'), otpType: anyNamed('otpType')),
      ).thenAnswer((_) async => authResponse(userJson: {'id': 'u1'}));

      expect((await repo.verifyPhoneOtp(input)).isRight(), isTrue);
      verify(ds.verifyOTP(data: input.toMap(), otpType: OtpType.sms)).called(1);
    });

    test(
      'maps an "expired or is invalid" throw to the friendly message',
      () async {
        when(
          ds.verifyOTP(data: anyNamed('data'), otpType: anyNamed('otpType')),
        ).thenThrow(Exception('Token has expired or is invalid'));

        expect(
          messageOf(await repo.verifyPhoneOtp(input)),
          'Invalid or expired code, kindly retry',
        );
      },
    );
  });

  // ── boolean-result methods ───────────────────────────────────────────────────

  group('setupPhone', () {
    final input = PhoneSetupInput(phone: '+254700000000');

    test('returns true on success', () async {
      when(
        ds.updatePhone(input.phone),
      ).thenAnswer((_) async => MockUserResponse());

      expect(await repo.setupPhone(input), Right<ApiFail, bool>(true));
      verify(ds.updatePhone(input.phone)).called(1);
    });

    test('fails when the datasource throws', () async {
      when(ds.updatePhone(any)).thenThrow(Exception('boom'));

      expect(
        messageOf(await repo.setupPhone(input)),
        'An error occurred, kindly retry',
      );
    });
  });

  group('setupNames', () {
    final input = NamesInput(firstName: 'Ada', lastName: 'Lovelace');

    test('returns true when a row is updated', () async {
      when(ds.updateNames(any)).thenAnswer((_) async => {'id': 'p1'});

      expect(await repo.setupNames(input), Right<ApiFail, bool>(true));
      verify(ds.updateNames(input.toMap())).called(1);
    });

    test('fails when no row comes back', () async {
      when(ds.updateNames(any)).thenAnswer((_) async => null);

      expect(
        messageOf(await repo.setupNames(input)),
        'Unable to save your name, kindly retry',
      );
    });
  });

  group('updateScoutProfile', () {
    const input = ScoutProfileInput(bio: 'Recon', tags: ['urban']);

    test('returns true when a row is updated', () async {
      when(ds.updateScoutProfile(any)).thenAnswer((_) async => {'id': 'p1'});

      expect(await repo.updateScoutProfile(input), Right<ApiFail, bool>(true));
    });

    test('fails when no row comes back', () async {
      when(ds.updateScoutProfile(any)).thenAnswer((_) async => null);

      expect(
        messageOf(await repo.updateScoutProfile(input)),
        'Unable to save your profile, kindly retry',
      );
    });
  });

  group('logout', () {
    test('returns true on success', () async {
      when(ds.logout()).thenAnswer((_) async {});

      expect(await repo.logout(), Right<ApiFail, bool>(true));
      verify(ds.logout()).called(1);
    });

    test('fails when the datasource throws', () async {
      when(ds.logout()).thenThrow(Exception('boom'));

      expect(messageOf(await repo.logout()), 'An error occurred, kindly retry');
    });
  });

  // ── password reset ───────────────────────────────────────────────────────────

  group('sendPasswordResetOtp', () {
    final input = ResetPasswordInput(email: 'a@b.com');

    test('returns true on success', () async {
      when(ds.sendPasswordResetOtp(input.email)).thenAnswer((_) async {});

      expect(
        await repo.sendPasswordResetOtp(input),
        Right<ApiFail, bool>(true),
      );
      verify(ds.sendPasswordResetOtp('a@b.com')).called(1);
    });

    test('fails when the datasource throws', () async {
      when(ds.sendPasswordResetOtp(any)).thenThrow(Exception('boom'));

      expect(
        messageOf(await repo.sendPasswordResetOtp(input)),
        'Could not send reset code, kindly retry',
      );
    });

    test('sendPasswordResetEmail delegates to the OTP method', () async {
      when(ds.sendPasswordResetOtp(input.email)).thenAnswer((_) async {});

      expect(
        await repo.sendPasswordResetEmail(input),
        Right<ApiFail, bool>(true),
      );
      verify(ds.sendPasswordResetOtp('a@b.com')).called(1);
    });
  });

  group('verifyPasswordResetOtp', () {
    final input = VerifyOtpInput.email(otp: '000111', email: 'a@b.com');

    test('returns true on a valid session', () async {
      when(
        ds.verifyPasswordResetOtp(
          email: anyNamed('email'),
          otp: anyNamed('otp'),
        ),
      ).thenAnswer((_) async => authResponse());

      expect(
        await repo.verifyPasswordResetOtp(input),
        Right<ApiFail, bool>(true),
      );
      verify(
        ds.verifyPasswordResetOtp(email: 'a@b.com', otp: '000111'),
      ).called(1);
    });

    test('fails on a missing session', () async {
      when(
        ds.verifyPasswordResetOtp(
          email: anyNamed('email'),
          otp: anyNamed('otp'),
        ),
      ).thenAnswer((_) async => authResponse(withSession: false));

      expect(
        messageOf(await repo.verifyPasswordResetOtp(input)),
        'Invalid or expired code, kindly retry',
      );
    });

    test('maps an "expired" throw to the friendly message', () async {
      when(
        ds.verifyPasswordResetOtp(
          email: anyNamed('email'),
          otp: anyNamed('otp'),
        ),
      ).thenThrow(Exception('token expired'));

      expect(
        messageOf(await repo.verifyPasswordResetOtp(input)),
        'Invalid or expired code, kindly retry',
      );
    });
  });

  group('updatePassword', () {
    final input = UpdatePasswordInput(newPassword: 'new-secret');

    test('returns true on success', () async {
      when(
        ds.updatePassword(input.newPassword),
      ).thenAnswer((_) async => MockUserResponse());

      expect(await repo.updatePassword(input), Right<ApiFail, bool>(true));
      verify(ds.updatePassword('new-secret')).called(1);
    });

    test('fails when the datasource throws', () async {
      when(ds.updatePassword(any)).thenThrow(Exception('boom'));

      expect(
        messageOf(await repo.updatePassword(input)),
        'Could not update password, kindly retry',
      );
    });
  });
}
