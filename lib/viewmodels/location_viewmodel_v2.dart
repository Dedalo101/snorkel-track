import 'package:flutter/foundation.dart';
import '../services/location_service.dart';
import '../models/spot.dart';

/// ViewModel that wraps LocationService for Provider state management
class LocationViewModelV2 extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  
  // Expose LocationService getters
  List<Spot> get spots => _locationService.spots;
  Spot? get selectedSpot => _locationService.selectedSpot;
  bool get isLocationLoading => _locationService.isLocationLoading;
  String? get locationError => _locationService.locationError;
  double? get currentLatitude => _locationService.currentLatitude;
  double? get currentLongitude => _locationService.currentLongitude;
  double? get distanceToTarget => _locationService.distanceToTarget;
  double? get bearingToTarget => _locationService.bearingToTarget;
  double? get currentHeading => _locationService.currentHeading;

  bool get isNavigating => _locationService.selectedSpot != null;

  /// Initialize the location service
  Future<void> initialize() async {
    await _locationService.initialize();
    notifyListeners();
  }

  /// Mark a spot at current location
  Future<void> markSpot() async {
    // First ensure we have current location
    await _locationService.getCurrentLocation();
    
    // Create spot with auto-generated name
    final spotCount = spots.length + 1;
    final success = await _locationService.addSpotAtCurrentLocation('Spot $spotCount');
    
    if (success) {
      notifyListeners();
    }
  }

  /// Remove a spot by index (for backward compatibility with UI)
  Future<void> removeSpotByIndex(int index) async {
    if (index >= 0 && index < spots.length) {
      final spotId = spots[index].id;
      await _locationService.removeSpot(spotId);
      notifyListeners();
    }
  }

  /// Select a spot for navigation
  void selectSpot(Spot spot) {
    _locationService.selectSpot(spot);
    notifyListeners();
  }

  /// Stop navigation
  void stopNavigating() {
    _locationService.clearNavigation();
    notifyListeners();
  }

  /// Get navigation data (rotation angle, distance) for UI
  (double rotation, double distance) getNavigationData() {
    final bearing = _locationService.bearingToTarget;
    final distance = _locationService.distanceToTarget ?? 0.0;
    final heading = _locationService.currentHeading ?? 0.0;
    
    if (bearing == null) return (0, 0);
    
    // Calculate rotation relative to current heading
    final rotation = bearing - heading;
    return (rotation, distance);
  }

  @override
  void dispose() {
    _locationService.dispose();
    super.dispose();
  }
}