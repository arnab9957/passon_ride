# PassionRide - Backend Architecture & Technical Implementation Specifications 🚗🛵⚡

This document details the complete backend service architecture, database schemas (PostgreSQL / Supabase & Firestore), API endpoint specifications, multi-language localization pipeline, AI engine workflows, and code mapping for **PassionRide** — a peer-to-peer (P2P) vehicle rental, IoT telematics monitoring, and AI-powered guided tour marketplace.

---

## 🏗️ 1. Master Architecture Blueprint

```text
                               ┌─────────────────────────────────────────┐
                               │       PassionRide Flutter App            │
                               │  (Android, iOS, Web, macOS, Windows)    │
                               └────────────────────┬────────────────────┘
                                                    │
              ┌─────────────────────────────────────┼─────────────────────────────────────┐
              │                                     │                                     │
              ▼                                     ▼                                     ▼
┌───────────────────────────┐         ┌───────────────────────────┐         ┌───────────────────────────┐
│    Supabase & PostgreSQL  │         │     Firebase Services     │         │   IoT Telematics Engine   │
│  - Supabase Auth & JWT    │         │  - Firebase Auth & Google │         │  - MQTT Telemetry Broker  │
│  - PostGIS Spatial Search │         │  - Cloud Firestore Sync   │         │  - OBD-II / TPMS Ingestion│
│  - Row Level Security RLS │         │  - FCM Push Notifications │         │  - Battery SoC Diagnostics│
│  - Storage Buckets (Media)│         │  - Remote Config & Ads    │         │  - Keyless Unlock Relay   │
└───────────────────────────┘         └───────────────────────────┘         └───────────────────────────┘
              │                                     │                                     │
              └─────────────────────────────────────┼─────────────────────────────────────┘
                                                    │
              ┌─────────────────────────────────────┼─────────────────────────────────────┐
              │                                     │                                     │
              ▼                                     ▼                                     ▼
┌───────────────────────────┐         ┌───────────────────────────┐         ┌───────────────────────────┐
│     AI & Translation      │         │   Payments & Escrow       │         │  Messaging & Safety       │
│  - Google Gemini 1.5/2.0  │         │  - Razorpay Gateway SDK   │         │  - Stream Chat SDK        │
│  - Groq AI LLM Fallback   │         │  - Web Checkout Bridge    │         │  - Platform Leakage Filter│
│  - LibreTranslate Service │         │  - Security Deposit Escrow │         │  - KYC Document OCR Engine│
│  - Slang i18n Generator   │         │  - Automated Payout Engine│         │  - Kinetic Trust Engine   │
└───────────────────────────┘         └───────────────────────────┘         └───────────────────────────┘
```

---

## 🧩 2. Backend Technical Modular Sections

### 🟢 Section 1: Authentication & User Profile Management
**Goal**: Unified identity verification across Supabase Auth, Firebase Auth, and Keycloak OIDC with multi-role support (`Rider`, `Host`, `Guide`, `Admin`).

* **Database Schemas (PostgreSQL / Supabase)**:
  ```sql
  CREATE TABLE public.profiles (
      id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
      email TEXT UNIQUE NOT NULL,
      phone TEXT UNIQUE,
      display_name TEXT NOT NULL,
      photo_url TEXT,
      role TEXT CHECK (role IN ('rider', 'host', 'guide', 'admin')) DEFAULT 'rider',
      bio TEXT,
      trust_score INT DEFAULT 100,
      is_kyc_verified BOOLEAN DEFAULT FALSE,
      created_at TIMESTAMPTZ DEFAULT NOW(),
      updated_at TIMESTAMPTZ DEFAULT NOW()
  );

  -- Row Level Security (RLS)
  ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
  CREATE POLICY "Public profiles read" ON public.profiles FOR SELECT USING (true);
  CREATE POLICY "User profile edit" ON public.profiles FOR UPDATE USING (auth.uid() = id);
  ```

* **API Endpoints & Actions**:
  * `POST /auth/register`: Create auth user & insert profile row.
  * `GET /users/me`: Fetch current authenticated user state & trust metadata.
  * `PUT /users/me`: Update bio, profile image URL, and contact details.

