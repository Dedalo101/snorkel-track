import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/spot.dart';

/// Service for managing location and snorkeling spots
class LocationService extends ChangeNotifier {
  static const String _spotsKey = 'snorkeling_spots';

  // Current location
  Position? _currentPosition;
  double? _currentLatitude;
  double? _currentLongitude;
  bool _isLocationLoading = false;
  String? _locationError;

  // Spots management
  List<Spot> _spots = [];
  Spot? _selectedSpot;

  // Navigation
  double? _targetLatitude;
  double? _targetLongitude;
  double? _distanceToTarget;
  double? _bearingToTarget;
  double? _currentHeading;

  // Compass stream
  StreamSubscription<CompassEvent>? _compassSubscription;

  // Getters
  Position? get currentPosition => _currentPosition;
  double? get currentLatitude => _currentLatitude;
  double? get currentLongitude => _currentLongitude;
  bool get isLocationLoading => _isLocationLoading;
  String? get locationError => _locationError;
  List<Spot> get spots => _spots; // Mutable for UI compatibility
  Spot? get selectedSpot => _selectedSpot;
  double? get targetLatitude => _targetLatitude;
  double? get targetLongitude => _targetLongitude;
  double? get distanceToTarget => _distanceToTarget;
  double? get bearingToTarget => _bearingToTarget;
  double? get currentHeading => _currentHeading;
  
  // UI Compatibility getters
  bool get isNavigating => _selectedSpot != null;

  /// Initialize location services and load saved spots
  Future<void> initialize() async {
    await _loadSpots();
    await _initializeCompass();
    // Try to get initial location (non-blocking)
    getCurrentLocation().catchError((e) {
      if (kDebugMode) {
        print('Initial location request failed: $e');
      }
    });
  }

  /// Initialize compass stream
  Future<void> _initializeCompass() async {
    try {
      _compassSubscription =
          FlutterCompass.events?.listen((CompassEvent event) {
        _currentHeading = event.heading;
        if (_targetLatitude != null && _targetLongitude != null) {
          _updateNavigation();
        }
        notifyListeners(); // Notify UI of compass updates
      });
    } catch (e) {
      if (kDebugMode) {
        print('Compass initialization failed: $e');
      }
    }
  }

