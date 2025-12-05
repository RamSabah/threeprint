import 'dart:convert';
import 'package:http/http.dart' as http;

class SpoolmanFilament {
  final String id;
  final String manufacturer;
  final String name;
  final String material;
  final double density;
  final double weight;
  final double? spoolWeight;
  final String? spoolType;
  final double diameter;
  final String? colorHex;
  final List<String>? colorHexes;
  final int? extruderTemp;
  final List<int>? extruderTempRange;
  final int? bedTemp;
  final List<int>? bedTempRange;
  final String? finish;
  final String? multiColorDirection;
  final String? pattern;
  final bool translucent;
  final bool glow;

  SpoolmanFilament({
    required this.id,
    required this.manufacturer,
    required this.name,
    required this.material,
    required this.density,
    required this.weight,
    this.spoolWeight,
    this.spoolType,
    required this.diameter,
    this.colorHex,
    this.colorHexes,
    this.extruderTemp,
    this.extruderTempRange,
    this.bedTemp,
    this.bedTempRange,
    this.finish,
    this.multiColorDirection,
    this.pattern,
    required this.translucent,
    required this.glow,
  });

  factory SpoolmanFilament.fromJson(Map<String, dynamic> json) {
    return SpoolmanFilament(
      id: json['id'] ?? '',
      manufacturer: json['manufacturer'] ?? '',
      name: json['name'] ?? '',
      material: json['material'] ?? '',
      density: (json['density'] ?? 0.0).toDouble(),
      weight: (json['weight'] ?? 0.0).toDouble(),
      spoolWeight: json['spool_weight']?.toDouble(),
      spoolType: json['spool_type'],
      diameter: (json['diameter'] ?? 0.0).toDouble(),
      colorHex: json['color_hex'],
      colorHexes: json['color_hexes'] != null 
          ? List<String>.from(json['color_hexes'])
          : null,
      extruderTemp: json['extruder_temp'],
      extruderTempRange: json['extruder_temp_range'] != null
          ? List<int>.from(json['extruder_temp_range'])
          : null,
      bedTemp: json['bed_temp'],
      bedTempRange: json['bed_temp_range'] != null
          ? List<int>.from(json['bed_temp_range'])
          : null,
      finish: json['finish'],
      multiColorDirection: json['multi_color_direction'],
      pattern: json['pattern'],
      translucent: json['translucent'] ?? false,
      glow: json['glow'] ?? false,
    );
  }

  String get displayName => '$manufacturer $name';
  String get fullName => '$manufacturer $name $material';
}

/// Search results with pagination info
class SearchResult {
  final List<SpoolmanFilament> filaments;
  final bool hasMore;
  final int totalCount;
  
  SearchResult({
    required this.filaments,
    required this.hasMore,
    required this.totalCount,
  });
}

class SpoolmanService {
  static const String _baseUrl = 'https://donkie.github.io/SpoolmanDB';
  static const String _filamentsUrl = '$_baseUrl/filaments.json';
  
  List<SpoolmanFilament>? _cachedFilaments;
  DateTime? _lastFetchTime;
  static const Duration _cacheExpiry = Duration(hours: 1);

  /// Fetch all filaments from SpoolmanDB
  Future<List<SpoolmanFilament>> fetchFilaments({bool forceRefresh = false}) async {
    // Return cached data if available and not expired
    if (!forceRefresh && 
        _cachedFilaments != null && 
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheExpiry) {
      return _cachedFilaments!;
    }

    try {
      final response = await http.get(Uri.parse(_filamentsUrl));
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        final filaments = jsonData
            .map((json) => SpoolmanFilament.fromJson(json))
            .toList();
        
        _cachedFilaments = filaments;
        _lastFetchTime = DateTime.now();
        
        return filaments;
      } else {
        throw Exception('Failed to fetch filaments: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Search filaments by manufacturer and name with pagination info
  Future<SearchResult> searchFilaments({
    String? query,
    String? manufacturer,
    String? material,
    int limit = 50,
    int offset = 0,
  }) async {
    final allFilaments = await fetchFilaments();
    
    var results = allFilaments.where((filament) {
      bool matches = true;
      
      if (query != null && query.isNotEmpty) {
        final searchTerm = query.toLowerCase();
        matches = matches && (
          filament.manufacturer.toLowerCase().contains(searchTerm) ||
          filament.name.toLowerCase().contains(searchTerm) ||
          filament.material.toLowerCase().contains(searchTerm) ||
          filament.fullName.toLowerCase().contains(searchTerm)
        );
      }
      
      if (manufacturer != null && manufacturer.isNotEmpty) {
        matches = matches && 
            filament.manufacturer.toLowerCase().contains(manufacturer.toLowerCase());
      }
      
      if (material != null && material.isNotEmpty) {
        matches = matches && 
            filament.material.toLowerCase().contains(material.toLowerCase());
      }
      
      return matches;
    }).toList();

    // Sort by relevance (manufacturer match first, then name match)
    if (query != null && query.isNotEmpty) {
      final searchTerm = query.toLowerCase();
      results.sort((a, b) {
        int scoreA = 0;
        int scoreB = 0;
        
        // Higher score for manufacturer exact match
        if (a.manufacturer.toLowerCase() == searchTerm) scoreA += 100;
        if (b.manufacturer.toLowerCase() == searchTerm) scoreB += 100;
        
        // Medium score for manufacturer starts with
        if (a.manufacturer.toLowerCase().startsWith(searchTerm)) scoreA += 50;
        if (b.manufacturer.toLowerCase().startsWith(searchTerm)) scoreB += 50;
        
        // Lower score for name contains
        if (a.name.toLowerCase().contains(searchTerm)) scoreA += 20;
        if (b.name.toLowerCase().contains(searchTerm)) scoreB += 20;
        
        // Manufacturer name alphabetical as tie-breaker
        if (scoreA == scoreB) {
          return a.manufacturer.compareTo(b.manufacturer);
        }
        
        return scoreB - scoreA;
      });
    }

    // Calculate pagination
    final totalCount = results.length;
    final startIndex = offset;
    final endIndex = (offset + limit).clamp(0, results.length);
    final hasMore = endIndex < results.length;
    
    if (startIndex >= results.length) {
      return SearchResult(
        filaments: [],
        hasMore: false,
        totalCount: totalCount,
      );
    }
    
    return SearchResult(
      filaments: results.sublist(startIndex, endIndex),
      hasMore: hasMore,
      totalCount: totalCount,
    );
  }

  /// Get unique manufacturers
  Future<List<String>> getManufacturers() async {
    final allFilaments = await fetchFilaments();
    final manufacturers = allFilaments
        .map((f) => f.manufacturer)
        .toSet()
        .toList();
    manufacturers.sort();
    return manufacturers;
  }

  /// Get unique materials
  Future<List<String>> getMaterials() async {
    final allFilaments = await fetchFilaments();
    final materials = allFilaments
        .map((f) => f.material)
        .toSet()
        .toList();
    materials.sort();
    return materials;
  }

  /// Clear cache
  void clearCache() {
    _cachedFilaments = null;
    _lastFetchTime = null;
  }
}