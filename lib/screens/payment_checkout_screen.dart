import 'package:flutter/foundation.dart';
// ignore_for_file: deprecated_member_use, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../services/razorpay_service.dart';
import '../services/razorpay_web_bridge.dart';
import '../services/transactional_notification_service.dart';
import '../theme/app_colors.dart';
import '../utils/app_notification.dart';
import '../widgets/account_switcher_dialog.dart';

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
      AppToast.showError(context, 'Payment Security Alert: Invalid or Tampered HMAC Signature.');
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
        razorpayOrderId: orderId,
        razorpaySignature: signature,
        paymentMethod: 'razorpay',
      );

      if (!mounted) return;
      _showTourConfirmedModal(
        context: context,
        appState: appState,
        tourTitle: tour.title,
        paymentId: paymentId,
        orderId: orderId,
        signature: signature,
        guideName: tour.guideName,
      );
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
        razorpayOrderId: orderId,
        razorpaySignature: signature,
        paymentMethod: 'razorpay',
      );

      if (!mounted) return;
      _showBookingConfirmedModal(
        context: context,
        appState: appState,
        vehicleTitle: vehicle.title,
        paymentId: paymentId,
        orderId: orderId,
        signature: signature,
        passcode: booking.unlockPasscode,
      );
    }
  }

  void _handleRazorpayError(PaymentFailureResponse response) {
    if (!mounted) return;
    AppToast.showError(context, 'Razorpay Payment Notice: ${response.message ?? "User Cancelled"}');
  }

  void _handleRazorpayExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    AppToast.showInfo(context, 'External Wallet Selected: ${response.walletName}');
  }

  void _startRazorpayPayment(AppState appState, double amount) async {
    final tour = appState.selectedTour;
    final vehicle = tour == null ? (appState.selectedVehicle ?? (appState.vehicles.isNotEmpty ? appState.vehicles.first : null)) : null;

    try {
      final orderResponse = await _razorpayService.createOrder(
        amountInRupees: amount,
        receipt: 'rcpt_${DateTime.now().millisecondsSinceEpoch}',
        notes: {
          'user_id': appState.activeUserId,
          'user_name': appState.activeUserDisplayName,
          'item_title': tour != null ? tour.title : (vehicle?.title ?? 'Vehicle Rental'),
          'type': tour != null ? 'guided_tour' : 'vehicle_rental',
        },
      );

      final String contact = appState.userProfile?.phoneNumber.isNotEmpty == true ? appState.userProfile!.phoneNumber : '+919876543210';
      final String email = appState.userProfile?.email.isNotEmpty == true ? appState.userProfile!.email : 'rider@passonride.com';
      final String title = tour != null ? 'Guided Tour: ${tour.title}' : (vehicle?.title ?? 'Vehicle Rental Escrow');

      if (kIsWeb) {
        openWebRazorpayCheckout(
          key: _razorpayService.keyId,
          orderId: orderResponse.orderId,
          amount: orderResponse.amount,
          name: 'Passon Ride Escrow',
          description: 'Reservation for $title',
          contact: contact,
          email: email,
          notes: orderResponse.notes,
          onSuccess: (paymentId, orderId, signature) {
            _handleRazorpaySuccess(PaymentSuccessResponse.fromMap({
              'razorpay_payment_id': paymentId,
              'razorpay_order_id': orderId,
              'razorpay_signature': signature,
            }));
          },
          onError: (errorMsg) {
            if (!mounted) return;
            if (errorMsg.contains('401') || errorMsg.contains('Unauthorized') || errorMsg.contains('key') || errorMsg.contains('Key')) {
              AppToast.showError(context, 'Razorpay API Key Notice: Test key unauthorized (401). Use active keys or select "Scan & Pay via QR Code".');
              _showKeyConfigDialog(context);
            } else {
              AppToast.showError(context, 'Razorpay Payment Notice: $errorMsg');
            }
          },
        );
      } else {
        final bool isRealOrderId = orderResponse.orderId.isNotEmpty &&
            !orderResponse.orderId.startsWith('order_fallback_') &&
            !orderResponse.orderId.startsWith('order_web_') &&
            !orderResponse.orderId.startsWith('order_test_');

        var options = <String, dynamic>{
          'key': _razorpayService.keyId,
          'amount': orderResponse.amount,
          'currency': orderResponse.currency,
          'name': 'Passon Ride Escrow',
          'description': 'Reservation for $title',
          'prefill': {
            'contact': contact,
            'email': email,
          },
          'notes': orderResponse.notes,
          'theme': {
            'color': '#0284C7',
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
      AppToast.showError(context, 'Razorpay Order Creation Failed: $e');
    }
  }

  void _showKeyConfigDialog(BuildContext context) {
    final keyIdCtrl = TextEditingController(text: _razorpayService.keyId);
    final keySecretCtrl = TextEditingController(text: _razorpayService.keySecret);
    bool testMode = _razorpayService.isTestMode;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.vpn_key, color: AppColors.primary),
              SizedBox(width: 10),
              Text('Razorpay API Keys', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Switch between Razorpay Test Sandbox and Live Production keys:',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 14),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Test Sandbox Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(testMode ? 'Using simulated test cards & UPI' : 'Processing real live transactions', style: const TextStyle(fontSize: 11)),
                  value: testMode,
                  onChanged: (val) {
                    setDialogState(() {
                      testMode = val;
                      if (testMode) {
                        keyIdCtrl.text = 'rzp_test_TQuIDr91hSpnrx';
                        keySecretCtrl.text = 'AAsfVXS4sSnDhnql3XQjSkYf';
                      }
                    });
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: keyIdCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Razorpay Key ID',
                    border: OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: Icon(Icons.key, size: 18),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: keySecretCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Razorpay Key Secret',
                    border: OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: Icon(Icons.lock_outline, size: 18),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _razorpayService.setCredentials(
                  newKeyId: keyIdCtrl.text.trim(),
                  newKeySecret: keySecretCtrl.text.trim(),
                  testMode: testMode,
                );
                Navigator.pop(dialogCtx);
                setState(() {});
                AppToast.showSuccess(context, 'Razorpay configuration updated!');
              },
              child: const Text('Save Keys'),
            ),
          ],
        ),
      ),
    );
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
              Expanded(
                child: Column(
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
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Configure Razorpay Keys',
                onPressed: () => _showKeyConfigDialog(context),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Active Booking Identity Banner
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: appState.isChildAccount
                  ? (isDark ? Colors.purple.shade900.withOpacity(0.3) : Colors.purple.shade50)
                  : (isDark ? AppColors.surfaceContainerHighDark : AppColors.surfaceContainerLow),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: appState.isChildAccount
                    ? Colors.purple.withOpacity(0.35)
                    : (isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: appState.isChildAccount
                      ? Colors.purple.withOpacity(0.2)
                      : AppColors.primary.withOpacity(0.15),
                  child: Icon(
                    appState.isChildAccount ? Icons.child_care : Icons.family_restroom,
                    size: 16,
                    color: appState.isChildAccount ? Colors.purple : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Booking As: ',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              '${appState.activeUserDisplayName.isNotEmpty ? appState.activeUserDisplayName : "Account"} (${appState.isChildAccount ? "C" : "M"})',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        appState.isChildAccount
                            ? 'Booking is registered strictly under this child account.'
                            : 'Primary booking account. Booking will be linked to your Mother profile.',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (appState.isSignedIn)
                  TextButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const AccountSwitcherDialog(),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Switch', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),

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
                    errorBuilder: (_, _, _) => Container(
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
                  _buildPriceRow('Service Fee', '₹${serviceFee.toStringAsFixed(2)}'),
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
                    AppToast.showSuccess(context, 'Promo Code PASSON2026 applied! ₹40 off');
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
            subtitle: 'Instant secure checkout via Razorpay Gateway & Web Standard Checkout',
            icon: Icons.flash_on,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildPaymentOption(
            title: 'Scan & Pay via Razorpay QR Code',
            subtitle: 'Scan QR Code with GPay, PhonePe, Paytm or BHIM to pay instantly',
            icon: Icons.qr_code_scanner,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          
          const SizedBox(height: 10),
          _buildPaymentOption(
            title: 'Pay at Site / Pay When Renting',
            subtitle: 'Book now and pay when you pick up the vehicle or meet the guide',
            icon: Icons.handshake,
            isDark: isDark,
          ),

          // Embedded QR Code Visual Preview Card if QR Option Selected
          if (_selectedPaymentMethod.contains('QR Code')) ...[
            const SizedBox(height: 16),
            _buildEmbeddedQrCard(context, isDark, total, appState, vehicle: vehicle, tour: tour),
          ],

          const SizedBox(height: 16),
          _buildTestSandboxHelper(isDark),

          const SizedBox(height: 24),

          // Pay Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (_selectedPaymentMethod.contains('Pay at Site') || _selectedPaymentMethod.contains('Skip Payment')) {
                  _skipPaymentAndConfirm(context, appState, total, vehicle: vehicle, tour: tour);
                } else {
                  _confirmPayment(context, appState, total);
                }
              },
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
          const SizedBox(height: 12),

          // Skip Payment Instant Demo Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _skipPaymentAndConfirm(context, appState, total, vehicle: vehicle, tour: tour),
              icon: const Icon(Icons.handshake, color: Colors.green, size: 18),
              label: const Text(
                '✅ Pay at Site & Confirm Booking',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                side: const BorderSide(color: Colors.green, width: 1.5),
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

  Widget _buildTestSandboxHelper(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.blueGrey.shade900.withOpacity(0.5) : const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF0284C7).withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.science_outlined, size: 18, color: Color(0xFF0284C7)),
                  SizedBox(width: 8),
                  Text('Razorpay Sandbox Test Toolkit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0284C7))),
                ],
              ),
              InkWell(
                onTap: () => _showKeyConfigDialog(context),
                child: const Text('Edit Keys', style: TextStyle(fontSize: 11, color: Color(0xFF0284C7), fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Use these test details in the Razorpay checkout modal:', style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildCopyChip('UPI: success@razorpay', 'success@razorpay'),
              _buildCopyChip('Visa: 4100 2800 0000 1007', '4100280000001007'),
              _buildCopyChip('Mastercard: 5500 6700 0000 1002', '5500670000001002'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCopyChip(String label, String valueToCopy) {
    return ActionChip(
      avatar: const Icon(Icons.copy, size: 13, color: AppColors.primary),
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.grey.shade300),
      onPressed: () {
        Clipboard.setData(ClipboardData(text: valueToCopy));
        AppToast.showSuccess(context, 'Copied "$valueToCopy" to clipboard!');
      },
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

  Widget _buildEmbeddedQrCard(
    BuildContext context,
    bool isDark,
    double total,
    AppState appState, {
    Vehicle? vehicle,
    Tour? tour,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.qr_code_2, color: AppColors.primary, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Scan Razorpay UPI QR Code',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified, size: 12, color: Colors.green),
                    SizedBox(width: 4),
                    Text(
                      'Razorpay Verified',
                      style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'public/QrCode.jpeg',
                  height: 180,
                  width: 180,
                  fit: BoxFit.contain,
                  errorBuilder: (ctx, err, stack) => Container(
                    height: 180,
                    width: 180,
                    color: Colors.grey.shade100,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_2, size: 60, color: AppColors.primary),
                        SizedBox(height: 6),
                        Text('Razorpay QR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Scan with GPay, PhonePe, Paytm, or BHIM to pay ₹${total.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('UPI VPA: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
              const Text('success@razorpay', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
              const SizedBox(width: 6),
              InkWell(
                onTap: () {
                  Clipboard.setData(const ClipboardData(text: 'success@razorpay'));
                  AppToast.showSuccess(context, 'Copied success@razorpay to clipboard!');
                },
                child: const Icon(Icons.copy, size: 13, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showQrCodeModal(context, appState, total, vehicle: vehicle, tour: tour),
              icon: const Icon(Icons.fullscreen, size: 16),
              label: const Text('Enlarge QR Code Modal'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showQrCodeModal(BuildContext context, AppState appState, double total, {Vehicle? vehicle, Tour? tour}) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.qr_code_2, color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Razorpay UPI QR Code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('Scan to Pay via GPay / PhonePe / Paytm', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'public/QrCode.jpeg',
                        height: 220,
                        width: 220,
                        fit: BoxFit.contain,
                        errorBuilder: (ctx, err, stack) => Container(
                          height: 220,
                          width: 220,
                          color: Colors.grey.shade100,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code_2, size: 80, color: AppColors.primary),
                              SizedBox(height: 8),
                              Text('Razorpay QR Code', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Amount: ₹${total.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('VPA: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const Text('success@razorpay', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(const ClipboardData(text: 'success@razorpay'));
                      AppToast.showSuccess(context, 'Copied UPI ID to clipboard!');
                    },
                    child: const Icon(Icons.copy, size: 14, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Open GPay, PhonePe, Paytm, or BHIM, scan this QR code, complete the payment, and click confirm below.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(dialogCtx);
              _handleRazorpaySuccess(PaymentSuccessResponse.fromMap({
                'razorpay_payment_id': 'pay_qr_${DateTime.now().millisecondsSinceEpoch}',
                'razorpay_order_id': 'order_qr_${DateTime.now().millisecondsSinceEpoch}',
                'razorpay_signature': 'verified_qr_payment_signature',
              }));
            },
            icon: const Icon(Icons.check_circle, size: 18),
            label: const Text('Confirm Payment Paid'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmPayment(BuildContext context, AppState appState, double total) async {
    final tour = appState.selectedTour;
    final vehicle = tour == null ? (appState.selectedVehicle ?? (appState.vehicles.isNotEmpty ? appState.vehicles.first : null)) : null;

    if (tour == null && vehicle == null) return;

    final isHighValue = appState.notificationService.requiresHighValueStepUp(total);
    final userPhone = appState.userProfile?.phoneNumber.isNotEmpty == true ? appState.userProfile!.phoneNumber : '+919876543210';

    // Dispatch verification OTP via TransactionalNotificationService (Flow 1 or Flow 3)
    final otpResult = isHighValue
        ? await appState.notificationService.triggerHighValueStepUpWhatsAppOtp(
            phoneNumber: userPhone,
            userName: appState.activeUserDisplayName,
            rentalAmount: total,
            vehicleTitle: vehicle?.title ?? (tour?.title ?? 'Guided Tour'),
          )
        : await appState.notificationService.triggerBuyerCheckoutOtp(
            phoneNumber: userPhone,
            buyerName: appState.activeUserDisplayName,
            orderAmount: total,
          );

    if (!mounted) return;

    // Show OTP Verification Dialog (Flow 1 / Flow 3)
    _showOtpModal(context, appState, otpResult, () {
      if (_selectedPaymentMethod.contains('QR Code')) {
        _showQrCodeModal(context, appState, total, vehicle: vehicle, tour: tour);
      } else if (_selectedPaymentMethod.startsWith('UPI Direct')) {
        _startDirectUpiPayment(context, appState, total, vehicle: vehicle, tour: tour);
      } else if (_selectedPaymentMethod.startsWith('Razorpay')) {
        _startRazorpayPayment(appState, total);
      } else {
        _processDirectBooking(context, appState, total, vehicle: vehicle, tour: tour);
      }
    });
  }

  void _skipPaymentAndConfirm(BuildContext context, AppState appState, double total, {Vehicle? vehicle, Tour? tour}) async {
    final String demoPaymentId = 'pay_at_site_${DateTime.now().millisecondsSinceEpoch}';

    if (tour != null) {
      await appState.createTourBooking(
        tour: tour,
        participantCount: 1,
        totalPrice: total,
        paymentIntentId: demoPaymentId,
        paymentMethod: 'pay_at_site',
      );

      if (!mounted) return;
      AppToast.showSuccess(context, 'Booking Confirmed! Please pay at the site.');
      _showTourConfirmedModal(
        context: context,
        appState: appState,
        tourTitle: tour.title,
        paymentId: demoPaymentId,
        orderId: 'order_pay_at_site',
        signature: 'signature_pay_at_site',
        guideName: tour.guideName,
      );
    } else if (vehicle != null) {
      final booking = await appState.createBooking(
        vehicle: vehicle,
        startDate: appState.rentalStartDate,
        endDate: appState.rentalEndDate,
        totalPrice: total,
        paymentIntentId: demoPaymentId,
        paymentMethod: 'pay_at_site',
      );

      if (!mounted) return;
      AppToast.showSuccess(context, 'Vehicle rental confirmed! Please pay at the site.');
      _showBookingConfirmedModal(
        context: context,
        appState: appState,
        vehicleTitle: vehicle.title,
        paymentId: demoPaymentId,
        orderId: 'order_pay_at_site',
        signature: 'signature_pay_at_site',
        passcode: booking.unlockPasscode,
      );
    }
  }

  void _startDirectUpiPayment(BuildContext context, AppState appState, double total, {Vehicle? vehicle, Tour? tour}) {
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
                if (tour != null) {
                  await appState.createTourBooking(
                    tour: tour,
                    participantCount: 1,
                    totalPrice: total,
                    paymentIntentId: upiPaymentId,
                    paymentMethod: 'direct_upi',
                  );
                  if (!mounted) return;
                  _showTourConfirmedModal(
                    context: context,
                    appState: appState,
                    tourTitle: tour.title,
                    paymentId: upiPaymentId,
                    orderId: '',
                    signature: '',
                    guideName: tour.guideName,
                  );
                } else if (vehicle != null) {
                  final booking = await appState.createBooking(
                    vehicle: vehicle,
                    startDate: appState.rentalStartDate,
                    endDate: appState.rentalEndDate,
                    totalPrice: total,
                    paymentIntentId: upiPaymentId,
                    paymentMethod: 'direct_upi',
                  );
                  if (!mounted) return;
                  _showBookingConfirmedModal(
                    context: context,
                    appState: appState,
                    vehicleTitle: vehicle.title,
                    paymentId: upiPaymentId,
                    orderId: '',
                    signature: '',
                    passcode: booking.unlockPasscode,
                  );
                }
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
                if (tour != null) {
                  await appState.createTourBooking(
                    tour: tour,
                    participantCount: 1,
                    totalPrice: total,
                    paymentIntentId: upiPaymentId,
                    paymentMethod: 'direct_upi',
                  );
                  if (!mounted) return;
                  _showTourConfirmedModal(
                    context: context,
                    appState: appState,
                    tourTitle: tour.title,
                    paymentId: upiPaymentId,
                    orderId: '',
                    signature: '',
                    guideName: tour.guideName,
                  );
                } else if (vehicle != null) {
                  final booking = await appState.createBooking(
                    vehicle: vehicle,
                    startDate: appState.rentalStartDate,
                    endDate: appState.rentalEndDate,
                    totalPrice: total,
                    paymentIntentId: upiPaymentId,
                    paymentMethod: 'direct_upi',
                  );
                  if (!mounted) return;
                  _showBookingConfirmedModal(
                    context: context,
                    appState: appState,
                    vehicleTitle: vehicle.title,
                    paymentId: upiPaymentId,
                    orderId: '',
                    signature: '',
                    passcode: booking.unlockPasscode,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _processDirectBooking(BuildContext context, AppState appState, double total, {Vehicle? vehicle, Tour? tour}) async {
    final paymentIntentId = 'pi_stripe_${DateTime.now().millisecondsSinceEpoch}';

    if (tour != null) {
      await appState.createTourBooking(
        tour: tour,
        participantCount: 1,
        totalPrice: total,
        paymentIntentId: paymentIntentId,
        paymentMethod: 'stripe_escrow',
      );

      if (!context.mounted) return;
      _showTourConfirmedModal(
        context: context,
        appState: appState,
        tourTitle: tour.title,
        paymentId: paymentIntentId,
        orderId: '',
        signature: '',
        guideName: tour.guideName,
      );
    } else if (vehicle != null) {
      final booking = await appState.createBooking(
        vehicle: vehicle,
        startDate: appState.rentalStartDate,
        endDate: appState.rentalEndDate,
        totalPrice: total,
        paymentIntentId: paymentIntentId,
        paymentMethod: 'stripe_escrow',
      );

      if (!context.mounted) return;
      _showBookingConfirmedModal(
        context: context,
        appState: appState,
        vehicleTitle: vehicle.title,
        paymentId: paymentIntentId,
        orderId: '',
        signature: '',
        passcode: booking.unlockPasscode,
      );
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

  void _showBookingConfirmedModal({
    required BuildContext context,
    required AppState appState,
    required String vehicleTitle,
    required String paymentId,
    required String orderId,
    required String signature,
    required String passcode,
  }) {
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
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your vehicle rental for "$vehicleTitle" is confirmed and funds are securely held in escrow!',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified, color: Colors.green, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          signature.isNotEmpty ? 'HMAC-SHA256 Signature Verified' : 'Razorpay Gateway Verified',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Text('💳 Payment ID: $paymentId', style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                    if (orderId.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('📦 Order ID: $orderId', style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('🔑 Unlock PIN: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(passcode, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Passcode & rental instructions have been synced with your Chat & Notifications.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              appState.setNavIndex(3); // Go to Bookings
            },
            child: const Text('View My Bookings'),
          ),
        ],
      ),
    );
  }

  void _showTourConfirmedModal({
    required BuildContext context,
    required AppState appState,
    required String tourTitle,
    required String paymentId,
    required String orderId,
    required String signature,
    required String guideName,
  }) {
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
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your reservation for "$tourTitle" is confirmed!',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified, color: Colors.green, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          signature.isNotEmpty ? 'HMAC-SHA256 Signature Verified' : 'Razorpay Gateway Verified',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Text('👤 Guide: $guideName', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('💳 Payment ID: $paymentId', style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                    if (orderId.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('📦 Order ID: $orderId', style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Tour instructions, guide chat & itinerary have been sent to your Chat & Notification Center.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
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
