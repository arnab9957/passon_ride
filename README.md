# PassionRide 🚗🛵⚡

**PassionRide** is a next-generation, cross-platform Peer-to-Peer (P2P) Vehicle Rental, Guided Tour Marketplace, and AI-powered Adventure ecosystem built with **Flutter**. It seamlessly connects vehicle owners and tour hosts with travelers and adventure seekers.

Featuring real-time IoT telematics tracking, keyless vehicle access, AI itinerary generation, kinetic trust scoring, multi-aspect feedback systems, multilingual support, and a context-aware AI assistant (Irsargo Co-pilot), PassionRide delivers a state-of-the-art mobility experience across iOS, Android, Web, and Desktop.

---

## 🌟 Key Features

### 🚗 1. P2P Vehicle Rental Marketplace
* **Multi-Category Fleet**: Rent motorcycles, electric scooters, luxury/economy cars, and EVs (`VehicleType.bike`, `car`, `scooter`, `electric`).
* **Smart Search & Filters**: Geolocation search, price filters, category criteria, and instant booking flags.
* **Vehicle Detail View**: Interactive booking calendars, detailed specifications, host profiles, and comprehensive feedback reviews.

### 🤖 2. Context-Aware AI Co-Pilot (Irsargo)
* **Active Screen Awareness**: Embedded AI chatbot (`IrsargoChatbotWidget`) that reads the user's active screen context using a `ContextCollector` to provide targeted advice.
* **Capabilities**: Answers questions about vehicle rentals, helps design day-by-day itineraries, interprets OBD-II error codes, and handles billing queries.
* **Flexible AI Engines**: Powered by Google Gemini (`GeminiAiService`) and Groq (`GroqAiService` utilizing `llama-3.3-70b-versatile`).

### 🗺️ 3. AI Tour & Adventure Planner
* **AI Itinerary Builder**: Input destination, duration, budget, and terrain preferences to generate custom, day-by-day itineraries with structured waypoints.
* **Curated Guided Rides**: Browse guide-led adventure tours featuring waypoint tracking, recommended gear lists, and guides.

### 🛰️ 4. Real-Time Telematics & IoT Health Hub
* **Live Vehicle Monitoring**: Monitor battery state-of-charge, fuel levels, tire pressure (TPMS), and engine health.
* **OBD-II Diagnostics**: Ingest OBD-II diagnostic trouble codes (DTCs) and track live location/odometer status.

### 🛡️ 5. Kinetic Trust & Safety Engine
* **Dynamic Trust Score**: A multi-factor algorithm evaluation evaluating host cancellation rates, client feedback, and telematics driving behavior.
* **Trust Badges**: Earn trust credentials like *Verified Driver*, *Superhost*, *Eco-Rider*, and *Fleet Manager*.

### 🗝️ 6. Keyless Entry & Verification
* **PIN & QR Unlock**: Effortless pickup with 6-digit keyless PIN passcodes and QR code scanning.
* **Rental Status Flow**: Tracks active bookings across `Confirmed`, `Active`, `Completed`, and `Cancelled` states.

### 📈 7. Aspect-Based Review System
* **Multi-Criteria Feedback**: Rate vehicle rentals across multiple aspects including condition, communication, accuracy, cleanliness, and value.
* **Aspect Dashboard**: Detailed visual feedback breakdown on screens for both clients and hosts.

### 🌐 8. Dynamic Localization & Translation
* **Multilingual Support**: Supports English, Spanish, Hindi, and Bengali translations out of the box.
* **Type-Safe i18n**: Configured using `slang` library. Includes automated dynamic translation fallbacks powered by `LibreTranslate` and Google Translate APIs.

### 💼 9. Host Ecosystem & Analytics
* **Provider Dashboard**: Manage vehicle fleets, list new tours, track booking status, view utilization metrics, and analyze earnings payouts.
* **Escrow Payments**: Integrated payments and secure escrow checkout flows using Razorpay.

---

## 🏗️ Architecture & Tech Stack

```text
                               ┌─────────────────────────────────────────┐
                               │       PassionRide Flutter App            │
                               │  (Android, iOS, Web, macOS, Windows)    │
                               └────────────────────┬────────────────────┘
                                                    │
             ┌──────────────────────────────────────┼──────────────────────────────────────┐
             │                                      │                                      │
             ▼                                      ▼                                      ▼
┌─────────────────────────┐            ┌─────────────────────────┐            ┌─────────────────────────┐
│     Firebase Services   │            │   PostgreSQL / Supabase │            │     AWS IoT Core        │
│  - Authentication       │            │  - PostGIS Geo Search   │            │  - MQTT Telemetry Broker│
│  - Cloud Messaging FCM  │            │  - Dynamic Reviews & DB │            │  - Live Telematics logs │
└─────────────────────────┘            └─────────────────────────┘            └─────────────────────────┘
             │                                      │                                      │
             └──────────────────────────────────────┼──────────────────────────────────────┘
                                                    │
             ┌──────────────────────────────────────┼──────────────────────────────────────┐
             │                                      │                                      │
             ▼                                      ▼                                      ▼
┌─────────────────────────┐            ┌─────────────────────────┐            ┌─────────────────────────┐
│   AI & Vector Engines   │            │  Payments & Compliance  │            │ Translation Services    │
│  - Google Gemini API    │            │  - Razorpay Gateway     │            │  - Slang compilation    │
│  - Groq (Llama-3.3-70b) │            │  - Document OCR Engine  │            │  - LibreTranslate API   │
└─────────────────────────┘            └─────────────────────────┘            └─────────────────────────┘
```

