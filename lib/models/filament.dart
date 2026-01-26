import 'package:cloud_firestore/cloud_firestore.dart';

class Filament {
  final String id;
  final String userId;
  final String type;
  final String color;
  final int count;
  final String brand;
  final String? productName;
  final double weight; // in grams
  final double diameter; // in mm
  final int quantity; // number of spools/rolls
  final double? emptySpoolWeight; // optional empty spool weight in grams
  final double? cost; // optional cost
  final String? storageLocation; // optional storage location
  final String? notes; // optional notes
  final double? density; // optional density in g/cm³
  final String? spoolType; // optional spool type
  final int? extruderTemp; // optional extruder temperature in °C
  final List<int>? extruderTempRange; // optional extruder temperature range [min, max] in °C
  final int? bedTemp; // optional bed temperature in °C
  final List<int>? bedTempRange; // optional bed temperature range [min, max] in °C
  final String? finish; // optional finish (matte, glossy, etc.)
  final String? pattern; // optional pattern (solid, multicolor, etc.)
  final bool? isTranslucent; // optional translucent property
  final bool? isGlowInDark; // optional glow in dark property
  final DateTime createdAt;
  final DateTime updatedAt;

  Filament({
    required this.id,
    required this.userId,
    required this.type,
    required this.color,
    required this.count,
    required this.brand,
    this.productName,
    required this.weight,
    required this.diameter,
    required this.quantity,
    this.emptySpoolWeight,
    this.cost,
    this.storageLocation,
    this.notes,
    this.density,
    this.spoolType,
    this.extruderTemp,
    this.extruderTempRange,
    this.bedTemp,
    this.bedTempRange,
    this.finish,
    this.pattern,
    this.isTranslucent,
    this.isGlowInDark,
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
      productName: data['productName'],
      weight: (data['weight'] ?? 1000.0).toDouble(),
      diameter: (data['diameter'] ?? 1.75).toDouble(),
      quantity: data['quantity'] ?? 1,
      emptySpoolWeight: data['emptySpoolWeight']?.toDouble(),
      cost: data['cost']?.toDouble(),
      storageLocation: data['storageLocation'],
      notes: data['notes'],
      density: data['density']?.toDouble(),
      spoolType: data['spoolType'],
      extruderTemp: data['extruderTemp']?.toInt(),
      extruderTempRange: data['extruderTempRange'] != null
          ? List<int>.from(data['extruderTempRange'])
          : null,
      bedTemp: data['bedTemp']?.toInt(),
      bedTempRange: data['bedTempRange'] != null
          ? List<int>.from(data['bedTempRange'])
          : null,
      finish: data['finish'],
      pattern: data['pattern'],
      isTranslucent: data['isTranslucent'],
      isGlowInDark: data['isGlowInDark'],
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
    if (productName != null && productName!.isNotEmpty) data['productName'] = productName;
    if (emptySpoolWeight != null) data['emptySpoolWeight'] = emptySpoolWeight;
    if (cost != null) data['cost'] = cost;
    if (storageLocation != null && storageLocation!.isNotEmpty) data['storageLocation'] = storageLocation;
    if (notes != null && notes!.isNotEmpty) data['notes'] = notes;
    if (density != null) data['density'] = density;
    if (spoolType != null && spoolType!.isNotEmpty) data['spoolType'] = spoolType;
    if (extruderTemp != null) data['extruderTemp'] = extruderTemp;
    if (extruderTempRange != null && extruderTempRange!.isNotEmpty) data['extruderTempRange'] = extruderTempRange;
    if (bedTemp != null) data['bedTemp'] = bedTemp;
    if (bedTempRange != null && bedTempRange!.isNotEmpty) data['bedTempRange'] = bedTempRange;
    if (finish != null && finish!.isNotEmpty) data['finish'] = finish;
    if (pattern != null && pattern!.isNotEmpty) data['pattern'] = pattern;
    if (isTranslucent != null) data['isTranslucent'] = isTranslucent;
    if (isGlowInDark != null) data['isGlowInDark'] = isGlowInDark;
    
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
    String? productName,
    double? weight,
    double? diameter,
    int? quantity,
    double? emptySpoolWeight,
    double? cost,
    String? storageLocation,
    String? notes,
    double? density,
    String? spoolType,
    int? extruderTemp,
    List<int>? extruderTempRange,
    int? bedTemp,
    List<int>? bedTempRange,
    String? finish,
    String? pattern,
    bool? isTranslucent,
    bool? isGlowInDark,
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
      productName: productName ?? this.productName,
      weight: weight ?? this.weight,
      diameter: diameter ?? this.diameter,
      quantity: quantity ?? this.quantity,
      emptySpoolWeight: emptySpoolWeight ?? this.emptySpoolWeight,
      cost: cost ?? this.cost,
      storageLocation: storageLocation ?? this.storageLocation,
      notes: notes ?? this.notes,
      density: density ?? this.density,
      spoolType: spoolType ?? this.spoolType,
      extruderTemp: extruderTemp ?? this.extruderTemp,
      extruderTempRange: extruderTempRange ?? this.extruderTempRange,
      bedTemp: bedTemp ?? this.bedTemp,
      bedTempRange: bedTempRange ?? this.bedTempRange,
      finish: finish ?? this.finish,
      pattern: pattern ?? this.pattern,
      isTranslucent: isTranslucent ?? this.isTranslucent,
      isGlowInDark: isGlowInDark ?? this.isGlowInDark,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Filament(id: $id, userId: $userId, type: $type, color: $color, count: $count, brand: $brand, weight: ${weight}g, diameter: ${diameter}mm, quantity: $quantity, emptySpoolWeight: ${emptySpoolWeight}g, cost: $cost, storageLocation: $storageLocation, notes: $notes)';
  }

  // JSON serialization for local storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'color': color,
      'count': count,
      'brand': brand,
      'productName': productName,
      'weight': weight,
      'diameter': diameter,
      'quantity': quantity,
      'emptySpoolWeight': emptySpoolWeight,
      'cost': cost,
      'storageLocation': storageLocation,
      'notes': notes,
      'density': density,
      'spoolType': spoolType,
      'extruderTemp': extruderTemp,
      'extruderTempRange': extruderTempRange,
      'bedTemp': bedTemp,
      'bedTempRange': bedTempRange,
      'finish': finish,
      'pattern': pattern,
      'isTranslucent': isTranslucent,
      'isGlowInDark': isGlowInDark,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Filament.fromJson(Map<String, dynamic> json) {
    return Filament(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: json['type'] as String,
      color: json['color'] as String,
      count: json['count'] as int,
      brand: json['brand'] as String,
      productName: json['productName'] as String?,
      weight: (json['weight'] as num).toDouble(),
      diameter: (json['diameter'] as num).toDouble(),
      quantity: json['quantity'] as int,
      emptySpoolWeight: (json['emptySpoolWeight'] as num?)?.toDouble(),
      cost: (json['cost'] as num?)?.toDouble(),
      storageLocation: json['storageLocation'] as String?,
      notes: json['notes'] as String?,
      density: (json['density'] as num?)?.toDouble(),
      spoolType: json['spoolType'] as String?,
      extruderTemp: json['extruderTemp'] as int?,
      extruderTempRange: (json['extruderTempRange'] as List?)?.cast<int>(),
      bedTemp: json['bedTemp'] as int?,
      bedTempRange: (json['bedTempRange'] as List?)?.cast<int>(),
      finish: json['finish'] as String?,
      pattern: json['pattern'] as String?,
      isTranslucent: json['isTranslucent'] as bool?,
      isGlowInDark: json['isGlowInDark'] as bool?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
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