import 'dart:async';

import 'package:zuru/core/entities/user.entity.dart';
import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/core/types/usecase.dart';
import 'package:zuru/modules/scouts/domain/repository/scouts_repository.dart';

class ScoutsFeedParams {
  /// Zero-based page index.
  final int page;
  final int pageSize;
  final bool availableOnly;
  final String? tag;

  const ScoutsFeedParams({
    this.page = 0,
    this.pageSize = 10,
    this.availableOnly = false,
    this.tag,
  });

  int get from => page * pageSize;
  int get to => from + pageSize - 1;
}

class GetScoutsFeedUseCase implements UseCase<List<User>, ScoutsFeedParams> {
  final ScoutsRepository repo;
  GetScoutsFeedUseCase({required this.repo});

  @override
  FutureOr<RepoResponse<List<User>>> call(ScoutsFeedParams params) =>
      repo.getScoutsFeed(
        from: params.from,
        to: params.to,
        availableOnly: params.availableOnly,
        tag: params.tag,
      );
}
