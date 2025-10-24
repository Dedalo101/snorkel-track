import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/spot.dart';

/// ViewModel for managing location services and snorkeling spots
class LocationViewModel extends ChangeNotifier {
  // Current location
  Position? _currentPosition;
  LatLng? _currentLatLng;
  bool _isLocationLoading = false;
  String? _locationError;

  // Spots management
  final List<Spot> _spots = [];
  Spot? _selectedSpot;

  // Navigation
  LatLng? _navigationTarget;
  double? _distanceToTarget;
  double? _bearingToTarget;

  // Getters
  Position? get currentPosition => _currentPosition;
  LatLng? get currentLatLng => _currentLatLng;
  bool get isLocationLoading => _isLocationLoading;
  String? get locationError => _locationError;
  List<Spot> get spots => List.unmodifiable(_spots);
  Spot? get selectedSpot => _selectedSpot;
  LatLng? get navigationTarget => _navigationTarget;
  double? get distanceToTarget => _distanceToTarget;
  double? get bearingToTarget => _bearingToTarget;

  /// Initialize location services
  Future<void> initializeLocation() async {
    _isLocationLoading = true;
    _locationError = null;
    notifyListeners();

    try {
      // Check permissions
      final permission = await _checkLocationPermission();
      if (!permission) {
        _locationError = 'Location permission denied';
        _isLocationLoading = false;
        notifyListeners();
        return;
      }

      // Get current position
      await _getCurrentLocation();
    } catch (e) {
      _locationError = 'Failed to get location: ${e.toString()}';
    } finally {
      _isLocationLoading = false;
      notifyListeners();
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

  /// Get current location
  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      _currentPosition = position;
      _currentLatLng = LatLng(position.latitude, position.longitude);
      _locationError = null;

      // Update navigation calculations if we have a target
      if (_navigationTarget != null) {
        _updateNavigation();
      }
    } catch (e) {
      _locationError = 'Failed to get current location: ${e.toString()}';
    }
  }

  /// Add a new spot at current location
  Future<void> addSpotAtCurrentLocation(
    String name, {
    String? notes,
    double? rating,
  }) async {
    if (_currentLatLng == null) {
      await _getCurrentLocation();
      if (_currentLatLng == null) return;
    }

    final spot = Spot(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      location: _currentLatLng!,
      name: name,
      timestamp: DateTime.now(),
      notes: notes,
      rating: rating,
    );

    _spots.add(spot);
    notifyListeners();

    // Provide haptic feedback
    try {
      await HapticFeedback.lightImpact();
    } catch (e) {
      // Haptic feedback not available on this platform
    }
  }

  /// Add a spot at specific location
  void addSpot(Spot spot) {
    _spots.add(spot);
    notifyListeners();
  }

  /// Remove a spot
  void removeSpot(String spotId) {
    _spots.removeWhere((spot) => spot.id == spotId);
    if (_selectedSpot?.id == spotId) {
      _selectedSpot = null;
      _navigationTarget = null;
      _distanceToTarget = null;
      _bearingToTarget = null;
    }
    notifyListeners();
  }

  /// Select a spot for navigation
  void selectSpot(Spot spot) {
    _selectedSpot = spot;
    _navigationTarget = spot.location;
    _updateNavigation();
    notifyListeners();
  }

  /// Clear navigation target
  void clearNavigation() {
    _selectedSpot = null;
    _navigationTarget = null;
    _distanceToTarget = null;
    _bearingToTarget = null;
    notifyListeners();
  }

  /// Update navigation calculations
  void _updateNavigation() {
    if (_currentLatLng == null || _navigationTarget == null) return;

    final Distance distance = Distance();

    // Calculate distance in meters
    _distanceToTarget = distance.as(
      LengthUnit.Meter,
      _currentLatLng!,
      _navigationTarget!,
    );

    // Calculate bearing (direction) in degrees
    _bearingToTarget = _calculateBearing(_currentLatLng!, _navigationTarget!);
  }

  /// Calculate bearing between two points
  double _calculateBearing(LatLng start, LatLng end) {
    final startLat = start.latitude * (pi / 180);
    final startLng = start.longitude * (pi / 180);
    final endLat = end.latitude * (pi / 180);
    final endLng = end.longitude * (pi / 180);

    final dLng = endLng - startLng;

    final dPhi = log(tan(endLat / 2 + pi / 4) / tan(startLat / 2 + pi / 4));
    if (dLng.abs() > pi) {
      if (dLng > 0) {
        return (atan2(sin(dLng - 2 * pi), dPhi) * 180 / pi + 360) % 360;
      } else {
        return (atan2(sin(dLng + 2 * pi), dPhi) * 180 / pi + 360) % 360;
      }
    }

    return (atan2(sin(dLng), dPhi) * 180 / pi + 360) % 360;
  }

  /// Refresh current location
  Future<void> refreshLocation() async {
    await _getCurrentLocation();
    if (_navigationTarget != null) {
      _updateNavigation();
    }
    notifyListeners();
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
}
