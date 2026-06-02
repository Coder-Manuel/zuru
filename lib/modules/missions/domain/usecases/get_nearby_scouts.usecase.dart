import 'dart:async';

import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/core/types/usecase.dart';
import 'package:zuru/modules/missions/domain/entities/nearby_scout.entity.dart';
import 'package:zuru/modules/missions/domain/repository/missions_repository.dart';

class NearbyScoutsInput {
  final double latitude;
  final double longitude;

  /// Search radius in kilometres (default: 5 km).
  final double radiusKm;

  const NearbyScoutsInput({
    required this.latitude,
    required this.longitude,
    this.radiusKm = 5.0,
  });
}

class GetNearbyScoutsUseCase
    implements UseCase<List<NearbyScout>, NearbyScoutsInput> {
  final MissionsRepository repo;
  GetNearbyScoutsUseCase({required this.repo});

  @override
  FutureOr<RepoResponse<List<NearbyScout>>> call(NearbyScoutsInput params) =>
      repo.getNearbyScouts(
        latitude: params.latitude,
        longitude: params.longitude,
        radiusKm: params.radiusKm,
      );
}
