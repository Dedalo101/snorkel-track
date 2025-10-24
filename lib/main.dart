import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/location_viewmodel.dart';

void main() {
  runApp(const SnorkelTrackApp());
}

class SnorkelTrackApp extends StatelessWidget {
  const SnorkelTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SnorkelTrack',
      theme: ThemeData(
        primarySwatch: Colors.teal, // Green-blue ocean
        scaffoldBackgroundColor: Colors.blue.shade50,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding:
                const EdgeInsets.symmetric(vertical: 16), // Large for wet taps
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.blueGrey.shade900,
      ),
      themeMode: ThemeMode.system,
      home: const SpotNavigatorScreen(),
    );
  }
}

class SpotNavigatorScreen extends StatefulWidget {
  const SpotNavigatorScreen({super.key});

  @override
  State<SpotNavigatorScreen> createState() => _SpotNavigatorScreenState();
}

class _SpotNavigatorScreenState extends State<SpotNavigatorScreen> {
  final LocationViewModel _viewModel = LocationViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SnorkelTrack'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: ChangeNotifierProvider.value(
        value: _viewModel,
        child: Consumer<LocationViewModel>(
          builder: (context, vm, child) {
            if (vm.isNavigating) {
              return _buildNavView(vm);
            } else {
              return _buildMarkView(vm);
            }
          },
        ),
      ),
    );
  }

  Widget _buildMarkView(LocationViewModel vm) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: vm.markSpot,
            icon: const Icon(Icons.location_on, size: 32),
            label:
                const Text('Mark Current Spot', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: vm.spots.length,
              itemBuilder: (context, index) {
                final spot = vm.spots[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.place, color: Colors.teal),
                    title: Text(spot.name),
                    subtitle: const Text(''), // Time only
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => vm.removeSpot(spot.id),
                    ),
                    onTap: () => vm.selectSpot(spot),
                  ),
                );
              },
            ),
          ),
          if (vm.spots.isEmpty)
            const Text('Tap to mark your first spot!',
                style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildNavView(LocationViewModel vm) {
    final navData = vm.getNavigationData();
    final rotation = navData.$1;
    final distance = navData.$2;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.rotate(
            angle: rotation * 3.14159 / 180, // Radians
            child: const Icon(Icons.arrow_forward_ios,
                size: 100, color: Colors.teal),
          ),
          const SizedBox(height: 24),
          Text(vm.selectedSpot!.name,
              style: Theme.of(context).textTheme.headlineMedium),
          Text(
            distance < 1
                ? '<1m'
                : distance < 1000
                    ? '${distance.toInt()}m'
                    : '${(distance / 1000).toStringAsFixed(1)}km',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: vm.stopNavigating,
            icon: const Icon(Icons.close),
            label: const Text('Stop Navigation'),
          ),
        ],
      ),
    );
  }
}
