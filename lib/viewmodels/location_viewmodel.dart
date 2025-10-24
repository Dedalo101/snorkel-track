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
    await Geolocator.requestPermission();
    FlutterCompass.events!.listen((event) {
      _currentHeading = event.heading ?? 0.0;
      notifyListeners();
    });
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high, distanceFilter: 5),
    ).listen((Position position) {
      _currentPosition = position;
      notifyListeners();
    });
  }

  void markSpot() {
    if (_currentPosition != null) {
      final spot = Spot(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Spot ${spots.length + 1}',
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        timestamp: DateTime.now(),
      );
      _spots.add(spot);
      notifyListeners();
    }
  }

  void removeSpot(String spotId) {
    _spots.removeWhere((spot) => spot.id == spotId);
    if (_selectedSpot?.id == spotId) {
      _selectedSpot = null;
      _isNavigating = false;
    }
    notifyListeners();
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
    final distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _selectedSpot!.latitude,
      _selectedSpot!.longitude,
    );
    double lat1 = _currentPosition!.latitude * 3.14159 / 180;
    double lat2 = _selectedSpot!.latitude * 3.14159 / 180;
    double deltaLon = (_selectedSpot!.longitude - _currentPosition!.longitude) *
        3.14159 /
        180;
    double y = sin(deltaLon) * cos(lat2);
    double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon);
    double bearing = atan2(y, x) * 180 / 3.14159;
    if (bearing < 0) bearing += 360;
    final rotation = bearing - _currentHeading;
    return (rotation, distance);
  }
}
