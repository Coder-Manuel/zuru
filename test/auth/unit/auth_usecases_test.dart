// Unit tests for the **auth** module's domain use cases.
//
// Each use case is a thin delegator over [AuthRepository], so the contract we
// verify is: (1) it forwards the exact params to the right repository method,
// (2) it returns the repository's success value untouched, and (3) it
// propagates the repository's failure untouched. The repository is mocked with
// mockito so no Supabase / network I/O is involved.
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:zuru/core/entities/user.entity.dart';
import 'package:zuru/core/models/enums.dart';
import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/modules/auth/data/models/auth.inputs.dart';
import 'package:zuru/modules/auth/data/models/scout_profile.input.dart';
import 'package:zuru/modules/auth/domain/usecases/login.usecase.dart';
import 'package:zuru/modules/auth/domain/usecases/login_oauth.usecase.dart';
import 'package:zuru/modules/auth/domain/usecases/logout.usecase.dart';
import 'package:zuru/modules/auth/domain/usecases/register.usecase.dart';
import 'package:zuru/modules/auth/domain/usecases/send_reset_email.usecase.dart';
import 'package:zuru/modules/auth/domain/usecases/send_reset_otp.usecase.dart';
import 'package:zuru/modules/auth/domain/usecases/setup_names.usecase.dart';
import 'package:zuru/modules/auth/domain/usecases/setup_phone.usecase.dart';
import 'package:zuru/modules/auth/domain/usecases/update_password.usecase.dart';
import 'package:zuru/modules/auth/domain/usecases/update_scout_profile.usecase.dart';
import 'package:zuru/modules/auth/domain/usecases/verify_email_otp.usecase.dart';
import 'package:zuru/modules/auth/domain/usecases/verify_phone_otp.usecase.dart';
import 'package:zuru/modules/auth/domain/usecases/verify_reset_otp.usecase.dart';

import '../../helpers/test_mocks.mocks.dart';

