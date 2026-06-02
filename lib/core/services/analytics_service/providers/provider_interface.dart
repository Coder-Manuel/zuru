abstract class AnalyticsProvider {
  Future<void> registerUser(String id);
  void setUserInfo(Map<String, dynamic> info);
  void setUserProperty({required String prop, dynamic value});
  void trackEvent({
    required String eventName,
    Map<String, dynamic>? properties,
  });
}
