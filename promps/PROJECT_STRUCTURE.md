# The Dot App - Project Structure

## Tech Stack & Versions

- **Flutter**: 3.22+
- **Dart**: 3.4+
- **State Management**: get ^4.7.3
- **BLE Core**: flutter_reactive_ble ^5.4.0
- **Location**: geolocator ^14.0.2
- **Background**: flutter_background_service ^5.1.0
- **UI Architecture**: widgetbook ^3.22.0 & widgetbook_annotation ^3.11.0
- **Build Runner**: build_runner ^2.8.0 & widgetbook_generator ^3.22.0

- **Architecture Overview**
- **Framework**: Flutter
- **State Management**: GetX
- **Navigation/Routing**: GetX Navigation (`getPages`)
- **i18n**: GetX Translations (`generated/locales.g.dart`)
- **Networking**: `dio` (with auto-generated JSON serializable models for requests/responses)
- **BLE Core**: `flutter_reactive_ble` (For precise, low-latency background scanning, reading battery properties, and iBeacon parsing)
- **Intelligent Scanning**: `AdaptiveScanService` utilizing `sensors_plus` and `geolocator` to regulate battery consumption via 3 dynamic modes (HOT, WARM, COLD).
- **Background Actions**: `flutter_background_service` (Android Foreground Service & iOS Background Processing).
- **Local Storage**: Built-in SQLite via `LoggerService` for background activity logging.

## Folder Structure (GetX Pattern)

```
lib/
├── config.dart                             # Environment configuration
├── widgetbook.dart                         # Entry point for UI Gallery (Dumb Widgets)
├── widgetbook.directories.g.dart           # Auto-generated Widgetbook structure
├── domain/                                 # Business Logic & Data Models
│   ├── models/
│   ├── request/                            # API Requests (e.g., Location Send)
│   └── response/                           # API Responses
├── generated/                                # Auto-generated code (e.g., GetX translation Locales)
│   └── locales.g.dart
├── infrastructure/                         # Core Services & Navigation
│   ├── assets/                             # Image / Asset paths
│   │   ├── fonts/                          # Custom font files (e.g., Kanit)
│   │   └── locales/                        # JSON translation files (en_US.json, th_TH.json)
│   ├── dio_base/                           # Dio configuration, interceptors, error handling
│   │   └── notwork_utils.dart              # Network connectivity utility class
│   ├── helper/                             # Global helpers (AppInitializer, Snackbar)
│   ├── navigation/                         # GetX Routes and Bindings
│   │   ├── bindings/
│   │   │   ├── controllers/                # Injection for Home, Loading, Log, etc.
│   │   │   └── domains/
│   │   ├── navigation.dart
│   │   └── routes.dart
│   ├── service/                            # Background & Logic Services
│   │   ├── adaptive_scan_service.dart      # Motion & Speed-based scanning throttle
│   │   ├── background_ble_service.dart     # Isolate entry point for flutter_background_service
│   │   ├── logger_service.dart             # Local SQLite logging
│   │   └── thedot.service.dart             # API communications
│   └── theme/                              # Theming & Fonts
│       ├── theme.controller.dart           # Persistent Theme Management (Dark/Light mode via WidgetsBinding)
│       └── app_theme.dart
├── presentation/                           # UI Layer
│   ├── controllers/                        # Global & Shared UI Controllers
│   │   ├── background_ble.controller.dart  # Background BLE Scanning logic
│   │   ├── language.controller.dart        # Responsive language management (i18n)
│   │   └── scan_mode.controller.dart       # Scanning speed/frequency logic
│   ├── devicemodelsetting/                 # Dynamic Device Model Filter Config
│   │   ├── controllers/
│   │   └── devicemodelsetting.screen.dart
│   ├── home/
│   │   ├── controllers/                    # Main Home Controller
│   │   ├── widgets/                        # UI Components: Tag list, Permission Gate, Dialogs (Language, Delete), Home Drawer
│   │   └── home.screen.dart
│   ├── loading/                            # Splash / Loading Screen
│   ├── log/                                # Background activity log viewing screen
│   ├── screens.dart                        # Screen barrel file
│   └── widgets/                            # Shared widgets layer
│       └── dumb_widgets/                   # Stateless, decoupled UI components with Widgetbook UseCases
├── utils/                                  # Helper utilities
│   ├── bgservice.key.dart                  # Centralized configuration (thresholds, durations, keys) for BG Service
│   └── ibeacon_parser.dart                 # iBeacon parsing and string formatting
└── main.dart                               # Entry point
```

