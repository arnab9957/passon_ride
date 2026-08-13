import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Stream of user authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Current authenticated Firebase user
  User? get currentUser => _auth.currentUser;

  /// Sign in with email and password
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user != null) {
        final uid = userCredential.user!.uid;
        await _analytics.setUserId(id: uid);
        await _analytics.setUserProperty(name: 'auth_status', value: 'authenticated');
        
        try {
          await FirebaseRemoteConfig.instance.fetchAndActivate();
        } catch (e) {
          print('Remote Config fetch warning: $e');
        }
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

  /// Create a new account with email and password
  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user != null) {
        final uid = userCredential.user!.uid;
        await _analytics.setUserId(id: uid);
        await _analytics.setUserProperty(name: 'auth_status', value: 'authenticated');

        try {
          await FirebaseRemoteConfig.instance.fetchAndActivate();
        } catch (e) {
          print('Remote Config fetch warning: $e');
        }
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
        final uid = userCredential.user!.uid;
        await _analytics.setUserId(id: uid);
        await _analytics.setUserProperty(name: 'auth_status', value: 'authenticated');
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
        final uid = userCredential.user!.uid;
        await _analytics.setUserId(id: uid);
        await _analytics.setUserProperty(name: 'auth_status', value: 'authenticated');

        try {
          await FirebaseRemoteConfig.instance.fetchAndActivate();
        } catch (e) {
          print('Remote Config fetch warning: $e');
        }
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
