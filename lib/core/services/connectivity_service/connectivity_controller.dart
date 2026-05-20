import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:observe_internet_connectivity/observe_internet_connectivity.dart';

class ConnectivityController extends GetxController {
  ConnectivityController({required this.strategy});
  final InternetObservingStrategy strategy;

  Rx<bool> isInitialAppOpen = true.obs;
  Rx<bool> showConnectedIndicator = false.obs;
  Rx<ConnectivityStatus> connectivity = ConnectivityStatus.pending.obs;

  bool get isConnected =>
      connectivity.value != ConnectivityStatus.disconnected;

  void onConnectionUpdate(BuildContext? _, bool status) {
    connectivity.value =
        status ? ConnectivityStatus.connected : ConnectivityStatus.disconnected;
    update();

    if (!isInitialAppOpen.value && status) {
      showConnectedIndicator.value = true;
      Future.delayed(const Duration(seconds: 3), () {
        showConnectedIndicator.value = false;
      });
    }

    isInitialAppOpen.value = false;
  }
}

enum ConnectivityStatus { pending, connected, disconnected }
