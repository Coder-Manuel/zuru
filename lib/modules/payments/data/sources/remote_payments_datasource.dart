import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zuru/core/services/monitor_service/monitor.service.dart';
import 'package:zuru/modules/payments/data/models/payments.inputs.dart';

abstract class RemotePaymentsDatasource {
  Future<List<Map<String, dynamic>>> getStatements();
  Future<FunctionResponse> initiateStkPush(StkPushInput input);
  Stream<Map<String, dynamic>> watchPayment(String paymentId);
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

  @override
  Future<FunctionResponse> initiateStkPush(StkPushInput input) {
    return client.functions.invoke('mpesa-stk-push', body: input.toBody());
  }

  @override
  Stream<Map<String, dynamic>> watchPayment(String paymentId) {
    final ctrl = StreamController<Map<String, dynamic>>.broadcast();
    RealtimeChannel? channel;

    Future<void> fetchOnce() async {
      if (ctrl.isClosed) return;
      try {
        final row = await client
            .from('payments')
            .select()
            .eq('id', paymentId)
            .maybeSingle();
        if (row != null && !ctrl.isClosed) {
          ctrl.add(Map<String, dynamic>.from(row));
        }
      } catch (e, stack) {
        MonitorService.report(
          ex: e,
          library: 'payments_datasource',
          description: 'while fetching payment $paymentId',
          stack: stack,
        );
      }
    }

    channel = client
        .channel('payment_watch_$paymentId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'payments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: paymentId,
          ),
          callback: (payload) {
            if (!ctrl.isClosed) {
              ctrl.add(Map<String, dynamic>.from(payload.newRecord));
            }
          },
        )
        .subscribe();

    fetchOnce();

    ctrl.onCancel = () {
      if (channel != null) client.removeChannel(channel);
      ctrl.close();
    };

    return ctrl.stream;
  }
}
