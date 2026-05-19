import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Placeholder scan screen — will be replaced with the camera barcode scanner.
class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.qr_code_scanner_rounded,
                color: AppColors.green, size: 56),
            const SizedBox(height: 16),
            Text('Scan', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 8),
            Text('Barcode scanner coming soon.', style: AppTextStyles.bodyLarge),
          ],
        ),
      ),
    );
  }
}
