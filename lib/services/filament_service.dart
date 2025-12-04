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
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
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
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Filament.fromFirestore(doc))
            .toList());
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
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
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
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
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
}