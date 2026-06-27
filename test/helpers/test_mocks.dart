// Central mock declarations for the test suite.
//
// Run `dart run build_runner build` (or `fvm flutter pub run build_runner
// build`) to (re)generate the companion `test_mocks.mocks.dart` whenever this
// list changes.
//
// Two seams are mocked:
//   • the *repository interfaces* — used by the use-case unit tests and the
//     widget tests (UI driven against a fake repo);
//   • the *remote datasources* (+ the Supabase response types they return) —
//     used by the repository-impl unit tests and the UI→datasource integration
//     tests, where everything above the network is real.
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:zuru/core/entities/user.entity.dart';
import 'package:zuru/modules/auth/data/sources/remote_auth_datasource.dart';
import 'package:zuru/modules/auth/domain/repository/auth_repository.dart';
import 'package:zuru/modules/missions/data/sources/remote_missions_datasource.dart';
import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';
import 'package:zuru/modules/missions/domain/entities/nearby_scout.entity.dart';
import 'package:zuru/modules/missions/domain/repository/missions_repository.dart';

@GenerateNiceMocks([
  // ── Repository interfaces (domain seam) ────────────────────────────────────
  MockSpec<AuthRepository>(),
  MockSpec<MissionsRepository>(),

  // ── Domain entities returned by the repos ──────────────────────────────────
  MockSpec<User>(),
  MockSpec<MissionEntity>(),
  MockSpec<NearbyScout>(),

  // ── Remote datasources (data seam) ─────────────────────────────────────────
  MockSpec<RemoteAuthDatasource>(),
  MockSpec<RemoteMissionsDatasource>(),

  // ── Supabase response types the auth datasource returns ────────────────────
  MockSpec<supa.AuthResponse>(as: #MockAuthResponse),
  MockSpec<supa.UserResponse>(as: #MockUserResponse),
  MockSpec<supa.Session>(as: #MockSession),
  MockSpec<supa.User>(as: #MockSupaUser),
])
void main() {}