* **Mapped Codebase Files**:
  * [`supabase_auth_service.dart`](file:///d:/Desktop/Flutter/passon_ride/lib/services/supabase_auth_service.dart)
  * [`supabase_auth_dialog.dart`](file:///d:/Desktop/Flutter/passon_ride/lib/widgets/supabase_auth_dialog.dart)
  * [`profile_screen.dart`](file:///d:/Desktop/Flutter/passon_ride/lib/screens/profile_screen.dart)

---

### 🌐 Section 2: Multi-Language & Native Localization Engine
**Goal**: Deliver 100% native translation coverage (English, Hindi, Bengali, Spanish) using statically typed `slang` generators combined with an AI-driven `LibreTranslate` service featuring zero-latency LRU caching.

* **Architecture Pipeline**:
  ```text
  [User Locale Selection] ──► [Slang Local Static Strings (0ms)]
                                        │ (If dynamic external text)
                                        ▼
                            [LanguageProvider LRU Cache Lookup]
                                   │              │
                           (Hit: 0ms)           (Miss: API Call)
                                   │              │
                                   ▼              ▼
                           [Return Cached]  [LibreTranslate API] ──► [Save to LRU Cache]
  ```

* **Core Features**:
  * **Static Translations**: Managed in `lib/i18n/*.i18n.json` and compiled via `dart run slang`.
  * **Dynamic AI Translation**: Uses `LibreTranslateService` with configurable API fallback servers.
  * **Zero-Latency LRU Cache**: In-memory `LinkedHashMap` capping cache size to 200 recent queries to prevent UI stutters.

* **Mapped Codebase Files**:
  * [`slang.yaml`](file:///d:/Desktop/Flutter/passon_ride/slang.yaml)
  * [`language_provider.dart`](file:///d:/Desktop/Flutter/passon_ride/lib/providers/language_provider.dart)
  * [`libretranslate_service.dart`](file:///d:/Desktop/Flutter/passon_ride/lib/services/libretranslate_service.dart)
  * [`strings.g.dart`](file:///d:/Desktop/Flutter/passon_ride/lib/i18n/strings.g.dart)
  * [`libretranslate_test.dart`](file:///d:/Desktop/Flutter/passon_ride/test/libretranslate_test.dart)

---

### 🚗 Section 3: Vehicle Catalog, Fleet Management & PostGIS Spatial Search
**Goal**: Onboarding vehicles, managing availability calendars, and performing high-performance geospatial radius queries.

* **Database Schemas (PostgreSQL + PostGIS)**:
  ```sql
  CREATE EXTENSION IF NOT EXISTS postgis;

  CREATE TABLE public.vehicles (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      host_id UUID NOT NULL REFERENCES public.profiles(id),
      title TEXT NOT NULL,
      type TEXT CHECK (type IN ('bike', 'car', 'scooter', 'electric')) NOT NULL,
      category TEXT NOT NULL,
      price_per_day NUMERIC(10, 2) NOT NULL,
      rating NUMERIC(3, 2) DEFAULT 5.0,
      review_count INT DEFAULT 0,
      image_url TEXT NOT NULL,
      location_name TEXT NOT NULL,
      location GEOGRAPHY(POINT, 4326) NOT NULL,
      is_instant_bookable BOOLEAN DEFAULT TRUE,
      fuel_type TEXT,
      transmission TEXT,
      seats INT DEFAULT 2,
      description TEXT,
      status TEXT CHECK (status IN ('available', 'rented', 'maintenance')) DEFAULT 'available',
      created_at TIMESTAMPTZ DEFAULT NOW()
  );

  CREATE INDEX idx_vehicles_location ON public.vehicles USING GIST(location);
  ```

* **Core API Queries**:
  * **PostGIS Spatial Search**:
    ```sql
    SELECT *, ST_Distance(location, ST_MakePoint(:lng, :lat)::geography) / 1000 AS distance_km
    FROM public.vehicles
    WHERE ST_DWithin(location, ST_MakePoint(:lng, :lat)::geography, :radius_meters)
      AND status = 'available'
    ORDER BY distance_km ASC;
    ```

* **Mapped Codebase Files**:
  * [`Vehicle`](file:///d:/Desktop/Flutter/passon_ride/lib/models/models.dart#L3-L69)
  * [`supabase_service.dart`](file:///d:/Desktop/Flutter/passon_ride/lib/services/supabase_service.dart)
  * [`discovery_screen.dart`](file:///d:/Desktop/Flutter/passon_ride/lib/screens/discovery_screen.dart)
  * [`vehicle_detail_screen.dart`](file:///d:/Desktop/Flutter/passon_ride/lib/screens/vehicle_detail_screen.dart)
  * [`register_vehicle_screen.dart`](file:///d:/Desktop/Flutter/passon_ride/lib/screens/register_vehicle_screen.dart)

---

### 💳 Section 4: Booking Engine, Calendar Locking & Keyless Entry
**Goal**: Rental booking lifecycle management, calendar lock preventing double bookings, keyless 6-digit PIN & QR generation, and escrow hold releases.

* **Database Schemas**:
  ```sql
  CREATE TABLE public.bookings (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      vehicle_id UUID NOT NULL REFERENCES public.vehicles(id),
      rider_id UUID NOT NULL REFERENCES public.profiles(id),
      host_id UUID NOT NULL REFERENCES public.profiles(id),
      start_date TIMESTAMPTZ NOT NULL,
      end_date TIMESTAMPTZ NOT NULL,
      total_price NUMERIC(10, 2) NOT NULL,
      status TEXT CHECK (status IN ('Confirmed', 'Active', 'Completed', 'Cancelled')) DEFAULT 'Confirmed',
      unlock_passcode VARCHAR(6) NOT NULL,
      qr_code_payload TEXT NOT NULL,
      payment_id TEXT,
      created_at TIMESTAMPTZ DEFAULT NOW()
  );
  ```

* **Lifecycle State Machine**:
  `Draft` ──► `Confirmed` (Passcode & QR Issued) ──► `Active` (PIN Verified at Vehicle) ──► `Completed` (Deposit Refunded)

* **Mapped Codebase Files**:
  * [`Booking`](file:///d:/Desktop/Flutter/passon_ride/lib/models/models.dart#L178-L204)
  * [`my_bookings_screen.dart`](file:///d:/Desktop/Flutter/passon_ride/lib/screens/my_bookings_screen.dart)
  * [`booking_verification_screen.dart`](file:///d:/Desktop/Flutter/passon_ride/lib/screens/booking_verification_screen.dart)

---

### 🛰️ Section 5: IoT Telematics & Vehicle Diagnostics Hub
**Goal**: High-throughput telemetry ingestion from OBD-II dongles & GPS sensors monitoring battery SoC, fuel percent, TPMS pressures, OBD DTC codes, and speed limits.

* **Telemetry Log Schema (TimescaleDB Hypertable)**:
  ```sql
  CREATE TABLE public.telemetry_logs (
      time TIMESTAMPTZ NOT NULL,
      vehicle_id UUID NOT NULL,
      latitude DOUBLE PRECISION,
      longitude DOUBLE PRECISION,
      speed_kmh DOUBLE PRECISION,
      battery_soc INT,
      fuel_percent INT,
      tpms_front_psi INT,
      tpms_rear_psi INT,
      obd_dtc_codes TEXT[]
  );
  SELECT create_hypertable('public.telemetry_logs', 'time');
  ```

* **Mapped Codebase Files**:
  * [`telematics_hub_screen.dart`](file:///d:/Desktop/Flutter/passon_ride/lib/screens/telematics_hub_screen.dart)
  * [`location_screen.dart`](file:///d:/Desktop/Flutter/passon_ride/lib/screens/location_screen.dart)

---

### 🤖 Section 6: AI Tour & Adventure Itinerary Generator Engine
**Goal**: Synthesize multi-day road trip itineraries using Google Gemini 1.5/2.0 API with fallback to Groq LLM API.

* **API Payload & Prompt Structuring**:
  * **Input Parameters**: `destination`, `durationDays`, `budgetTier`, `terrainType` (`Mountain`, `Coastal`, `Off-Road`, `Highway`).
  * **Response Format**: Structured JSON Array containing day-by-day waypoints, landmark coordinates, recommended fuel stops, and safety warnings.

* **Mapped Codebase Files**:
  * [`gemini_ai_service.dart`](file:///d:/Desktop/Flutter/passon_ride/lib/services/gemini_ai_service.dart)
  * [`groq_ai_service.dart`](file:///d:/Desktop/Flutter/passon_ride/lib/services/groq_ai_service.dart)
  * [`ai_tour_generator_screen.dart`](file:///d:/Desktop/Flutter/passon_ride/lib/screens/ai_tour_generator_screen.dart)
  * [`register_tour_screen.dart`](file:///d:/Desktop/Flutter/passon_ride/lib/screens/register_tour_screen.dart)

---

### 🛡️ Section 7: Document OCR, KYC Compliance & Kinetic Trust Engine
**Goal**: Automated identity document parsing (Driving License, RC, Insurance) via OCR and multi-factor dynamic trust scoring.

* **Trust Calculation Formula**:
  $$\text{Trust Score} = 100 - (\text{Cancellation Rate} \times 20) + (\text{Completed Trips} \times 2) + (\text{KYC Verified} ? 15 : 0) + (\text{Telematics Safety Score} \times 0.25)$$

* **Mapped Codebase Files**:
  * [`document_ocr_service.dart`](file:///d:/Desktop/Flutter/passon_ride/lib/services/document_ocr_service.dart)
  * [`documents_compliance_screen.dart`](file:///d:/Desktop/Flutter/passon_ride/lib/screens/documents_compliance_screen.dart)
  * [`kinetic_trust_screen.dart`](file:///d:/Desktop/Flutter/passon_ride/lib/screens/kinetic_trust_screen.dart)

---

### 💬 Section 8: In-App Messaging & Platform Leakage Prevention
**Goal**: Enable real-time chat while intercepting off-platform transaction attempts (phone numbers, emails, external links).

* **Leakage Detection Logic**:
  * Scans outbound text via `PlatformLeakageFilter` regex suite for patterns matching Indian/international phone numbers, obfuscated digits (e.g. "nine eight zero..."), WhatsApp keywords, and email strings.
  * Sanitizes text or blocks message transmission with user warnings.

* **Mapped Codebase Files**:
  * [`stream_chat_service.dart`](file:///d:/Desktop/Flutter/passon_ride/lib/services/stream_chat_service.dart)
  * [`platform_leakage_filter.dart`](file:///d:/Desktop/Flutter/passon_ride/lib/services/platform_leakage_filter.dart)
  * [`chat_screen.dart`](file:///d:/Desktop/Flutter/passon_ride/lib/screens/chat_screen.dart)

---

### 💳 Section 9: Payments & Payout Engine
**Goal**: Razorpay payment checkout integration with cross-platform web stubs and host payout calculations.

* **Mapped Codebase Files**:
  * [`razorpay_service.dart`](file:///d:/Desktop/Flutter/passon_ride/lib/services/razorpay_service.dart)
  * [`razorpay_web_bridge.dart`](file:///d:/Desktop/Flutter/passon_ride/lib/services/razorpay_web_bridge.dart)
  * [`payment_checkout_screen.dart`](file:///d:/Desktop/Flutter/passon_ride/lib/screens/payment_checkout_screen.dart)
  * [`earnings_screen.dart`](file:///d:/Desktop/Flutter/passon_ride/lib/screens/earnings_screen.dart)

---

## 📊 3. Implementation & Testing Matrix

| Component | Status | Primary Service / Provider | Test Coverage |
| :--- | :--- | :--- | :--- |
| **Auth & Profiles** | Operational | `SupabaseAuthService` | Manual & Unit |
| **Multi-Language (Slang + LibreTranslate)** | Operational | `LanguageProvider`, `LibreTranslateService` | `libretranslate_test.dart` |
| **Vehicle Search & PostGIS** | Operational | `SupabaseService` | Flutter Analyze |
| **Booking & Keyless Passcode** | Operational | `AppState` | Flutter Analyze |
| **IoT Telematics Hub** | Operational | `telematics_hub_screen.dart` | Flutter Analyze |
| **AI Tour Generator** | Operational | `GeminiAIService` / `GroqAIService` | Manual API Test |
| **Document OCR Compliance** | Operational | `DocumentOcrService` | Unit & Mock OCR |
| **Platform Bypass Filter** | Operational | `PlatformLeakageFilter` | Regex Unit Test |
| **Razorpay Payments** | Operational | `RazorpayService` | Test Gateway Credentials |
