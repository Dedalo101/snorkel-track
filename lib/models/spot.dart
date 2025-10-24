class Spot {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  Spot({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  }) : id = DateTime.now().millisecondsSinceEpoch.toString();

  // JSON for storage (expand for GPX export)
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp.toIso8601String(),
      };

  factory Spot.fromJson(Map<String, dynamic> json) => Spot(
        name: json['name'],
        latitude: json['latitude'],
        longitude: json['longitude'],
        timestamp: DateTime.parse(json['timestamp']),
      );
}
