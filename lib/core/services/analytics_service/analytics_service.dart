import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:zuru/core/services/analytics_service/providers/mixpanel.dart';
import 'package:zuru/core/services/analytics_service/providers/provider_interface.dart';
import 'package:zuru/core/services/analytics_service/static/event_enum.dart';
import 'package:zuru/core/services/storage_service/storage.service.dart';

class AnalyticsService {
  static AnalyticsService? _instance;
  AnalyticsProvider? _provider;

  AnalyticsService._internal(this._provider) {
    _init(_provider);
  }

  static Future<void> init([AnalyticsProvider? provider]) async {
    _instance ??= AnalyticsService._internal(
      provider ?? MixPanelProvider.instance,
    );
  }

  static AnalyticsService get instance {
    _instance ??= AnalyticsService._internal(MixPanelProvider.instance);
    return _instance!;
  }

  void _init(AnalyticsProvider? provider) {
    if (kReleaseMode) {
      _provider ??= provider;
      if (_provider != null) log('Analytics Service Initialized');
    }
  }

  Future<Map<String, dynamic>> get _properties async {
    await StorageService.get<Map<String, dynamic>?>(StorageKeys.userDataKey);
    return {};
  }

  Future<void> identifyUser(String id) async {
    await _provider?.registerUser(id);
    await _setUserInfo();
  }

  void setUserProperty({required String prop, dynamic value}) {
    _provider?.setUserProperty(prop: prop, value: value);
    _setUserInfo();
  }

  Future<void> trackEvent({
    required AnalyticsEvent event,
    Map<String, dynamic>? properties,
  }) async {
    final eventProperties = await _properties;
    if (properties != null && properties.isNotEmpty) {
      eventProperties.addAll(properties);
    }
    _provider?.trackEvent(eventName: event.name, properties: properties);
  }

  void trackScreenView({String? currentScreen, String? previousScreen}) async {
    final eventProperties = await _properties;
    eventProperties.addAll({
      'Page': currentScreen,
      'Previous Page': previousScreen,
    });
    _provider?.trackEvent(
      eventName: AnalyticsEvent.SCREEN_VIEW.name,
      properties: eventProperties,
    );
  }

  Future<void> _setUserInfo() async {
    final details = await _properties;
    _provider?.setUserInfo(details);
  }
}
