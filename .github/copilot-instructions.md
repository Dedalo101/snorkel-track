# SnorkelTrack - AI Coding Guidelines

## Architecture Overview
SnorkelTrack is a Flutter MVP for cross-platform snorkeling GPS logging and navigation. The app follows MVVM architecture with Provider for state management.

**Core Components:**
- `lib/models/spot.dart` - Data model with JSON serialization for GPS coordinates and timestamps
- `lib/viewmodels/location_viewmodel.dart` - Active state management (location, compass, spot selection)
- `lib/services/location_service.dart` - Comprehensive location service (currently unused, see integration note below)

**Key Data Flow:**
- GPS/compass streams → LocationViewModel → Provider → UI updates
- Spots persisted via SharedPreferences as JSON
- Navigation calculations use Haversine formula for distance/bearing

## Critical Patterns

### State Management
Use Provider/ChangeNotifier pattern consistently:
```dart
class LocationViewModel extends ChangeNotifier {
  // Private fields with public getters
  Position? _currentPosition;
  Position? get currentPosition => _currentPosition;

  // Always call notifyListeners() after state changes
  void updatePosition(Position newPos) {
    _currentPosition = newPos;
    notifyListeners();
  }
}
```

### Location/Geospatial Calculations
- Distance: Haversine formula (meters): `6371000 * c` where `c = 2 * atan2(sqrt(a), sqrt(1 - a))`
- Bearing: `atan2(y, x) * (180 / π)` normalized to 0-360°
- Always convert degrees ↔ radians: `lat/lng * π/180` for calculations

### Persistence
Spots stored as JSON in SharedPreferences:
```dart
// Serialization pattern from Spot model
Map<String, dynamic> toJson() => {
  'latitude': latitude,
  'longitude': longitude,
  'timestamp': timestamp.toIso8601String(),
};
```

## Development Workflows

### Testing Location Features
Location/compass features require physical device/simulator with GPS. Mock data for unit tests:
```dart
// Mock position for testing
const mockPosition = Position(
  latitude: 21.3069,  // Hawaii coordinates
  longitude: -157.8583,
  accuracy: 10.0,
  altitude: 0.0,
  heading: 0.0,
  speed: 0.0,
  speedAccuracy: 0.0,
  timestamp: null,
);
```

### Permissions & Platform Setup
Always request location permissions on app start:
```dart
await Geolocator.requestPermission();
// Handle LocationPermission.denied/deniedForever cases
```

### Build Commands
```bash
flutter run --device-id=<device>  # Test GPS features on device
flutter test --coverage          # Run tests with coverage
flutter build apk --release      # Production Android build
flutter build ios --release      # Production iOS build
```

## Integration Notes

⚠️ **LocationService vs LocationViewModel**: The codebase contains two location implementations:
- `LocationService` - Feature-complete with spot persistence, navigation calculations, compass integration
- `LocationViewModel` - Simpler version currently used in main.dart

**Migration Path**: Replace LocationViewModel with LocationService in main.dart:

## Code Quality Standards

### Naming Conventions
- ViewModels: `LocationViewModel`, `SpotViewModel`
- Services: `LocationService`, `PersistenceService`
- Models: PascalCase class names, camelCase fields

### Error Handling
Use try/catch with user-friendly error messages:
```dart
try {
  final position = await Geolocator.getCurrentPosition();
} catch (e) {
  _locationError = 'Failed to get location: ${e.toString()}';
  notifyListeners();
}
```

### UI Patterns
- Teal color scheme (`Colors.teal`, `Colors.blue.shade50`)
- ElevatedButton with icons for primary actions
- ListView.builder for dynamic spot lists
- Transform.rotate for compass navigation arrow

## Testing Strategy
- Widget tests for UI interactions (see `test/widget_test.dart`)
- Mock location data for unit tests
- Integration tests for GPS workflows on physical devices

## Dependencies
Core packages (see `pubspec.yaml`):
- `geolocator: ^14.0.2` - GPS positioning
- `flutter_compass: ^0.8.0` - Device compass
- `provider: ^6.1.1` - State management
- `shared_preferences: ^2.2.2` - Local persistence</content>
<parameter name="filePath">c:\Users\room\Documents\GitHub\snorkel-track\.github\copilot-instructions.md