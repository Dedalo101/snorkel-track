import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../services/location_service.dart';
import '../models/spot.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final MapController _mapController = MapController();
  bool _followUserLocation = true;
  bool _showSatelliteView = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationService>(
      builder: (context, locationService, child) {
        // Center map on current location or first spot
        LatLng center = const LatLng(21.3099, -157.8581); // Default to Hawaii
        
        if (locationService.currentLatitude != null && 
            locationService.currentLongitude != null && 
            _followUserLocation) {
          center = LatLng(
            locationService.currentLatitude!, 
            locationService.currentLongitude!
          );
        } else if (locationService.spots.isNotEmpty) {
          final firstSpot = locationService.spots.first;
          center = LatLng(firstSpot.latitude, firstSpot.longitude);
        }

        return Scaffold(
          body: Stack(
            children: [
              // Map
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 15.0,
                  minZoom: 3.0,
                  maxZoom: 18.0,
                  onTap: (tapPosition, point) async {
                    // Add spot at tapped location
                    if (await _showAddSpotDialog(point)) {
                      _addSpotAtLocation(locationService, point);
                    }
                  },
                ),
                children: [
                  // Base map layer
                  TileLayer(
                    urlTemplate: _showSatelliteView
                        ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.snorkel_track',
                    maxZoom: 19,
                  ),
                  
                  // Current location marker
                  if (locationService.currentLatitude != null && 
                      locationService.currentLongitude != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(
                            locationService.currentLatitude!,
                            locationService.currentLongitude!,
                          ),
                          width: 40,
                          height: 40,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.my_location,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  
                  // Spot markers
                  MarkerLayer(
                    markers: locationService.spots.map((spot) => _buildSpotMarker(
                      spot, 
                      locationService,
                      isSelected: spot.id == locationService.selectedSpot?.id,
                    )).toList(),
                  ),
                  
                  // Navigation line to selected spot
                  if (locationService.selectedSpot != null &&
                      locationService.currentLatitude != null &&
                      locationService.currentLongitude != null)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: [
                            LatLng(
                              locationService.currentLatitude!,
                              locationService.currentLongitude!,
                            ),
                            LatLng(
                              locationService.selectedSpot!.latitude,
                              locationService.selectedSpot!.longitude,
                            ),
                          ],
                          color: Theme.of(context).primaryColor,
                          strokeWidth: 3.0,
                          pattern: const StrokePattern.dotted(),
                        ),
                      ],
                    ),
                ],
              ),
              
              // Control buttons
              Positioned(
                top: 50,
                right: 16,
                child: Column(
                  children: [
                    FloatingActionButton(
                      heroTag: 'satellite',
                      mini: true,
                      backgroundColor: Colors.white,
                      onPressed: () {
                        setState(() {
                          _showSatelliteView = !_showSatelliteView;
                        });
                      },
                      child: Icon(
                        _showSatelliteView ? Icons.map : Icons.satellite,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton(
                      heroTag: 'center',
                      mini: true,
                      backgroundColor: Colors.white,
                      onPressed: () {
                        if (locationService.currentLatitude != null &&
                            locationService.currentLongitude != null) {
                          _mapController.move(
                            LatLng(
                              locationService.currentLatitude!,
                              locationService.currentLongitude!,
                            ),
                            15.0,
                          );
                          setState(() {
                            _followUserLocation = true;
                          });
                        }
                      },
                      child: Icon(
                        Icons.my_location,
                        color: _followUserLocation ? Theme.of(context).primaryColor : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Add spot button
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton(
                  heroTag: 'add_spot',
                  onPressed: locationService.isLocationLoading 
                      ? null 
                      : () async {
                          await locationService.markSpot();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Spot marked at current location!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                  child: locationService.isLocationLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add_location),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Marker _buildSpotMarker(Spot spot, LocationService locationService, {bool isSelected = false}) {
    return Marker(
      point: LatLng(spot.latitude, spot.longitude),
      width: isSelected ? 50 : 40,
      height: isSelected ? 50 : 40,
      child: GestureDetector(
        onTap: () => _onSpotTapped(spot, locationService),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.orange : Theme.of(context).primaryColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.location_on,
            color: Colors.white,
            size: isSelected ? 25 : 20,
          ),
        ),
      ),
    );
  }

  void _onSpotTapped(Spot spot, LocationService locationService) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              spot.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Coordinates: ${spot.latitude.toStringAsFixed(6)}, ${spot.longitude.toStringAsFixed(6)}'),
            Text('Marked: ${spot.timestamp.toString().split('.')[0]}'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    locationService.selectSpot(spot);
                    Navigator.pop(context);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Navigating to ${spot.name}')),
                      );
                    }
                  },
                  icon: const Icon(Icons.navigation),
                  label: const Text('Navigate'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await locationService.removeSpot(spot.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${spot.name} deleted')),
                      );
                    }
                  },
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showAddSpotDialog(LatLng point) async {
    String spotName = 'Spot ${Provider.of<LocationService>(context, listen: false).spots.length + 1}';
    
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Spot'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Coordinates: ${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Spot Name',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => spotName = value,
              controller: TextEditingController(text: spotName),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add Spot'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _addSpotAtLocation(LocationService locationService, LatLng point) {
    // This would require extending LocationService to add spots at specific coordinates
    // For now, we'll use the current location method
    locationService.markSpot();
  }
}