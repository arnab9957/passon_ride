import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state.dart';
import '../../models/models.dart';

class BookingsManagementScreen extends StatefulWidget {
  const BookingsManagementScreen({super.key});

  @override
  State<BookingsManagementScreen> createState() => _BookingsManagementScreenState();
}

class _BookingsManagementScreenState extends State<BookingsManagementScreen> {
  final int _limit = 20;
  int _currentPage = 1;
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStatus = 'All';

  List<Booking> _bookings = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    final appState = Provider.of<AppState>(context, listen: false);
    final bookings = await appState.supabaseService.getBookingsPaginated(
      _currentPage,
      _limit,
      searchQuery: _searchQuery,
      status: _selectedStatus,
    );
    if (!mounted) return;
    setState(() {
      _bookings = bookings;
      _isLoading = false;
    });
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    _currentPage = 1;
    _loadBookings();
  }

  void _onStatusChanged(String? status) {
    if (status != null) {
      _selectedStatus = status;
      _currentPage = 1;
      _loadBookings();
    }
  }

  void _showBookingDetails(Booking booking) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Booking #${booking.id.substring(0, 8)}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Vehicle: ${booking.vehicleTitle}'),
              Text('Rider: ${booking.customerName} (${booking.customerEmail})'),
              Text('Host: ${booking.hostName}'),
              Text('Total Price: ₹${booking.totalPrice.toStringAsFixed(2)}'),
              Text('Status: ${booking.status}'),
              const SizedBox(height: 8),
              Text('Dates: ${DateFormat('MMM dd').format(booking.startDate)} - ${DateFormat('MMM dd, yyyy').format(booking.endDate)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by booking ID or user name',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onSubmitted: _onSearchChanged,
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _selectedStatus,
                items: ['All', 'Upcoming', 'Active', 'Completed', 'Cancelled', 'Disputed'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: _onStatusChanged,
              ),
            ],
          ),
        ),

        // List View
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _bookings.isEmpty
                  ? const Center(child: Text('No bookings found.'))
                  : ListView.builder(
                      itemCount: _bookings.length,
                      itemBuilder: (context, index) {
                        final booking = _bookings[index];
                        return ListTile(
                          leading: const Icon(Icons.book_online),
                          title: Text('Booking #${booking.id.substring(0, 8)} - ${booking.vehicleTitle}'),
                          subtitle: Text('${booking.status} • ₹${booking.totalPrice.toStringAsFixed(2)} • Rider: ${booking.customerName}'),
                          trailing: Text(
                            DateFormat('MMM dd, yyyy').format(booking.createdAt),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          onTap: () => _showBookingDetails(booking),
                        );
                      },
                    ),
        ),

        // Pagination Controls
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage > 1
                    ? () {
                        _currentPage--;
                        _loadBookings();
                      }
                    : null,
              ),
              Text('Page $_currentPage'),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _bookings.length == _limit
                    ? () {
                        _currentPage++;
                        _loadBookings();
                      }
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
