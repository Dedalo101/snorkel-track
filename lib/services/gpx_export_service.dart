import 'dart:io';
import 'package:xml/xml.dart';
import 'package:path_provider/path_provider.dart';
import '../models/spot.dart';

/// Service for exporting spots to GPX format
class GpxExportService {
  
  /// Generate GPX XML content from a list of spots
  String generateGpx(List<Spot> spots, {String? trackName}) {
    final builder = XmlBuilder();
    
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element('gpx', nest: () {
      // GPX attributes
      builder.attribute('version', '1.1');
      builder.attribute('creator', 'SnorkelTrack');
      builder.attribute('xmlns', 'http://www.topografix.com/GPX/1/1');
      builder.attribute('xmlns:xsi', 'http://www.w3.org/2001/XMLSchema-instance');
      builder.attribute('xsi:schemaLocation', 
          'http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd');
      
      // Metadata
      builder.element('metadata', nest: () {
        builder.element('name', nest: trackName ?? 'SnorkelTrack Export');
        builder.element('desc', nest: 'Snorkeling spots exported from SnorkelTrack');
        builder.element('author', nest: () {
          builder.element('name', nest: 'SnorkelTrack App');
        });
        builder.element('time', nest: DateTime.now().toIso8601String());
      });
      
      // Add each spot as a waypoint
      for (final spot in spots) {
        builder.element('wpt', nest: () {
          builder.attribute('lat', spot.latitude.toString());
          builder.attribute('lon', spot.longitude.toString());
          
          builder.element('name', nest: spot.name);
          builder.element('desc', nest: 'Snorkeling spot marked at ${spot.timestamp}');
          builder.element('time', nest: spot.timestamp.toIso8601String());
          builder.element('sym', nest: 'Swimming'); // Garmin symbol for water activities
          
          // Add elevation if available (set to 0 for water surface)
          builder.element('ele', nest: '0');
        });
      }
      
      // Create track from spots if there are multiple
      if (spots.length > 1) {
        builder.element('trk', nest: () {
          builder.element('name', nest: trackName ?? 'Snorkeling Route');
          builder.element('desc', nest: 'Route connecting snorkeling spots');
          
          builder.element('trkseg', nest: () {
            for (final spot in spots) {
              builder.element('trkpt', nest: () {
                builder.attribute('lat', spot.latitude.toString());
                builder.attribute('lon', spot.longitude.toString());
                builder.element('ele', nest: '0');
                builder.element('time', nest: spot.timestamp.toIso8601String());
              });
            }
          });
        });
      }
    });
    
    return builder.buildDocument().toXmlString(pretty: true);
  }
  
  /// Export spots to a GPX file
  Future<String> exportToFile(List<Spot> spots, {String? fileName}) async {
    if (spots.isEmpty) {
      throw Exception('No spots to export');
    }
    
    // Generate filename if not provided
    fileName ??= 'snorkel_spots_${DateTime.now().millisecondsSinceEpoch}.gpx';
    if (!fileName.endsWith('.gpx')) {
      fileName = '$fileName.gpx';
    }
    
    // Get the app documents directory
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    
    // Generate GPX content
    final gpxContent = generateGpx(spots);
    
    // Write to file
    await file.writeAsString(gpxContent);
    
    return file.path;
  }
  
  /// Get a shareable GPX file for the spots
  Future<File> createShareableGpx(List<Spot> spots, {String? fileName}) async {
    final filePath = await exportToFile(spots, fileName: fileName);
    return File(filePath);
  }
  
  /// Import spots from GPX content
  List<Spot> importFromGpx(String gpxContent) {
    final document = XmlDocument.parse(gpxContent);
    final spots = <Spot>[];
    
    // Parse waypoints
    final waypoints = document.findAllElements('wpt');
    for (final wpt in waypoints) {
      final lat = double.parse(wpt.getAttribute('lat')!);
      final lon = double.parse(wpt.getAttribute('lon')!);
      
      final nameElement = wpt.findElements('name').firstOrNull;
      final timeElement = wpt.findElements('time').firstOrNull;
      
      final name = nameElement?.innerText ?? 'Imported Spot';
      final timeStr = timeElement?.innerText;
      DateTime timestamp;
      
      if (timeStr != null) {
        try {
          timestamp = DateTime.parse(timeStr);
        } catch (e) {
          timestamp = DateTime.now();
        }
      } else {
        timestamp = DateTime.now();
      }
      
      final spot = Spot(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        latitude: lat,
        longitude: lon,
        timestamp: timestamp,
      );
      
      spots.add(spot);
    }
    
    return spots;
  }
}