// ignore_for_file: use_build_context_synchronously
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';

/// TEMPORARY (testing): hides the "Renter Documents & Photo" section and skips its
/// required-photo checks so the booking flow can be tested quickly.
/// TODO: set back to false to reconnect the document upload section before release.
const bool kBypassRenterDocuments = false;

/// Modal dialog for Providers to manually record/onboard offline walk-in bookings
/// for their vehicles, homestays/hotels, or guided tours.
class RecordOfflineBookingDialog extends StatefulWidget {
  final AppState appState;
  final List<Vehicle> vehicles;
  final List<Hotel> hotels;
  final List<Tour> tours;

  const RecordOfflineBookingDialog({
    super.key,
    required this.appState,
    required this.vehicles,
    required this.hotels,
    required this.tours,
  });

  static Future<void> show(
    BuildContext context,
    AppState appState, {
    List<Vehicle>? vehicles,
    List<Hotel>? hotels,
    List<Tour>? tours,
  }) {
    final vList = vehicles ?? appState.myHostedVehicles;
    final currentUid = appState.activeUserId;
    final currentName = appState.activeUserDisplayName.toLowerCase();

    final hList =
        hotels ??
        appState.hotels.where((h) {
          if (currentUid.isNotEmpty && h.hostId == currentUid) return true;
          if (h.hostName.isNotEmpty && h.hostName.toLowerCase() == currentName) return true;
          return false;
        }).toList();

    final tList =
        tours ??
        appState.tours.where((t) {
          if (currentUid.isNotEmpty && t.hostId == currentUid) return true;
          if (t.guideName.isNotEmpty && t.guideName.toLowerCase() == currentName) return true;
          return false;
        }).toList();

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: RecordOfflineBookingDialog(appState: appState, vehicles: vList, hotels: hList, tours: tList),
        ),
      ),
    );
  }

  @override
  State<RecordOfflineBookingDialog> createState() => _RecordOfflineBookingDialogState();
}

class _RecordOfflineBookingDialogState extends State<RecordOfflineBookingDialog> {
  final _formKey = GlobalKey<FormState>();

  String _bookingType = 'vehicle'; // 'vehicle', 'stay', 'tour'
  String? _selectedItemId;
  static const _unlisted = '__unlisted__';
  bool get _isUnlisted => _selectedItemId == _unlisted;
  final _unlistedNameController = TextEditingController();
  Uint8List? _unlistedPhoto;

  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerEmailController = TextEditingController();
  final _customerIdNumberController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  final _stayRoomTypeController = TextEditingController(text: 'Deluxe / Standard');

  // Vehicle bookings: rent and advance are entered separately (total payable = rent + advance).
  final _rentController = TextEditingController();
  final _advanceController = TextEditingController();

  // For vehicles these carry the receiving / returning time as well as the date.
  DateTime _startDate = _nowToMinute();
  DateTime _endDate = _nowToMinute().add(const Duration(days: 1));
  String _paymentMethod = 'Cash';
  bool _isSaving = false;

  // 0 = details form, 1 = overview, 2 = total payable, 3 = payment method
  int _step = 0;
  static const _stepLabels = ['Details', 'Overview', 'Total', 'Payment'];
  final _scrollController = ScrollController();

