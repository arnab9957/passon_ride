# PassionRide 🚗🛵⚡

**PassionRide** is a next-generation, cross-platform Peer-to-Peer (P2P) Vehicle Rental, IoT Telematics Monitoring, and AI-Powered Guided Tour Marketplace built with **Flutter**. It seamlessly connects vehicle hosts and tour operators with travelers and adventure enthusiasts.

Featuring real-time IoT telematics tracking, keyless vehicle access, AI itinerary generation, kinetic trust scoring, multi-language localization, document OCR verification, and robust compliance management, PassionRide delivers a state-of-the-art mobility experience on **iOS, Android, Web, macOS, Windows, and Linux**.

---

## 🌟 Key Functional Sections & Features

### 🚗 1. P2P Vehicle Rental Marketplace
* **Multi-Category Fleet Catalog**: Browse and rent motorcycles, electric scooters, luxury/economy cars, and EVs (`VehicleType.bike`, `car`, `scooter`, `electric`).
* **Geospatial Search & Filters**: Search by real-time location (GPS/Geocoding), instant booking status, price range, transmission type, and fuel type.
* **Interactive Vehicle Detail View**: Inspect comprehensive specs, host ratings, review breakdowns, dynamic booking calendars, and high-resolution photo carousels.

### 🤖 2. AI Tour & Adventure Generator
* **AI Itinerary Engine**: Generate personalized multi-day road trip itineraries using **Google Gemini AI** (with **Groq AI** fallback) based on destination, trip duration, budget, and terrain preferences.
* **Curated Host-Guided Tours**: Onboard and discover host-guided group rides complete with interactive map waypoints, included safety gear, terrain difficulty metrics, and guide details.

### 🌐 3. Multi-Language & Native Localization System
* **Statically Typed Code Generation**: Built with **`slang`** (`slang.yaml`) for zero-cost, type-safe multi-language support covering **English (en)**, **Hindi (hi)**, **Bengali (bn)**, and **Spanish (es)**.
* **Live LibreTranslate Engine**: Integrates **`LibreTranslateService`** for on-the-fly AI translation of user-generated content with an **in-memory LRU cache** ensuring 0ms latency for repeated terms.

### 🛰️ 4. Real-Time IoT Telematics & Fleet Health Hub
* **Vehicle Diagnostics**: Live tracking of battery State-of-Charge (SoC), fuel levels, tire pressure monitoring systems (TPMS front/rear PSI), and OBD-II trouble codes.
* **Telemetry & GPS Routing**: Real-time vehicle location streaming on interactive maps, speed limit compliance, odometer tracking, and remote vehicle status telemetry.

### 🛡️ 5. Kinetic Trust & Safety Engine
* **Dynamic Trust Algorithm**: Multi-factor scoring system evaluating host reliability, driver trip history, telematics driving behavior, and verified credentials.
* **Trust Badges**: Earn verifiable badges including *Verified Driver*, *Superhost*, *Eco-Rider*, *Safety Champion*, and *Fleet Manager*.

### 🗝️ 6. Keyless Access & Booking Verification
* **PIN Passcode & QR Code Unlock**: Secure 6-digit PIN unlock generation and camera-based QR code scanning for seamless keyless vehicle pickup.
* **Booking State Machine**: Real-time lifecycle state transitions across `Confirmed`, `Active`, `Completed`, and `Cancelled` states with escrow hold releases.

### 📄 7. Document OCR & KYC Compliance Hub
* **Automated Identity Verification**: Powered by **`DocumentOcrService`** for scanning and parsing Driving Licenses, Vehicle Registrations (RC), Insurance documents, and Commercial Permits.
* **Compliance Dashboard**: Track document status (`Verified`, `Pending`, `Action Required`) and expiry dates with automated re-verification alerts.

### 💬 8. In-App Messaging & Platform Bypass Protection
* **Stream Chat & Real-Time Messaging**: Built-in instant messaging between riders, hosts, and tour guides.
* **Platform Leakage Filter**: Proprietary regex and NLP filter (**`PlatformLeakageFilter`**) that detects and blocks off-platform transaction attempts (e.g., hidden phone numbers, email addresses, social handles) to enforce platform safety and escrow protection.

