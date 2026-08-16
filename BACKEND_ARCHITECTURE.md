# PassonRide - Backend Architecture & Implementation Roadmap 🚗🛵⚡

This document outlines the backend service architecture, database schemas, API endpoint specifications, and step-by-step implementation phases for **PassonRide** — a peer-to-peer (P2P) vehicle rental and AI-powered guided tour marketplace built with Flutter.

---

## 🏗️ 1. Overall System Architecture & Tech Stack

```text
                               ┌─────────────────────────────────────────┐
                               │       PassonRide Flutter App            │
                               │  (Android, iOS, Web, macOS, Windows)    │
                               └────────────────────┬────────────────────┘
                                                    │
             ┌──────────────────────────────────────┼──────────────────────────────────────┐
             │                                      │                                      │
             ▼                                      ▼                                      ▼
┌─────────────────────────┐            ┌─────────────────────────┐            ┌─────────────────────────┐
│     Firebase Services   │            │   PostgreSQL / Supabase │            │     AWS IoT Core        │
│  - Authentication       │            │  - PostGIS Geo Search   │            │  - MQTT Telemetry Broker│
│  - Cloud Firestore Chat │            │  - Calendar Availability│            │  - TimescaleDB (TS data)│
│  - Cloud Messaging FCM  │            │  - Transactional Engine │            │  - Keyless Unlock Relay │
└─────────────────────────┘            └─────────────────────────┘            └─────────────────────────┘
             │                                      │                                      │
             └──────────────────────────────────────┼──────────────────────────────────────┘
                                                    │
             ┌──────────────────────────────────────┼──────────────────────────────────────┐
             │                                      │                                      │
             ▼                                      ▼                                      ▼
┌─────────────────────────┐            ┌─────────────────────────┐            ┌─────────────────────────┐
│   AI & Vector Engines   │            │  Payments & Compliance  │            │ Event Workflows         │
│  - Google Gemini API    │            │  - Stripe Connect Split │            │  - Inngest / Temporal   │
│  - Pgvector / RAG       │            │  - Persona / Onfido KYC │            │  - Escrow Hold Release  │
└─────────────────────────┘            └─────────────────────────┘            └─────────────────────────┘
```

---

## 🧩 2. Backend Modular Sections

### 🟢 Section 1: Authentication & User Profile Management
**Goal**:   User authentication, role assignment (Rider, Host, Guide, Admin), and profile management.

* **Database Schemas**:
  * `users`: `id`, `email`, `phone`, `displayName`, `photoUrl`, `role`, `createdAt`, `updatedAt`
  * `host_profiles`: `userId`, `bio`, `rating`, `reviewCount`, `totalFleetCount`, `trustScore`
* **Core API Endpoints**:
  * `POST /auth/register` & `POST /auth/login` (or Firebase Auth Webhooks)
  * `GET /users/me` & `PUT /users/me` (Profile update)
  * `GET /hosts/:id/profile` (Host public profile & trust stats)
