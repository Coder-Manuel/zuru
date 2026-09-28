import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/core/utils/error_wrapper.dart';
import 'package:zuru/modules/payments/data/models/collect_payment_result.model.dart';
import 'package:zuru/modules/payments/data/models/payment.model.dart';
import 'package:zuru/modules/payments/data/models/payments.inputs.dart';
import 'package:zuru/modules/payments/data/models/statement.model.dart';
import 'package:zuru/modules/payments/data/sources/remote_payments_datasource.dart';
import 'package:zuru/modules/payments/domain/entities/collect_payment_result.entity.dart';
import 'package:zuru/modules/payments/domain/entities/payment.entity.dart';
import 'package:zuru/modules/payments/domain/entities/statement.entity.dart';
import 'package:zuru/modules/payments/domain/repository/payments_repository.dart';

class PaymentsRepositoryImpl extends PaymentsRepository {
  final _library = 'Payments Repository';
  final RemotePaymentsDatasource remoteDatasource;

  PaymentsRepositoryImpl({required this.remoteDatasource});

  @override
  Future<RepoResponse<List<StatementEntity>>> getStatements() async {
    final response =
        await ErrorWrapper.async<RepoResponse<List<StatementEntity>>>(
          () async {
            final rows = await remoteDatasource.getStatements();
            final statements = rows.map(StatementModel.fromMap).toList();
            return SuccessResponse(statements);
          },
          onError: (_) => FailureResponse('Unable to load payment statements.'),
          library: _library,
          description: 'while fetching payment statements',
        );
    return response!;
  }

  @override
  Future<RepoResponse<CollectPaymentResult>> collectPayment(
    CollectPaymentInput input,
  ) async {
    final response =
        await ErrorWrapper.async<RepoResponse<CollectPaymentResult>>(
          () async {
            final FunctionResponse res;
            try {
              res = await remoteDatasource.collectPayment(input);
            } on FunctionException catch (e) {
              return FailureResponse.from(_collectFailure(e.status, e.details));
            }
            final data = res.data;
            if (res.status != 200 || data is! Map) {
              return FailureResponse.from(_collectFailure(res.status, data));
            }
            final result = CollectPaymentResultModel.fromMap(
              Map<String, dynamic>.from(data),
            );
            if (result.paymentId.isEmpty) {
              return FailureResponse.from(
                CollectPaymentFail(
                  _collectRetryMessage,
                  kind: CollectFailKind.retryable,
                ),
              );
            }
            return SuccessResponse(result);
          },
          onError: (_) => FailureResponse.from(
            CollectPaymentFail(
              _collectRetryMessage,
              kind: CollectFailKind.retryable,
            ),
          ),
          library: _library,
          description: 'while collecting payment',
        );
    return response!;
  }

  static const _collectRetryMessage =
      'Could not start the payment. Please retry.';

  /// Maps an `intasend-collect` error status to what the UI should do.
  CollectPaymentFail _collectFailure(int status, dynamic details) {
    final serverMessage = details is Map ? details['error']?.toString() : null;
    return switch (status) {
      400 => CollectPaymentFail(
        serverMessage ?? 'Please check your details and try again.',
        kind: CollectFailKind.invalid,
      ),
      403 || 404 => CollectPaymentFail(
        'This mission can\'t be paid for right now.',
        kind: CollectFailKind.forbidden,
      ),
      409 => CollectPaymentFail(
        serverMessage ?? 'Mission already paid',
        kind: CollectFailKind.alreadyPaid,
      ),
      _ => CollectPaymentFail(
        _collectRetryMessage,
        kind: CollectFailKind.retryable,
      ),
    };
  }

  @override
  Stream<RepoResponse<PaymentEntity>> watchPayment(String paymentId) async* {
    yield* ErrorWrapper.stream<RepoResponse<PaymentEntity>>(
      () async* {
        await for (final row in remoteDatasource.watchPayment(paymentId)) {
          yield SuccessResponse(PaymentModel.fromMap(row));
        }
      },
      onError: (_) => FailureResponse('Lost connection to the payment.'),
      library: _library,
      description: 'while watching payment',
    );
  }
}
