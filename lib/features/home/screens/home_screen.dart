import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Placeholder home screen — will be replaced with the full dashboard.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.home_outlined, color: AppColors.green, size: 56),
            const SizedBox(height: 16),
            Text('Home', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 8),
            Text('Dashboard coming soon.', style: AppTextStyles.bodyLarge),
          ],
        ),
      ),
    );
  }
}
