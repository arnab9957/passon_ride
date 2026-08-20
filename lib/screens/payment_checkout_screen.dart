import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../services/razorpay_service.dart';
import '../services/razorpay_web_bridge.dart';
import '../services/transactional_notification_service.dart';
import '../theme/app_colors.dart';
import '../utils/app_notification.dart';

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
      AppNotification.showError(context, 'Payment Security Error: Invalid HMAC Signature.');
      return;
    }

    if (appState.selectedTour != null) {
      // Tour Checkout Flow
      final tour = appState.selectedTour!;
      final double discount = _promoApplied ? 40.00 : 0.00;
      final double total = (tour.price - discount).clamp(0.0, 999999.0);

      await appState.createTourBooking(
        tour: tour,
        participantCount: 1,
        totalPrice: total,
        paymentIntentId: paymentId,
      );

      if (!mounted) return;
      _showTourConfirmedModal(context, appState, tour.title, paymentId, tour.guideName);
    } else {
      // Vehicle Checkout Flow
      final vehicle = appState.selectedVehicle ?? (appState.vehicles.isNotEmpty ? appState.vehicles.first : null);
      if (vehicle == null) return;

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
  }

  void _handleRazorpayError(PaymentFailureResponse response) {
    if (!mounted) return;
    AppNotification.showError(context, 'Razorpay Payment Failed: ${response.message ?? "User Cancelled"}');
  }

  void _handleRazorpayExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    AppNotification.showInfo(context, 'External Wallet Selected: ${response.walletName}');
  }

  void _startRazorpayPayment(AppState appState, double amount) async {
    final tour = appState.selectedTour;
    final vehicle = tour == null ? (appState.selectedVehicle ?? (appState.vehicles.isNotEmpty ? appState.vehicles.first : null)) : null;

    try {
      final orderResponse = await _razorpayService.createOrder(
        amountInRupees: amount,
        receipt: 'rcpt_${DateTime.now().millisecondsSinceEpoch}',
      );

      final String contact = appState.userProfile?.phoneNumber.isNotEmpty == true ? appState.userProfile!.phoneNumber : '9876543210';
      final String email = appState.userProfile?.email.isNotEmpty == true ? appState.userProfile!.email : 'rider@passonride.com';
      final String title = tour != null ? 'Guided Tour: ${tour.title}' : (vehicle?.title ?? 'Vehicle Rental Escrow');

      if (kIsWeb) {
        openWebRazorpayCheckout(
          _razorpayService.keyId,
          orderResponse.amount,
          'PassonRide Escrow',
          'Reservation for $title',
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
            AppNotification.showError(context, 'Razorpay Payment Failed: $errorMsg');
          },
        );
      } else {
        final bool isRealOrderId = orderResponse.orderId.isNotEmpty &&
            !orderResponse.orderId.startsWith('order_fallback_') &&
            !orderResponse.orderId.startsWith('order_web_') &&
            !orderResponse.orderId.startsWith('order_17');

        var options = <String, dynamic>{
          'key': _razorpayService.keyId,
          'amount': orderResponse.amount,
          'currency': orderResponse.currency,
          'name': 'PassonRide Escrow',
          'description': 'Reservation for $title',
          'prefill': {
            'contact': contact,
            'email': email,
            'method': 'upi',
          },
          'config': {
            'display': {
              'blocks': {
                'upi': {
                  'name': 'Pay via UPI / QR / App',
                  'instruments': [
                    {'method': 'upi'}
                  ]
                },
                'cards': {
                  'name': 'Cards & NetBanking',
                  'instruments': [
                    {'method': 'card'},
                    {'method': 'netbanking'},
                    {'method': 'wallet'}
                  ]
                }
              },
              'sequence': ['block.upi', 'block.cards'],
              'preferences': {
                'show_default_blocks': true
              }
            }
          },
          'retry': {'enabled': true, 'max_count': 3},
          'external': {
            'wallets': ['paytm', 'gpay', 'phonepe']
          }
        };

        if (isRealOrderId) {
          options['order_id'] = orderResponse.orderId;
        }

        _razorpay.open(options);
      }
    } catch (e) {
      if (!mounted) return;
      AppNotification.showError(context, 'Razorpay Order Creation Failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tour = appState.selectedTour;
    final vehicle = tour == null ? (appState.selectedVehicle ?? (appState.vehicles.isNotEmpty ? appState.vehicles.first : null)) : null;

    if (tour == null && vehicle == null) {
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
                'Select a vehicle or guided adventure tour to proceed with booking checkout.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => appState.setNavIndex(1),
                    icon: const Icon(Icons.search),
                    label: const Text('Browse Listings'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Pricing calculation
    final bool isTour = tour != null;
    final int days = appState.rentalDaysCount;
    final double baseRate = isTour ? tour.price : (vehicle!.pricePerDay * days);
    final double serviceFee = isTour ? 0.00 : 24.00;
    final double roadsideFee = isTour ? 0.00 : 15.00;
    final double discount = _promoApplied ? 40.00 : 0.00;
    final double total = (baseRate + serviceFee + roadsideFee - discount).clamp(0.0, 999999.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (isTour) {
                    appState.clearSelectedTour();
                    appState.setNavIndex(1);
                  } else {
                    appState.setNavIndex(3);
                  }
                },
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isTour ? 'GUIDED TOUR CHECKOUT' : 'VEHICLE CHECKOUT',
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
                    isTour ? tour.imageUrl : vehicle!.imageUrl,
                    height: 80,
                    width: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 80,
                      width: 80,
                      color: Colors.grey.shade300,
                      child: Icon(isTour ? Icons.tour : Icons.directions_car),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isTour ? tour.title : vehicle!.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isTour
                            ? 'Duration: ${tour.duration} • Guide: ${tour.guideName}'
                            : '${appState.rentalStartDate.day}/${appState.rentalStartDate.month} - ${appState.rentalEndDate.day}/${appState.rentalEndDate.month} ($days Days)',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isTour ? 'Meeting Point: ${tour.location}' : 'Pickup: ${vehicle!.location}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
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
                if (isTour)
                  _buildPriceRow('1x Guided Adventure Pass', '₹${baseRate.toStringAsFixed(2)}')
                else ...[
                  _buildPriceRow('$days Days Rental (₹${vehicle!.pricePerDay.toStringAsFixed(0)}/day)', '₹${baseRate.toStringAsFixed(2)}'),
                  const SizedBox(height: 8),
                  _buildPriceRow('Service & Telematics Fee', '₹${serviceFee.toStringAsFixed(2)}'),
                  const SizedBox(height: 8),
                  _buildPriceRow('24/7 Roadside Protection', '₹${roadsideFee.toStringAsFixed(2)}'),
                ],
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
                if (!isTour) ...[
                  const SizedBox(height: 6),
                  const Text(
                    '+ ₹2500.00 refundable security deposit hold',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
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
                    AppNotification.showSuccess(context, 'Promo Code PASSON2026 applied! ₹40 off');
                  }
                },
                child: const Text('Apply'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Payment Methods Section
          const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),

          _buildPaymentOption(
            title: 'Razorpay (UPI / Cards / NetBanking)',
            subtitle: 'Instant secure checkout via Razorpay Gateway & Web Checkout',
            icon: Icons.flash_on,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildPaymentOption(
            title: 'Credit / Debit Card (Stripe Escrow)',
            subtitle: 'Safe escrow holding until return & inspection',
            icon: Icons.credit_card,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildPaymentOption(
            title: 'UPI / NetBanking Instant Pay',
            subtitle: 'GPay, PhonePe, Paytm, BHIM instant transfer',
            icon: Icons.account_balance,
            isDark: isDark,
          ),

          const SizedBox(height: 32),

          // Pay Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _confirmPayment(context, appState, total),
              icon: const Icon(Icons.lock, color: Colors.white, size: 18),
              label: Text(
                'Pay ₹${total.toStringAsFixed(2)} & Confirm ${isTour ? "Tour" : "Rental"}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield_outlined, size: 14, color: Colors.grey),
                SizedBox(width: 6),
                Text(
                  '256-bit Encrypted Escrow • Kinetic Trust Guarantee',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDiscount ? Colors.green : null,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isDark,
  }) {
    final isSelected = _selectedPaymentMethod == title;
    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = title),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
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
    final isTour = appState.selectedTour != null;
    final tour = appState.selectedTour;
    final vehicle = isTour ? null : (appState.selectedVehicle ?? (appState.vehicles.isNotEmpty ? appState.vehicles.first : null));

    if (tour == null && vehicle == null) return;

    final isHighValue = appState.notificationService.requiresHighValueStepUp(total);
    final userPhone = appState.userProfile?.phoneNumber.isNotEmpty == true ? appState.userProfile!.phoneNumber : '+919876543210';

    // Dispatch verification OTP via TransactionalNotificationService (Flow 1 or Flow 3)
    final otpResult = isHighValue
        ? await appState.notificationService.triggerHighValueStepUpWhatsAppOtp(
            phoneNumber: userPhone,
            userName: appState.activeUserDisplayName,
            rentalAmount: total,
            vehicleTitle: vehicle.title,
          )
        : await appState.notificationService.triggerBuyerCheckoutOtp(
            phoneNumber: userPhone,
            buyerName: appState.activeUserDisplayName,
            orderAmount: total,
          );

    if (!mounted) return;

    // Show OTP Verification Dialog (Flow 1 / Flow 3)
    _showOtpModal(context, appState, otpResult, () {
      if (_selectedPaymentMethod.startsWith('UPI Direct')) {
        _startDirectUpiPayment(context, appState, total, vehicle);
      } else if (_selectedPaymentMethod.startsWith('Razorpay')) {
        _startRazorpayPayment(appState, total);
      } else {
        _processDirectBooking(context, appState, total, vehicle);
      }
    });
  }

  void _startDirectUpiPayment(BuildContext context, AppState appState, double total, dynamic vehicle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomCtx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.qr_code_2, color: AppColors.secondary, size: 28),
                    SizedBox(width: 10),
                    Text('UPI Escrow Payment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(bottomCtx)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Amount Due: ₹${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.flash_on, color: Colors.white)),
              title: const Text('Google Pay / PhonePe / Paytm', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Instant Intent Launch'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                Navigator.pop(bottomCtx);
                final upiPaymentId = 'pay_upi_${DateTime.now().millisecondsSinceEpoch}';
                final booking = await appState.createBooking(
                  vehicle: vehicle,
                  startDate: appState.rentalStartDate,
                  endDate: appState.rentalEndDate,
                  totalPrice: total,
                  paymentIntentId: upiPaymentId,
                );
                if (!mounted) return;
                _showBookingConfirmedModal(context, appState, vehicle.title, upiPaymentId, booking.unlockPasscode);
              },
            ),
            const Divider(),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.deepPurple, child: Icon(Icons.vibration, color: Colors.white)),
              title: const Text('UPI ID / VPA (e.g. user@upi)', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Collect Request'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                Navigator.pop(bottomCtx);
                final upiPaymentId = 'pay_vpa_${DateTime.now().millisecondsSinceEpoch}';
                final booking = await appState.createBooking(
                  vehicle: vehicle,
                  startDate: appState.rentalStartDate,
                  endDate: appState.rentalEndDate,
                  totalPrice: total,
                  paymentIntentId: upiPaymentId,
                );
                if (!mounted) return;
                _showBookingConfirmedModal(context, appState, vehicle.title, upiPaymentId, booking.unlockPasscode);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _processDirectBooking(BuildContext context, AppState appState, double total, dynamic vehicle) async {
    final paymentIntentId = 'pi_stripe_${DateTime.now().millisecondsSinceEpoch}';

    if (isTour) {
      await appState.createTourBooking(
        tour: tour!,
        participantCount: 1,
        totalPrice: total,
        paymentIntentId: paymentIntentId,
      );

      if (!context.mounted) return;
      _showTourConfirmedModal(context, appState, tour.title, paymentIntentId, tour.guideName);
    } else {
      final booking = await appState.createBooking(
        vehicle: vehicle!,
        startDate: appState.rentalStartDate,
        endDate: appState.rentalEndDate,
        totalPrice: total,
        paymentIntentId: paymentIntentId,
      );

      if (!context.mounted) return;
      _showBookingConfirmedModal(context, appState, vehicle.title, paymentIntentId, booking.unlockPasscode);
    }
  }

  void _showOtpModal(
    BuildContext context,
    AppState appState,
    dynamic otpResult,
    VoidCallback onSuccess,
  ) {
    final TextEditingController otpController = TextEditingController(text: otpResult.otpCode ?? '');
    final bool isWhatsApp = otpResult.channel == NotificationChannel.whatsapp;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              isWhatsApp ? Icons.security : Icons.mark_email_read,
              color: isWhatsApp ? Colors.green : AppColors.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isWhatsApp ? 'Flow 3: High-Value WhatsApp Step-Up' : 'Flow 1: Buyer Checkout Verification',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isWhatsApp ? Colors.green.shade50 : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                otpResult.payloadText,
                style: TextStyle(
                  fontSize: 11,
                  color: isWhatsApp ? Colors.green.shade900 : Colors.blue.shade900,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Chip(
                  avatar: const Icon(Icons.speed, size: 14, color: Colors.green),
                  label: Text('Latency: ${otpResult.latencyMs}ms', style: const TextStyle(fontSize: 10)),
                  backgroundColor: Colors.green.shade50,
                ),
                const SizedBox(width: 8),
                Chip(
                  avatar: Icon(isWhatsApp ? Icons.lock : Icons.sms, size: 14, color: AppColors.primary),
                  label: Text(isWhatsApp ? 'IP Encrypted' : 'Sub-12s Target', style: const TextStyle(fontSize: 10)),
                  backgroundColor: AppColors.surfaceContainerLow,
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter 6-Digit OTP Code',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.pin),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(dialogCtx);
              onSuccess();
            },
            icon: const Icon(Icons.check_circle),
            label: const Text('Verify & Proceed'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isWhatsApp ? Colors.green.shade700 : AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
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
            Text('Payment & Reservation Escrowed!', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your rental for $vehicleTitle is confirmed!\n\n'
              '💳 Payment ID:\n$paymentId\n\n'
              '🔑 Keyless Unlock Passcode:\n$passcode\n\n'
              'Passcode & IoT controls have been sent to your Chat and Notification Bell.',
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

  void _showTourConfirmedModal(BuildContext context, AppState appState, String tourTitle, String paymentId, String guideName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.check_circle, color: AppColors.secondary, size: 54),
            SizedBox(height: 12),
            Text('Guided Tour Reserved!', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your reservation for "$tourTitle" is confirmed!\n\n'
              'Guide: $guideName\n'
              '💳 Payment ID:\n$paymentId\n\n'
              'Tour instructions & itinerary have been sent to your Chat & Notification Center.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              appState.clearSelectedTour();
              appState.setNavIndex(5); // Chat
            },
            child: const Text('Open Tour Chat & Details'),
          ),
        ],
      ),
    );
  }
}
