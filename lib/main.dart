import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

import 'core/theme/app_theme.dart';
import 'core/navigation/root_shell.dart';

/// Returns the local Supabase URL for the current platform.
///
/// For physical Android devices, run `adb reverse tcp:54321 tcp:54321`
/// before launching so the phone tunnels its localhost through USB to
/// the host machine. Both emulators and physical devices then use 127.0.0.1.
String get _supabaseUrl {
  if (kIsWeb) return 'http://127.0.0.1:54321';
  if (Platform.isAndroid) return 'http://127.0.0.1:54321';
  return 'http://127.0.0.1:54321';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Local cache
  await Hive.initFlutter();
  await Hive.openBox('userPreferences');

  // Supabase — uses local instance; swap URL + key for production.
  await Supabase.initialize(
    url: _supabaseUrl,
    anonKey: 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH',
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stock Sense',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const RootShell(),
    );
  }
}
