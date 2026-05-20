import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zuru/modules/payments/data/repositories_impl/payments_repository_impl.dart';
import 'package:zuru/modules/payments/data/sources/remote_payments_datasource.dart';
import 'package:zuru/modules/payments/domain/repository/payments_repository.dart';
import 'package:zuru/modules/payments/domain/usecases/get_statements.usecase.dart';
import 'package:zuru/modules/payments/presentation/controllers/statements_controller.dart';

class PaymentsBindings extends Bindings {
  @override
  void dependencies() {
    // ── Data layer ────────────────────────────────────────────────────────────
    Get.lazyPut<RemotePaymentsDatasource>(
      () => RemotePaymentsDatasourceImpl(client: Get.find<SupabaseClient>()),
      fenix: true,
    );
    Get.lazyPut<PaymentsRepository>(
      () => PaymentsRepositoryImpl(
        remoteDatasource: Get.find<RemotePaymentsDatasource>(),
      ),
      fenix: true,
    );

    // ── Use cases ─────────────────────────────────────────────────────────────
    Get.lazyPut<GetStatementsUseCase>(
      () => GetStatementsUseCase(repo: Get.find<PaymentsRepository>()),
      fenix: true,
    );

    // ── Controller ────────────────────────────────────────────────────────────
    Get.lazyPut<StatementsController>(
      () => StatementsController(
        getStatements: Get.find<GetStatementsUseCase>(),
      ),
      fenix: true,
    );
  }
}
