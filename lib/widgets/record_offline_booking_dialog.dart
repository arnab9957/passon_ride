// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
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

  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerEmailController = TextEditingController();
  final _customerIdNumberController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  final _stayRoomTypeController = TextEditingController(text: 'Deluxe / Standard');

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  String _paymentMethod = 'Cash';
  bool _isSaving = false;

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
    _stayRoomTypeController.dispose();
    super.dispose();
  }

  void _autoSelectFirstItem() {
    if (_bookingType == 'vehicle' && widget.vehicles.isNotEmpty) {
      _selectedItemId = widget.vehicles.first.id;
      _priceController.text = widget.vehicles.first.pricePerDay.toStringAsFixed(0);
    } else if (_bookingType == 'stay' && widget.hotels.isNotEmpty) {
      _selectedItemId = widget.hotels.first.id;
      _priceController.text = widget.hotels.first.pricePerNight.toStringAsFixed(0);
    } else if (_bookingType == 'tour' && widget.tours.isNotEmpty) {
      _selectedItemId = widget.tours.first.id;
      _priceController.text = widget.tours.first.price.toStringAsFixed(0);
    } else {
      _selectedItemId = null;
    }
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

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedItemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an item to book'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    String itemTitle = '';
    String itemImageUrl = '';

    if (_bookingType == 'vehicle') {
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

    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;

    await widget.appState.createOfflineBooking(
      bookingType: _bookingType,
      itemId: _selectedItemId!,
      itemTitle: itemTitle,
      itemImageUrl: itemImageUrl,
      customerName: _customerNameController.text.trim(),
      customerPhone: _customerPhoneController.text.trim(),
      customerEmail: _customerEmailController.text.trim(),
      customerIdNumber: _customerIdNumberController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      totalPrice: price,
      notes: _notesController.text.trim(),
      stayRoomType: _stayRoomTypeController.text.trim(),
      paymentMethod: _paymentMethod,
    );

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

              Row(
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
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
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
                  ),
                  if (_bookingType == 'stay') ...[
                    const SizedBox(width: 10),
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
                      onPressed: _isSaving ? null : _handleSave,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle_outline, color: Colors.white),
                      label: Text(
                        _isSaving ? 'Recording...' : 'Confirm Offline Booking',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
          ),
        ),
      ),
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
      if (widget.vehicles.isEmpty) {
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
              Expanded(child: Text('No vehicles hosted yet. Register a vehicle first.', style: TextStyle(fontSize: 12))),
            ],
          ),
        );
      }
      return DropdownButtonFormField<String>(
        initialValue: _selectedItemId,
        isExpanded: true,
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          isDense: true,
        ),
        items: widget.vehicles.map((v) {
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
        }).toList(),
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
        initialValue: _selectedItemId,
        isExpanded: true,
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
        initialValue: _selectedItemId,
        isExpanded: true,
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
