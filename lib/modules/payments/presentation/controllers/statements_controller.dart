import 'package:get/get.dart';
import 'package:zuru/modules/payments/domain/entities/statement.entity.dart';
import 'package:zuru/modules/payments/domain/usecases/get_statements.usecase.dart';

class StatementsController extends GetxController {
  final GetStatementsUseCase _getStatements;

  StatementsController({required GetStatementsUseCase getStatements})
    : _getStatements = getStatements;

  final isLoading = true.obs;
  final hasError = false.obs;
  final statements = <StatementEntity>[].obs;

  @override
  void onReady() {
    super.onReady();
    fetchStatements();
  }

  Future<void> fetchStatements() async {
    isLoading.value = true;
    hasError.value = false;

    final result = await _getStatements();

    result.fold(
      (_) {
        hasError.value = true;
        isLoading.value = false;
      },
      (data) {
        statements.assignAll(data);
        isLoading.value = false;
      },
    );
  }
}
