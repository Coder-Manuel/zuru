import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:observe_internet_connectivity/observe_internet_connectivity.dart';
import 'package:zuru/core/services/connectivity_service/connectivity_controller.dart';

class OfflineWidget extends GetView<ConnectivityController> {
  const OfflineWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: !kIsWeb,
      child: InternetConnectivityListener(
        connectivityListener: controller.onConnectionUpdate,
        internetConnectivity: InternetConnectivity(
          internetObservingStrategy: controller.strategy,
        ),
        child: GetBuilder<ConnectivityController>(
          builder: (_) {
            return Stack(
              children: [
                Visibility(
                  visible: !controller.isConnected,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Material(
                      key: const Key('OfflineWidget'),
                      child: AnimatedContainer(
                        width: double.infinity,
                        duration: const Duration(milliseconds: 800),
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.shade800,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.only(
                            bottom: Platform.isIOS ? 10 : 5,
                            top: 5,
                          ),
                          child: const Text(
                            'No internet connection',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Obx(() => Visibility(
                  visible: controller.showConnectedIndicator.value,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Material(
                      key: const Key('OnlineWidget'),
                      child: AnimatedContainer(
                        width: double.infinity,
                        duration: const Duration(milliseconds: 800),
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(color: Colors.green.shade800),
                        child: Padding(
                          padding: EdgeInsets.only(
                            bottom: Platform.isIOS ? 10 : 5,
                            top: 5,
                          ),
                          child: const Text(
                            "You're back online",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                  ),
                )),
              ],
            );
          },
        ),
      ),
    );
  }
}
