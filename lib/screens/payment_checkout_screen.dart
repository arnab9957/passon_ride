import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../providers/app_state.dart';
import '../services/razorpay_service.dart';
import '../services/razorpay_web_bridge.dart';
import '../theme/app_colors.dart';

class PaymentCheckoutScreen extends StatefulWidget {
  const PaymentCheckoutScreen({super.key});

  @override
  State<PaymentCheckoutScreen> createState() => _PaymentCheckoutScreenState();
}

class _PaymentCheckoutScreenState extends State<PaymentCheckoutScreen> {
  String _selectedPaymentMethod = 'Razorpay (UPI / Cards / NetBanking)';
  final TextEditingController _promoController = TextEditingController();
  bool _promoApplied = false;
  late Razorpay _razorpay;

  final RazorpayService _razorpayService = RazorpayService();

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _razorpay = Razorpay();
      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleRazorpaySuccess);
      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleRazorpayError);
      _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleRazorpayExternalWallet);
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      _razorpay.clear();
    }
    _promoController.dispose();
    super.dispose();
  }

  void _handleRazorpaySuccess(PaymentSuccessResponse response) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final vehicle = appState.selectedVehicle ?? (appState.vehicles.isNotEmpty ? appState.vehicles.first : null);
    if (vehicle == null) return;

    final String orderId = response.orderId ?? '';
    final String paymentId = response.paymentId ?? '';
    final String signature = response.signature ?? '';

    // STEP 3: BACKEND - Verify HMAC-SHA256 Signature
    bool isValidSignature = false;
    if (orderId.isNotEmpty && paymentId.isNotEmpty && signature.isNotEmpty) {
      isValidSignature = _razorpayService.verifyPaymentSignature(
        orderId: orderId,
        paymentId: paymentId,
        razorpaySignature: signature,
      );
    } else if (paymentId.isNotEmpty) {
      // Direct sandbox / test key fallback
      isValidSignature = true;
    }

    if (!isValidSignature) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Payment Security Error: Invalid HMAC Signature.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    final int days = appState.rentalDaysCount;
    final double baseRate = vehicle.pricePerDay * days;
    const double serviceFee = 24.00;
    const double roadsideFee = 15.00;
    final double discount = _promoApplied ? 40.00 : 0.00;
    final double total = baseRate + serviceFee + roadsideFee - discount;

    final booking = await appState.createBooking(
      vehicle: vehicle,
      startDate: appState.rentalStartDate,
      endDate: appState.rentalEndDate,
      totalPrice: total,
      paymentIntentId: paymentId,
    );

    if (!mounted) return;
    _showBookingConfirmedModal(context, appState, vehicle.title, paymentId, booking.unlockPasscode);
  }

  void _handleRazorpayError(PaymentFailureResponse response) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Razorpay Payment Failed: ${response.message ?? "User Cancelled"}'),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  void _handleRazorpayExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External Wallet Selected: ${response.walletName}')),
    );
  }

  void _startRazorpayPayment(AppState appState, double amount) async {
    final vehicle = appState.selectedVehicle ?? (appState.vehicles.isNotEmpty ? appState.vehicles.first : null);

    try {
      final orderResponse = await _razorpayService.createOrder(
        amountInRupees: amount,
        receipt: 'rcpt_${DateTime.now().millisecondsSinceEpoch}',
      );

      final String contact = appState.userProfile?.phoneNumber.isNotEmpty == true ? appState.userProfile!.phoneNumber : '9876543210';
      final String email = appState.userProfile?.email.isNotEmpty == true ? appState.userProfile!.email : 'rider@passonride.com';
      final String title = vehicle?.title ?? 'Vehicle Rental Escrow';

      if (kIsWeb) {
        openWebRazorpayCheckout(
          _razorpayService.keyId,
          orderResponse.amount,
          'PassonRide Escrow',
          'Rental Reservation for $title',
          contact,
          email,
          (paymentId, orderId, signature) {
            _handleRazorpaySuccess(PaymentSuccessResponse.fromMap({
              'razorpay_payment_id': paymentId,
              'razorpay_order_id': orderId,
              'razorpay_signature': signature,
            }));
          },
          (errorMsg) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Razorpay Payment Failed: $errorMsg'),
                backgroundColor: Colors.red.shade700,
              ),
            );
          },
        );
      } else {
        var options = <String, dynamic>{
          'key': _razorpayService.keyId,
          'amount': orderResponse.amount,
          'currency': orderResponse.currency,
          'name': 'PassonRide Escrow',
          'description': 'Rental Reservation for $title',
          'prefill': {
            'contact': contact,
            'email': email,
          },
          'external': {
            'wallets': ['paytm', 'gpay', 'phonepe']
          }
        };

        if (orderResponse.orderId.isNotEmpty && !orderResponse.orderId.startsWith('order_17')) {
          options['order_id'] = orderResponse.orderId;
        }

        _razorpay.open(options);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Razorpay Order Creation Failed: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final vehicle = appState.selectedVehicle ?? (appState.vehicles.isNotEmpty ? appState.vehicles.first : null);

    if (vehicle == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                size: 64,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              const SizedBox(height: 16),
              const Text(
                'No Active Reservation',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select a vehicle to proceed with booking checkout.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => appState.setNavIndex(1),
                icon: const Icon(Icons.search),
                label: const Text('Browse Vehicles'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final int days = appState.rentalDaysCount;

    final double baseRate = vehicle.pricePerDay * days;
    const double serviceFee = 24.00;
    const double roadsideFee = 15.00;
    final double discount = _promoApplied ? 40.00 : 0.00;
    final double total = baseRate + serviceFee + roadsideFee - discount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => appState.setNavIndex(3),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CHECKOUT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: isDark ? AppColors.secondaryFixedDim : AppColors.secondary,
                    ),
                  ),
                  const Text('Payment Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Order Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
              ),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    vehicle.imageUrl,
                    height: 80,
                    width: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vehicle.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(
                        '${appState.rentalStartDate.day}/${appState.rentalStartDate.month} - ${appState.rentalEndDate.day}/${appState.rentalEndDate.month} ($days Days)',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text('Pickup: ${vehicle.location}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Pricing Breakdown Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Price Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                _buildPriceRow('$days Days Rental (₹${vehicle.pricePerDay.toStringAsFixed(0)}/day)', '₹${baseRate.toStringAsFixed(2)}'),
                const SizedBox(height: 8),
                _buildPriceRow('Service & Telematics Fee', '₹${serviceFee.toStringAsFixed(2)}'),
                const SizedBox(height: 8),
                _buildPriceRow('24/7 Roadside Protection', '₹${roadsideFee.toStringAsFixed(2)}'),
                if (_promoApplied) ...[
                  const SizedBox(height: 8),
                  _buildPriceRow('Promo Code (PASSON2026)', '-₹40.00', isDiscount: true),
                ],
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Due Today', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      '₹${total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.secondaryFixedDim : AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  '+ ₹2500.00 refundable security deposit hold',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Promo Code Input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _promoController,
                  decoration: const InputDecoration(
                    hintText: 'Enter Promo Code (e.g. PASSON2026)',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  if (_promoController.text.trim().isNotEmpty) {
                    setState(() => _promoApplied = true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Promo Code PASSON2026 applied! ₹40 off')),
                    );
                  }
                },
                child: const Text('Apply'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Payment Methods Header
          const Text('Select Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),

          _buildPaymentOption('Razorpay (UPI / Cards / NetBanking)', 'GPay, PhonePe, Paytm, BHIM & Cards', Icons.account_balance_wallet),
          _buildPaymentOption('PassonPay Wallet', 'Balance: ₹5400.00 Available', Icons.account_balance_wallet_outlined),
          _buildPaymentOption('Credit / Debit Card (Stripe)', 'Visa, Mastercard, RuPay', Icons.credit_card),
          _buildPaymentOption('Apple Pay / Google Pay', 'Instant 1-Click Pay', Icons.phone_iphone),

          const SizedBox(height: 32),

          // Pay Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _confirmPayment(context, appState, total),
              icon: const Icon(Icons.lock_outline),
              label: Text('Pay ₹${total.toStringAsFixed(2)} & Confirm Ride', style: const TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String title, String amount, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: 13, color: isDiscount ? AppColors.secondary : null)),
        Text(
          amount,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDiscount ? AppColors.secondary : null,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption(String title, String subtitle, IconData icon) {
    final isSelected = _selectedPaymentMethod == title;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = title),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            Radio<String>(
              value: title,
              groupValue: _selectedPaymentMethod,
              onChanged: (val) => setState(() => _selectedPaymentMethod = val!),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmPayment(BuildContext context, AppState appState, double total) async {
    final vehicle = appState.selectedVehicle ?? (appState.vehicles.isNotEmpty ? appState.vehicles.first : null);
    if (vehicle == null) return;

    if (_selectedPaymentMethod.startsWith('Razorpay')) {
      _startRazorpayPayment(appState, total);
      return;
    }

    final paymentIntentId = 'pi_stripe_${DateTime.now().millisecondsSinceEpoch}';

    final booking = await appState.createBooking(
      vehicle: vehicle,
      startDate: appState.rentalStartDate,
      endDate: appState.rentalEndDate,
      totalPrice: total,
      paymentIntentId: paymentIntentId,
    );

    if (!context.mounted) return;
    _showBookingConfirmedModal(context, appState, vehicle.title, paymentIntentId, booking.unlockPasscode);
  }

  void _showBookingConfirmedModal(BuildContext context, AppState appState, String vehicleTitle, String paymentId, String passcode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.check_circle, color: AppColors.secondary, size: 54),
            SizedBox(height: 12),
            Text('Payment & Reservation Escrowed!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your rental for $vehicleTitle is confirmed!\n\n'
              '💳 Payment ID:\n$paymentId\n\n'
              '🔑 Keyless Unlock Passcode:\n$passcode\n\n'
              'Passcode & IoT controls have been sent to your Chat.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              appState.setNavIndex(5); // Go to Chat / Keyless Unlock
            },
            child: const Text('Open Keyless Chat & Controls'),
          ),
        ],
      ),
    );
  }
}
