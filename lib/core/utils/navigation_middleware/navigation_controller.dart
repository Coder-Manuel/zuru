import 'package:get/get.dart';

class NavigationController extends GetxController {
  final List<String?> _history = [];

  void push(String? route) => _history.add(route);

  void remove(String? route) => _history.remove(route);

  void replace({String? oldRoute, String? newRoute}) {
    remove(oldRoute);
    push(newRoute);
  }

  bool hasRoute(String? route) => _history.any((v) => v == route);
}