## Features List

1. **Tag Registration & Management**
   - Add Tag by scanning nearby devices or searching specific tag names / MAC Addresses.
   - List registered Tags (Name, UUID/MAC Address, Battery %).
   - Seamlessly connect to tags to read `180f` battery level characteristics or parse iBeacon minor/major.
2. **Adaptive Background Monitoring**
   - **HOT Mode (Driving)**: GPS Speed > 20 km/h. Scans for 15s every 1 minute.
   - **WARM Mode (Walking)**: Accelerometer magnitude > 1.0 (or movement detected). Scans for 30s every 3 minutes.
   - **COLD Mode (Still)**: Device is resting. Scans for 30s every 10 minutes to preserve maximum battery life.
3. **Automated Reporting & Filtering**
   - Dynamic Device Model Filter configurable via `DeviceModelSettingScreen`. Modifying this updates iOS/Android Background isolates without reboot.
   - Cooldown logic per MAC address to prevent network spam.
   - Batch reporting inside the isolate utilizing `geolocator` for exact coordinates via API (`thedot.service.dart`).
4. **Log Viewer**
   - Built-in SQLite local database that tracks background execution and scans.
   - `LogScreen` provides debugging UI to ensure the background isolate works as expected.
5. **UI Development & Verification (Widgetbook)**
   - Monolithic screens are divided into **Dumb Widgets** - small, stateless components focused only on presentation.
   - Every Dumb Widget includes a `@widgetbook.UseCase` allowing for isolated testing and previewing via code generation.
   - Use of `context.knobs` to interactively tweak widget states (e.g., changing colors, text, or animations) during development.

## State Variables (`HomeController`)

- `RxList<TagCard> registeredTags`: List of user-saved tags tracking offline.
- `RxList<TagCard> connectedTags`: List of actively observed / background-tracking tags.
- `RxString bleStatus`: Reactive permission gateway ('checking', 'denied', 'off', 'granted').
- _No Emulator Mode is currently strictly required in logic flow; relies heavily on real device BLE capabilities._

## Logic Flow: Adaptive Background Service

1. User enables Service -> `FlutterBackgroundService` spawns isolate (`onStart`).
2. `BackgroundBleController` initializes the `AdaptiveScanService`.
3. `AdaptiveScanService` starts listening to `userAccelerometerEventStream`.
4. Motion triggers GPS speed validation (`LocationAccuracy.medium` to save battery).
5. Scanning cycles run via `flutter_reactive_ble` matching the current mode's intervals.
6. When an observed MAC or iBeacon is detected -> checks cooldown.
7. If valid -> requests precise GPS (wrapped in try-catch to prevent timeouts breaking isolate) and fires HTTP POST to backend via Dio interceptors.
8. Writes background logs to local SQLite via `LoggerService` for user debugging.

### Background Platform Differences (Android vs iOS)

- **Android:** Utilizes the custom `AdaptiveScanService` (Accelerometer + GPS) to switch between HOT/WARM/COLD.
- **iOS:** Accelerometer is suspended in the background. Therefore, iOS entirely bypasses the AdaptiveScanService and relies directly on Apple's Native CoreBluetooth Background execution, strictly filtering by the `FEE9` Service UUID to keep the app awake and scanning efficiently.
