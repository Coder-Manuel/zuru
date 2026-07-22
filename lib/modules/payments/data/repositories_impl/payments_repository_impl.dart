import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/core/utils/error_wrapper.dart';
import 'package:zuru/modules/payments/data/models/payment.model.dart';
import 'package:zuru/modules/payments/data/models/payments.inputs.dart';
import 'package:zuru/modules/payments/data/models/statement.model.dart';
import 'package:zuru/modules/payments/data/models/stk_push_result.model.dart';
import 'package:zuru/modules/payments/data/sources/remote_payments_datasource.dart';
import 'package:zuru/modules/payments/domain/entities/payment.entity.dart';
import 'package:zuru/modules/payments/domain/entities/statement.entity.dart';
import 'package:zuru/modules/payments/domain/entities/stk_push_result.entity.dart';
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
  Future<RepoResponse<StkPushResult>> initiateStkPush(
    StkPushInput input,
  ) async {
    final response = await ErrorWrapper.async<RepoResponse<StkPushResult>>(
      () async {
        final res = await remoteDatasource.initiateStkPush(input);
        final data = res.data;
        if (res.status != 200 || data is! Map) {
          return FailureResponse('Could not start the payment. Please retry.');
        }
        final result = StkPushResultModel.fromMap(
          Map<String, dynamic>.from(data),
        );
        if (result.paymentId.isEmpty) {
          return FailureResponse('Could not start the payment. Please retry.');
        }
        return SuccessResponse(result);
      },
      onError: (_) =>
          FailureResponse('Could not start the payment. Please retry.'),
      library: _library,
      description: 'while initiating STK push',
    );
    return response!;
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
