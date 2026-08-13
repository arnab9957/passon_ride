# PassonRide 🚗🛵⚡

**PassonRide** is a next-generation, cross-platform Peer-to-Peer (P2P) Vehicle Rental and AI-Powered Guided Tour Marketplace built with **Flutter**. It seamlessly connects vehicle owners and tour hosts with travelers and adventure seekers.

Featuring real-time IoT telematics tracking, keyless vehicle access, AI itinerary generation, kinetic trust scoring, and robust compliance management, PassonRide delivers a state-of-the-art mobility experience on iOS, Android, Web, and Desktop.

---

## 🌟 Key Features

### 🚗 1. P2P Vehicle Rental Marketplace
* **Multi-Category Fleet**: Rent motorcycles, electric scooters, luxury/economy cars, and EVs (`VehicleType.bike`, `car`, `scooter`, `electric`).
* **Smart Search & Filters**: Search by location, category, instant booking status, and price range.
* **Vehicle Detail View**: Interactive booking calendar, full vehicle specifications, host profiles, and reviews.

### 🤖 2. AI Tour & Adventure Generator
* **AI Itinerary Builder**: Generate custom multi-day road trips and adventure tours based on destination, duration, budget, and terrain preferences.
* **Curated Guided Rides**: Discover host-guided tours complete with waypoints, included gear, and guide details.

### 🛰️ 3. Real-Time Telematics & IoT Health Hub
* **Live Vehicle Monitoring**: Monitor battery state-of-charge, fuel levels, tire pressures (TPMS), and engine health diagnostics (OBD-II).
* **Telemetry & GPS**: View live vehicle location tracking, odometer readings, and telemetry diagnostics.

### 🛡️ 4. Kinetic Trust & Safety Engine
* **Dynamic Trust Score**: Multi-factor scoring algorithm evaluating host reliability, driver history, and telematics behavior.
* **Trust Badges**: Earn badges such as *Verified Driver*, *Superhost*, *Eco-Rider*, and *Fleet Manager*.

### 🗝️ 5. Keyless Entry & Booking Verification
* **PIN & QR Unlock**: Secure PIN unlock passcodes and QR code scanning for effortless keyless pickup.
* **Rental Status Flow**: Real-time lifecycle tracking across *Confirmed*, *Active*, *Completed*, and *Cancelled* states.

### 💼 6. Host & Provider Ecosystem
* **Provider Dashboard**: Manage vehicle fleets, monitor booking requests, view utilization rates, and respond to clients.
* **Vehicle & Tour Listing**: Onboard vehicles and create guided group tours with custom pricing and availability.
* **Earnings Analytics**: Visual earnings breakdowns, payout tracking, and transaction summaries.

### 📄 7. Document & Compliance Hub
* **KYC & Identity Verification**: Upload and verify Driving Licenses, Vehicle Registrations (RC), Insurance documents, and Commercial Permits.

### 💬 8. In-App Messaging
* **Real-time Chat**: Direct messaging between riders, vehicle owners, and tour guides.

---

## 🏗️ Architecture & Tech Stack

* **Framework**: [Flutter](https://flutter.dev/) (Dart SDK `^3.12.2`)
* **State Management**: [Provider](https://pub.dev/packages/provider) (`AppState`)
* **Backend Services**:
  * [Firebase Core](https://pub.dev/packages/firebase_core) & [Cloud Firestore](https://pub.dev/packages/cloud_firestore)
  * [Firebase Authentication](https://pub.dev/packages/firebase_auth) & [Google Sign-In](https://pub.dev/packages/google_sign_in)
  * [Firebase Analytics](https://pub.dev/packages/firebase_analytics) & Remote Config
* **Monetization**: [Google Mobile Ads / AdMob](https://pub.dev/packages/google_mobile_ads)
* **Design & Theme**: Custom Material 3 theme (`AppTheme`) supporting Light and Dark modes.

---

## 📁 Directory Structure

```text
lib/
├── config/                  # Environment & App configurations
│   └── env_config.dart
├── models/                  # Data models (Vehicle, Tour, Booking, Chat, Compliance)
│   └── models.dart
├── providers/               # State management (AppState)
│   └── app_state.dart
├── screens/                 # Application Screens
│   ├── ai_tour_generator_screen.dart
│   ├── booking_verification_screen.dart
│   ├── chat_screen.dart
│   ├── discovery_screen.dart
│   ├── documents_compliance_screen.dart
│   ├── earnings_screen.dart
│   ├── favorites_screen.dart
│   ├── home_screen.dart
│   ├── kinetic_trust_screen.dart
│   ├── main_navigation_screen.dart
│   ├── message_list_screen.dart
│   ├── payment_checkout_screen.dart
│   ├── profile_screen.dart
│   ├── provider_dashboard_screen.dart
│   ├── register_tour_screen.dart
│   ├── register_vehicle_screen.dart
│   ├── telematics_hub_screen.dart
│   └── vehicle_detail_screen.dart
├── services/                # External Services & APIs
│   ├── ad_manager.dart
│   ├── firebase_auth_service.dart
│   └── firestore_service.dart
├── theme/                   # Custom Theme & Colors
│   ├── app_colors.dart
│   └── app_theme.dart
└── widgets/                 # Reusable UI Components & Dialogs
    └── firebase_auth_dialog.dart
```

---

## 🚀 Getting Started

### Prerequisites

Ensure you have the following installed on your system:
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.12.2`)
* [Dart SDK](https://dart.dev/get-dart)
* Android Studio / Xcode (for mobile development) or VS Code with Flutter extension.

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/arnab9957/passon_ride.git
   cd passon_ride
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure Environment**:
   Copy `.env.example` to `.env` and fill in any required variables:
   ```bash
   cp .env.example .env
   ```

4. **Firebase Configuration**:
   Ensure platform options are configured in `lib/firebase_options.dart` or via FlutterFire CLI:
   ```bash
   flutterfire configure
   ```

5. **Run the Application**:
   ```bash
   flutter run
   ```

---

## 📱 Supported Platforms

* 📱 **Android**
* 🍎 **iOS**
* 🌐 **Web**
* 💻 **macOS / Windows / Linux**

---

## 📄 License

This project is proprietary and confidential. All rights reserved.

