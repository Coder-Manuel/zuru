import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:zuru/config/env.dart';
import 'package:zuru/core/services/analytics_service/providers/provider_interface.dart';

class MixPanelProvider implements AnalyticsProvider {
  static MixPanelProvider? _instance;
  Mixpanel? _mixpanel;

  MixPanelProvider._internal() {
    _init();
  }

  static MixPanelProvider get instance {
    _instance ??= MixPanelProvider._internal();
    return _instance!;
  }

  void _init() async {
    _mixpanel ??= await Mixpanel.init(
      Env.mixpanelToken,
      trackAutomaticEvents: true,
    );
  }

  @override
  void setUserInfo(Map<String, dynamic> info) =>
      _mixpanel?.registerSuperProperties(info);

  @override
  Future<void> registerUser(String id) async {
    final distinctId = await _mixpanel?.getDistinctId();
    if (distinctId != id) _mixpanel?.identify(id);
    await _mixpanel?.flush();
  }

  @override
  void setUserProperty({required String prop, dynamic value}) =>
      _mixpanel?.getPeople().set(prop, value);

  @override
  void trackEvent({
    required String eventName,
    Map<String, dynamic>? properties,
  }) async {
    _mixpanel?.track(eventName, properties: properties);
    await _mixpanel?.flush();
  }
}
