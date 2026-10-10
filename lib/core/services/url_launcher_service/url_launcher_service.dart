import 'package:url_launcher/url_launcher.dart';
import 'package:zuru/core/services/monitor_service/monitor.service.dart';

abstract class UrlLauncherService {
  Future<bool> launch(Uri uri);
  Future<bool> canLaunch(Uri uri);
}

class UrlLauncherServiceImpl implements UrlLauncherService {
  @override
  Future<bool> launch(Uri uri) async {
    // launchUrl THROWS (rather than returning false) when no activity can
    // handle the intent. Callers treat this as a yes/no, and an uncaught
    // throw strands them mid-flow — the payment sheet would sit on
    // "Setting up your card payment…" forever.
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e, stack) {
      MonitorService.report(
        ex: e,
        library: 'url_launcher_service',
        description: 'while launching $uri',
        stack: stack,
      );
      return false;
    }
  }

  @override
  Future<bool> canLaunch(Uri uri) async {
    try {
      return await canLaunchUrl(uri);
    } catch (_) {
      return false;
    }
  }
}