### 💳 9. Escrow Payments & Razorpay Integration
* **Multi-Gateway Support**: Integrates **`RazorpayService`** with web bridge stubs (`razorpay_web_bridge`, `web_auth_helper`) for seamless payment processing on mobile and web.
* **Security Deposit Escrow**: Automated pre-authorization holds and automated post-rental settlement logic.

### 📊 10. Host & Fleet Provider Ecosystem
* **Provider Dashboard**: Real-time fleet overview, vehicle availability toggles, active rental monitoring, and fleet utilization metrics.
* **Earnings Analytics**: Visual monthly/weekly revenue charts, payout logs, and completed trip financial breakdowns.

### 📢 11. Monetization & Ad Manager
* **Google Mobile Ads / AdMob**: Integrated banner and interstitial ad placement via **`AdManager`** for free-tier users.

---

## 🏗️ Architecture & Tech Stack

* **Frontend Framework**: [Flutter](https://flutter.dev/) (Dart SDK `>=3.12.2`)
* **State Management**: [Provider](https://pub.dev/packages/provider) (`AppState`, `LanguageProvider`)
* **Localization Engine**: [Slang](https://pub.dev/packages/slang) (`slang_flutter`) & [LibreTranslate](https://libretranslate.com/)
* **Backend Services**:
  * **Supabase**: PostgreSQL database, PostGIS spatial queries, Row Level Security (RLS), Supabase Auth, Storage, and Realtime streams.
  * **Firebase**: Firebase Core, Cloud Firestore, Firebase Auth, Analytics, and Remote Config.
* **AI & Machine Learning**: Google Gemini 1.5/2.0 API, Groq AI API, Tesseract OCR for document parsing.
* **Real-time Chat**: Stream Chat Flutter SDK (`StreamChatService`).
* **Payments**: Razorpay SDK (`razorpay_flutter`) with cross-platform web stubs.
* **Maps & Location**: Geolocator, Flutter Map / Google Maps, Nominatim Geocoding API.
* **Media CDN**: ImageKit.io CDN integration (`ImageKitService`).

---

## 📁 Repository Directory Structure

```text
passon_ride/
├── .env.example                     # Environment configuration template
├── slang.yaml                       # Slang internationalization configuration
├── BACKEND_ARCHITECTURE.md          # Comprehensive backend schema & API specifications
├── README.md                        # Master project documentation
├── web/
│   └── technical_documentation.html # Interactive offline technical documentation web dashboard
├── lib/
│   ├── config/                      # Environment settings & API keys
│   │   └── env_config.dart
│   ├── i18n/                        # Internationalization translations & generated files
│   │   ├── en.i18n.json             # English translations
│   │   ├── hi.i18n.json             # Hindi translations
│   │   ├── bn.i18n.json             # Bengali translations
│   │   ├── es.i18n.json             # Spanish translations
│   │   ├── strings.g.dart           # Master Slang translation generator
│   │   ├── strings_en.g.dart
│   │   ├── strings_hi.g.dart
│   │   ├── strings_bn.g.dart
│   │   └── strings_es.g.dart
│   ├── models/                      # Strongly-typed Dart data models
│   │   ├── models.dart              # Vehicle, Tour, Booking, ChatThread, Compliance models
│   │   ├── feedback_model.dart      # Reviews, ratings & feedback models
│   │   └── location_model.dart      # GPS coordinates & geo-location models
│   ├── providers/                   # Reactive state management providers
│   │   ├── app_state.dart           # Main application state & business logic
│   │   └── language_provider.dart    # Multi-language locale switcher & LRU translation cache
│   ├── screens/                     # UI Screen Components (22 Screens)
│   │   ├── ai_tour_generator_screen.dart
│   │   ├── booking_verification_screen.dart
│   │   ├── chat_screen.dart
│   │   ├── discovery_screen.dart
│   │   ├── documents_compliance_screen.dart
│   │   ├── earnings_screen.dart
│   │   ├── favorites_screen.dart
│   │   ├── feedback_dashboard_screen.dart
│   │   ├── home_screen.dart
│   │   ├── in_app_web_view_screen.dart
│   │   ├── kinetic_trust_screen.dart
│   │   ├── location_screen.dart
│   │   ├── main_navigation_screen.dart
│   │   ├── message_list_screen.dart
│   │   ├── my_bookings_screen.dart
│   │   ├── payment_checkout_screen.dart
│   │   ├── profile_screen.dart
│   │   ├── provider_dashboard_screen.dart
│   │   ├── register_tour_screen.dart
│   │   ├── register_vehicle_screen.dart
│   │   ├── telematics_hub_screen.dart
│   │   └── vehicle_detail_screen.dart
│   ├── services/                    # API Services, Hardware & External Integrations (23 Services)
│   │   ├── ad_manager.dart          # Mobile Ads service
│   │   ├── document_ocr_service.dart# ID & driving license OCR scanner
│   │   ├── feedback_service.dart    # Customer review & sentiment service
│   │   ├── gemini_ai_service.dart   # Google Gemini AI tour itinerary engine
│   │   ├── groq_ai_service.dart     # Groq LLM fallback engine
│   │   ├── imagekit_service.dart    # ImageKit CDN uploader & optimizer
│   │   ├── libretranslate_service.dart # Real-time translation API with LRU cache
│   │   ├── local_storage_service.dart  # Offline Hive / SharedPreferences persistence
│   │   ├── location_service.dart    # Geolocator & GPS reverse-geocoding service
│   │   ├── platform_leakage_filter.dart # Anti-bypass off-platform content filter
│   │   ├── razorpay_service.dart    # Payment gateway service & web stubs
│   │   ├── stream_chat_service.dart # Stream Chat SDK initialization
│   │   ├── supabase_service.dart    # Supabase DB, RLS, Storage & Realtime
│   │   ├── supabase_auth_service.dart # Supabase Authentication helper
│   │   └── transactional_notification_service.dart # Push & transactional alerts
│   ├── theme/                       # Design System & Material 3 Styling
│   │   ├── app_colors.dart          # Color tokens & gradients
│   │   └── app_theme.dart           # Dark & Light Material 3 theme configurations
│   └── widgets/                     # Reusable UI Widgets & Dialogs
│       ├── supabase_auth_dialog.dart# Auth modal dialog
│       └── tour_details_modal.dart  # Tour itinerary view modal
└── test/                            # Unit & Integration Tests
    ├── widget_test.dart
    └── libretranslate_test.dart
```

---

## 🚀 Environment Setup & Getting Started

### Prerequisites

Ensure you have the following installed:
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>=3.12.2`)
* [Dart SDK](https://dart.dev/get-dart)
* Android Studio / Xcode (for mobile builds) or VS Code.

### Installation

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/arnab9957/passon_ride.git
   cd passon_ride
   ```

2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure Environment Variables**:
   Copy `.env.example` to `.env` and enter your API keys:
   ```bash
   cp .env.example .env
   ```
   *Required Keys*:
   * `SUPABASE_URL` & `SUPABASE_ANON_KEY`
   * `GEMINI_API_KEY` / `GROQ_API_KEY`
   * `IMAGEKIT_PUBLIC_KEY`, `IMAGEKIT_PRIVATE_KEY`, `IMAGEKIT_URL_ENDPOINT`
   * `RAZORPAY_KEY_ID`

4. **Generate Translations (Slang)**:
   If you modify JSON files in `lib/i18n/`, regenerate Dart classes with:
   ```bash
   dart run slang
   ```

5. **Run Analysis & Tests**:
   ```bash
   flutter analyze
   flutter test test/libretranslate_test.dart
   ```

6. **Run the Application**:
   ```bash
   flutter run -d chrome     # Web
   flutter run -d android    # Android
   flutter run -d ios        # iOS
   ```

---

## 📱 Supported Platforms

* 📱 **Android** (API Level 21+)
* 🍎 **iOS** (iOS 13.0+)
* 🌐 **Web** (Chrome, Safari, Firefox, Edge)
* 💻 **macOS / Windows / Linux**

---

## 📄 License & Ownership

Proprietary Software. All rights reserved by **PassionRide Technologies**.
