import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/location_service.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => LocationService()..initialize(),
      child: const SnorkelTrackApp(),
    ),
  );
}

class SnorkelTrackApp extends StatelessWidget {
  const SnorkelTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SnorkelTrack',
      theme: ThemeData(
          primarySwatch: Colors.teal,
          scaffoldBackgroundColor: Colors.blue.shade50),
      home: const SpotNavigatorScreen(),
    );
  }
}

class SpotNavigatorScreen extends StatelessWidget {
  const SpotNavigatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('SnorkelTrack'), backgroundColor: Colors.teal),
      body: Consumer<LocationService>(
        builder: (context, vm, child) =>
            vm.isNavigating ? _NavView(vm: vm) : _MarkView(vm: vm),
      ),
    );
  }
}

class _MarkView extends StatelessWidget {
  final LocationService vm;
  const _MarkView({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Debug info card
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Debug Info:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
                  const SizedBox(height: 4),
                  Text('Spots count: ${vm.spots.length}'),
                  Text('Location loading: ${vm.isLocationLoading}'),
                  Text('Current lat: ${vm.currentLatitude?.toStringAsFixed(6) ?? 'null'}'),
                  Text('Current lng: ${vm.currentLongitude?.toStringAsFixed(6) ?? 'null'}'),
                  Text('Error: ${vm.locationError ?? 'none'}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: vm.isLocationLoading ? null : () async {
              print('Mark Spot button pressed!'); // Debug print
              await vm.markSpot();
              print('Mark Spot completed, spots count: ${vm.spots.length}'); // Debug print
            },
            icon: vm.isLocationLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.add_location),
            label: Text(
              vm.isLocationLoading ? 'Getting location...' : 'Mark Spot',
              style: const TextStyle(fontSize: 18),
            ),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 60)),
          ),
          if (vm.locationError != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      vm.locationError!,
                      style: TextStyle(color: Colors.red.shade800),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: vm.spots.length,
              itemBuilder: (context, i) => ListTile(
                title: Text(vm.spots[i].name),
                subtitle: Text('${vm.spots[i].latitude.toStringAsFixed(6)}, ${vm.spots[i].longitude.toStringAsFixed(6)}'),
                onTap: () => vm.selectSpot(vm.spots[i]),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => vm.removeSpotByIndex(i),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavView extends StatelessWidget {
  final LocationService vm;
  const _NavView({required this.vm});

  @override
  Widget build(BuildContext context) {
    final data = vm.getNavigationData();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.rotate(
            angle: data.$1 * 3.14159 / 180,
            child: const Icon(Icons.navigation, size: 100, color: Colors.teal),
          ),
          Text(vm.selectedSpot!.name,
              style: Theme.of(context).textTheme.headlineSmall),
          Text(
            data.$2 < 1000
                ? '${data.$2.toInt()}m'
                : '${(data.$2 / 1000).toStringAsFixed(1)}km',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          ElevatedButton(
            onPressed: vm.stopNavigating,
            child: const Text('Stop Nav'),
          ),
        ],
      ),
    );
  }
}