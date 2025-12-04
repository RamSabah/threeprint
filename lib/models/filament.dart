import 'package:cloud_firestore/cloud_firestore.dart';

class Filament {
  final String id;
  final String userId;
  final String type;
  final String color;
  final int count;
  final String brand;
  final double weight; // in grams
  final double diameter; // in mm
  final int quantity; // number of spools/rolls
  final double? emptySpoolWeight; // optional empty spool weight in grams
  final double? cost; // optional cost
  final String? storageLocation; // optional storage location
  final String? notes; // optional notes
  final DateTime createdAt;
  final DateTime updatedAt;

  Filament({
    required this.id,
    required this.userId,
    required this.type,
    required this.color,
    required this.count,
    required this.brand,
    required this.weight,
    required this.diameter,
    required this.quantity,
    this.emptySpoolWeight,
    this.cost,
    this.storageLocation,
    this.notes,
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
      brand: data['brand'] ?? '',
      weight: (data['weight'] ?? 1000.0).toDouble(),
      diameter: (data['diameter'] ?? 1.75).toDouble(),
      quantity: data['quantity'] ?? 1,
      emptySpoolWeight: data['emptySpoolWeight']?.toDouble(),
      cost: data['cost']?.toDouble(),
      storageLocation: data['storageLocation'],
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert Filament to Map for Firestore
  Map<String, dynamic> toFirestore() {
    final Map<String, dynamic> data = {
      'userId': userId,
      'type': type,
      'color': color,
      'count': count,
      'brand': brand,
      'weight': weight,
      'diameter': diameter,
      'quantity': quantity,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
    
    // Add optional fields only if they have values
    if (emptySpoolWeight != null) data['emptySpoolWeight'] = emptySpoolWeight;
    if (cost != null) data['cost'] = cost;
    if (storageLocation != null && storageLocation!.isNotEmpty) data['storageLocation'] = storageLocation;
    if (notes != null && notes!.isNotEmpty) data['notes'] = notes;
    
    return data;
  }

  // Create a copy with updated fields
  Filament copyWith({
    String? id,
    String? userId,
    String? type,
    String? color,
    int? count,
    String? brand,
    double? weight,
    double? diameter,
    int? quantity,
    double? emptySpoolWeight,
    double? cost,
    String? storageLocation,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Filament(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      color: color ?? this.color,
      count: count ?? this.count,
      brand: brand ?? this.brand,
      weight: weight ?? this.weight,
      diameter: diameter ?? this.diameter,
      quantity: quantity ?? this.quantity,
      emptySpoolWeight: emptySpoolWeight ?? this.emptySpoolWeight,
      cost: cost ?? this.cost,
      storageLocation: storageLocation ?? this.storageLocation,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Filament(id: $id, userId: $userId, type: $type, color: $color, count: $count, brand: $brand, weight: ${weight}g, diameter: ${diameter}mm, quantity: $quantity, emptySpoolWeight: ${emptySpoolWeight}g, cost: $cost, storageLocation: $storageLocation, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Filament &&
        other.id == id &&
        other.userId == userId &&
        other.type == type &&
        other.color == color &&
        other.count == count &&
        other.brand == brand &&
        other.weight == weight &&
        other.diameter == diameter &&
        other.quantity == quantity &&
        other.emptySpoolWeight == emptySpoolWeight &&
        other.cost == cost &&
        other.storageLocation == storageLocation &&
        other.notes == notes;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        type.hashCode ^
        brand.hashCode ^
        weight.hashCode ^
        diameter.hashCode ^
        quantity.hashCode ^
        emptySpoolWeight.hashCode ^
        cost.hashCode ^
        storageLocation.hashCode ^
        notes.hashCode ^
        color.hashCode ^
        count.hashCode;
  }
}