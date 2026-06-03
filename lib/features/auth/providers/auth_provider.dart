import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A convenience getter for the Supabase client used throughout the app.
final supabase = Supabase.instance.client;

/// Exposes the current [Session] (or null when signed out) as a stream.
///
/// Any widget or provider that depends on auth state should watch this.
/// When the value is null the user is unauthenticated; when non-null they
/// are signed in.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return supabase.auth.onAuthStateChange;
});

/// A simple synchronous provider that returns the current session.
/// Useful for guards and one-shot checks.
final currentSessionProvider = Provider<Session?>((ref) {
  return supabase.auth.currentSession;
});


Future<void> setupPushNotifications() async {
  final messaging = FirebaseMessaging.instance;
  
  // 1. Request OS permission (Requires the POST_NOTIFICATIONS manifest tag on Android)
  final settings = await messaging.requestPermission();
  
  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    // 2. Get the unique device token
    final token = await messaging.getToken();
    if (token != null) {
      // 3. Save it to Supabase so the Edge Function knows where to send alerts
      await Supabase.instance.client.from('device_tokens').upsert({
        'user_id': Supabase.instance.client.auth.currentUser!.id,
        'token': token,
        'platform': Platform.operatingSystem,
      });
    }
  }
}