import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/location_service.dart';
import 'widgets/map_view.dart';

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
        brightness: Brightness.dark,
        primaryColor: Colors.green,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.green,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.black,
            textStyle: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.green, fontFamily: 'monospace'),
          bodyMedium: TextStyle(color: Colors.green, fontFamily: 'monospace'),
          headlineSmall: TextStyle(color: Colors.green, fontFamily: 'monospace', fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.green),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    SpotNavigatorScreen(),
    MapView(),
    SpotsListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.navigation),
            label: 'Navigate',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Spots',
          ),
        ],
      ),
    );
  }
}

class SpotNavigatorScreen extends StatelessWidget {
  const SpotNavigatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('SnorkelTrack')),
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
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400 || screenSize.height < 600;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 8.0 : 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Main action button - centered and prominent
            Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxWidth: isSmallScreen ? 280 : 400,
              ),
              child: ElevatedButton.icon(
                onPressed: vm.isLocationLoading ? null : vm.markSpot,
                icon: vm.isLocationLoading
                    ? SizedBox(
                        width: isSmallScreen ? 16 : 20,
                        height: isSmallScreen ? 16 : 20,
                        child: const CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.add_location),
                label: Text(
                  vm.isLocationLoading ? 'Getting location...' : 'Mark Spot',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, isSmallScreen ? 48 : 60),
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 12 : 24,
                    vertical: isSmallScreen ? 12 : 18,
                  ),
                ),
              ),
            ),

            // Error display - centered
            if (vm.locationError != null) ...[
              SizedBox(height: isSmallScreen ? 8 : 12),
              Container(
                constraints: BoxConstraints(
                  maxWidth: isSmallScreen ? 280 : 400,
                ),
                padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        color: Colors.red.shade600,
                        size: isSmallScreen ? 16 : 20),
                    SizedBox(width: isSmallScreen ? 6 : 8),
                    Expanded(
                      child: Text(
                        vm.locationError!,
                        style: TextStyle(
                          color: Colors.red.shade800,
                          fontSize: isSmallScreen ? 12 : 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Spots list - flexible height
            SizedBox(height: isSmallScreen ? 12 : 20),
            Expanded(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isSmallScreen ? 320 : 500,
                ),
                child: vm.spots.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.place_outlined,
                              size: isSmallScreen ? 32 : 48,
                              color: Colors.green.withOpacity(0.5),
                            ),
                            SizedBox(height: isSmallScreen ? 8 : 12),
                            Text(
                              'No spots marked yet',
                              style: TextStyle(
                                color: Colors.green.withOpacity(0.7),
                                fontSize: isSmallScreen ? 14 : 16,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: isSmallScreen ? 4 : 8),
                            Text(
                              'Tap "Mark Spot" to add your first location',
                              style: TextStyle(
                                color: Colors.green.withOpacity(0.5),
                                fontSize: isSmallScreen ? 12 : 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: vm.spots.length,
                        itemBuilder: (context, i) => Container(
                          margin: EdgeInsets.only(bottom: isSmallScreen ? 4 : 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.green.withOpacity(0.2)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            dense: isSmallScreen,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 12 : 16,
                              vertical: isSmallScreen ? 4 : 8,
                            ),
                            title: Text(
                              vm.spots[i].name,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              '${vm.spots[i].latitude.toStringAsFixed(4)}, ${vm.spots[i].longitude.toStringAsFixed(4)}',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 10 : 12,
                                color: Colors.green.withOpacity(0.7),
                              ),
                            ),
                            onTap: () => vm.selectSpot(vm.spots[i]),
                            trailing: IconButton(
                              icon: Icon(Icons.delete,
                                  color: Colors.red.shade400,
                                  size: isSmallScreen ? 20 : 24),
                              onPressed: () => vm.removeSpotByIndex(i),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
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
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400 || screenSize.height < 600;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Compass arrow - centered and prominent
            Container(
              constraints: BoxConstraints(
                maxWidth: isSmallScreen ? 200 : 300,
                maxHeight: isSmallScreen ? 200 : 300,
              ),
              child: Center(
                child: Transform.rotate(
                  angle: data.$1 * 3.14159 / 180,
                  child: Icon(
                    Icons.navigation,
                    size: isSmallScreen ? 80 : 100,
                    color: Colors.green,
                  ),
                ),
              ),
            ),

            SizedBox(height: isSmallScreen ? 16 : 24),

            // Spot name - centered
            Container(
              constraints: BoxConstraints(
                maxWidth: isSmallScreen ? 280 : 400,
              ),
              child: Text(
                vm.selectedSpot!.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: isSmallScreen ? 18 : 24,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            SizedBox(height: isSmallScreen ? 12 : 16),

            // Distance display - centered and prominent
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 16 : 24,
                vertical: isSmallScreen ? 8 : 12,
              ),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Text(
                data.$2 < 1000
                    ? '${data.$2.toInt()}m'
                    : '${(data.$2 / 1000).toStringAsFixed(1)}km',
                style: TextStyle(
                  fontSize: isSmallScreen ? 24 : 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
            ),

            SizedBox(height: isSmallScreen ? 20 : 32),

            // Stop navigation button - centered
            Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxWidth: isSmallScreen ? 240 : 300,
              ),
              child: ElevatedButton(
                onPressed: vm.stopNavigating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, isSmallScreen ? 44 : 50),
                  padding: EdgeInsets.symmetric(
                    vertical: isSmallScreen ? 12 : 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Stop Navigation',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // Optional: Add bearing direction for better navigation (only on larger screens)
            if (!isSmallScreen) ...[
              SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  vm.getCompassDirection(data.$1),
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SpotsListScreen extends StatelessWidget {
  const SpotsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Snorkeling Spots'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              final locationService = Provider.of<LocationService>(context, listen: false);
              
              switch (value) {
                case 'export_gpx':
                  await _exportGpx(context, locationService);
                  break;
                case 'import_gpx':
                  await _importGpx(context, locationService);
                  break;
                case 'clear_all':
                  await _clearAllSpots(context, locationService);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export_gpx',
                child: ListTile(
                  leading: Icon(Icons.file_download),
                  title: Text('Export GPX'),
                ),
              ),
              const PopupMenuItem(
                value: 'import_gpx',
                child: ListTile(
                  leading: Icon(Icons.file_upload),
                  title: Text('Import GPX'),
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: ListTile(
                  leading: Icon(Icons.clear_all),
                  title: Text('Clear All'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<LocationService>(
        builder: (context, vm, child) {
          if (vm.spots.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No spots marked yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Use the Navigate tab to mark your first spot!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: vm.spots.length,
            itemBuilder: (context, i) => Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text('${i + 1}'),
                ),
                title: Text(vm.spots[i].name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${vm.spots[i].latitude.toStringAsFixed(6)}, ${vm.spots[i].longitude.toStringAsFixed(6)}'),
                    Text('Marked: ${vm.spots[i].timestamp.toString().split('.')[0]}'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.navigation),
                      onPressed: () {
                        vm.selectSpot(vm.spots[i]);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Navigating to ${vm.spots[i].name}')),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDelete(context, vm, i),
                    ),
                  ],
                ),
                onTap: () => vm.selectSpot(vm.spots[i]),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _exportGpx(BuildContext context, LocationService locationService) async {
    if (locationService.spots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No spots to export')),
      );
      return;
    }

    try {
      final filePath = await locationService.exportSpotsToGpx();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('GPX exported to: $filePath'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Share',
            onPressed: () {
              // Share functionality would go here
              // For now, just show a message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share functionality coming soon!')),
              );
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  Future<void> _importGpx(BuildContext context, LocationService locationService) async {
    // For now, show a placeholder message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('GPX import functionality coming soon!')),
    );
  }

  Future<void> _clearAllSpots(BuildContext context, LocationService locationService) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Spots'),
        content: const Text('Are you sure you want to delete all spots? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    ) ?? false;

    if (confirmed) {
      // Clear all spots
      while (locationService.spots.isNotEmpty) {
        await locationService.removeSpot(locationService.spots.first.id);
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All spots cleared')),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, LocationService vm, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${vm.spots[index].name}'),
        content: const Text('Are you sure you want to delete this spot?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;

    if (confirmed) {
      await vm.removeSpotByIndex(index);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${vm.spots[index].name} deleted')),
      );
    }
  }
}