* **Frontend Framework**: [Flutter](https://flutter.dev/) (Dart SDK `^3.12.2`)
* **State Management**: [Provider](https://pub.dev/packages/provider) (`AppState`, `LanguageProvider`)
* **Backend Database & API**:
  * **Firebase Core & Auth** (Google Authentication, Push Notifications)
  * **Supabase / PostgreSQL** (Core data tables: users, reviews, bookings, blog, chatbot chats)
* **AI Processing**: Google Gemini API & Groq LLMs
* **Maps & Geolocation**: Free Map/Flutter Map Integration with OSM layer (`flutter_map`, `latlong2`)
* **Translation**: `slang_flutter` & `translator`
* **Theme**: Custom Material 3 theme (`AppTheme`) with responsive dark and light modes.

---

## 📁 Directory Structure

```text
lib/
├── config/                  # Environment & App configurations
│   └── env_config.dart
├── i18n/                    # JSON translation files & generated classes (slang)
│   ├── bn.i18n.json, en.i18n.json, es.i18n.json, hi.i18n.json
│   └── strings.g.dart, strings_*.g.dart
├── irsargo/                 # Irsargo Context-Aware AI Co-pilot
│   ├── chatbot.dart
│   ├── context_collector.dart
│   └── irsargo_api.dart
├── models/                  # Core Data Models (Vehicles, Bookings, Compliance, Feedback, Location)
│   ├── feedback_model.dart
│   ├── location_model.dart
│   └── models.dart
├── providers/               # State Management Providers
│   ├── app_state.dart
│   └── language_provider.dart
├── screens/                 # Mobile/Web UI Screens
│   ├── ai_tour_generator_screen.dart
│   ├── blog_screen.dart
│   ├── booking_verification_screen.dart
│   ├── chat_screen.dart
│   ├── discovery_screen.dart
│   ├── documents_compliance_screen.dart
│   ├── earnings_screen.dart
│   ├── favorites_screen.dart
│   ├── feedback_dashboard_screen.dart
│   ├── home_screen.dart
│   ├── in_app_web_view_screen.dart
│   ├── kinetic_trust_screen.dart
│   ├── location_screen.dart
│   ├── main_navigation_screen.dart
│   ├── message_list_screen.dart
│   ├── my_bookings_screen.dart
│   ├── payment_checkout_screen.dart
│   ├── profile_screen.dart
│   ├── provider_dashboard_screen.dart
│   ├── register_tour_screen.dart
│   ├── register_vehicle_screen.dart
│   ├── technical_documentation_screen.dart
│   ├── telematics_hub_screen.dart
│   └── vehicle_detail_screen.dart
├── services/                # Backend API Helpers & External Integrations
│   ├── ad_manager.dart
│   ├── document_ocr_service.dart
│   ├── feedback_service.dart
│   ├── gemini_ai_service.dart
│   ├── groq_ai_service.dart
│   ├── imagekit_service.dart
│   ├── libretranslate_service.dart
│   ├── local_storage_service.dart
│   ├── location_service.dart
│   ├── platform_leakage_filter.dart
│   ├── razorpay_service.dart
│   ├── stream_chat_service.dart
│   ├── supabase_auth_service.dart
│   ├── supabase_service.dart
│   └── transactional_notification_service.dart
├── theme/                   # Theme Setup and Material 3 Swatches
│   ├── app_colors.dart
│   └── app_theme.dart
└── widgets/                 # Reusable UI Widgets & Modal Components
    ├── advanced_feedback_modal.dart
    ├── aspect_rating_widget.dart
    ├── auth_guard_widget.dart
    ├── auto_sliding_image_carousel.dart
    ├── blog_iframe_widget.dart
    ├── create_post_dialog.dart
    ├── floating_language_widget.dart
    ├── global_feedback_fab.dart
    ├── interactive_map_pin_picker.dart
    ├── location_prompt_dialog.dart
    ├── movable_chatbot_button.dart
    ├── native_language_selector_dialog.dart
    ├── notification_center_modal.dart
    ├── rental_review_modal.dart
    ├── side_by_side_reviews_widget.dart
    ├── supabase_auth_dialog.dart
    ├── tour_details_modal.dart
    └── tr_text.dart
```

---

## 🚀 Getting Started

### Prerequisites

Ensure you have the following installed:
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.12.2`)
* [Dart SDK](https://dart.dev/get-dart)
* Android Studio / Xcode (for emulation/mobile compile) or VS Code.

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/arnab9957/passon_ride.git
   cd passon_ride
   ```

2. **Install Flutter packages**:
   ```bash
   flutter pub get
   ```

3. **Generate Translations**:
   Build localization keys using `slang`:
   ```bash
   dart run slang
   # Or watch for translations update dynamically:
   dart run slang watch
   ```

4. **Environment Variables**:
   Copy `.env.example` to `.env` and enter your API credentials:
   ```bash
   cp .env.example .env
   ```

5. **Initialize Supabase**:
   Optionally push local migration scripts to your remote PostgreSQL instance:
   ```bash
   supabase link --project-ref <your-project-ref>
   supabase db push
   ```

6. **Run the application**:
   ```bash
   flutter run
   ```

---

## 📱 Supported Platforms

* 📱 **Android** (Full features + Ads)
* 🍎 **iOS** (Full features + Ads)
* 🌐 **Web** (Support via local bridges/stubs for camera, auth, and payments)
* 💻 **macOS / Windows / Linux** (Desktop builds)

---

## 📄 License

This project is proprietary and confidential. All rights reserved.
