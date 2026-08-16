import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firestore_service.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirestoreService _firestoreService = FirestoreService();

  /// Stream of user authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Current authenticated Firebase user
  User? get currentUser => _auth.currentUser;

  /// Helper to ensure user profile document exists in Firestore without overwriting custom saved details
  Future<void> syncUserProfile(User user) async {
    try {
      final existingProfile = await _firestoreService.getUserProfile(user.uid);

      if (existingProfile == null) {
        // First-time user sign-up: create initial profile document
        await _firestoreService.saveUserProfile(user.uid, {
          'email': user.email ?? '',
          'displayName': user.displayName ?? (user.email != null && user.email!.isNotEmpty ? user.email!.split('@').first : 'Rider User'),
          'photoUrl': user.photoURL ?? '',
          'phoneNumber': user.phoneNumber ?? '',
          'role': 'Rider',
          'trustScore': 95.0,
          'bio': '',
        });
      } else {
        // Existing user logging in again: preserve saved displayName, phoneNumber, bio, and role
        final updates = <String, dynamic>{
          'email': user.email ?? existingProfile.email,
        };
        if (user.photoURL != null && user.photoURL!.isNotEmpty && existingProfile.photoUrl.isEmpty) {
          updates['photoUrl'] = user.photoURL;
        }
        await _firestoreService.saveUserProfile(user.uid, updates);
      }
    } catch (e) {
      print('Warning: User Profile Firestore Sync Warning: $e');
    }
  }

  void _triggerBackgroundTasks(User user) {
    // Non-blocking background telemetry, profile sync & remote config fetch
    unawaited(_analytics.setUserId(id: user.uid));
    unawaited(_analytics.setUserProperty(name: 'auth_status', value: 'authenticated'));
    unawaited(syncUserProfile(user));
    unawaited(
      FirebaseRemoteConfig.instance
          .fetchAndActivate()
          .timeout(const Duration(seconds: 2), onTimeout: () => false)
          .catchError((_) => false),
    );
  }

  /// Sign in with email and password (Instant)
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user != null) {
        _triggerBackgroundTasks(userCredential.user!);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Sign-In Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected Auth Error: $e');
      rethrow;
    }
  }

  /// Create a new account with email and password (Instant)
  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user != null) {
        _triggerBackgroundTasks(userCredential.user!);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Sign-Up Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected Auth Error: $e');
      rethrow;
    }
  }

  /// Send password reset link to specified email address
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Send Email Verification link to signed-in user
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  /// Request SMS OTP Verification Code for Phone Number
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(FirebaseAuthException error) onError,
    required Function(PhoneAuthCredential credential) onAutoCompleted,
  }) async {
    // Sanitize phone number (keep leading + and digits only)
    final cleanPhone = phoneNumber.trim().replaceAll(RegExp(r'[^\d+]'), '');

    await _auth.verifyPhoneNumber(
      phoneNumber: cleanPhone,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
        onAutoCompleted(credential);
      },
      verificationFailed: onError,
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  /// Verify 6-digit SMS OTP Code and sign in
  Future<UserCredential?> signInWithPhoneOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        _triggerBackgroundTasks(userCredential.user!);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Phone OTP Verification Error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Sign in with Google Account (Supports Web & Mobile)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        // Web Platform: Use Firebase Auth Popup
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        // Mobile Platform: Use native google_sign_in plugin
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          // User cancelled the sign-in prompt
          return null;
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth.signInWithCredential(credential);
      }

      if (userCredential.user != null) {
        _triggerBackgroundTasks(userCredential.user!);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Google Auth Sign-In Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected Google Auth Error: $e');
      rethrow;
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        try {
          await GoogleSignIn().signOut();
        } catch (_) {}
      }
      await _auth.signOut();
      await _analytics.setUserId(id: null);
      await _analytics.setUserProperty(name: 'auth_status', value: 'guest');

      try {
        await FirebaseRemoteConfig.instance.fetchAndActivate();
      } catch (e) {
        print('Remote Config fetch warning: $e');
      }
    } catch (e) {
      print('Firebase Auth Sign-Out Error: $e');
    }
  }
}
