import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'web_auth_helper_stub.dart' if (dart.library.html) 'web_auth_helper_web.dart' as web_auth;

class SupabaseAuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get currently signed in user
  User? get currentUser => _supabase.auth.currentUser;

  /// Get current session
  Session? get currentSession => _supabase.auth.currentSession;

  /// Stream auth state changes
  Stream<AuthState> get onAuthStateChange => _supabase.auth.onAuthStateChange;

  /// Check if user is signed in
  bool get isSignedIn => currentUser != null;

  /// Sign Up with Email and Password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email.trim(),
      password: password.trim(),
      data: {
        if (displayName != null && displayName.isNotEmpty) 'full_name': displayName,
        if (displayName != null && displayName.isNotEmpty) 'display_name': displayName,
      },
    );
    return response;
  }

  /// Sign In with Email and Password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password.trim(),
    );
    return response;
  }

  /// OAuth Sign In with Google
  Future<bool> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final String authUrl = 'https://gxqlsogewjjkcdetubuv.supabase.co/auth/v1/authorize?provider=google&redirect_to=${Uri.base.origin}';
        web_auth.openGoogleAuthPopup(authUrl);
        return true;
      } else {
        final String? redirectTo = 'passonride://login-callback';
        return await _supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: redirectTo,
        );
      }
    } catch (e) {
      print('Google sign in error: $e');
      rethrow;
    }
  }

  /// Send Password Reset Email
  Future<void> sendPasswordResetEmail(String email) async {
    await _supabase.auth.resetPasswordForEmail(email.trim());
  }

  /// Sign Out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
