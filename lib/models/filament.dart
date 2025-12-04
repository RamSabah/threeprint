import 'package:cloud_firestore/cloud_firestore.dart';

class Filament {
  final String id;
  final String userId;
  final String type;
  final String color;
  final int count;
  final DateTime createdAt;
  final DateTime updatedAt;

  Filament({
    required this.id,
    required this.userId,
    required this.type,
    required this.color,
    required this.count,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create Filament from Firestore document
  factory Filament.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Filament(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: data['type'] ?? '',
      color: data['color'] ?? '',
      count: data['count'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert Filament to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type,
      'color': color,
      'count': count,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create a copy with updated fields
  Filament copyWith({
    String? id,
    String? userId,
    String? type,
    String? color,
    int? count,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Filament(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      color: color ?? this.color,
      count: count ?? this.count,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Filament(id: $id, userId: $userId, type: $type, color: $color, count: $count)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Filament &&
        other.id == id &&
        other.userId == userId &&
        other.type == type &&
        other.color == color &&
        other.count == count;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        type.hashCode ^
        color.hashCode ^
        count.hashCode;
  }
}