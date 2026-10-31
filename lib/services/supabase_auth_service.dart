import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    String? phoneNumber,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email.trim(),
      password: password.trim(),
      data: {
        if (displayName != null && displayName.isNotEmpty) 'full_name': displayName,
        if (displayName != null && displayName.isNotEmpty) 'display_name': displayName,
        if (phoneNumber != null && phoneNumber.isNotEmpty) 'phone_number': phoneNumber,
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
  Future<bool> signInWithGoogle({String? customRedirectTo}) async {
    final String redirectTo = customRedirectTo ??
        (kIsWeb
            ? (Uri.base.origin.isNotEmpty ? Uri.base.origin : 'http://localhost:3000')
            : 'passonride://login-callback');

    return await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectTo,
    );
  }

  /// Send Password Reset Email with redirect URL
  Future<void> sendPasswordResetEmail(String email, {String? redirectTo}) async {
    final String redirect = redirectTo ??
        (kIsWeb
            ? (Uri.base.origin.isNotEmpty ? '${Uri.base.origin}/update-password' : 'http://localhost:3000/update-password')
            : 'passonride://update-password');

    await _supabase.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: redirect,
    );
  }

  /// Update User Password (User must be authenticated / in recovery session)
  Future<UserResponse> updatePassword(String newPassword) async {
    return await _supabase.auth.updateUser(
      UserAttributes(password: newPassword.trim()),
    );
  }

  /// Sign Out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
