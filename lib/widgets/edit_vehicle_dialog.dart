import 'package:flutter/material.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../screens/register_vehicle_screen.dart';

/// Opens the host vehicle editing page matching the vehicle registration wizard layout.
void showEditVehicleDialog(
  BuildContext context,
  AppState appState,
  Vehicle vehicle,
) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => RegisterVehicleScreen(vehicleToEdit: vehicle),
    ),
  );
}
