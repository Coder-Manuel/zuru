import 'package:flutter/material.dart';
import 'package:zuru/config/colors.dart';

// TODO(Phase 2): Replace with full SplashPage migrated from unseen-client
//                (shimmer animation + SplashController auth check)
class SplashPage extends StatelessWidget {
  static const String route = '/';
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text(
          'Zuru World',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 48,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}
