import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/supabase_auth_service.dart';
import '../theme/app_colors.dart';
import 'location_prompt_dialog.dart';

class SupabaseAuthDialog extends StatefulWidget {
  const SupabaseAuthDialog({super.key});

  @override
  State<SupabaseAuthDialog> createState() => _SupabaseAuthDialogState();
}

class _SupabaseAuthDialogState extends State<SupabaseAuthDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _signInEmailController = TextEditingController();
  final _signInPasswordController = TextEditingController();

  final _signUpNameController = TextEditingController();
  final _signUpEmailController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final _signUpConfirmPasswordController = TextEditingController();

  final SupabaseAuthService _authService = SupabaseAuthService();

  bool _obscureSignInPassword = true;
  bool _obscureSignUpPassword = true;
  bool _obscureSignUpConfirmPassword = true;

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted && !_tabController.indexIsChanging) {
        setState(() {
          _errorMessage = null;
          _successMessage = null;
          // reset password visibility when switching tabs
          _obscureSignInPassword = true;
          _obscureSignUpPassword = true;
          _obscureSignUpConfirmPassword = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    _signUpNameController.dispose();
    _signUpEmailController.dispose();
    _signUpPasswordController.dispose();
    _signUpConfirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailAuth() async {
    final isSignUp = _tabController.index == 1;
    final email = isSignUp ? _signUpEmailController.text.trim() : _signInEmailController.text.trim();
    final password = isSignUp ? _signUpPasswordController.text.trim() : _signInPasswordController.text.trim();
    final name = _signUpNameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter both email and password.');
      return;
    }

    if (isSignUp) {
      final confirmPassword = _signUpConfirmPasswordController.text.trim();
      if (password.length < 6) {
        setState(() => _errorMessage = 'Password must be at least 6 characters.');
        return;
      }
      if (confirmPassword.isNotEmpty && password != confirmPassword) {
        setState(() => _errorMessage = 'Passwords do not match.');
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      if (isSignUp) {
        final res = await _authService.signUpWithEmail(
          email: email,
          password: password,
          displayName: name.isNotEmpty ? name : null,
        );

        if (res.user != null) {
          if (res.session == null) {
            setState(() {
              _isLoading = false;
              _successMessage = 'Verification link sent to $email!';
            });
            if (mounted) {
              _showEmailVerificationDialog(email);
            }
            return;
          } else {
            setState(() {
              _successMessage = 'Account created successfully for $email!';
            });
          }
        }
      } else {
        await _authService.signInWithEmail(email: email, password: password);
      }

      if (mounted) {
        final appState = Provider.of<AppState>(context, listen: false);
        await appState.reloadUserSession();
        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isSignUp
                        ? '🎉 Registered & Authenticated as $email!'
                        : '👋 Welcome back! Signed in as $email',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        // Prompt the user for location permission/prompt
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            LocationPromptDialog.show(context);
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleAuth() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final success = await _authService.signInWithGoogle();
      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white),
                SizedBox(width: 10),
                Text('Redirecting to Google Auth via Supabase...'),
              ],
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else if (!success) {
        setState(() {
          _errorMessage = 'Google Sign-In failed. Please verify that the Google Auth provider is configured correctly in the Supabase Console.';
        });
      }
    } catch (e) {
      String errStr = e.toString().replaceAll('Exception: ', '');
      if (errStr.contains('provider is not enabled')) {
        errStr = 'Google Authentication is not enabled in your Supabase Dashboard. Please go to Auth -> Providers in your Supabase Console and enable Google.';
      }
      setState(() {
        _errorMessage = errStr;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(text: _signInEmailController.text.trim());
    bool isSending = false;
    String? resetError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLowest,
            title: const Row(
              children: [
                Icon(Icons.lock_reset_rounded, color: AppColors.primary, size: 24),
                SizedBox(width: 10),
                Text('Reset Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter your registered email address to receive password reset instructions.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: resetEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: const Icon(Icons.email_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                if (resetError != null) ...[
                  const SizedBox(height: 10),
                  Text(resetError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSending ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSending
                    ? null
                    : () async {
                        final email = resetEmailController.text.trim();
                        if (email.isEmpty) {
                          setDialogState(() => resetError = 'Please enter an email address.');
                          return;
                        }
                        setDialogState(() {
                          isSending = true;
                          resetError = null;
                        });
                        try {
                          await _authService.sendPasswordResetEmail(email);
                          if (ctx.mounted) {
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Password reset link sent to $email'),
                                backgroundColor: Colors.green.shade700,
                              ),
                            );
                          }
                        } catch (err) {
                          setDialogState(() {
                            isSending = false;
                            resetError = err.toString().replaceAll('Exception: ', '');
                          });
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Send Reset Link'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEmailVerificationDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLowest,
          title: const Row(
            children: [
              Icon(Icons.mark_email_read_rounded, color: AppColors.primary, size: 28),
              SizedBox(width: 12),
              Text(
                'Verify Your Email',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'A confirmation email has been sent to:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                email,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              const Text(
                'Please click the verification link in the email to activate your account. If you do not see it, please check your spam folder.',
                style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                // Switch to Sign In tab
                _tabController.animateTo(0);
                // Prefill the sign in email
                _signInEmailController.text = email;
                _signInPasswordController.clear();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text('Okay, Got it!'),
            ),
          ],
        );
      },
    );
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
    required bool isDark,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.black38),
      labelStyle: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87),
      prefixIcon: Icon(prefixIcon, size: 20, color: AppColors.primary),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSignUp = _tabController.index == 1;
    final tabLabel = isSignUp ? 'Create Account' : 'Sign In';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
      elevation: 16,
      child: Container(
        width: 440,
        constraints: const BoxConstraints(maxWidth: 440),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.15),
                          AppColors.secondary.withValues(alpha: 0.15),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.two_wheeler_rounded, color: AppColors.primary, size: 26),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PassOn Ride',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19, letterSpacing: -0.3),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Secure Supabase Authentication',
                          style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22),
                    tooltip: 'Close',
                    splashRadius: 20,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Segmented Tab Switcher
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    color: AppColors.primary,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  labelColor: Colors.white,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  tabs: const [
                    Tab(height: 40, text: 'Sign In'),
                    Tab(height: 40, text: 'Sign Up'),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Error Banner
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 18, color: Colors.redAccent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),

              // Success Banner
              if (_successMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 18, color: Colors.green),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),

              // Tab Contents via TabBarView
              SizedBox(
                height: isSignUp ? 350 : 185,
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildSignInFields(isDark),
                    _buildSignUpFields(isDark),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Main Submit Button (Sign In / Sign Up)
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleEmailAuth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          tabLabel,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.2),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // OR Divider
              Row(
                children: [
                  Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.grey.shade300, thickness: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white38 : Colors.black38,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.grey.shade300, thickness: 1)),
                ],
              ),

              const SizedBox(height: 14),

              // Continue with Google Auth Button
              SizedBox(
                height: 46,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _handleGoogleAuth,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: isDark ? Colors.white12 : Colors.grey.shade300,
                      width: 1.2,
                    ),
                    backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Google 'G' stylized badge
                      Container(
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? Colors.white : Colors.transparent,
                        ),
                        child: const Text(
                          'G',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: Color(0xFF4285F4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Continue with Google',
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF1F2937),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Footer info
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield_outlined, size: 13, color: isDark ? Colors.white38 : Colors.grey.shade500),
                  const SizedBox(width: 5),
                  Text(
                    'End-to-End Encrypted • Powered by Supabase',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignInFields(bool isDark) {
    return Column(
      key: const ValueKey('sign_in_fields'),
      children: [
        TextField(
          controller: _signInEmailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: _buildInputDecoration(
            labelText: 'Email Address',
            hintText: 'Enter your email',
            prefixIcon: Icons.email_outlined,
            isDark: isDark,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _signInPasswordController,
          obscureText: _obscureSignInPassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _handleEmailAuth(),
          decoration: _buildInputDecoration(
            labelText: 'Password',
            hintText: '••••••••',
            prefixIcon: Icons.lock_outline_rounded,
            isDark: isDark,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureSignInPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
              tooltip: _obscureSignInPassword ? 'Show password' : 'Hide password',
              splashRadius: 18,
              onPressed: () {
                setState(() => _obscureSignInPassword = !_obscureSignInPassword);
              },
            ),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _showForgotPasswordDialog,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              visualDensity: VisualDensity.compact,
            ),
            child: const Text(
              'Forgot Password?',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpFields(bool isDark) {
    return Column(
      key: const ValueKey('sign_up_fields'),
      children: [
        TextField(
          controller: _signUpNameController,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: _buildInputDecoration(
            labelText: 'Full Name',
            hintText: 'e.g. Rahul Sharma',
            prefixIcon: Icons.person_outline_rounded,
            isDark: isDark,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _signUpEmailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: _buildInputDecoration(
            labelText: 'Email Address',
            hintText: 'name@example.com',
            prefixIcon: Icons.email_outlined,
            isDark: isDark,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _signUpPasswordController,
          obscureText: _obscureSignUpPassword,
          textInputAction: TextInputAction.next,
          decoration: _buildInputDecoration(
            labelText: 'Password',
            hintText: 'Minimum 6 characters',
            prefixIcon: Icons.lock_outline_rounded,
            isDark: isDark,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureSignUpPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
              tooltip: _obscureSignUpPassword ? 'Show password' : 'Hide password',
              splashRadius: 18,
              onPressed: () {
                setState(() => _obscureSignUpPassword = !_obscureSignUpPassword);
              },
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _signUpConfirmPasswordController,
          obscureText: _obscureSignUpConfirmPassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _handleEmailAuth(),
          decoration: _buildInputDecoration(
            labelText: 'Confirm Password',
            hintText: 'Re-enter password',
            prefixIcon: Icons.lock_reset_rounded,
            isDark: isDark,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureSignUpConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
              tooltip: _obscureSignUpConfirmPassword ? 'Show password' : 'Hide password',
              splashRadius: 18,
              onPressed: () {
                setState(() => _obscureSignUpConfirmPassword = !_obscureSignUpConfirmPassword);
              },
            ),
          ),
        ),
      ],
    );
  }
}
