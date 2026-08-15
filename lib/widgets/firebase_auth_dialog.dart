import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_auth_service.dart';
import '../theme/app_colors.dart';

class FirebaseAuthDialog extends StatefulWidget {
  const FirebaseAuthDialog({super.key});

  @override
  State<FirebaseAuthDialog> createState() => _FirebaseAuthDialogState();
}

class _FirebaseAuthDialogState extends State<FirebaseAuthDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Controllers for Email Auth
  final _emailController = TextEditingController(text: 'user@passonride.com');
  final _passwordController = TextEditingController(text: 'Password123!');
  
  // Controllers for Phone OTP Auth
  final _phoneController = TextEditingController(text: '+1 555-019-2834');
  final _otpController = TextEditingController();
  
  final FirebaseAuthService _authService = FirebaseAuthService();
  
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  
  // Phone Auth State
  String? _verificationId;
  bool _otpSent = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // Handle Email Auth Sign In / Registration
  Future<void> _handleEmailAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please fill in both email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final isSignUp = _tabController.index == 1;

    try {
      if (isSignUp) {
        final credential = await _authService.signUpWithEmail(email, password);
        // Send email verification link in background
        credential?.user?.sendEmailVerification();
        setState(() {
          _successMessage = 'Account registered! Verification link sent to $email';
        });
      } else {
        await _authService.signInWithEmail(email, password);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isSignUp
                        ? 'Registered & Verification Email Sent to $email!'
                        : 'Signed in with Firebase Auth as $email!',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'configuration-not-found' || e.code == 'operation-not-allowed') {
        setState(() => _errorMessage = 'Email/Password auth is disabled in Firebase Console. Please enable it in Console > Authentication > Providers.');
      } else {
        setState(() => _errorMessage = e.message ?? 'Authentication error [${e.code}]');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Handle Phone OTP Request
  Future<void> _handleSendPhoneOTP() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      setState(() => _errorMessage = 'Please enter a valid phone number (e.g. +1 555-019-2834)');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await _authService.verifyPhoneNumber(
        phoneNumber: phone,
        onCodeSent: (verificationId) {
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
              _otpSent = true;
              _isLoading = false;
              _successMessage = '6-digit OTP code sent to $phone!';
            });
          }
        },
        onError: (e) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              if (e.code == 'configuration-not-found' || e.code == 'operation-not-allowed') {
                _errorMessage = 'Phone Provider is not saved/enabled in Firebase Console [passon-ride-rental-888].\n\n'
                    'Fix Checklist:\n'
                    '1. Open Firebase Console > Authentication > Sign-in method.\n'
                    '2. Click "Phone" provider, turn switch ON, and click "Save".\n'
                    '3. Under Phone settings, add "+1 555-019-2834" to "Phone numbers for testing" with code 123456.';
              } else if (e.code == 'captcha-check-failed' || e.code == 'invalid-app-credential') {
                _errorMessage = 'Web reCAPTCHA check failed.\n'
                    'Please add "+1 555-019-2834" in Firebase Console > Auth > Phone > "Phone numbers for testing" to bypass SMS reCAPTCHA during Web testing.';
              } else {
                _errorMessage = 'Phone Auth Error [${e.code}]: ${e.message ?? e.code}.\n'
                    'Note: Configure Test Phone Numbers in Firebase Console > Auth > Phone for testing.';
              }
            });
          }
        },
        onAutoCompleted: (credential) {
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Phone number verified automatically via SMS!'), backgroundColor: Colors.green),
            );
          }
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error requesting Phone OTP: $e';
      });
    }
  }

  // Handle Verify SMS OTP Code
  Future<void> _handleVerifyOTP() async {
    final smsCode = _otpController.text.trim();
    if (smsCode.isEmpty || smsCode.length < 6) {
      setState(() => _errorMessage = 'Please enter the 6-digit OTP code.');
      return;
    }

    if (_verificationId == null) {
      setState(() => _errorMessage = 'Please request an OTP code first.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signInWithPhoneOTP(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.verified, color: Colors.white),
                const SizedBox(width: 8),
                Text('Phone OTP Verified! Signed in as ${_phoneController.text}'),
              ],
            ),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = 'Invalid OTP code [${e.code}]: ${e.message ?? e.code}');
    } catch (e) {
      setState(() => _errorMessage = 'Error verifying OTP: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Handle Google OAuth Sign In
  Future<void> _handleGoogleAuth() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final credential = await _authService.signInWithGoogle();
      if (credential != null && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Signed in with Google as ${credential.user?.displayName ?? credential.user?.email ?? 'Google User'}!'),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'configuration-not-found' || e.code == 'operation-not-allowed') {
        setState(() => _errorMessage = 'Google Sign-In is disabled in Firebase Console. Enable Google provider in Firebase Console > Authentication.');
      } else {
        setState(() => _errorMessage = 'Google Sign-In Error [${e.code}]: ${e.message ?? e.code}');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Google Sign-In: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Firebase Header Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_fire_department, color: Colors.deepOrange, size: 28),
                ),
                const SizedBox(width: 12),
                const Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Firebase Authentication', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                      Text('Email, Phone OTP & Google Sign-In', style: TextStyle(fontSize: 11, color: Colors.grey), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // TabBar (Email Sign In vs Register vs Phone OTP)
            TabBar(
              controller: _tabController,
              labelColor: Colors.deepOrange,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.deepOrange,
              isScrollable: true,
              tabs: const [
                Tab(text: 'Email Sign In'),
                Tab(text: 'Register Email'),
                Tab(text: 'Phone SMS OTP'),
              ],
            ),

            const SizedBox(height: 16),

            // Error Feedback Banner
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 11)),
                    ),
                  ],
                ),
              ),

            // Success Feedback Banner
            if (_successMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_successMessage!, style: TextStyle(color: Colors.green.shade800, fontSize: 11)),
                    ),
                  ],
                ),
              ),

            // Tab Content Views
            SizedBox(
              height: 170,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // 1. Email Sign In View
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: Icon(Icons.email_outlined),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline),
                            isDense: true,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. Email Register View
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email Address for Verification',
                            prefixIcon: Icon(Icons.mark_email_read_outlined),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Choose Password',
                            prefixIcon: Icon(Icons.lock_clock_outlined),
                            isDense: true,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3. Phone SMS OTP View
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number (with Country Code)',
                            hintText: '+1 555-019-2834',
                            prefixIcon: Icon(Icons.phone_android_outlined),
                            isDense: true,
                          ),
                        ),
                        if (_otpSent) ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            decoration: const InputDecoration(
                              labelText: '6-Digit SMS OTP Code',
                              prefixIcon: Icon(Icons.pin_outlined),
                              isDense: true,
                              counterText: '',
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          '💡 For web testing: Add test phone numbers in Firebase Console > Auth > Phone to bypass reCAPTCHA.',
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Action Button Builder
            ListenableBuilder(
              listenable: _tabController,
              builder: (ctx, _) {
                final isPhoneTab = _tabController.index == 2;

                return SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : (isPhoneTab
                            ? (_otpSent ? _handleVerifyOTP : _handleSendPhoneOTP)
                            : _handleEmailAuth),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            isPhoneTab
                                ? (_otpSent ? 'Verify 6-Digit OTP' : 'Send Phone SMS OTP')
                                : (_tabController.index == 0 ? 'Sign In with Email' : 'Register & Send Verification Link'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // OR Divider
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.shade300)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('OR', style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                Expanded(child: Divider(color: Colors.grey.shade300)),
              ],
            ),

            const SizedBox(height: 12),

            // Google Sign In Button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _handleGoogleAuth,
                icon: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  child: const Text('G', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                label: const Text(
                  'Continue with Google',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? Colors.white : Colors.black87,
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
