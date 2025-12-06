import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/filament.dart';

class FilamentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();
  
  static const String _collection = 'filaments';

  /// Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Save a new filament to Firestore
  Future<String> saveFilament({
    required String type,
    required String color,
    required int count,
    required String brand,
    required double weight,
    required double diameter,
    required int quantity,
    double? emptySpoolWeight,
    double? cost,
    String? storageLocation,
    String? notes,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User must be authenticated to save filament');
      }

      final filamentId = _uuid.v4();
      final now = DateTime.now();
      
      final filament = Filament(
        id: filamentId,
        userId: userId,
        type: type,
        color: color,
        count: count,
        brand: brand,
        weight: weight,
        diameter: diameter,
        quantity: quantity,
        emptySpoolWeight: emptySpoolWeight,
        cost: cost,
        storageLocation: storageLocation,
        notes: notes,
        createdAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection(_collection)
          .doc(filamentId)
          .set(filament.toFirestore());

      return filamentId;
    } catch (e) {
      throw Exception('Failed to save filament: $e');
    }
  }

  /// Get all filaments for the current user
  Future<List<Filament>> getUserFilaments() async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User must be authenticated to get filaments');
      }

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      // Sort locally by createdAt (descending) since we can't use orderBy without index
      final docs = querySnapshot.docs.toList()
        ..sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aCreatedAt = (aData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          final bCreatedAt = (bData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          return bCreatedAt.compareTo(aCreatedAt); // Descending order
        });

      return docs
          .map((doc) => Filament.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get filaments: $e');
    }
  }

  /// Get filaments stream for real-time updates
  Stream<List<Filament>> getUserFilamentsStream() {
    final userId = _currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          // Sort locally by createdAt (descending) since we can't use orderBy without index
          final docs = snapshot.docs.toList()
            ..sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              final aCreatedAt = (aData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
              final bCreatedAt = (bData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
              return bCreatedAt.compareTo(aCreatedAt); // Descending order
            });
          
          return docs
              .map((doc) => Filament.fromFirestore(doc))
              .toList();
        });
  }

  /// Update an existing filament
  Future<void> updateFilament({
    required String filamentId,
    String? type,
    String? color,
    int? count,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User must be authenticated to update filament');
      }

      final updateData = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (type != null) updateData['type'] = type;
      if (color != null) updateData['color'] = color;
      if (count != null) updateData['count'] = count;

      await _firestore
          .collection(_collection)
          .doc(filamentId)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to update filament: $e');
    }
  }

  /// Delete a filament
  Future<void> deleteFilament(String filamentId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User must be authenticated to delete filament');
      }

      // Verify the filament belongs to the current user
      final doc = await _firestore
          .collection(_collection)
          .doc(filamentId)
          .get();

      if (!doc.exists) {
        throw Exception('Filament not found');
      }

      final filament = Filament.fromFirestore(doc);
      if (filament.userId != userId) {
        throw Exception('Unauthorized to delete this filament');
      }

      await _firestore
          .collection(_collection)
          .doc(filamentId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete filament: $e');
    }
  }

  /// Get a specific filament by ID
  Future<Filament?> getFilament(String filamentId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User must be authenticated to get filament');
      }

      final doc = await _firestore
          .collection(_collection)
          .doc(filamentId)
          .get();

      if (!doc.exists) {
        return null;
      }

      final filament = Filament.fromFirestore(doc);
      
      // Only return if it belongs to the current user
      if (filament.userId != userId) {
        throw Exception('Unauthorized to access this filament');
      }

      return filament;
    } catch (e) {
      throw Exception('Failed to get filament: $e');
    }
  }

  /// Get filaments by type
  Future<List<Filament>> getFilamentsByType(String type) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User must be authenticated to get filaments');
      }

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: type)
          .get();

      // Sort locally by createdAt (descending) since we can't use orderBy without index
      final docs = querySnapshot.docs.toList()
        ..sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aCreatedAt = (aData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          final bCreatedAt = (bData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          return bCreatedAt.compareTo(aCreatedAt); // Descending order
        });

      return docs
          .map((doc) => Filament.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get filaments by type: $e');
    }
  }

  /// Get filaments by color
  Future<List<Filament>> getFilamentsByColor(String color) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User must be authenticated to get filaments');
      }

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('color', isEqualTo: color)
          .get();

      // Sort locally by createdAt (descending) since we can't use orderBy without index
      final docs = querySnapshot.docs.toList()
        ..sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aCreatedAt = (aData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          final bCreatedAt = (bData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          return bCreatedAt.compareTo(aCreatedAt); // Descending order
        });

      return docs
          .map((doc) => Filament.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get filaments by color: $e');
    }
  }

  /// Get total count of filaments for current user
  Future<int> getTotalFilamentCount() async {
    try {
      final filaments = await getUserFilaments();
      return filaments.fold<int>(0, (sum, filament) => sum + filament.count);
    } catch (e) {
      throw Exception('Failed to get total filament count: $e');
    }
  }

  /// Search filaments by type or color
  Future<List<Filament>> searchFilaments(String query) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User must be authenticated to search filaments');
      }

      // Get all user filaments and filter locally
      // Firestore doesn't support case-insensitive search or OR queries easily
      final allFilaments = await getUserFilaments();
      final lowercaseQuery = query.toLowerCase();

      return allFilaments.where((filament) =>
          filament.type.toLowerCase().contains(lowercaseQuery) ||
          filament.color.toLowerCase().contains(lowercaseQuery)
      ).toList();
    } catch (e) {
      throw Exception('Failed to search filaments: $e');
    }
  }

  /// Save a SpoolmanFilament from search results to user's library
  Future<String> saveSpoolmanFilament({
    required String spoolmanId,
    required String displayName,
    required String manufacturer,
    required String material,
    required double diameter,
    required double weight,
    String? colorHex,
    List<String>? colorHexes,
    int? extruderTemp,
    int? bedTemp,
    required int quantity,
    double? cost,
    String? notes,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User must be authenticated to save filament');
      }

      final filamentId = _uuid.v4();
      final now = DateTime.now();
      
      // Determine color string - use first color from multi-color or single color
      String colorString;
      if (colorHexes != null && colorHexes.isNotEmpty) {
        colorString = 'Multi-Color (${colorHexes.join(', ')})';
      } else if (colorHex != null) {
        colorString = colorHex;
      } else {
        colorString = 'Unknown';
      }
      
      final filament = Filament(
        id: filamentId,
        userId: userId,
        type: material,
        color: colorString,
        count: 1, // Default count
        brand: manufacturer,
        weight: weight,
        diameter: diameter,
        quantity: quantity,
        cost: cost,
        notes: notes != null ? '$notes\n\nSpoolman ID: $spoolmanId' : 'Spoolman ID: $spoolmanId',
        createdAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection(_collection)
          .doc(filamentId)
          .set(filament.toFirestore());

      return filamentId;
    } catch (e) {
      throw Exception('Failed to save filament to library: $e');
    }
  }

  /// Check if a SpoolmanFilament is already saved in user's library
  Future<bool> isSpoolmanFilamentSaved(String spoolmanId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return false;
      }

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      // Check if any filament has the spoolmanId in notes
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final notes = data['notes'] as String?;
        if (notes != null && notes.contains('Spoolman ID: $spoolmanId')) {
          return true;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }
}