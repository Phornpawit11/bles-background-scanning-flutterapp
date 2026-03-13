# Bearcon Card App (the-dot-app)

A modern, robust Flutter-based BLE Beacon tracking application designed for continuous background monitoring, adaptive battery saving, and automated location reporting.

## 🚀 Key Features

- **Device Tag Management**: Register BLE beacons by scanning nearby devices or typing MAC Addresses manually. Save, track, and manage connections dynamically.
- **Intelligent Adaptive Scanning**: Utilizes `sensors_plus` and `geolocator` to conditionally scan based on user movement, aggressively conserving battery life out in the field.
  - **HOT Mode (Driving)**: Precise, rapid scanning (15s every 1 minute).
  - **WARM Mode (Walking)**: Moderate intervals for walking speeds (30s every 3 minutes).
  - **COLD Mode (Still)**: Rare pings when the device is completely stationary (30s every 10 minutes).
- **Background Execution Engine**: Reliable isolate background processing via `flutter_background_service` (Android) and `CoreBluetooth` state preservation (iOS).
- **Internationalization (i18n)**: Fully responsive language translation support (English 🇺🇸 & Thai 🇹🇭) integrated cleanly with GetX and `SharedPreferences`.
- **Dynamic Device Filter**: Easily configurable runtime settings that update background isolate parsing filters dynamically (e.g., scanning only PB713 model devices).
- **Comprehensive Documentation**: Core services, controllers, and background isolates are thoroughly documented using standardized Thai Dartdoc (`///`). The documentation explicitly explains the 'Why' (Business Logic) behind complex features like background execution, adaptive scanning, and memory management.
- **Dumb Widgets & Storybook (Widgetbook)**: Monolithic UI screens are refactored into small, reusable "Dumb Widgets" decoupled from business logic. A comprehensive UI Gallery is maintained via `widgetbook` (code generation) for isolated testing and interactive previewing.
- **Clean UI / UX**: A premium, minimalist UI designed for low cognitive load and clear status display with soft shadows and rich color coding.

## 🛠 Tech Stack

- **Framework**: [Flutter](https://flutter.dev/) (3.22+)
- **State Management, Navigation, & i18n**: [GetX](https://pub.dev/packages/get)
- **BLE Core Engine**: [flutter_reactive_ble](https://pub.dev/packages/flutter_reactive_ble)
- **Background Logic**: [flutter_background_service](https://pub.dev/packages/flutter_background_service)
- **Sensors & Location**: [sensors_plus](https://pub.dev/packages/sensors_plus) & [geolocator](https://pub.dev/packages/geolocator)
- **Permissions**: [permission_handler](https://pub.dev/packages/permission_handler)
- **Networking**: `dio` (with auto-generated JSON serializable request/response objects)
- **UI Gallery**: [Widgetbook](https://pub.dev/packages/widgetbook) (with code generation)

## 📁 Architecture Overview

This project heavily utilizes the GetX pattern paired with Clean Code principles. For an extensive deep dive into features, flow sequence, and iOS vs Android implementation differences, please view the [`promps/PROJECT_STRUCTURE.md`](promps/PROJECT_STRUCTURE.md) document.

```
lib/
├── domain/                                 # Business Logic & Request/Response Models
├── generated/                              # Auto-generated code (e.g., locales.g.dart)
├── infrastructure/                         # Core Services, Storage, and Assets
│   ├── assets/locales/                     # JSON translation files
│   ├── dio_base/                           # Network Interceptors
│   ├── helper/                             # Global Helpers (Init, Logger)
│   ├── navigation/                         # Routing & Bindings
│   ├── service/                            # Background logic & Data Providers
│   └── theme/                              # Application Theming (Dark/Light)
├── presentation/                           # UI Layer & Screen specific controllers
│   ├── controllers/                        # Global & Shared UI Controllers
│   ├── devicemodelsetting/                 # Settings Screens
│   ├── home/                               # Main Application Screens
│   ├── log/                                # Built-in local SQLite Logger Viewer
│   └── widgets/                            # Reusable Components
│       └── dumb_widgets/                   # Stateless, decoupled UI with Widgetbook UseCases
└── utils/                                  # iBeacon parsers & string formatting
```

## ⚙️ Getting Started

### Prerequisites

- Flutter SDK (Targets latest stable)
- Android Studio / Xcode
- **A specific requirement**: Must use a physical iOS or Android device for proper BLE functionality (the emulator does not support live Bluetooth tracking).

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application:
   ```bash
   flutter run
   ```

## 💻 Development Commands

Commonly used commands for development and code generation maintenance.

### 🧹 Clean Build & Code Generation

When model or location translation keys update, re-run generation.

```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### 🎨 Run Widgetbook (UI Gallery)

Isolated environment for testing and previewing components with interactive knobs.

```bash
flutter run lib/widgetbook.dart
```

### 📦 Build APK

```bash
flutter build apk --split-per-abi
```

---

Developed with ❤️ for Bearcon.
