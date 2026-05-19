import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme/app_theme.dart';
import 'core/navigation/root_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Local cache
  await Hive.initFlutter();
  await Hive.openBox('userPreferences');

  // Supabase — uses local instance; swap URL + key for production.
  await Supabase.initialize(
    url: 'http://127.0.0.1:54321',
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
