import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import '../models/spot.dart';

class LocationViewModel extends ChangeNotifier {
  Position? _currentPosition;
  double _currentHeading = 0.0;
  final List<Spot> _spots = [];
  Spot? _selectedSpot;
  bool _isNavigating = false;

  Position? get currentPosition => _currentPosition;
  double get currentHeading => _currentHeading;
  List<Spot> get spots => _spots;
  Spot? get selectedSpot => _selectedSpot;
  bool get isNavigating => _isNavigating;

  Future<void> initialize() async {
    await _requestPermissions();
    _startListening();
  }

  Future<void> _requestPermissions() async {
    await Geolocator.requestPermission();
    FlutterCompass.events!.listen((event) {
      _currentHeading = event.heading ?? 0.0;
      notifyListeners();
    });
  }

  void _startListening() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      _currentPosition = position;
      notifyListeners();
    });
  }

  void markSpot() {
    if (_currentPosition != null) {
      final spot = Spot(
        name: 'Spot ${spots.length + 1}',
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        timestamp: DateTime.now(),
      );
      _spots.add(spot);
      notifyListeners();
      // Save to prefs (MVP; async later)
    }
  }

  void selectSpot(Spot spot) {
    _selectedSpot = spot;
    _isNavigating = true;
    notifyListeners();
  }

  void stopNavigating() {
    _isNavigating = false;
    _selectedSpot = null;
    notifyListeners();
  }

  (double rotation, double distance) getNavigationData() {
    if (_selectedSpot == null || _currentPosition == null) return (0, 0);
    final spotPos = Position(
      latitude: _selectedSpot!.latitude,
      longitude: _selectedSpot!.longitude,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
    final distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      spotPos.latitude,
      spotPos.longitude,
    );

    // Bearing calc
    final y = (spotPos.longitude - _currentPosition!.longitude).toRadians();
    final x = cos(_currentPosition!.latitude.toRadians()) *
            sin(spotPos.latitude.toRadians()) -
        sin(_currentPosition!.latitude.toRadians()) *
            cos(spotPos.latitude.toRadians()) *
            cos(y);
    var bearing = (atan2(y, x) * 180 / pi) + 360;
    if (bearing >= 360) bearing -= 360;
    final rotation = bearing - _currentHeading;

    return (rotation, distance);
  }
}

// Extension for radians (add to utils if needed)
extension NumExtension on num {
  double toRadians() => this * pi / 180;
}
