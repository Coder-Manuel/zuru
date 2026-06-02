import 'package:supabase_flutter/supabase_flutter.dart';

abstract class RemotePaymentsDatasource {
  /// Fetches the scout's payment statement rows from Supabase.
  Future<List<Map<String, dynamic>>> getStatements();
}

class RemotePaymentsDatasourceImpl implements RemotePaymentsDatasource {
  final SupabaseClient client;

  RemotePaymentsDatasourceImpl({required this.client});

  @override
  Future<List<Map<String, dynamic>>> getStatements() async {
    final data = await client
        .from('payment_statements')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }
}
