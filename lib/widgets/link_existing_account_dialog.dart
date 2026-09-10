// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';

class LinkExistingAccountDialog extends StatefulWidget {
  const LinkExistingAccountDialog({super.key});

  @override
  State<LinkExistingAccountDialog> createState() => _LinkExistingAccountDialogState();
}

class _LinkExistingAccountDialogState extends State<LinkExistingAccountDialog> {
  final _emailController = TextEditingController();
  final _verifySecretController = TextEditingController();

  bool _isConfirmStep = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscureSecret = true;

  @override
  void dispose() {
    _emailController.dispose();
    _verifySecretController.dispose();
    super.dispose();
  }

  void _proceedToConfirmation() {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      setState(() => _errorMessage = 'Please enter a valid account email.');
      return;
    }

    final appState = Provider.of<AppState>(context, listen: false);

    if (email.toLowerCase() == appState.activeUserEmail.toLowerCase()) {
      setState(() => _errorMessage = 'Cannot link the active Mother account as a Child.');
      return;
    }

    if (appState.childProfiles.any((c) => c.email.toLowerCase() == email.toLowerCase())) {
      setState(() => _errorMessage = 'This account is already linked under your Mother Profile.');
      return;
    }

    if (appState.childProfiles.length >= 3) {
      setState(() => _errorMessage = 'You have reached the maximum limit of 3 child accounts.');
      return;
    }

    setState(() {
      _errorMessage = null;
      _isConfirmStep = true;
    });
  }

  Future<void> _handleConfirmLink() async {
    final appState = Provider.of<AppState>(context, listen: false);

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await appState.linkExistingAccount(
      childEmail: _emailController.text.trim(),
      passwordOrConfirmation: _verifySecretController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res.success && res.profile != null) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.link, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Account "${res.profile!.email}" successfully linked as Child Profile!'),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() {
        _errorMessage = res.error ?? 'Failed to link account.';
        _isConfirmStep = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceLight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.link_rounded, color: Colors.purple, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Link Existing Account',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Connect existing ID as Child Profile',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 12, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              if (!_isConfirmStep) ...[
                // Step 1: Input Form
                Text(
                  'Enter the email address of the existing independent account to link under this Mother ID.',
                  style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade300 : Colors.black87),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Child Account Email *',
                    hintText: 'child@example.com',
                    prefixIcon: const Icon(Icons.email_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: _verifySecretController,
                  obscureText: _obscureSecret,
                  decoration: InputDecoration(
                    labelText: 'Account Verification / Password *',
                    hintText: 'Verify account ownership',
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureSecret ? Icons.visibility_off : Icons.visibility, size: 18),
                      onPressed: () => setState(() => _obscureSecret = !_obscureSecret),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    helperText: 'Prevents unauthorized linking of third-party accounts',
                  ),
                ),
                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.teal.withOpacity(0.25)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_outlined, color: Colors.teal, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Preserves existing bookings, hosting history, and vehicle ownership intact without duplication.',
                          style: TextStyle(fontSize: 11, color: Colors.teal),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _proceedToConfirmation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Next  →'),
                    ),
                  ],
                ),
              ] else ...[
                // Step 2: Confirmation Screen (Requirement 12)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceContainerLowestDark : AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'Link this account?',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Child Account:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
                      ),
                      Text(
                        _emailController.text.trim(),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.purple),
                      ),
                      const Divider(height: 20),
                      const Text(
                        'Mother Account:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
                      ),
                      Text(
                        appState.activeUserEmail,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '• The child account will retain independent booking and hosting.\n'
                        '• The mother account will have limited booking visibility.\n'
                        '• All past bookings and vehicles are safely retained.',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => setState(() => _isConfirmStep = false),
                      child: const Text('Back'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleConfirmLink,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Confirm & Link'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