  static DateTime _nowToMinute() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day, n.hour, n.minute);
  }

  bool get _isVehicle => _bookingType == 'vehicle';
  double get _rent => double.tryParse(_rentController.text.trim()) ?? 0.0;
  double get _advance => double.tryParse(_advanceController.text.trim()) ?? 0.0;
  double get _totalPayable => _isVehicle ? _rent + _advance : (double.tryParse(_priceController.text.trim()) ?? 0.0);

  static final _money = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  static const _paymentOptions = [
    (value: 'Cash', label: 'Cash', subtitle: 'Collect cash at the counter', icon: Icons.payments_outlined),
    (
      value: 'UPI / GPay / PhonePe',
      label: 'UPI',
      subtitle: 'GPay, PhonePe, Paytm or any UPI app',
      icon: Icons.qr_code_2,
    ),
    (
      value: 'Card (POS)',
      label: 'Card (POS)',
      subtitle: 'Debit / credit card on the POS machine',
      icon: Icons.credit_card,
    ),
    (
      value: 'Bank Transfer',
      label: 'Bank Transfer',
      subtitle: 'NEFT / IMPS to your bank account',
      icon: Icons.account_balance_outlined,
    ),
    (
      value: 'Pay at Return / Checkout',
      label: 'Pay at Return',
      subtitle: 'Customer pays when the booking ends',
      icon: Icons.schedule,
    ),
  ];

  // Renter KYC captured at the counter
  Uint8List? _renterPhoto;
  Uint8List? _idDocument;
  Uint8List? _handoverPhoto; // renter with the vehicle
  Uint8List? _idProof; // Aadhaar / passport (vehicle bookings; stays/tours use the ID tile)
  final _picker = ImagePicker();

  bool get _needsHandover => _bookingType == 'vehicle';

  Future<void> _pickHandover(ImageSource source, {bool idProof = false}) async {
    try {
      final file = await _picker.pickImage(source: source, maxWidth: 1600, imageQuality: 80);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (mounted) setState(() => idProof ? _idProof = bytes : _handoverPhoto = bytes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open camera/gallery: $e'), backgroundColor: Colors.orange));
    }
  }

  Future<void> _pick({required bool photo, required ImageSource source}) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 80,
        preferredCameraDevice: photo ? CameraDevice.front : CameraDevice.rear,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() => photo ? _renterPhoto = bytes : _idDocument = bytes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open camera/gallery: $e'), backgroundColor: Colors.orange));
    }
  }

  String get _idDocLabel => _bookingType == 'vehicle' ? 'Driving License' : 'Aadhaar / Passport';

  Widget _buildKycSection(bool isDark) {
    final scheme = Theme.of(context).colorScheme;
    Widget tile({required bool photo, bool handover = false, bool idProof = false}) {
      final bytes = idProof
          ? _idProof
          : handover
          ? _handoverPhoto
          : (photo ? _renterPhoto : _idDocument);
      final title = idProof
          ? 'Aadhaar / Passport'
          : handover
          ? 'Renter with Vehicle'
          : (photo ? 'Current Photo of Renter' : _idDocLabel);
      final emptyIcon = idProof
          ? Icons.contact_page_outlined
          : handover
          ? Icons.two_wheeler
          : (photo ? Icons.person_outline : Icons.credit_card);
      void pick(ImageSource src) =>
          (handover || idProof) ? _pickHandover(src, idProof: idProof) : _pick(photo: photo, source: src);
      final has = bytes != null;
      return Expanded(
        child: Container(
          constraints: const BoxConstraints(minHeight: 0),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: has
                ? Colors.green.withValues(alpha: isDark ? 0.15 : 0.07)
                : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
            border: Border.all(color: has ? Colors.green.shade400 : scheme.outlineVariant),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    has
                        ? Icons.check_circle
                        : (handover
                              ? Icons.photo_camera_front
                              : (photo ? Icons.face_retouching_natural : Icons.badge_outlined)),
                    size: 18,
                    color: has ? Colors.green.shade700 : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: scheme.onSurface),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AspectRatio(
                aspectRatio: 4 / 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: has
                      ? Image.memory(bytes, fit: BoxFit.cover, width: double.infinity)
                      : Container(
                          color: scheme.surface,
                          alignment: Alignment.center,
                          child: Icon(emptyIcon, size: 36, color: scheme.outline),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => pick(ImageSource.camera),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        minimumSize: const Size(0, 34),
                      ),
                      icon: const Icon(Icons.photo_camera, size: 16),
                      label: Text(has ? 'Retake' : 'Camera', style: const TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton.outlined(
                    tooltip: 'Choose from gallery',
                    onPressed: () => pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Renter Documents & Photo',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: scheme.onSurface),
        ),
        const SizedBox(height: 2),
        Text(
          'Take a live photo of the renter and a clear picture of their ${_idDocLabel.toLowerCase()}'
          '${_needsHandover ? ', their Aadhaar / passport, and a photo of the renter standing with the vehicle at handover' : ''}.',
          style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [tile(photo: true), const SizedBox(width: 10), tile(photo: false)],
          ),
        ),
        if (_needsHandover) ...[
          const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                tile(photo: false, idProof: true),
                const SizedBox(width: 10),
                tile(photo: false, handover: true),
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _autoSelectFirstItem();
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerEmailController.dispose();
    _customerIdNumberController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    _unlistedNameController.dispose();
    _stayRoomTypeController.dispose();
    _rentController.dispose();
    _advanceController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Nothing is pre-selected: the provider picks the listing (or "Not listed").
  void _autoSelectFirstItem() {
    _selectedItemId = null;
    _priceController.clear();
    _rentController.clear();
    _advanceController.clear();
    _unlistedPhoto = null;
    _unlistedNameController.clear();
  }

  Future<void> _pickUnlistedPhoto(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, maxWidth: 1600, imageQuality: 80);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (mounted) setState(() => _unlistedPhoto = bytes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open camera/gallery: $e'), backgroundColor: Colors.orange));
    }
  }

  Widget _buildUnlistedSection() {
    final scheme = Theme.of(context).colorScheme;
    final has = _unlistedPhoto != null;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: has ? Colors.green.shade400 : scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _unlistedNameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Vehicle name & number (e.g. Honda Activa WB 41 1234)',
              prefixIcon: const Icon(Icons.two_wheeler),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
            ),
            validator: (v) => _isUnlisted && (v == null || v.trim().isEmpty) ? 'Enter the vehicle name' : null,
          ),
          const SizedBox(height: 10),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: has
                  ? Image.memory(_unlistedPhoto!, fit: BoxFit.cover, width: double.infinity)
                  : Container(
                      color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_a_photo_outlined, size: 36, color: scheme.outline),
                          const SizedBox(height: 4),
                          Text('Photo of the vehicle', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickUnlistedPhoto(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera, size: 16),
                  label: Text(has ? 'Retake' : 'Take picture'),
                ),
              ),
              const SizedBox(width: 6),
              IconButton.outlined(
                tooltip: 'Choose from gallery',
                onPressed: () => _pickUnlistedPhoto(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Enter the total price below manually.', style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: _pickerTheme,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _recalculatePrice();
      });
    }
  }

  Widget _pickerTheme(BuildContext context, Widget? child) => Theme(
    data: Theme.of(context).copyWith(
      colorScheme: ColorScheme.fromSeed(seedColor: _bookingTypeColor, primary: _bookingTypeColor),
    ),
    child: child!,
  );

  /// Vehicle bookings: pick the receiving (pickup) or returning date, then the time.
  Future<void> _pickVehicleDateTime({required bool receiving}) async {
    final current = receiving ? _startDate : _endDate;
    final now = DateTime.now();
    final first = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: current.isBefore(first) ? first : current,
      firstDate: first,
      lastDate: now.add(const Duration(days: 365)),
      helpText: receiving ? 'Vehicle receiving date' : 'Vehicle returning date',
      builder: _pickerTheme,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
      helpText: receiving ? 'Vehicle receiving time' : 'Vehicle returning time',
      builder: _pickerTheme,
    );
    if (time == null || !mounted) return;
    final picked = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (receiving) {
        // Keep the same rental length when the receiving time moves past the return.
        final length = _endDate.difference(_startDate);
        _startDate = picked;
        if (!_endDate.isAfter(picked)) {
          _endDate = picked.add(length > Duration.zero ? length : const Duration(days: 1));
        }
      } else {
        _endDate = picked;
      }
      _recalculatePrice();
    });
  }

  /// Rental length in billable days (any part of a 24h block counts as a day).
  int get _vehicleRentalDays {
    final minutes = _endDate.difference(_startDate).inMinutes;
    return mathMax(1, (minutes / (24 * 60)).ceil());
  }

  String _durationLabel() {
    final d = _endDate.difference(_startDate);
    if (d.inMinutes <= 0) return '—';
    final days = d.inDays, hours = d.inHours % 24, mins = d.inMinutes % 60;
    return [
      if (days > 0) '$days day${days == 1 ? '' : 's'}',
      if (hours > 0) '$hours hr${hours == 1 ? '' : 's'}',
      if (mins > 0) '$mins min',
    ].join(' ');
  }

  void _recalculatePrice() {
    if (_selectedItemId == null || _isUnlisted) return;
    final days = mathMax(1, _endDate.difference(_startDate).inDays);
    if (_bookingType == 'vehicle') {
      final v = widget.vehicles.firstWhere((e) => e.id == _selectedItemId, orElse: () => widget.vehicles.first);
      _rentController.text = (v.pricePerDay * _vehicleRentalDays).toStringAsFixed(0);
    } else if (_bookingType == 'stay') {
      final h = widget.hotels.firstWhere((e) => e.id == _selectedItemId, orElse: () => widget.hotels.first);
      _priceController.text = (h.pricePerNight * days).toStringAsFixed(0);
    } else if (_bookingType == 'tour') {
      final t = widget.tours.firstWhere((e) => e.id == _selectedItemId, orElse: () => widget.tours.first);
      _priceController.text = t.price.toStringAsFixed(0);
    }
  }

  int mathMax(int a, int b) => a > b ? a : b;

  Color get _bookingTypeColor {
    switch (_bookingType) {
      case 'stay':
        return Colors.teal;
      case 'tour':
        return AppColors.secondary;
      case 'vehicle':
      default:
        return AppColors.primary;
    }
  }

  void _warn(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.orange));
  }

  /// Checks everything on the details page before moving on to the overview.
  bool _validateDetails() {
    if (!_formKey.currentState!.validate()) return false;
    if (_selectedItemId == null) {
      _warn('Please select an item to book');
      return false;
    }
    if (_isVehicle && !_endDate.isAfter(_startDate)) {
      _warn('Returning date & time must be after the receiving date & time');
      return false;
    }
    if (_isVehicle && _rent + _advance <= 0) {
      _warn('Enter the rent amount');
      return false;
    }
    if (_isUnlisted && _unlistedPhoto == null) {
      _warn('Please take a picture of the vehicle');
      return false;
    }
    if (kBypassRenterDocuments) return true;
    if (_renterPhoto == null) {
      _warn("Please take the renter's current photo");
      return false;
    }
    if (_idDocument == null) {
      _warn("Please upload the renter's $_idDocLabel");
      return false;
    }
    if (_needsHandover && _idProof == null) {
      _warn("Please upload the renter's Aadhaar card or passport");
      return false;
    }
    if (_needsHandover && _handoverPhoto == null) {
      _warn('Please take a photo of the renter with the vehicle');
      return false;
    }
    return true;
  }

  void _goToStep(int step) {
    FocusScope.of(context).unfocus();
    setState(() => _step = step);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
    });
  }

  void _next() {
    if (_step == 0 && !_validateDetails()) return;
    if (_step < _stepLabels.length - 1) _goToStep(_step + 1);
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);

    String itemTitle = '';
    String itemImageUrl = '';

    if (_isUnlisted) {
      itemTitle = _unlistedNameController.text.trim();
    } else if (_bookingType == 'vehicle') {
      final v = widget.vehicles.firstWhere((e) => e.id == _selectedItemId);
      itemTitle = v.title;
      itemImageUrl = v.imageUrl;
    } else if (_bookingType == 'stay') {
      final h = widget.hotels.firstWhere((e) => e.id == _selectedItemId);
      itemTitle = h.name;
      itemImageUrl = h.imageUrl;
    } else {
      final t = widget.tours.firstWhere((e) => e.id == _selectedItemId);
      itemTitle = t.title;
      itemImageUrl = t.imageUrl;
    }

    final price = _totalPayable;

    try {
      await widget.appState.createOfflineBooking(
        bookingType: _bookingType,
        itemId: _isUnlisted ? 'unlisted_${DateTime.now().millisecondsSinceEpoch}' : _selectedItemId!,
        itemPhotoBytes: _isUnlisted ? _unlistedPhoto : null,
        itemTitle: itemTitle,
        itemImageUrl: itemImageUrl,
        customerName: _customerNameController.text.trim(),
        customerPhone: _customerPhoneController.text.trim(),
        customerEmail: _customerEmailController.text.trim(),
        customerIdNumber: _customerIdNumberController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        totalPrice: price,
        rentAmount: _isVehicle ? _rent : 0.0,
        advanceAmount: _isVehicle ? _advance : 0.0,
        notes: _notesController.text.trim(),
        stayRoomType: _stayRoomTypeController.text.trim(),
        paymentMethod: _paymentMethod,
        renterPhotoBytes: _renterPhoto,
        idDocumentBytes: _idDocument,
        handoverPhotoBytes: _needsHandover ? _handoverPhoto : null,
        idProofBytes: _needsHandover ? _idProof : null,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _warn('Could not record the booking: $e');
      return;
    }

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Offline booking for "${_customerNameController.text.trim()}" onboarded successfully!'),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          action: SnackBarAction(
            label: 'View Bookings',
            textColor: Colors.white,
            onPressed: () => widget.appState.setNavIndex(19),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('dd MMM yyyy');

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(left: 20, right: 20, top: 14, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top drag bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
                ),
              ),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _bookingTypeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.person_add_alt_1_rounded, color: _bookingTypeColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Onboard Offline / Walk-in Customer',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Manually record walk-in booking details to keep track in My Bookings & PMS.',
                          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 14),
              _buildStepIndicator(),
              const SizedBox(height: 16),

              if (_step == 0) ...[
                // Booking Type Selector (Vehicle / Stay / Tour)
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Expanded(child: _buildTypeButton('vehicle', 'Vehicle / Bike', Icons.directions_bike)),
                      Expanded(child: _buildTypeButton('stay', 'Homestay / Hotel', Icons.holiday_village_outlined)),
                      Expanded(child: _buildTypeButton('tour', 'Guided Tour', Icons.tour_outlined)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Select Listing Item
                const Text(
                  'SELECT LISTING',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                _buildItemDropdown(isDark),
                if (_isUnlisted) _buildUnlistedSection(),
                const SizedBox(height: 16),

                // Customer Details Section
                const Text(
                  'CUSTOMER / GUEST INFORMATION',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.grey),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _customerNameController,
                        decoration: InputDecoration(
                          labelText: 'Customer Full Name *',
                          prefixIcon: const Icon(Icons.person_outline, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          isDense: true,
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter customer name' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _customerPhoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Phone Number *',
                          prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          isDense: true,
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter phone number' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _customerIdNumberController,
                        decoration: InputDecoration(
                          labelText: 'ID / DL / Aadhaar No. (Optional)',
                          prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _customerEmailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email Address (Optional)',
                          prefixIcon: const Icon(Icons.email_outlined, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Booking Schedule & Pricing
                Text(
                  _isVehicle ? 'RECEIVING & RETURNING' : 'BOOKING DATES & PRICING',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                if (_isVehicle) _buildVehicleScheduleAndPricing() else _buildDateRangeAndTotal(dateFormat),
                if (_bookingType == 'stay') ...[
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _stayRoomTypeController,
                    decoration: InputDecoration(
                      labelText: 'Room Type',
                      prefixIcon: const Icon(Icons.meeting_room_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      isDense: true,
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                if (!kBypassRenterDocuments) ...[_buildKycSection(isDark), const SizedBox(height: 12)],

                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Special Notes / Customer Requests (Optional)',
                    hintText: 'e.g., Helmet provided, fuel level, scratches noted, etc.',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    isDense: true,
                  ),
                ),
              ] else if (_step == 1)
                _buildOverview(dateFormat)
              else if (_step == 2)
                _buildTotalPayable()
              else
                _buildPaymentMethods(),
              const SizedBox(height: 20),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step flow: Details -> Overview -> Total payable -> Payment method
  // ---------------------------------------------------------------------------

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.grey),
    ),
  );

  Widget _buildStepIndicator() {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (var i = 0; i < _stepLabels.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 16),
                color: i <= _step ? _bookingTypeColor : scheme.outlineVariant,
              ),
            ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: i <= _step ? _bookingTypeColor : scheme.surfaceContainerHighest,
                child: i < _step
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: i == _step ? Colors.white : scheme.onSurfaceVariant,
                        ),
                      ),
              ),
              const SizedBox(height: 4),
              Text(
                _stepLabels[i],
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: i == _step ? FontWeight.bold : FontWeight.w500,
                  color: i == _step ? _bookingTypeColor : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Stays / tours: the original date range + single total.
  Widget _buildDateRangeAndTotal(DateFormat dateFormat) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: InkWell(
            onTap: _selectDateRange,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_month, color: _bookingTypeColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${dateFormat.format(_startDate)} - ${dateFormat.format(_endDate)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Total ₹ *',
              prefixText: '₹ ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
            ),
            validator: (val) => val == null || val.trim().isEmpty ? 'Enter amount' : null,
          ),
        ),
      ],
    );
  }

  Widget _dateTimeTile({required bool receiving}) {
    final scheme = Theme.of(context).colorScheme;
    final value = receiving ? _startDate : _endDate;
    final invalid = !receiving && !_endDate.isAfter(_startDate);
    return InkWell(
      onTap: () => _pickVehicleDateTime(receiving: receiving),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: invalid ? scheme.error : Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(receiving ? Icons.login_rounded : Icons.logout_rounded, size: 16, color: _bookingTypeColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    receiving ? 'Receiving' : 'Returning',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant),
                  ),
                ),
                Icon(Icons.edit_calendar_outlined, size: 16, color: scheme.outline),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              DateFormat('dd MMM yyyy').format(value),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('hh:mm a').format(value),
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _bookingTypeColor),
            ),
          ],
        ),
      ),
    );
  }

  /// Vehicles: receiving / returning date + time, then Rent and Advance.
  Widget _buildVehicleScheduleAndPricing() {
    final scheme = Theme.of(context).colorScheme;
    final validRange = _endDate.isAfter(_startDate);
    InputDecoration money(String label, IconData icon, {String? helper}) => InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      prefixText: '₹ ',
      helperText: helper,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      isDense: true,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _dateTimeTile(receiving: true)),
            const SizedBox(width: 10),
            Expanded(child: _dateTimeTile(receiving: false)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(
              validRange ? Icons.timelapse : Icons.error_outline,
              size: 14,
              color: validRange ? scheme.onSurfaceVariant : scheme.error,
            ),
            const SizedBox(width: 4),
            Text(
              validRange
                  ? 'Duration: ${_durationLabel()}  •  billed as $_vehicleRentalDays day${_vehicleRentalDays == 1 ? '' : 's'}'
                  : 'Returning time must be after receiving time',
              style: TextStyle(fontSize: 11.5, color: validRange ? scheme.onSurfaceVariant : scheme.error),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _sectionLabel('PAYMENT'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _rentController,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: money('Rent *', Icons.two_wheeler, helper: 'Rental charge'),
                validator: (v) {
                  final n = double.tryParse((v ?? '').trim());
                  return n == null || n <= 0 ? 'Enter rent' : null;
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _advanceController,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: money('Advance', Icons.savings_outlined, helper: 'Refundable deposit'),
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.isEmpty) return null;
                  final n = double.tryParse(t);
                  return n == null || n < 0 ? 'Invalid amount' : null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  ({String title, String imageUrl, String subtitle}) get _selectedItemInfo {
    if (_isUnlisted) return (title: _unlistedNameController.text.trim(), imageUrl: '', subtitle: 'Not listed');
    if (_bookingType == 'vehicle') {
      final v = widget.vehicles.where((e) => e.id == _selectedItemId).firstOrNull;
      if (v != null) {
        return (
          title: v.title,
          imageUrl: v.imageUrl,
          subtitle: '${v.category} • ₹${v.pricePerDay.toStringAsFixed(0)}/day',
        );
      }
    } else if (_bookingType == 'stay') {
      final h = widget.hotels.where((e) => e.id == _selectedItemId).firstOrNull;
      if (h != null) {
        return (
          title: h.name,
          imageUrl: h.imageUrl,
          subtitle: '${h.location} • ${_stayRoomTypeController.text.trim()}',
        );
      }
    } else {
      final t = widget.tours.where((e) => e.id == _selectedItemId).firstOrNull;
      if (t != null) return (title: t.title, imageUrl: t.imageUrl, subtitle: t.duration);
    }
    return (title: '—', imageUrl: '', subtitle: '');
  }

  Widget _card({required Widget child}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: child,
    );
  }

  Widget _kv(String label, String value, {bool bold = false, Color? color}) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.bold : FontWeight.w600, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverview(DateFormat dateFormat) {
    final scheme = Theme.of(context).colorScheme;
    final item = _selectedItemInfo;
    final dateTime = DateFormat('dd MMM yyyy, hh:mm a');
    final photos = <(String, Uint8List?)>[
      ('Renter', _renterPhoto),
      (_idDocLabel, _idDocument),
      if (_needsHandover) ('Aadhaar / Passport', _idProof),
      if (_needsHandover) ('With Vehicle', _handoverPhoto),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('BOOKING OVERVIEW'),
        _card(
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 72,
                  height: 54,
                  child: _isUnlisted && _unlistedPhoto != null
                      ? Image.memory(_unlistedPhoto!, fit: BoxFit.cover)
                      : item.imageUrl.isNotEmpty
                      ? Image.network(
                          item.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Icon(Icons.image_not_supported_outlined, color: scheme.outline),
                        )
                      : Container(
                          color: scheme.surfaceContainerHighest,
                          child: Icon(Icons.two_wheeler, color: scheme.outline),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold)),
                    if (item.subtitle.isNotEmpty)
                      Text(item.subtitle, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
        ),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Customer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              _kv('Name', _customerNameController.text.trim()),
              _kv('Phone', _customerPhoneController.text.trim()),
              _kv('ID / DL / Aadhaar', _customerIdNumberController.text.trim()),
              _kv('Email', _customerEmailController.text.trim()),
            ],
          ),
        ),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isVehicle ? 'Receiving & Returning' : 'Schedule',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              if (_isVehicle) ...[
                _kv('Receiving', dateTime.format(_startDate)),
                _kv('Returning', dateTime.format(_endDate)),
                _kv('Duration', _durationLabel()),
              ] else ...[
                _kv(_bookingType == 'stay' ? 'Check-in' : 'Start', dateFormat.format(_startDate)),
                _kv(_bookingType == 'stay' ? 'Check-out' : 'End', dateFormat.format(_endDate)),
              ],
            ],
          ),
        ),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Charges', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              if (_isVehicle) ...[
                _kv('Rent', _money.format(_rent)),
                _kv('Advance', _money.format(_advance)),
                const Divider(height: 14),
              ],
              _kv('Total', _money.format(_totalPayable), bold: true, color: _bookingTypeColor),
            ],
          ),
        ),
        if (!kBypassRenterDocuments)
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Documents & Photos', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final (label, bytes) in photos)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Column(
                            children: [
                              AspectRatio(
                                aspectRatio: 1,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: bytes != null
                                      ? Image.memory(bytes, fit: BoxFit.cover)
                                      : Container(color: scheme.surfaceContainerHighest),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 10.5, color: scheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        if (_notesController.text.trim().isNotEmpty)
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Notes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(_notesController.text.trim(), style: const TextStyle(fontSize: 12.5)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTotalPayable() {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_bookingTypeColor, _bookingTypeColor.withValues(alpha: 0.75)],
            ),
          ),
          child: Column(
            children: [
              const Text(
                'TOTAL PAYABLE AMOUNT',
                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
              const SizedBox(height: 10),
              FittedBox(
                child: Text(
                  _money.format(_totalPayable),
                  style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _customerNameController.text.trim(),
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _card(
          child: Column(
            children: [
              if (_isVehicle) ...[
                _kv('Rent', _money.format(_rent)),
                _kv('Advance', _money.format(_advance)),
                const Divider(height: 14),
              ],
              _kv('Total payable', _money.format(_totalPayable), bold: true, color: _bookingTypeColor),
            ],
          ),
        ),
        if (_isVehicle && _advance > 0)
          Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'The advance of ${_money.format(_advance)} is refundable when the vehicle is returned.',
                  style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildPaymentMethods() {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('SELECT PAYMENT METHOD'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _bookingTypeColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text('Amount to collect', style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
              const Spacer(),
              Text(
                _money.format(_totalPayable),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _bookingTypeColor),
              ),
            ],
          ),
        ),
        for (final o in _paymentOptions)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => setState(() => _paymentMethod = o.value),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: _paymentMethod == o.value ? _bookingTypeColor.withValues(alpha: 0.08) : null,
                  border: Border.all(
                    color: _paymentMethod == o.value ? _bookingTypeColor : scheme.outlineVariant,
                    width: _paymentMethod == o.value ? 1.6 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _bookingTypeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(o.icon, size: 20, color: _bookingTypeColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(o.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          Text(o.subtitle, style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    Icon(
                      _paymentMethod == o.value ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: _paymentMethod == o.value ? _bookingTypeColor : scheme.outline,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActions() {
    final isLast = _step == _stepLabels.length - 1;
    final nextLabel = switch (_step) {
      0 => 'Next',
      1 => 'Next',
      2 => 'Choose Payment Method',
      _ => _isSaving ? 'Recording...' : 'Confirm Booking',
    };
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isSaving ? null : () => _step == 0 ? Navigator.pop(context) : _goToStep(_step - 1),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(_step == 0 ? 'Cancel' : 'Back'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: _step == 2 ? 2 : 1,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : (isLast ? _handleSave : _next),
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Icon(isLast ? Icons.check_circle_outline : Icons.arrow_forward_rounded, color: Colors.white),
            label: Text(
              nextLabel,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _bookingTypeColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeButton(String type, String label, IconData icon) {
    final isSelected = _bookingType == type;
    return InkWell(
      onTap: () {
        setState(() {
          _bookingType = type;
          _autoSelectFirstItem();
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _bookingTypeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey.shade700),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemDropdown(bool isDark) {
    if (_bookingType == 'vehicle') {
      return DropdownButtonFormField<String>(
        key: ValueKey('vehicle_${_selectedItemId ?? 'none'}'),
        initialValue: _selectedItemId,
        isExpanded: true,
        hint: const Text('Select your vehicle', style: TextStyle(fontSize: 13)),
        decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), isDense: true),
        items: [
          const DropdownMenuItem(
            value: _unlisted,
            child: Row(
              children: [
                Icon(Icons.add_a_photo_outlined, size: 20, color: Colors.deepOrange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Not listed — take a picture',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.deepOrange),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          ...widget.vehicles.map((v) {
            return DropdownMenuItem(
              value: v.id,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      v.imageUrl,
                      width: 32,
                      height: 24,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(Icons.directions_bike, size: 20),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${v.title} (${v.category}) — ₹${v.pricePerDay.toStringAsFixed(0)}/day',
                      style: const TextStyle(fontSize: 12.5),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
        onChanged: (val) {
          setState(() {
            _selectedItemId = val;
            _recalculatePrice();
          });
        },
      );
    } else if (_bookingType == 'stay') {
      if (widget.hotels.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.shade300),
          ),
          child: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Expanded(child: Text('No stays/hotels hosted yet. Add a stay first.', style: TextStyle(fontSize: 12))),
            ],
          ),
        );
      }
      return DropdownButtonFormField<String>(
        key: ValueKey('Select your stay_${_selectedItemId ?? 'none'}'),
        initialValue: _selectedItemId,
        isExpanded: true,
        hint: const Text('Select your stay', style: TextStyle(fontSize: 13)),
        decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), isDense: true),
        items: widget.hotels.map((h) {
          return DropdownMenuItem(
            value: h.id,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    h.imageUrl,
                    width: 32,
                    height: 24,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(Icons.hotel, size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${h.name} (${h.location}) — ₹${h.pricePerNight.toStringAsFixed(0)}/night',
                    style: const TextStyle(fontSize: 12.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (val) {
          setState(() {
            _selectedItemId = val;
            _recalculatePrice();
          });
        },
      );
    } else {
      if (widget.tours.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.shade300),
          ),
          child: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Expanded(child: Text('No tours published yet. Register a tour first.', style: TextStyle(fontSize: 12))),
            ],
          ),
        );
      }
      return DropdownButtonFormField<String>(
        key: ValueKey('Select your tour_${_selectedItemId ?? 'none'}'),
        initialValue: _selectedItemId,
        isExpanded: true,
        hint: const Text('Select your tour', style: TextStyle(fontSize: 13)),
        decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), isDense: true),
        items: widget.tours.map((t) {
          return DropdownMenuItem(
            value: t.id,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    t.imageUrl,
                    width: 32,
                    height: 24,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(Icons.tour, size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${t.title} (${t.duration}) — ₹${t.price.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 12.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (val) {
          setState(() {
            _selectedItemId = val;
            _recalculatePrice();
          });
        },
      );
    }
  }
}
