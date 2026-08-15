import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

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
                onPressed: () => appState.setNavIndex(8), // Back to provider dashboard
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FINANCIALS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: isDark ? AppColors.secondaryFixedDim : AppColors.secondary,
                    ),
                  ),
                  const Text('Earnings & Revenue', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Balance Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [AppColors.surfaceContainerHighDark, AppColors.surfaceContainerDark]
                    : [AppColors.secondary, AppColors.onSecondaryContainer],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Available Balance for Withdrawal', style: TextStyle(fontSize: 12, color: Colors.white70)),
                const SizedBox(height: 6),
                Text(
                  '₹${appState.totalEarnings.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                const Text('+₹5800.00 currently processing from active rentals', style: TextStyle(fontSize: 11, color: Colors.white60)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    final amount = appState.totalEarnings;
                    if (amount > 0) {
                      appState.withdrawEarnings(amount);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Instant Payout of ₹${amount.toStringAsFixed(2)} initiated to HDFC Bank!'),
                          backgroundColor: Colors.green.shade700,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No available balance to withdraw.')),
                      );
                    }
                  },
                  icon: const Icon(Icons.account_balance, size: 18),
                  label: const Text('Instant Withdraw Funds'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Monthly Revenue Chart Simulation
          const Text('Monthly Earnings Trend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
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
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Aug 2026 Earnings: ₹48,200.00', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('Target: ₹50,000', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildBar('May', 0.5, '₹24k', isDark),
                    _buildBar('Jun', 0.7, '₹35k', isDark),
                    _buildBar('Jul', 0.85, '₹42k', isDark),
                    _buildBar('Aug', 0.96, '₹48k', isDark, isHighlighted: true),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Transaction Log Table
          const Text('Recent Rental Payouts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          _buildTxRow(context, 'Aug 12', 'BMW R1250 GS', 'David V.', '₹3,870.00', 'Completed'),
          _buildTxRow(context, 'Aug 10', 'Tesla Model 3', 'Sarah K.', '₹4,350.00', 'Completed'),
          _buildTxRow(context, 'Aug 06', 'Vespa Elettrica', 'Jason M.', '₹1,470.00', 'Completed'),
          _buildTxRow(context, 'Aug 02', 'Porsche 911', 'Robert L.', '₹8,850.00', 'Completed'),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildBar(String label, double pct, String val, bool isDark, {bool isHighlighted = false}) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isHighlighted ? AppColors.secondary : Colors.grey)),
        const SizedBox(height: 6),
        Container(
          height: 100 * pct,
          width: 28,
          decoration: BoxDecoration(
            color: isHighlighted
                ? AppColors.secondary
                : (isDark ? AppColors.surfaceContainerHighDark : AppColors.surfaceContainerHigh),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildTxRow(BuildContext context, String date, String vehicle, String renter, String net, String status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.secondaryContainer,
                child: Icon(Icons.arrow_downward, size: 16, color: AppColors.onSecondaryContainer),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$vehicle ($renter)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(date, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(net, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.secondary)),
              Text(status, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}
