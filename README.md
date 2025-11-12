# 🏊‍♂️ SnorkelTrack

**Professional Snorkeling GPS Logger & Navigator** - A comprehensive Flutter app for underwater exploration and navigation.

## 🌟 Features

### 📍 **GPS Tracking & Navigation**
- Real-time location tracking with high accuracy
- Compass-guided navigation to saved spots
- Distance and bearing calculations
- Interactive visual navigation with arrow compass

### 🗺️ **Interactive Maps**
- **OpenStreetMap integration** with satellite/street view toggle
- Real-time location marker with user position
- Visual spot markers with selection and navigation
- Route visualization between current location and target spots
- Tap-to-add new spots functionality

### 💾 **Spot Management**
- Mark unlimited snorkeling spots with GPS coordinates
- Persistent storage with SharedPreferences
- Edit, delete, and organize your spots
- Automatic spot naming with custom rename options
- Detailed spot information with timestamps

### 📁 **GPX Export & Import**
- **Full GPX export** of all spots as waypoints and tracks
- Professional XML format compatible with Garmin, marine apps
- Shareable files for backup and collaboration
- Import existing GPX files from other apps
- Metadata including timestamps and descriptions

### 🧭 **Advanced Navigation**
- **Flutter Compass integration** for accurate heading
- Haversine formula for precise distance calculations
- Visual compass rose with real-time direction updates
- Relative bearing calculations adjusted for device heading

## 🚀 Getting Started

### Prerequisites
- Flutter 3.0.0 or higher
- Dart 3.0.0 or higher
- Android 6.0+ or iOS 12.0+
- Location permissions enabled

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/snorkel-track.git
   cd snorkel-track
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Enable location permissions** (Android)
   - Location permissions are already configured in the manifest
   - Grant permissions when prompted on first run

4. **Run the app**
   ```bash
   flutter run
   ```

## 📱 Usage Guide

### **Navigate Tab**
- **Mark Spot**: Press the floating button to save your current GPS location
- **Navigation Mode**: Tap any saved spot to start compass navigation
- **Distance Display**: See real-time distance and bearing to target
- **Loading States**: Visual feedback during GPS operations

### **Map Tab**
- **Interactive View**: Pan, zoom, and explore your spots on OpenStreetMap
- **Satellite Toggle**: Switch between street map and satellite imagery
- **Add Spots**: Tap anywhere on the map to add a new snorkeling spot
- **Spot Details**: Tap markers for navigation, deletion, and details
- **My Location**: Blue dot shows your current position with accuracy
- **Navigation Lines**: Visual route display to selected destinations

### **Spots Tab**
- **Spot Management**: View, edit, and delete all saved spots
- **GPX Export**: Export all spots to professional GPX format
- **Bulk Operations**: Clear all spots or selective management
- **Detailed Info**: Coordinates, timestamps, and metadata
- **Quick Navigation**: One-tap navigation to any spot

## 🛠️ Technical Details

### **Architecture**
- **MVVM Pattern** with Provider for state management
- **Service Layer** for GPS, compass, and file operations
- **Modular Design** with separated concerns and reusable components

### **Key Dependencies**
```yaml
dependencies:
  geolocator: ^14.0.2        # GPS tracking and positioning
  flutter_compass: ^0.8.0    # Device compass and heading
  flutter_map: ^7.0.2        # Interactive maps with OpenStreetMap
  latlong2: ^0.9.1          # Latitude/longitude calculations
  path_provider: ^2.1.4     # File system access for exports
  xml: ^6.5.0               # GPX XML generation and parsing
  shared_preferences: ^2.2.2 # Local spot persistence
```

### **GPS & Navigation**
- **High accuracy positioning** with 5-meter distance filter
- **Haversine formula** for accurate distance calculations
- **Bearing calculations** with magnetic declination compensation
- **Real-time updates** with efficient listener management

### **Map Integration**
- **OpenStreetMap tiles** with offline caching capability
- **Multiple layer support** (street, satellite, hybrid)
- **Custom markers** with spot identification and selection
- **Polyline routing** with visual navigation indicators

### **Data Format**
```json
{
  "id": "unique_timestamp_id",
  "name": "Spot Name",
  "latitude": 21.3069,
  "longitude": -157.8583,
  "timestamp": "2023-11-12T10:30:00.000Z"
}
```

## 📂 Project Structure

```
lib/
├── main.dart                 # App entry point with navigation
├── models/
│   └── spot.dart            # Spot data model with JSON serialization
├── services/
│   ├── location_service.dart # GPS, compass, navigation service
│   └── gpx_export_service.dart # GPX export/import functionality
├── widgets/
│   └── map_view.dart        # Interactive map component
└── main_debug.dart          # Debug version with extra logging
```

## 🔧 Development

### **Running Tests**
```bash
flutter test                  # Unit and widget tests
flutter test --coverage      # With coverage report
```

### **Building**
```bash
flutter build apk --release  # Android production build
flutter build ios --release  # iOS production build
flutter build web           # Web version
```

### **Debugging Location Issues**
- Use `main_debug.dart` for enhanced logging
- Check location permissions in device settings
- Verify GPS is enabled and has clear sky view
- Test with physical device (GPS doesn't work in simulators)

## 🌊 Perfect for Snorkelers

### **Use Cases**
- **Reef Navigation**: Mark beautiful coral spots and return easily
- **Safety**: Share GPS coordinates with dive buddies
- **Exploration**: Create maps of your favorite snorkeling areas
- **Planning**: Export routes for trip planning and marine navigation
- **Documentation**: Keep detailed logs of underwater discoveries

### **Marine-Friendly Features**
- **Waterproof device compatibility** (when used with proper cases)
- **Large, clear navigation indicators** easy to see underwater
- **Offline functionality** for areas with poor cell coverage
- **Professional GPS accuracy** suitable for marine navigation
- **Standard GPX format** compatible with marine chartplotters

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Issues**: Report bugs and feature requests on GitHub
- **Documentation**: Check the [Wiki](wiki) for detailed guides
- **Community**: Join our discussions for tips and tricks

---

**Dive safe and navigate smart with SnorkelTrack! 🏊‍♂️🧭**
