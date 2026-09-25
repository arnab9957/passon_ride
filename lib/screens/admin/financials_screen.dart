import 'package:flutter/material.dart';

class FinancialsScreen extends StatefulWidget {
  const FinancialsScreen({super.key});

  @override
  State<FinancialsScreen> createState() => _FinancialsScreenState();
}

class _FinancialsScreenState extends State<FinancialsScreen> {
  // In a real application, you would load financial data from Supabase, Stripe, Razorpay, etc.
  // For this implementation, we will use mock data to represent payouts and commissions.
  final List<Map<String, dynamic>> _payouts = [
    {'id': 'PO-1001', 'host': 'Alex Rivera', 'amount': 4500.0, 'status': 'Pending'},
    {'id': 'PO-1002', 'host': 'Sarah Jenkins', 'amount': 12000.0, 'status': 'Processed'},
    {'id': 'PO-1003', 'host': 'Mike Thompson', 'amount': 850.0, 'status': 'Pending'},
  ];

  void _markAsProcessed(int index) {
    setState(() {
      _payouts[index]['status'] = 'Processed';
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Payout ${_payouts[index]['id']} marked as processed.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text('Financials & Payouts', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        ),
        
        // Payouts List
        Expanded(
          child: ListView.builder(
            itemCount: _payouts.length,
            itemBuilder: (context, index) {
              final payout = _payouts[index];
              return ListTile(
                leading: const Icon(Icons.account_balance),
                title: Text('Payout ${payout['id']} - ${payout['host']}'),
                subtitle: Text('Amount: ₹${payout['amount']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Chip(
                      label: Text(payout['status'], style: const TextStyle(fontSize: 12)),
                      backgroundColor: payout['status'] == 'Processed' ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                    ),
                    if (payout['status'] == 'Pending') ...[
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => _markAsProcessed(index),
                        child: const Text('Mark Processed'),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
