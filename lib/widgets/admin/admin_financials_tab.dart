import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import 'admin_metric_card.dart';

class AdminFinancialsTab extends StatefulWidget {
  final List<PaymentTransaction> transactions;

  const AdminFinancialsTab({
    super.key,
    required this.transactions,
  });

  @override
  State<AdminFinancialsTab> createState() => _AdminFinancialsTabState();
}

class _AdminFinancialsTabState extends State<AdminFinancialsTab> {
  String _searchQuery = '';
  String _selectedStatusFilter = 'All';

  List<PaymentTransaction> get _filteredTransactions {
    return widget.transactions.where((t) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          t.razorpayPaymentId.toLowerCase().contains(q) ||
          t.razorpayOrderId.toLowerCase().contains(q) ||
          t.bookingId.toLowerCase().contains(q) ||
          t.userId.toLowerCase().contains(q);

      final matchesStatus = _selectedStatusFilter == 'All' ||
          t.status.toLowerCase() == _selectedStatusFilter.toLowerCase();

      return matchesSearch && matchesStatus;
    }).toList();
  }

  void _showTransactionDetails(PaymentTransaction tx) {
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.receipt_long, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('Transaction #${tx.id.substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRow('Tx ID', tx.id),
              _buildRow('Razorpay Payment', tx.razorpayPaymentId),
              _buildRow('Razorpay Order', tx.razorpayOrderId),
              _buildRow('Booking ID', tx.bookingId.isNotEmpty ? tx.bookingId : 'Direct Topup / Escrow'),
              _buildRow('User ID', tx.userId),
              _buildRow('Amount', currencyFormatter.format(tx.amount)),
              _buildRow('Payment Status', tx.status.toUpperCase()),
              _buildRow('Payment Mode', tx.paymentMethod.toUpperCase()),
              _buildRow('Escrow State', tx.escrowStatus),
              _buildRow('Created Date', DateFormat('dd MMM yyyy, HH:mm:ss').format(tx.createdAt)),
              if (tx.errorCode != null && tx.errorCode!.isNotEmpty)
                _buildRow('Error Code', tx.errorCode!),
              if (tx.errorDescription != null && tx.errorDescription!.isNotEmpty)
                _buildRow('Error Details', tx.errorDescription!),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    final double capturedAmount = widget.transactions
        .where((t) => t.status.toLowerCase() == 'captured')
        .fold(0.0, (sum, t) => sum + t.amount);

    final double refundedAmount = widget.transactions
        .where((t) => t.status.toLowerCase() == 'refunded')
        .fold(0.0, (sum, t) => sum + t.amount);

    final double escrowHeldAmount = widget.transactions
        .where((t) => t.escrowStatus == 'held_in_escrow')
        .fold(0.0, (sum, t) => sum + t.amount);

    final filtered = _filteredTransactions;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Financial Summary KPI Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              return GridView.count(
                crossAxisCount: isWide ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: isWide ? 1.8 : 1.6,
                children: [
                  AdminMetricCard(
                    title: 'Gross Settled Volume',
                    value: currencyFormatter.format(capturedAmount),
                    subtitle: '${widget.transactions.where((t) => t.status.toLowerCase() == "captured").length} captured payments',
                    icon: Icons.check_circle_outline,
                    accentColor: Colors.green.shade700,
                  ),
                  AdminMetricCard(
                    title: 'Held In Escrow',
                    value: currencyFormatter.format(escrowHeldAmount),
                    subtitle: 'Active security deposits',
                    icon: Icons.lock_clock,
                    accentColor: Colors.blue.shade700,
                  ),
                  AdminMetricCard(
                    title: 'Refunds Processed',
                    value: currencyFormatter.format(refundedAmount),
                    subtitle: '${widget.transactions.where((t) => t.status.toLowerCase() == "refunded").length} refunded payments',
                    icon: Icons.replay,
                    accentColor: Colors.purple.shade700,
                  ),
                  AdminMetricCard(
                    title: 'Estimated Margin (15%)',
                    value: currencyFormatter.format(capturedAmount * 0.15),
                    subtitle: 'Net platform commissions',
                    icon: Icons.account_balance,
                    accentColor: Colors.teal.shade700,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Search & Filter
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by Razorpay Payment ID, Order ID, User ID, or Booking ID...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    filled: true,
                    fillColor: isDark ? AppColors.surfaceContainerLowDark : Colors.white,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceContainerLowDark : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.outlineVariantDark : Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedStatusFilter,
                    items: ['All', 'captured', 'refunded', 'pending', 'failed'].map((st) {
                      return DropdownMenuItem(value: st, child: Text('Status: ${st.toUpperCase()}'));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedStatusFilter = val);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Transactions Ledger
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No payment transactions match this criteria.'))
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final tx = filtered[index];
                      final isCaptured = tx.status.toLowerCase() == 'captured';
                      final isRefunded = tx.status.toLowerCase() == 'refunded';

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceContainerLowDark : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppColors.outlineVariantDark : Colors.grey.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (isCaptured ? Colors.green : (isRefunded ? Colors.purple : Colors.orange)).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isCaptured ? Icons.credit_score : (isRefunded ? Icons.replay : Icons.error_outline),
                                color: isCaptured ? Colors.green : (isRefunded ? Colors.purple : Colors.orange),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        tx.razorpayPaymentId.isNotEmpty ? tx.razorpayPaymentId : 'Payment #${tx.id.substring(0, 8)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildStatusBadge(tx.status),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          tx.paymentMethod.toUpperCase(),
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Order: ${tx.razorpayOrderId} • Booking: ${tx.bookingId.isNotEmpty ? tx.bookingId : "Direct"}',
                                    style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Escrow: ${tx.escrowStatus} • ${DateFormat('dd MMM yyyy, HH:mm').format(tx.createdAt)}',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  currencyFormatter.format(tx.amount),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isCaptured ? Colors.green.shade700 : (isRefunded ? Colors.purple : null),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                IconButton(
                                  icon: const Icon(Icons.info_outline, size: 18),
                                  tooltip: 'Details',
                                  onPressed: () => _showTransactionDetails(tx),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    switch (status.toLowerCase()) {
      case 'captured':
        bg = Colors.green.withValues(alpha: 0.15);
        fg = Colors.green.shade700;
        break;
      case 'refunded':
        bg = Colors.purple.withValues(alpha: 0.15);
        fg = Colors.purple.shade700;
        break;
      case 'failed':
        bg = Colors.red.withValues(alpha: 0.15);
        fg = Colors.red.shade700;
        break;
      default:
        bg = Colors.orange.withValues(alpha: 0.15);
        fg = Colors.orange.shade800;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg)),
    );
  }
}
