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
class LocationService {
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
  List<Spot> get spots => List.unmodifiable(_spots);
  Spot? get selectedSpot => _selectedSpot;
  double? get targetLatitude => _targetLatitude;
  double? get targetLongitude => _targetLongitude;
  double? get distanceToTarget => _distanceToTarget;
  double? get bearingToTarget => _bearingToTarget;
  double? get currentHeading => _currentHeading;

  /// Initialize location services and load saved spots
  Future<void> initialize() async {
    await _loadSpots();
    await _initializeCompass();
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

    try {
      // Check permissions
      final permission = await _checkLocationPermission();
      if (!permission) {
        _locationError = 'Location permission denied';
        _isLocationLoading = false;
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
      return true;
    } catch (e) {
      _locationError = 'Failed to get current location: ${e.toString()}';
      _isLocationLoading = false;
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
  }

  /// Select a spot for navigation
  void selectSpot(Spot spot) {
    _selectedSpot = spot;
    _targetLatitude = spot.latitude;
    _targetLongitude = spot.longitude;
    _updateNavigation();
  }

  /// Clear navigation target
  void clearNavigation() {
    _selectedSpot = null;
    _targetLatitude = null;
    _targetLongitude = null;
    _distanceToTarget = null;
    _bearingToTarget = null;
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

  /// Get compass direction from bearing
  String getCompassDirection(double? bearing) {
    if (bearing == null) return 'Unknown';

    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((bearing + 22.5) / 45).floor() % 8;
    return directions[index];
  }

  /// Dispose resources
  void dispose() {
    _compassSubscription?.cancel();
  }
}