* **Mapped Flutter Codebase Files**:
  * [`firebase_auth_service.dart`](file:///d:/Desktop/Flutter/passon_ride/lib/services/firebase_auth_service.dart)
  * [`firebase_auth_dialog.dart`](file:///d:/Desktop/Flutter/passon_ride/lib/widgets/firebase_auth_dialog.dart)
  * [`profile_screen.dart`](file:///d:/Desktop/Flutter/passon_ride/lib/screens/profile_screen.dart)

---

### 🚗 Section 2: Vehicle Catalog & Fleet Management
**Goal**: Host vehicle onboarding, category management, price setting, and geospatial vehicle search.

* **Database Schemas**:
  * `vehicles`: `id`, `hostId`, `title`, `type` (`bike`, `car`, `scooter`, `electric`), `category`, `pricePerDay`, `rating`, `reviewCount`, `imageUrl`, `location`, `latitude`, `longitude`, `isInstantBookable`, `fuelType`, `transmission`, `seats`, `description`, `status`
* **Core API Endpoints**:
  * `GET /vehicles/search`: Geo-query (PostGIS) & filter by location, category, date range, and price.
  * `GET /vehicles/:id`: Fetch detailed vehicle specifications and real-time status.
  * `POST /vehicles`: Host lists a new vehicle (handles photo uploads to Cloud Storage).
  * `GET /hosts/me/vehicles`: Fleet management dashboard for vehicle hosts.
* **Mapped Flutter Codebase Files**:
  * [`Vehicle`](file:///d:/Desktop/Flutter/passon_ride/lib/models/models.dart#L3-L69)
  * [`firestore_service.dart`](file:///d:/Desktop/Flutter/passon_ride/lib/services/firestore_service.dart)
  * [`discovery_screen.dart`](file:///d:/Desktop/Flutter/passon_ride/lib/screens/discovery_screen.dart)
  * [`vehicle_detail_screen.dart`](file:///d:/Desktop/Flutter/passon_ride/lib/screens/vehicle_detail_screen.dart)
  * [`register_vehicle_screen.dart`](file:///d:/Desktop/Flutter/passon_ride/lib/screens/register_vehicle_screen.dart)
  * [`provider_dashboard_screen.dart`](file:///d:/Desktop/Flutter/passon_ride/lib/screens/provider_dashboard_screen.dart)

---

### 💳 Section 3: Booking Engine & Escrow Payments
**Goal**: Reservation calendar locking, keyless passcode generation, booking status transitions (`Confirmed`, `Active`, `Completed`, `Cancelled`), and payment processing via Stripe Connect.

* **Database Schemas**:
  * `bookings`: `id`, `vehicleId`, `riderId`, `hostId`, `startDate`, `endDate`, `totalPrice`, `status`, `unlockPasscode`, `paymentIntentId`, `createdAt`
* **Core API Endpoints**:
  * `POST /bookings/create`: Check calendar availability & place temporary lock.
  * `POST /bookings/checkout`: Process payment via Stripe Connect & generate 6-digit keyless unlock PIN / QR code.
  * `POST /bookings/:id/verify-unlock`: Validate unlock PIN at vehicle pickup to change status to `Active`.
  * `POST /bookings/:id/complete`: Finish rental, release security deposit hold, and prompt review.
* **Mapped Flutter Codebase Files**:
  * [`Booking`](file:///d:/Desktop/Flutter/passon_ride/lib/models/models.dart#L178-L204)
  * [`payment_checkout_screen.dart`](file:///d:/Desktop/Flutter/passon_ride/lib/screens/payment_checkout_screen.dart)
  * [`booking_verification_screen.dart`](file:///d:/Desktop/Flutter/passon_ride/lib/screens/booking_verification_screen.dart)

---

### 🛰️ Section 4: IoT Telematics & Vehicle Diagnostics Hub
**Goal**: Ingest high-frequency telemetry from vehicle OBD-II dongles/GPS hardware (speed, battery State of Charge, fuel level, TPMS tire pressures, engine diagnostics).

* **Database Schemas**:
  * `telemetry_logs` (TimescaleDB / InfluxDB time-series hypertable): `time`, `vehicleId`, `lat`, `lng`, `speed`, `batterySoc`, `fuelPercent`, `tpmsFrontPsi`, `tpmsRearPsi`, `obdDtcCodes`
* **Core API Endpoints**:
  * `MQTT /telemetry/ingest`: High-throughput broker ingestion.
  * `GET /vehicles/:id/telematics`: Returns current vehicle health snapshot.
  * `WS /vehicles/:id/live-stream`: WebSocket/Redis stream for live map location updates.
* **Mapped Flutter Codebase Files**:
  * [`telematics_hub_screen.dart`](file:///d:/Desktop/Flutter/passon_ride/lib/screens/telematics_hub_screen.dart)
  * `iotData` in [`Vehicle`](file:///d:/Desktop/Flutter/passon_ride/lib/models/models.dart#L22)

---

### 🤖 Section 5: AI Tour & Itinerary Generator Engine
**Goal**: Generate customized road trip itineraries using Google Gemini API / OpenAI and manage curated guided group tours.

* **Database Schemas**:
  * `tours`: `id`, `guideId`, `title`, `location`, `price`, `duration`, `rating`, `reviewCount`, `imageUrl`, `guideName`, `waypoints` (array), `includedGear` (array), `description`
  * `ai_generations`: `id`, `userId`, `destination`, `durationDays`, `budget`, `terrain`, `generatedItineraryJson`
* **Core API Endpoints**:
  * `POST /ai/generate-itinerary`: Accepts destination & trip constraints, queries LLM API (with RAG via Pgvector), and returns structured day-by-day waypoints.
  * `GET /tours` & `POST /tours`: List and create guided tours.
* **Mapped Flutter Codebase Files**:
  * [`Tour`](file:///d:/Desktop/Flutter/passon_ride/lib/models/models.dart#L71-L122)
  * [`ai_tour_generator_screen.dart`](file:///d:/Desktop/Flutter/passon_ride/lib/screens/ai_tour_generator_screen.dart)
  * [`register_tour_screen.dart`](file:///d:/Desktop/Flutter/passon_ride/lib/screens/register_tour_screen.dart)

---

### 🛡️ Section 6: Kinetic Trust Scoring & KYC Compliance
**Goal**: Automated identity document verification (Driving License, RC, Insurance) via OCR and dynamic risk/trust scoring.

* **Database Schemas**:
  * `compliance_documents`: `id`, `userId`, `title`, `type` (`Driving License`, `Vehicle Registration`, `Insurance`), `status` (`Verified`, `Pending`, `Action Required`), `expiryDate`, `documentUrl`
  * `trust_scores`: `userId`, `trustScore`, `trustBadges` (array), `telematicsScore`, `cancellationRate`
* **Core API Endpoints**:
  * `POST /compliance/upload`: Upload scanned ID to secure S3 bucket + trigger Persona/Onfido verification webhook.
  * `GET /compliance/my-documents`: Fetch verification status of user's IDs.
  * `GET /trust/score/:userId`: Get breakdown of kinetic trust factors and earned badges.
* **Mapped Flutter Codebase Files**:
  * [`ComplianceDocument`](file:///d:/Desktop/Flutter/passon_ride/lib/models/models.dart#L162-L176)
  * [`documents_compliance_screen.dart`](file:///d:/Desktop/Flutter/passon_ride/lib/screens/documents_compliance_screen.dart)
  * [`kinetic_trust_screen.dart`](file:///d:/Desktop/Flutter/passon_ride/lib/screens/kinetic_trust_screen.dart)

---

### 💬 Section 7: In-App Messaging & Host Earnings Analytics
**Goal**: Real-time rider-host messaging, Firebase Cloud Messaging (FCM) push notifications, and host payout analytics.

* **Database Schemas**:
  * `chat_threads`: `id`, `partnerName`, `partnerAvatar`, `lastMessage`, `lastTime`, `unreadCount`, `vehicleTitle`
  * `chat_messages`: `id`, `threadId`, `senderId`, `text`, `timestamp`, `isUser`
  * `host_earnings`: `hostId`, `totalEarnings`, `monthlyEarnings`, `completedTrips`, `payoutLogs`
* **Core API Endpoints**:
  * Firestore realtime stream for `chat_threads` and `chat_messages`.
  * `POST /notifications/push`: Trigger FCM notifications for booking updates & alerts.
  * `GET /hosts/me/earnings`: Retrieve host earnings analytics and transaction history.
* **Mapped Flutter Codebase Files**:
  * [`ChatMessage`](file:///d:/Desktop/Flutter/passon_ride/lib/models/models.dart#L124-L138)
  * [`ChatThread`](file:///d:/Desktop/Flutter/passon_ride/lib/models/models.dart#L140-L160)
  * [`chat_screen.dart`](file:///d:/Desktop/Flutter/passon_ride/lib/screens/chat_screen.dart)
  * [`message_list_screen.dart`](file:///d:/Desktop/Flutter/passon_ride/lib/screens/message_list_screen.dart)
  * [`earnings_screen.dart`](file:///d:/Desktop/Flutter/passon_ride/lib/screens/earnings_screen.dart)

---

## 🚀 3. Step-by-Step Implementation Timeline

| Phase | Duration | Scope | Deliverables |
| :--- | :--- | :--- | :--- |
| **Phase 1** | Week 1 | **Sections 1 & 2** (Auth & Vehicles) | User login, profile setup, vehicle catalog search with location filters, host vehicle onboarding. |
| **Phase 2** | Week 2 | **Section 3** (Bookings & Checkout) | Booking reservation flow, Stripe payment integration, PIN unlock passcode generation. |
| **Phase 3** | Week 3 | **Sections 5 & 7** (AI Tours & Messaging) | Google Gemini AI itinerary generation, real-time chat, host earnings analytics. |
| **Phase 4** | Week 4 | **Sections 4 & 6** (IoT & Compliance) | MQTT telemetry streaming, live map tracking, KYC document OCR verification, Kinetic Trust engine. |
