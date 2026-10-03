import 'package:flutter/material.dart';
import '../models/models.dart';
import 'register_vehicle_screen.dart';

/// Full-page screen for host editing vehicle details matching the vehicle registration wizard layout.
class EditVehicleScreen extends StatelessWidget {
  final Vehicle vehicle;

  const EditVehicleScreen({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return RegisterVehicleScreen(vehicleToEdit: vehicle);
  }
}
