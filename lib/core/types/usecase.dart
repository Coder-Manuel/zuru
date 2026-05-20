import 'dart:async';

import 'package:zuru/core/types/repo_reponse.type.dart';

abstract class UseCase<T, Params> {
  FutureOr<RepoResponse<T>> call(Params params);
}

abstract class StreamUseCase<T, Params> {
  Stream<RepoResponse<T>> call(Params params);
}
