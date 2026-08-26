import 'dart:math' as math;
import '../providers/app_state.dart';

class IrsargoContextCollector {
  /// Scrapes and formats rich, real-time public front-end UI data from Flutter AppState.
  /// Strictly collects ONLY front-end visible information (no internal secrets or credentials).
  static String collectPublicAppContext(AppState appState) {
    final screenNames = [
      'Home Screen',
      'Discovery Catalog',
      'Vehicle Details',
      'Booking Verification',
      'Checkout & Payment',
      'Live Chat',
      'Inbox',
      'Favorites',
      'Host Dashboard',
      'Earnings & Payouts',
      'Register Vehicle',
      'Register Guided Tour',
      'AI Tour Generator',
      'IoT Telematics Hub',
      'Documents & Compliance',
      'Kinetic Trust',
      'Profile Settings',
    ];

    final activeScreen = (appState.currentNavIndex < screenNames.length)
        ? screenNames[appState.currentNavIndex]
        : 'PassionRide Main Canvas';

    final sb = StringBuffer();
    sb.writeln('Active Flutter Screen: $activeScreen');
    sb.writeln('User Location Setting: ${appState.selectedLocation}');
    sb.writeln(
      'Active Role: ${appState.activeUserRole} (Trust Score: ${appState.activeUserTrustScore})',
    );

    if (appState.searchQuery.isNotEmpty) {
      sb.writeln('User Active Search Filter: "${appState.searchQuery}"');
    }
    if (appState.selectedCategory != 'All') {
      sb.writeln('Selected Category Filter: ${appState.selectedCategory}');
    }

    // 1. Visible Vehicles on User Screen
    final visibleVehicles = appState.filteredVehicles;
    if (visibleVehicles.isNotEmpty) {
      sb.writeln(
        '\n[VISIBLE VEHICLE LISTINGS ON SCREEN (${visibleVehicles.length} items)]',
      );
      final count = math.min(visibleVehicles.length, 5);
      for (int i = 0; i < count; i++) {
        final v = visibleVehicles[i];
        sb.writeln(
          '- Vehicle #${i + 1}: ${v.title} | Category: ${v.category} | Type: ${v.type.name} | Price: \$${v.pricePerDay}/day | Location: ${v.location} | Host: ${v.hostName} | Instant Book: ${v.isInstantBookable}',
        );
        if (v.description.isNotEmpty) {
          final descSnippet = v.description.length > 80
              ? '${v.description.substring(0, 80)}...'
              : v.description;
          sb.writeln('  Description: $descSnippet');
        }
        final iot = v.iotData;
        sb.writeln(
          '  IoT Diagnostics: Battery ${iot['batteryLevel'] ?? iot['batterySoc'] ?? 90}%, Fuel ${iot['fuelLevel'] ?? 100}%, Speed ${iot['speed'] ?? 0} km/h, DTC Codes: ${iot['dtcCodes'] ?? "None"}',
        );
      }
    } else {
      sb.writeln('\n[VISIBLE VEHICLE LISTINGS ON SCREEN]');
      sb.writeln('No vehicle listings currently match search criteria.');
    }

    // 2. Selected Guided Tour Details (if active)
    if (appState.selectedTour != null) {
      final t = appState.selectedTour!;
      sb.writeln('\n[ACTIVE SELECTED GUIDED TOUR]');
      sb.writeln('Tour Name: ${t.title}');
      sb.writeln('Location: ${t.location}');
      sb.writeln('Price: \$${t.price} | Duration: ${t.duration}');
      sb.writeln('Guide Name: ${t.guideName}');
      if (t.waypoints.isNotEmpty) {
        sb.writeln('Route Waypoints: ${t.waypoints.join(" ➔ ")}');
      }
      if (t.includedGear.isNotEmpty) {
        sb.writeln('Included Gear: ${t.includedGear.join(", ")}');
      }
    } else if (appState.filteredTours.isNotEmpty) {
      sb.writeln(
        '\n[AVAILABLE GUIDED TOURS (${appState.filteredTours.length} items)]',
      );
      final count = math.min(appState.filteredTours.length, 3);
      for (int i = 0; i < count; i++) {
        final t = appState.filteredTours[i];
        sb.writeln(
          '- Tour #${i + 1}: ${t.title} | ${t.location} | \$${t.price} (${t.duration}) | Guide: ${t.guideName}',
        );
      }
    }

    // 3. User Reservations / Active Bookings
    if (appState.activeBookings.isNotEmpty) {
      sb.writeln(
        '\n[ACTIVE USER RESERVATIONS (${appState.activeBookings.length} bookings)]',
      );
      for (var b in appState.activeBookings.take(3)) {
        final shortId = b.id.length > 8 ? b.id.substring(0, 8) : b.id;
        sb.writeln(
          '- Booking #$shortId | Status: ${b.status} | Total: \$${b.totalPrice} | Dates: ${b.startDate.toString().split(" ").first} to ${b.endDate.toString().split(" ").first}',
        );
      }
    }

    // 4. Notifications Summary
    if (appState.notifications.isNotEmpty) {
      sb.writeln(
        '\n[USER UNREAD NOTIFICATIONS: ${appState.unreadNotificationCount}]',
      );
    }

    return sb.toString().trim();
  }
}
