import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';

class BookingVerificationScreen extends StatefulWidget {
  const BookingVerificationScreen({super.key});

  @override
  State<BookingVerificationScreen> createState() => _BookingVerificationScreenState();
}

class _BookingVerificationScreenState extends State<BookingVerificationScreen> {
  bool _agreedToTerms = true;
  bool _selfieVerified = true;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => appState.setNavIndex(2),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BOOKING SAFETY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: isDark ? AppColors.secondaryFixedDim : AppColors.secondary,
                    ),
                  ),
                  const Text('Verification Checklist', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Progress indicator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Verification Status', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('4/4 Steps Completed', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: const LinearProgressIndicator(
                    value: 1.0,
                    minHeight: 8,
                    backgroundColor: Colors.black12,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Step 1 Card: ID Check
          _buildStepTile(
            context: context,
            stepNum: '1',
            title: 'Driver License & Identity Scan',
            subtitle: 'California Driver License #DL-948102 (Verified)',
            isDone: true,
            icon: Icons.badge,
          ),

          const SizedBox(height: 12),

          // Step 2 Card: Security Deposit
          _buildStepTile(
            context: context,
            stepNum: '2',
            title: 'Security Deposit Pre-authorization',
            subtitle: '₹2500.00 refundable deposit hold via PassonPay/UPI',
            isDone: true,
            icon: Icons.lock_clock,
          ),

          const SizedBox(height: 12),

          // Step 3 Card: Agreement Sign
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const Text('3', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('P2P Rental Contract & Terms', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('Standard peer-to-peer liability policy', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const Icon(Icons.check_circle, color: AppColors.secondary),
                  ],
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _agreedToTerms,
                  onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
                  title: const Text(
                    'I agree to the PassonRide vehicle usage policy, telemetry monitoring rules, and return condition terms.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Step 4 Card: Live Selfie Scan
          _buildStepTile(
            context: context,
            stepNum: '4',
            title: 'Biometric Selfie Check',
            subtitle: 'Biometric liveness check matched profile photo (100% Match)',
            isDone: _selfieVerified,
            icon: Icons.face,
          ),

          const SizedBox(height: 32),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _agreedToTerms
                  ? () => appState.setNavIndex(4) // Go to Payment Checkout
                  : null,
              child: const Text('Continue to Payment Checkout', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStepTile({
    required BuildContext context,
    required String stepNum,
    required String title,
    required String subtitle,
    required bool isDone,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDone ? AppColors.secondaryContainer : AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Text(
              stepNum,
              style: TextStyle(
                color: isDone ? AppColors.onSecondaryContainer : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          if (isDone)
            const Icon(Icons.check_circle, color: AppColors.secondary)
          else
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}