void main() {
  late MockAuthRepository repo;
  late MockUser user;

  setUp(() {
    repo = MockAuthRepository();
    user = MockUser();
  });

  // A canonical failure used across the "sad path" tests.
  final failure = ApiFail('boom');

  group('LoginUseCase', () {
    late LoginUseCase useCase;
    final input = LoginInput(email: 'a@b.com', password: 'secret');

    setUp(() => useCase = LoginUseCase(repo: repo));

    test('forwards to repo.login and returns the user on success', () async {
      when(repo.login(input)).thenAnswer((_) async => Right(user));

      final result = await useCase(input);

      expect(result, Right<ApiFail, User>(user));
      verify(repo.login(input)).called(1);
      verifyNoMoreInteractions(repo);
    });

    test('propagates the repository failure', () async {
      when(repo.login(input)).thenAnswer((_) async => Left(failure));

      final result = await useCase(input);

      expect(result, Left<ApiFail, User>(failure));
      verify(repo.login(input)).called(1);
    });
  });

  group('LoginOAuthUseCase', () {
    late LoginOAuthUseCase useCase;
    final input = OAuthInput(idToken: 'id-token', accessToken: 'access-token');

    setUp(() => useCase = LoginOAuthUseCase(repo: repo));

    test('forwards to repo.loginWithOAuth on success', () async {
      when(repo.loginWithOAuth(input)).thenAnswer((_) async => Right(user));

      final result = await useCase(input);

      expect(result, Right<ApiFail, User>(user));
      verify(repo.loginWithOAuth(input)).called(1);
    });

    test('propagates the repository failure', () async {
      when(repo.loginWithOAuth(input)).thenAnswer((_) async => Left(failure));

      final result = await useCase(input);

      expect(result.isLeft(), isTrue);
      verify(repo.loginWithOAuth(input)).called(1);
    });
  });

  group('RegisterUsecase', () {
    late RegisterUsecase useCase;
    final input = SignupInput(
      email: 'new@user.com',
      password: 'secret',
      role: UserRole.client,
    );

    setUp(() => useCase = RegisterUsecase(repo: repo));

    test('forwards to repo.signup on success', () async {
      when(repo.signup(input)).thenAnswer((_) async => Right(user));

      final result = await useCase(input);

      expect(result, Right<ApiFail, User>(user));
      verify(repo.signup(input)).called(1);
    });

    test('propagates the repository failure', () async {
      when(repo.signup(input)).thenAnswer((_) async => Left(failure));

      expect((await useCase(input)).isLeft(), isTrue);
      verify(repo.signup(input)).called(1);
    });
  });

  group('VerifyEmailOtpUseCase', () {
    late VerifyEmailOtpUseCase useCase;
    final input = VerifyOtpInput.email(otp: '123456', email: 'a@b.com');

    setUp(() => useCase = VerifyEmailOtpUseCase(repo: repo));

    test('forwards to repo.verifyEmailOtp on success', () async {
      when(repo.verifyEmailOtp(input)).thenAnswer((_) async => Right(user));

      final result = await useCase(input);

      expect(result, Right<ApiFail, User>(user));
      verify(repo.verifyEmailOtp(input)).called(1);
    });

    test('propagates the repository failure', () async {
      when(repo.verifyEmailOtp(input)).thenAnswer((_) async => Left(failure));

      expect((await useCase(input)).isLeft(), isTrue);
      verify(repo.verifyEmailOtp(input)).called(1);
    });
  });

  group('SetupPhoneUseCase', () {
    late SetupPhoneUseCase useCase;
    final input = PhoneSetupInput(phone: '+254700000000');

    setUp(() => useCase = SetupPhoneUseCase(repo: repo));

    test('returns true on success', () async {
      when(repo.setupPhone(input)).thenAnswer((_) async => Right(true));

      final result = await useCase(input);

      expect(result, Right<ApiFail, bool>(true));
      verify(repo.setupPhone(input)).called(1);
    });

    test('propagates the repository failure', () async {
      when(repo.setupPhone(input)).thenAnswer((_) async => Left(failure));

      expect((await useCase(input)).isLeft(), isTrue);
      verify(repo.setupPhone(input)).called(1);
    });
  });

  group('VerifyPhoneOtpUseCase', () {
    late VerifyPhoneOtpUseCase useCase;
    final input = VerifyOtpInput.phone(otp: '654321', phone: '+254700000000');

    setUp(() => useCase = VerifyPhoneOtpUseCase(repo: repo));

    test('forwards to repo.verifyPhoneOtp on success', () async {
      when(repo.verifyPhoneOtp(input)).thenAnswer((_) async => Right(user));

      final result = await useCase(input);

      expect(result, Right<ApiFail, User>(user));
      verify(repo.verifyPhoneOtp(input)).called(1);
    });

    test('propagates the repository failure', () async {
      when(repo.verifyPhoneOtp(input)).thenAnswer((_) async => Left(failure));

      expect((await useCase(input)).isLeft(), isTrue);
      verify(repo.verifyPhoneOtp(input)).called(1);
    });
  });

  group('SetupNamesUseCase', () {
    late SetupNamesUseCase useCase;
    final input = NamesInput(firstName: 'Ada', lastName: 'Lovelace');

    setUp(() => useCase = SetupNamesUseCase(repo: repo));

    test('returns true on success', () async {
      when(repo.setupNames(input)).thenAnswer((_) async => Right(true));

      final result = await useCase(input);

      expect(result, Right<ApiFail, bool>(true));
      verify(repo.setupNames(input)).called(1);
    });

    test('propagates the repository failure', () async {
      when(repo.setupNames(input)).thenAnswer((_) async => Left(failure));

      expect((await useCase(input)).isLeft(), isTrue);
      verify(repo.setupNames(input)).called(1);
    });
  });

  group('UpdateScoutBioUseCase', () {
    late UpdateScoutBioUseCase useCase;
    const input = ScoutProfileInput(bio: 'Recon specialist', tags: ['urban']);

    setUp(() => useCase = UpdateScoutBioUseCase(repo: repo));

    test('returns true on success', () async {
      when(repo.updateScoutProfile(input)).thenAnswer((_) async => Right(true));

      final result = await useCase(input);

      expect(result, Right<ApiFail, bool>(true));
      verify(repo.updateScoutProfile(input)).called(1);
    });

    test('propagates the repository failure', () async {
      when(
        repo.updateScoutProfile(input),
      ).thenAnswer((_) async => Left(failure));

      expect((await useCase(input)).isLeft(), isTrue);
      verify(repo.updateScoutProfile(input)).called(1);
    });
  });

  group('LogoutUseCase', () {
    late LogoutUseCase useCase;

    setUp(() => useCase = LogoutUseCase(repo: repo));

    test('returns true on success (ignores its param)', () async {
      when(repo.logout()).thenAnswer((_) async => Right(true));

      final result = await useCase();

      expect(result, Right<ApiFail, bool>(true));
      verify(repo.logout()).called(1);
    });

    test('propagates the repository failure', () async {
      when(repo.logout()).thenAnswer((_) async => Left(failure));

      expect((await useCase()).isLeft(), isTrue);
      verify(repo.logout()).called(1);
    });
  });

  group('SendResetOtpUseCase', () {
    late SendResetOtpUseCase useCase;
    final input = ResetPasswordInput(email: 'a@b.com');

    setUp(() => useCase = SendResetOtpUseCase(repo: repo));

    test('returns true on success', () async {
      when(
        repo.sendPasswordResetOtp(input),
      ).thenAnswer((_) async => Right(true));

      final result = await useCase(input);

      expect(result, Right<ApiFail, bool>(true));
      verify(repo.sendPasswordResetOtp(input)).called(1);
    });

    test('propagates the repository failure', () async {
      when(
        repo.sendPasswordResetOtp(input),
      ).thenAnswer((_) async => Left(failure));

      expect((await useCase(input)).isLeft(), isTrue);
      verify(repo.sendPasswordResetOtp(input)).called(1);
    });
  });

  group('SendResetEmailUseCase', () {
    late SendResetEmailUseCase useCase;
    final input = ForgotPasswordInput(email: 'scout@b.com');

    setUp(() => useCase = SendResetEmailUseCase(repo: repo));

    test('returns true on success', () async {
      when(
        repo.sendPasswordResetEmail(input),
      ).thenAnswer((_) async => Right(true));

      final result = await useCase(input);

      expect(result, Right<ApiFail, bool>(true));
      verify(repo.sendPasswordResetEmail(input)).called(1);
    });

    test('propagates the repository failure', () async {
      when(
        repo.sendPasswordResetEmail(input),
      ).thenAnswer((_) async => Left(failure));

      expect((await useCase(input)).isLeft(), isTrue);
      verify(repo.sendPasswordResetEmail(input)).called(1);
    });
  });

  group('VerifyResetOtpUseCase', () {
    late VerifyResetOtpUseCase useCase;
    final input = VerifyOtpInput.email(otp: '000111', email: 'a@b.com');

    setUp(() => useCase = VerifyResetOtpUseCase(repo: repo));

    test('returns true on success', () async {
      when(
        repo.verifyPasswordResetOtp(input),
      ).thenAnswer((_) async => Right(true));

      final result = await useCase(input);

      expect(result, Right<ApiFail, bool>(true));
      verify(repo.verifyPasswordResetOtp(input)).called(1);
    });

    test('propagates the repository failure', () async {
      when(
        repo.verifyPasswordResetOtp(input),
      ).thenAnswer((_) async => Left(failure));

      expect((await useCase(input)).isLeft(), isTrue);
      verify(repo.verifyPasswordResetOtp(input)).called(1);
    });
  });

  group('UpdatePasswordUseCase', () {
    late UpdatePasswordUseCase useCase;
    final input = UpdatePasswordInput(newPassword: 'new-secret');

    setUp(() => useCase = UpdatePasswordUseCase(repo: repo));

    test('returns true on success', () async {
      when(repo.updatePassword(input)).thenAnswer((_) async => Right(true));

      final result = await useCase(input);

      expect(result, Right<ApiFail, bool>(true));
      verify(repo.updatePassword(input)).called(1);
    });

    test('propagates the repository failure', () async {
      when(repo.updatePassword(input)).thenAnswer((_) async => Left(failure));

      expect((await useCase(input)).isLeft(), isTrue);
      verify(repo.updatePassword(input)).called(1);
    });
  });
}