  /// Load spots from SharedPreferences
  Future<void> _loadSpots() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final spotsJson = prefs.getString(_spotsKey);
      if (spotsJson != null) {
        final List<dynamic> spotsList = json.decode(spotsJson);
        _spots = spotsList.map((json) => Spot.fromJson(json)).toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load spots: $e');
      }
    }
  }

  /// Save spots to SharedPreferences
  Future<void> _saveSpots() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final spotsJson =
          json.encode(_spots.map((spot) => spot.toJson()).toList());
      await prefs.setString(_spotsKey, spotsJson);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to save spots: $e');
      }
    }
  }

  /// Get current location
  Future<bool> getCurrentLocation() async {
    _isLocationLoading = true;
    _locationError = null;
    notifyListeners(); // Immediately update UI to show loading state

    try {
      // Check permissions
      final permission = await _checkLocationPermission();
      if (!permission) {
        _locationError = 'Location permission denied';
        _isLocationLoading = false;
        notifyListeners(); // Update UI with permission error
        return false;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      _currentPosition = position;
      _currentLatitude = position.latitude;
      _currentLongitude = position.longitude;
      _locationError = null;

      // Update navigation calculations if we have a target
      if (_targetLatitude != null && _targetLongitude != null) {
        _updateNavigation();
      }

      _isLocationLoading = false;
      notifyListeners(); // Notify UI of location updates
      return true;
    } catch (e) {
      _locationError = 'Failed to get current location: ${e.toString()}';
      _isLocationLoading = false;
      notifyListeners(); // Notify UI of errors
      return false;
    }
  }

  /// Check and request location permissions
  Future<bool> _checkLocationPermission() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _locationError = 'Location services are disabled';
        return false;
      }

      // Check permission status
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _locationError = 'Location permission denied';
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _locationError = 'Location permission permanently denied';
        return false;
      }

      return true;
    } catch (e) {
      _locationError = 'Permission check failed: ${e.toString()}';
      return false;
    }
  }

  /// Add a new spot at current location
  Future<bool> addSpotAtCurrentLocation(
    String name, {
    String? notes,
    double? rating,
  }) async {
    if (_currentLatitude == null || _currentLongitude == null) {
      final success = await getCurrentLocation();
      if (!success || _currentLatitude == null || _currentLongitude == null) {
        return false;
      }
    }

    final spot = Spot(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      latitude: _currentLatitude!,
      longitude: _currentLongitude!,
      timestamp: DateTime.now(),
    );

    _spots.add(spot);
    await _saveSpots();

    // Provide haptic feedback
    try {
      await HapticFeedback.lightImpact();
    } catch (e) {
      // Haptic feedback not available on this platform
    }

    notifyListeners(); // Notify UI of new spot
    return true;
  }

  /// Remove a spot
  Future<void> removeSpot(String spotId) async {
    _spots.removeWhere((spot) => spot.id == spotId);
    if (_selectedSpot?.id == spotId) {
      _selectedSpot = null;
      _targetLatitude = null;
      _targetLongitude = null;
      _distanceToTarget = null;
      _bearingToTarget = null;
    }
    await _saveSpots();
    notifyListeners(); // Notify UI of spot removal
  }

  /// Select a spot for navigation
  void selectSpot(Spot spot) {
    _selectedSpot = spot;
    _targetLatitude = spot.latitude;
    _targetLongitude = spot.longitude;
    _updateNavigation();
    notifyListeners(); // Notify UI of navigation start
  }

  /// Clear navigation target
  void clearNavigation() {
    _selectedSpot = null;
    _targetLatitude = null;
    _targetLongitude = null;
    _distanceToTarget = null;
    _bearingToTarget = null;
    notifyListeners(); // Notify UI of navigation stop
  }

  /// Update navigation calculations
  void _updateNavigation() {
    if (_currentLatitude == null ||
        _currentLongitude == null ||
        _targetLatitude == null ||
        _targetLongitude == null) {
      return;
    }

    // Calculate distance in meters using Haversine formula
    _distanceToTarget = _calculateDistance(_currentLatitude!,
        _currentLongitude!, _targetLatitude!, _targetLongitude!);

    // Calculate bearing (direction) in degrees
    _bearingToTarget = _calculateBearing(_currentLatitude!, _currentLongitude!,
        _targetLatitude!, _targetLongitude!);
  }

  /// Calculate distance between two coordinates using Haversine formula
  double _calculateDistance(
      double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371000; // Earth's radius in meters

    final double lat1Rad = lat1 * (pi / 180);
    final double lat2Rad = lat2 * (pi / 180);
    final double deltaLatRad = (lat2 - lat1) * (pi / 180);
    final double deltaLngRad = (lng2 - lng1) * (pi / 180);

    final double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) *
            cos(lat2Rad) *
            sin(deltaLngRad / 2) *
            sin(deltaLngRad / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// Calculate bearing between two coordinates
  double _calculateBearing(double lat1, double lng1, double lat2, double lng2) {
    final startLat = lat1 * (pi / 180);
    final startLng = lng1 * (pi / 180);
    final endLat = lat2 * (pi / 180);
    final endLng = lng2 * (pi / 180);

    final dLng = endLng - startLng;

    final y = sin(dLng) * cos(endLat);
    final x =
        cos(startLat) * sin(endLat) - sin(startLat) * cos(endLat) * cos(dLng);

    final bearing = atan2(y, x) * (180 / pi);
    return (bearing + 360) % 360;
  }

  /// Get the relative bearing (bearing adjusted for current heading)
  double? getRelativeBearing() {
    if (_bearingToTarget == null || _currentHeading == null) return null;
    return (_bearingToTarget! - _currentHeading! + 360) % 360;
  }

  /// Get formatted distance string
  String getFormattedDistance(double? distanceInMeters) {
    if (distanceInMeters == null) return 'Unknown';

    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toStringAsFixed(0)}m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)}km';
    }
  }

  // UI Compatibility methods to match LocationViewModel interface
  
  /// Mark a spot at current location with auto-generated name
  Future<void> markSpot() async {
    try {
      final spotCount = spots.length + 1;
      if (kDebugMode) {
        print('Attempting to mark spot $spotCount...');
      }
      
      final success = await addSpotAtCurrentLocation('Spot $spotCount');
      
      if (!success) {
        if (kDebugMode) {
          print('Failed to mark spot: $_locationError');
        }
        // Even if it fails, notify listeners to update any error states
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Exception in markSpot: $e');
      }
      _locationError = 'Failed to mark spot: ${e.toString()}';
      notifyListeners();
    }
  }
  
  /// Remove a spot by index (for UI compatibility)
  Future<void> removeSpotByIndex(int index) async {
    if (index >= 0 && index < _spots.length) {
      final spotId = _spots[index].id;
      await removeSpot(spotId);
    }
  }
  
  /// Stop navigation (alias for clearNavigation)
  void stopNavigating() {
    clearNavigation();
  }
  
  /// Get navigation data in format expected by UI (rotation angle, distance)
  (double rotation, double distance) getNavigationData() {
    final bearing = _bearingToTarget;
    final distance = _distanceToTarget ?? 0.0;
    final heading = _currentHeading ?? 0.0;
    
    if (bearing == null) return (0, 0);
    
    // Calculate rotation relative to current heading
    double rotation = bearing - heading;
    // Normalize to -180 to 180 degrees
    while (rotation > 180) {
      rotation -= 360;
    }
    while (rotation < -180) {
      rotation += 360;
    }
    
    return (rotation, distance);
  }

  /// Get compass direction from bearing
  String getCompassDirection(double? bearing) {
    if (bearing == null) return 'Unknown';

    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((bearing + 22.5) / 45).floor() % 8;
    return directions[index];
  }

  /// Dispose resources
  @override
  void dispose() {
    _compassSubscription?.cancel();
    super.dispose();
  }
}
