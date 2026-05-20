import 'package:dartz/dartz.dart';

typedef RepoResponse<T> = Either<ApiFail, T>;

class ApiFail implements Exception {
  final String message;

  ApiFail(this.message);
}

class FailureResponse<T> extends Left<ApiFail, T> {
  FailureResponse(String message) : super(ApiFail(message));
}

class SuccessResponse<T> extends Right<ApiFail, T> {
  SuccessResponse(super.data);
}
