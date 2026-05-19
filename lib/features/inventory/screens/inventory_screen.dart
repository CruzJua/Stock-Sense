import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Placeholder inventory screen — will be replaced with the item list view.
class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined,
                color: AppColors.green, size: 56),
            const SizedBox(height: 16),
            Text('Inventory', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 8),
            Text('Item list coming soon.', style: AppTextStyles.bodyLarge),
          ],
        ),
      ),
    );
  }
}
