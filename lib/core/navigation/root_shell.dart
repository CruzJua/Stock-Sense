import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/scan/screens/scan_screen.dart';
import '../../features/inventory/screens/inventory_screen.dart';

/// The root shell of the app.
///
/// Responsibilities:
/// - Listens to [authStateProvider] and shows [LoginScreen] when the user is
///   signed out.
/// - When authenticated, renders the three-tab [BottomNavigationBar] with
///   [HomeScreen], [ScanScreen], and [InventoryScreen].
class RootShell extends ConsumerStatefulWidget {
  const RootShell({super.key});

  @override
  ConsumerState<RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<RootShell> {
  int _selectedIndex = 0;

  // Keep all tab bodies alive so their state is preserved when switching tabs.
  static const List<Widget> _pages = [
    HomeScreen(),
    ScanScreen(),
    InventoryScreen(),
  ];

  static const List<BottomNavigationBarItem> _navItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home_rounded),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.qr_code_scanner_outlined),
      activeIcon: Icon(Icons.qr_code_scanner_rounded),
      label: 'Scan',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.inventory_2_outlined),
      activeIcon: Icon(Icons.inventory_2_rounded),
      label: 'Inventory',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      // While the auth stream is initialising, show a branded splash.
      loading: () => const _SplashScreen(),

      // If the stream errors, show the login screen (safe fallback).
      error: (_, __) => const LoginScreen(),

      data: (state) {
        // No active session → show login.
        if (state.session == null) return const LoginScreen();

        // Authenticated → show the main app shell.
        return Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),
          bottomNavigationBar: _buildNavBar(),
        );
      },
    );
  }

  Widget _buildNavBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) => setState(() => _selectedIndex = index),
      items: _navItems,
    );
  }
}

// ---------------------------------------------------------------------------
// Branded splash / loading screen
// ---------------------------------------------------------------------------

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.inventory_2_rounded,
                  color: AppColors.black, size: 40),
            ),
            const SizedBox(height: 20),
            Text('StockSense', style: AppTextStyles.headlineLarge),
            const SizedBox(height: 32),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.green),
            ),
          ],
        ),
      ),
    );
  }
}
