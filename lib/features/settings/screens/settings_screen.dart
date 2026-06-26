import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _handleSignOut(BuildContext context) async {

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text('Sign Out', style: AppTextStyles.headlineMedium),
        content: Text('Are you sure you want to log out?', style: AppTextStyles.bodyLarge),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true) {

      try {
        final box = Hive.box('inventoryCache');
        await box.clear();
      } catch (_) {}

      await Supabase.instance.client.auth.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text('Settings', style: AppTextStyles.headlineMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // TODO: Future settings items will go here.

          ListTile(
            leading: const Icon(Icons.person_outline, color: AppColors.textPrimary),
            title: Text('Account', style: AppTextStyles.bodyLarge),
            onTap: () {}, // TODO: Implement account settings
          ),
          const Divider(color: AppColors.surfaceDark),
          
          // Sign Out Button
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.error),
            title: Text('Sign Out', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.error)),
            onTap: () => _handleSignOut(context),
          ),
        ],
      ),
    );
  }
}