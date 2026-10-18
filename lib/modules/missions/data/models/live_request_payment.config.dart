/// `app_config.live_request_payment`: how long a client has to pay after a
/// guide accepts. The backend expiry job reads the same value.
class LiveRequestPaymentConfig {
  static const key = 'live_request_payment';
  static const fallbackWindow = Duration(minutes: 30);

  static Duration windowFromSection(Map<String, dynamic>? section) {
    final raw = section?['minutes'];
    final minutes = raw is num ? raw.toInt() : null;
    return minutes != null && minutes > 0
        ? Duration(minutes: minutes)
        : fallbackWindow;
  }
}
