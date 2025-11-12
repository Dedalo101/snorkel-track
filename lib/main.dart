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
          ElevatedButton.icon(
            onPressed: vm.markSpot,
            icon: const Icon(Icons.add_location),
            label: const Text('Mark Spot', style: TextStyle(fontSize: 18)),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 60)),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: vm.spots.length,
              itemBuilder: (context, i) => ListTile(
                title: Text(vm.spots[i].name),
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
