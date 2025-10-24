import 'package:latlong2/latlong.dart';

/// Represents a snorkeling spot with location and metadata
class Spot {
  final String id;
  final LatLng location;
  final String name;
  final DateTime timestamp;
  final String? notes;
  final double? rating;
  final List<String> tags;

  const Spot({
    required this.id,
    required this.location,
    required this.name,
    required this.timestamp,
    this.notes,
    this.rating,
    this.tags = const [],
  });

  /// Create a spot from JSON
  factory Spot.fromJson(Map<String, dynamic> json) {
    return Spot(
      id: json['id'] as String,
      location: LatLng(json['latitude'] as double, json['longitude'] as double),
      name: json['name'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      notes: json['notes'] as String?,
      rating: json['rating'] as double?,
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  /// Convert spot to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'name': name,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
      'rating': rating,
      'tags': tags,
    };
  }

  /// Copy spot with new values
  Spot copyWith({
    String? id,
    LatLng? location,
    String? name,
    DateTime? timestamp,
    String? notes,
    double? rating,
    List<String>? tags,
  }) {
    return Spot(
      id: id ?? this.id,
      location: location ?? this.location,
      name: name ?? this.name,
      timestamp: timestamp ?? this.timestamp,
      notes: notes ?? this.notes,
      rating: rating ?? this.rating,
      tags: tags ?? this.tags,
    );
  }

  @override
  String toString() {
    return 'Spot(id: $id, name: $name, location: $location, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Spot && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
