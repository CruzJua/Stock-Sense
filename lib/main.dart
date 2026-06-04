import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'core/theme/app_theme.dart';
import 'core/navigation/root_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
   await Firebase.initializeApp();
  }

  // Local cache
  await Hive.initFlutter();
  await Hive.openBox('userPreferences');
  await Hive.openBox('inventoryCache');

  // Supabase — uses local instance; swap URL + key for production.
await Supabase.initialize(
  url: 'https://nfsegggccezuawboegxi.supabase.co',
  anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5mc2VnZ2djY2V6dWF3Ym9lZ3hpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkxNjAzNjMsImV4cCI6MjA5NDczNjM2M30.NiMQiF7vGUZk6nRArjGxN8h1rLWFKHlA4X7GSEzgoQo',
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
