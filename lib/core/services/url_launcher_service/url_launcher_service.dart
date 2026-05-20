import 'package:url_launcher/url_launcher.dart';

abstract class UrlLauncherService {
  Future<bool> launch(Uri uri);
  Future<bool> canLaunch(Uri uri);
}

class UrlLauncherServiceImpl implements UrlLauncherService {
  @override
  Future<bool> launch(Uri uri) async =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  @override
  Future<bool> canLaunch(Uri uri) async => canLaunchUrl(uri);
}
