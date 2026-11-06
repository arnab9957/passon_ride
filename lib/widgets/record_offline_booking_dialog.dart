// ignore_for_file: use_build_context_synchronously
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';

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

    final hList = hotels ??
        appState.hotels.where((h) {
          if (currentUid.isNotEmpty && h.hostId == currentUid) return true;
          if (h.hostName.isNotEmpty && h.hostName.toLowerCase() == currentName) return true;
          return false;
        }).toList();

    final tList = tours ??
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
          child: RecordOfflineBookingDialog(
            appState: appState,
            vehicles: vList,
            hotels: hList,
            tours: tList,
          ),
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

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _pickupTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _returnTime = const TimeOfDay(hour: 10, minute: 0);
  final _advanceController = TextEditingController();

  // 0 = details form, 1 = order overview & payment, 2 = booking created
  int _step = 0;
  Uint8List? _paymentProof;
  String _createdBookingId = '';

  DateTime _at(DateTime d, TimeOfDay t) => DateTime(d.year, d.month, d.day, t.hour, t.minute);
  DateTime get _startAt => _at(_startDate, _pickupTime);
  DateTime get _endAt => _at(_endDate, _returnTime);
  double get _rent => double.tryParse(_priceController.text.trim()) ?? 0;
  double get _advance => double.tryParse(_advanceController.text.trim()) ?? 0;
  double get _totalPayable => _rent + _advance;
  String _paymentMethod = 'Cash';
  bool _isSaving = false;

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open camera/gallery: $e'), backgroundColor: Colors.orange),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open camera/gallery: $e'), backgroundColor: Colors.orange),
      );
    }
  }

  String get _idDocLabel => _bookingType == 'vehicle' ? 'Driving License' : 'Aadhaar / Passport';

  Widget _buildKycSection(bool isDark) {
    final scheme = Theme.of(context).colorScheme;
    Widget tile({required bool photo, bool handover = false, bool idProof = false}) {
      final bytes = idProof ? _idProof : handover ? _handoverPhoto : (photo ? _renterPhoto : _idDocument);
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
      void pick(ImageSource src) => (handover || idProof)
          ? _pickHandover(src, idProof: idProof)
          : _pick(photo: photo, source: src);
      final has = bytes != null;
      return Expanded(
        child: Container(
          constraints: const BoxConstraints(minHeight: 0),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: has ? Colors.green.withValues(alpha: isDark ? 0.15 : 0.07) : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
            border: Border.all(color: has ? Colors.green.shade400 : scheme.outlineVariant),
          ),
          child: Column(children: [
            Row(children: [
              Icon(has ? Icons.check_circle : (handover ? Icons.photo_camera_front : (photo ? Icons.face_retouching_natural : Icons.badge_outlined)),
                  size: 18, color: has ? Colors.green.shade700 : scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: scheme.onSurface)),
              ),
            ]),
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
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => pick(ImageSource.camera),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6), minimumSize: const Size(0, 34)),
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
            ]),
          ]),
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Renter Documents & Photo',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: scheme.onSurface)),
      const SizedBox(height: 2),
      Text(
          'Take a live photo of the renter and a clear picture of their ${_idDocLabel.toLowerCase()}'
          '${_needsHandover ? ', their Aadhaar / passport, and a photo of the renter standing with the vehicle at handover' : ''}.',
          style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant)),
      const SizedBox(height: 8),
      IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          tile(photo: true),
          const SizedBox(width: 10),
          tile(photo: false),
        ]),
      ),
      if (_needsHandover) ...[
        const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            tile(photo: false, idProof: true),
            const SizedBox(width: 10),
            tile(photo: false, handover: true),
          ]),
        ),
      ],
    ]);
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
    _advanceController.dispose();
    _stayRoomTypeController.dispose();
    super.dispose();
  }

  /// Nothing is pre-selected: the provider picks the listing (or "Not listed").
  void _autoSelectFirstItem() {
    _selectedItemId = null;
    _priceController.clear();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open camera/gallery: $e'), backgroundColor: Colors.orange),
      );
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.add_a_photo_outlined, size: 36, color: scheme.outline),
                      const SizedBox(height: 4),
                      Text('Photo of the vehicle', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                    ]),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Row(children: [
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
        ]),
        const SizedBox(height: 4),
        Text('Enter the total price below manually.', style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
      ]),
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: _bookingTypeColor,
              primary: _bookingTypeColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _recalculatePrice();
      });
    }
  }

  void _recalculatePrice() {
    if (_selectedItemId == null || _isUnlisted) return;
    final days = mathMax(1, _endDate.difference(_startDate).inDays);
    if (_bookingType == 'vehicle') {
      final v = widget.vehicles.firstWhere((e) => e.id == _selectedItemId, orElse: () => widget.vehicles.first);
      _priceController.text = (v.pricePerDay * days).toStringAsFixed(0);
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

  Future<void> _pickTime({required bool pickup}) async {
    final t = await showTimePicker(context: context, initialTime: pickup ? _pickupTime : _returnTime);
    if (t != null) setState(() => pickup ? _pickupTime = t : _returnTime = t);
  }

  Future<void> _pickPaymentProof(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, maxWidth: 1600, imageQuality: 80);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (mounted) setState(() => _paymentProof = bytes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open camera/gallery: $e'), backgroundColor: Colors.orange),
      );
    }
  }

  /// Step 1 → 2: validate everything, then show the order overview.
  void _goToOverview() {
    if (!_formKey.currentState!.validate()) return;
    if (!_endAt.isAfter(_startAt)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Return date & time must be after the pickup'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    if (_needsHandover && (_handoverPhoto == null || _idProof == null) && _renterPhoto != null && _idDocument != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_idProof == null
            ? "Please upload the renter's Aadhaar card or passport"
            : 'Please take a photo of the renter with the vehicle'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    if (_renterPhoto == null || _idDocument == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_renterPhoto == null
              ? "Please take the renter's current photo"
              : 'Please upload the renter\'s $_idDocLabel'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_isUnlisted && _unlistedPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please take a picture of the vehicle'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    if (_selectedItemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an item to book'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() => _step = 1);
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
    final notes = [
      if (_notesController.text.trim().isNotEmpty) _notesController.text.trim(),
      'Rent ₹${_rent.toStringAsFixed(0)} + Advance ₹${_advance.toStringAsFixed(0)} = ₹${price.toStringAsFixed(0)}',
    ].join('\n');

    final bookingId = await widget.appState.createOfflineBooking(
      bookingType: _bookingType,
      itemId: _isUnlisted ? 'unlisted_${DateTime.now().millisecondsSinceEpoch}' : _selectedItemId!,
      itemPhotoBytes: _isUnlisted ? _unlistedPhoto : null,
      itemTitle: itemTitle,
      itemImageUrl: itemImageUrl,
      customerName: _customerNameController.text.trim(),
      customerPhone: _customerPhoneController.text.trim(),
      customerEmail: _customerEmailController.text.trim(),
      customerIdNumber: _customerIdNumberController.text.trim(),
      startDate: _startAt,
      endDate: _endAt,
      totalPrice: price,
      notes: notes,
      paymentProofBytes: _paymentProof,
      stayRoomType: _stayRoomTypeController.text.trim(),
      paymentMethod: _paymentMethod,
      renterPhotoBytes: _renterPhoto,
      idDocumentBytes: _idDocument,
      handoverPhotoBytes: _needsHandover ? _handoverPhoto : null,
      idProofBytes: _needsHandover ? _idProof : null,
    );

    if (mounted) {
      setState(() {
        _isSaving = false;
        _createdBookingId = bookingId;
        _step = 2;
      });
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
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
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
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
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
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_step == 1)
                ..._buildOverview(isDark)
              else if (_step == 2)
                ..._buildSuccess()
              else ...[
              // Booking Type Selector (Vehicle / Stay / Tour)
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTypeButton('vehicle', 'Vehicle / Bike', Icons.directions_bike),
                    ),
                    Expanded(
                      child: _buildTypeButton('stay', 'Homestay / Hotel', Icons.holiday_village_outlined),
                    ),
                    Expanded(
                      child: _buildTypeButton('tour', 'Guided Tour', Icons.tour_outlined),
                    ),
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

              // Booking Schedule & Total Price
              const Text(
                'BOOKING DATES & PRICING',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.grey),
              ),
              const SizedBox(height: 8),

              InkWell(
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
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.edit_calendar, size: 18, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _timeBox(label: 'Pickup time', time: _pickupTime, onTap: () => _pickTime(pickup: true))),
                const SizedBox(width: 10),
                Expanded(child: _timeBox(label: 'Return time', time: _returnTime, onTap: () => _pickTime(pickup: false))),
              ]),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Rent ₹ *',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        isDense: true,
                      ),
                      validator: (val) => (double.tryParse(val?.trim() ?? '') ?? 0) <= 0 ? 'Enter rent' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _advanceController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Advance / Deposit ₹',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  if (_bookingType == 'stay') ...[
                    Expanded(
                      child: TextFormField(
                        controller: _stayRoomTypeController,
                        decoration: InputDecoration(
                          labelText: 'Room Type',
                          prefixIcon: const Icon(Icons.meeting_room_outlined, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),

              _buildKycSection(isDark),
              const SizedBox(height: 12),

              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Special Notes / Customer Requests (Optional)',
                  hintText: 'e.g., Helmet provided, security deposit ₹1000 collected, etc.',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _goToOverview,
                      icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                      label: const Text(
                        'Next: Review order',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _bookingTypeColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
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

  Widget _timeBox({required String label, required TimeOfDay time, required VoidCallback onTap}) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(Icons.schedule, color: _bookingTypeColor, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            isDense: true,
          ),
          child: Text(time.format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      );

  String get _itemTitleForOverview {
    if (_isUnlisted) return _unlistedNameController.text.trim();
    if (_bookingType == 'vehicle') {
      return widget.vehicles.where((e) => e.id == _selectedItemId).map((e) => e.title).firstOrNull ?? '';
    }
    if (_bookingType == 'stay') {
      return widget.hotels.where((e) => e.id == _selectedItemId).map((e) => e.name).firstOrNull ?? '';
    }
    return widget.tours.where((e) => e.id == _selectedItemId).map((e) => e.title).firstOrNull ?? '';
  }

  Widget _overviewCard(String title, List<Widget> children) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(12, 6, 6, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.35)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(title,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.grey)),
            ),
            TextButton.icon(
              onPressed: () => setState(() => _step = 0),
              icon: const Icon(Icons.edit, size: 14),
              label: const Text('Edit', style: TextStyle(fontSize: 12)),
            ),
          ]),
          ...children,
        ]),
      );

  Widget _kv(String k, String v, {bool bold = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 4, right: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 92, child: Text(k, style: const TextStyle(fontSize: 12.5, color: Colors.grey))),
          Expanded(
            child: Text(v.isEmpty ? '—' : v,
                style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.bold : FontWeight.w500)),
          ),
        ]),
      );

  List<Widget> _buildOverview(bool isDark) {
    final f = DateFormat('EEE, dd MMM yyyy • hh:mm a');
    final docs = <(String, Uint8List?)>[
      ('Renter', _renterPhoto),
      (_idDocLabel, _idDocument),
      if (_needsHandover) ('Aadhaar / Passport', _idProof),
      if (_needsHandover) ('With vehicle', _handoverPhoto),
      if (_isUnlisted) ('Vehicle', _unlistedPhoto),
    ];
    String rs(double v) => '₹${v.toStringAsFixed(0)}';
    return [
      const Text('ORDER OVERVIEW', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1)),
      const SizedBox(height: 4),
      const Text('Check the details. Tap Edit to fix anything before submitting.',
          style: TextStyle(fontSize: 11.5, color: Colors.grey)),
      const SizedBox(height: 10),
      _overviewCard('BOOKING', [
        _kv('Type', _bookingType == 'vehicle' ? 'Vehicle / Bike' : _bookingType == 'stay' ? 'Homestay / Hotel' : 'Guided Tour'),
        _kv(_bookingType == 'vehicle' ? 'Vehicle' : 'Listing', _itemTitleForOverview, bold: true),
        if (_bookingType == 'stay') _kv('Room type', _stayRoomTypeController.text.trim()),
      ]),
      _overviewCard('CUSTOMER', [
        _kv('Name', _customerNameController.text.trim(), bold: true),
        _kv('Phone', _customerPhoneController.text.trim()),
        _kv('ID number', _customerIdNumberController.text.trim()),
        _kv('Email', _customerEmailController.text.trim()),
      ]),
      _overviewCard('SCHEDULE', [
        _kv('Pickup', f.format(_startAt), bold: true),
        _kv('Return', f.format(_endAt), bold: true),
      ]),
      _overviewCard('DOCUMENTS', [
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final (label, bytes) in docs)
            Column(mainAxisSize: MainAxisSize.min, children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: bytes != null
                    ? Image.memory(bytes, width: 64, height: 64, fit: BoxFit.cover)
                    : Container(width: 64, height: 64, color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported)),
              ),
              const SizedBox(height: 2),
              SizedBox(
                width: 64,
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10)),
              ),
            ]),
        ]),
      ]),
      if (_notesController.text.trim().isNotEmpty)
        _overviewCard('NOTES', [_kv('Notes', _notesController.text.trim())]),

      // Total payable
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _bookingTypeColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _bookingTypeColor.withValues(alpha: 0.4)),
        ),
        child: Column(children: [
          _kv('Rent', rs(_rent)),
          _kv('Advance', rs(_advance)),
          const Divider(),
          Row(children: [
            const Expanded(child: Text('Total payable', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
            Text(rs(_totalPayable),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _bookingTypeColor)),
          ]),
        ]),
      ),
      const SizedBox(height: 14),

      // Payment mode + proof
      DropdownButtonFormField<String>(
        initialValue: _paymentMethod,
        decoration: InputDecoration(
          labelText: 'Payment Mode',
          prefixIcon: const Icon(Icons.payments_outlined, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          isDense: true,
        ),
        items: const [
          DropdownMenuItem(value: 'Cash', child: Text('Cash Payment')),
          DropdownMenuItem(value: 'UPI / GPay / PhonePe', child: Text('UPI Direct')),
          DropdownMenuItem(value: 'Card (POS)', child: Text('Card POS')),
          DropdownMenuItem(value: 'Pay at Return / Checkout', child: Text('Pay at Checkout')),
        ],
        onChanged: (val) {
          if (val != null) setState(() => _paymentMethod = val);
        },
      ),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _paymentProof != null ? Colors.green.shade400 : Colors.grey.withValues(alpha: 0.4)),
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _paymentProof != null
                ? Image.memory(_paymentProof!, width: 64, height: 64, fit: BoxFit.cover)
                : Container(width: 64, height: 64, color: Colors.grey.shade200, child: const Icon(Icons.receipt_long)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Payment proof', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const Text('Photo / screenshot of the payment (optional)',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 6),
              Row(children: [
                OutlinedButton.icon(
                  onPressed: () => _pickPaymentProof(ImageSource.camera),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 32), padding: const EdgeInsets.symmetric(horizontal: 10)),
                  icon: const Icon(Icons.photo_camera, size: 15),
                  label: Text(_paymentProof != null ? 'Retake' : 'Camera', style: const TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 6),
                IconButton.outlined(
                  tooltip: 'Choose from gallery',
                  onPressed: () => _pickPaymentProof(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined, size: 17),
                ),
              ]),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 18),
      Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isSaving ? null : () => setState(() => _step = 0),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _handleSave,
            icon: _isSaving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.check_circle_outline, color: Colors.white),
            label: Text(_isSaving ? 'Submitting...' : 'Submit booking',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _bookingTypeColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ]),
    ];
  }

  List<Widget> _buildSuccess() => [
        const SizedBox(height: 12),
        const Center(child: Icon(Icons.check_circle_rounded, size: 72, color: Colors.green)),
        const SizedBox(height: 8),
        const Center(child: Text('Booking created!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
        const SizedBox(height: 4),
        Center(
          child: Text('for ${_customerNameController.text.trim()} • ₹${_totalPayable.toStringAsFixed(0)}',
              style: const TextStyle(color: Colors.grey)),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _bookingTypeColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _bookingTypeColor.withValues(alpha: 0.4)),
          ),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('BOOKING ID', style: TextStyle(fontSize: 11, letterSpacing: 1, color: Colors.grey)),
                const SizedBox(height: 4),
                SelectableText(_createdBookingId,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _bookingTypeColor)),
              ]),
            ),
            IconButton(
              tooltip: 'Copy',
              icon: const Icon(Icons.copy),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _createdBookingId));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking ID copied')));
              },
            ),
          ]),
        ),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Done'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.appState.setNavIndex(19);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _bookingTypeColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('View bookings'),
            ),
          ),
        ]),
      ];

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
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
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
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          isDense: true,
        ),
        items: [
          const DropdownMenuItem(
            value: _unlisted,
            child: Row(children: [
              Icon(Icons.add_a_photo_outlined, size: 20, color: Colors.deepOrange),
              SizedBox(width: 8),
              Expanded(
                child: Text('Not listed — take a picture',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.deepOrange),
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
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
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          isDense: true,
        ),
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
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          isDense: true,
        ),
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
