import 'package:supabase_flutter/supabase_flutter.dart';

abstract class RemoteRatingDatasource {
  Future<Map<String, dynamic>> createRating(Map<String, dynamic> data);
}

class RemoteRatingDatasourceImpl implements RemoteRatingDatasource {
  final SupabaseClient client;

  RemoteRatingDatasourceImpl({required this.client});

  @override
  Future<Map<String, dynamic>> createRating(Map<String, dynamic> data) {
    return client.from('ratings').insert(data).select().single();
  }
}
