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
