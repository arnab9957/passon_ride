import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';

class RegisterVehicleScreen extends StatefulWidget {
  const RegisterVehicleScreen({super.key});

  @override
  State<RegisterVehicleScreen> createState() => _RegisterVehicleScreenState();
}

class _RegisterVehicleScreenState extends State<RegisterVehicleScreen> {
  final _titleController = TextEditingController(text: '2025 Yamaha Tenere 700');
  final _priceController = TextEditingController(text: '115.00');
  final _vinController = TextEditingController(text: 'JYACJ01E8L0094819');
  String _selectedCategory = 'Motorcycle';
  bool _instantBook = true;

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
                onPressed: () => appState.setNavIndex(8),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HOST LISTING WIZARD',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: isDark ? AppColors.secondaryFixedDim : AppColors.secondary,
                    ),
                  ),
                  const Text('Register New Vehicle', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Basic Details
          const Text('1. Basic Vehicle Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),

          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Vehicle Title / Make & Model',
              prefixIcon: Icon(Icons.directions_car),
            ),
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Vehicle Type',
              prefixIcon: Icon(Icons.category),
            ),
            items: ['Motorcycle', 'Car', 'Scooter', 'Electric EV']
                .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                .toList(),
            onChanged: (val) => setState(() => _selectedCategory = val!),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _vinController,
            decoration: const InputDecoration(
              labelText: 'VIN / Registration Plate Number',
              prefixIcon: Icon(Icons.pin),
            ),
          ),

          const SizedBox(height: 24),

          // Pricing & Policies
          const Text('2. Rental Rates & Instant Booking', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),

          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Daily Price Rate (\$USD)',
              prefixIcon: Icon(Icons.attach_money),
            ),
          ),
          const SizedBox(height: 12),

          SwitchListTile(
            title: const Text('Enable Instant Booking', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: const Text('Verified renters can book without waiting for host approval', style: TextStyle(fontSize: 12)),
            value: _instantBook,
            onChanged: (val) => setState(() => _instantBook = val),
            activeColor: AppColors.secondary,
          ),

          const SizedBox(height: 24),

          // IoT Telematics Device Pair
          const Text('3. Pair IoT Telematics Hardware', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.secondary),
            ),
            child: Row(
              children: [
                const Icon(Icons.bluetooth_searching, color: AppColors.secondary, size: 28),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PassonRide OBD-II IoT Node', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('Device ID: #IOT-NODE-9941 (Connected)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('IoT Telematics Node Test Signal Verified!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                  child: const Text('Test Lock', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () async {
                final title = _titleController.text.trim();
                final price = double.tryParse(_priceController.text.trim()) ?? 100.0;
                final isCar = _selectedCategory.contains('Car');
                final isScooter = _selectedCategory.contains('Scooter');

                final newVehicle = Vehicle(
                  id: 'v_${DateTime.now().millisecondsSinceEpoch}',
                  title: title.isEmpty ? 'Custom Vehicle Listing' : title,
                  type: isCar ? VehicleType.car : (isScooter ? VehicleType.scooter : VehicleType.bike),
                  category: _selectedCategory,
                  pricePerDay: price,
                  rating: 5.0,
                  reviewCount: 1,
                  imageUrl: isCar
                      ? 'https://images.unsplash.com/photo-1560958089-b8a1929cea89?w=800&q=80'
                      : 'https://images.unsplash.com/photo-1558981403-c5f9899a28bc?w=800&q=80',
                  location: appState.selectedLocation,
                  hostName: appState.activeUserDisplayName,
                  hostAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&q=80',
                  hostTrustScore: 99.0,
                  fuelType: 'Gasoline',
                  transmission: 'Automatic',
                  seats: isCar ? 5 : 2,
                  description: 'Freshly registered rental listing. Maintained in prime condition with keyless IoT access.',
                  iotData: {
                    'locked': true,
                    'engineOn': false,
                    'batteryLevel': 98,
                    'odometer': 1200,
                    'tirePressureFront': 32.0,
                    'tirePressureRear': 35.0,
                    'lat': 37.7749,
                    'lng': -122.4194,
                  },
                );

                await appState.addVehicle(newVehicle);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Vehicle "$title" published live to PassonRide Marketplace!'),
                      backgroundColor: Colors.green.shade700,
                    ),
                  );
                  appState.setNavIndex(8); // Return to provider dashboard
                }
              },
              icon: const Icon(Icons.publish),
              label: const Text('Publish Vehicle Listing', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
