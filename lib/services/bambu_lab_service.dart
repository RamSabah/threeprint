import 'dart:io';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class BambuLabService {
  static const String _bambuConnectScheme = 'bambu-connect://import-file';
  
  /// Send a 3MF file to Bambu Connect for printing
  static Future<bool> sendFileToBambuConnect({
    required String filePath,
    required String fileName,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist: $filePath');
      }
      
      if (!filePath.toLowerCase().endsWith('.3mf') && 
          !filePath.toLowerCase().endsWith('.gcode.3mf')) {
        throw Exception('File must be a .3mf or .gcode.3mf file');
      }
      
      final encodedPath = Uri.encodeComponent(filePath);
      final encodedName = Uri.encodeComponent(fileName);
      const version = '1.0.0';
      
      final bambuUrl = '$_bambuConnectScheme?path=$encodedPath&name=$encodedName&version=$version';
      final uri = Uri.parse(bambuUrl);
      
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      } else {
        throw Exception('Bambu Connect is not installed or cannot handle the URL scheme');
      }
    } catch (e) {
      print('Error sending file to Bambu Connect: $e');
      return false;
    }
  }
  
  /// Check if Bambu Connect is available on the system
  static Future<bool> isBambuConnectAvailable() async {
    try {
      final uri = Uri.parse(_bambuConnectScheme);
      return await canLaunchUrl(uri);
    } catch (e) {
      return false;
    }
  }
  
  /// Save a temporary file to send to Bambu Connect
  static Future<String?> saveTemporaryFile({
    required String content,
    required String fileName,
    String extension = '3mf',
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName.$extension');
      
      await file.writeAsString(content);
      return file.path;
    } catch (e) {
      print('Error saving temporary file: $e');
      return null;
    }
  }
  
  /// Search for filaments using Bambu Lab API
  static Future<List<Map<String, dynamic>>> searchFilaments({
    String query = '',
    String? brand,
    String? material,
    String? color,
  }) async {
    try {
      // First try to get filaments from Bambu Lab's official API
      final filaments = await _fetchBambuLabFilaments();
      
      if (filaments.isNotEmpty) {
        return _filterFilaments(filaments, query: query, brand: brand, material: material, color: color);
      }
      
      // Fallback to mock data if API is not available
      return await _getMockFilaments(query: query, brand: brand, material: material, color: color);
    } catch (e) {
      print('Error searching filaments: $e');
      return await _getMockFilaments(query: query, brand: brand, material: material, color: color);
    }
  }

  /// Fetch filaments from Bambu Lab's official API
  static Future<List<Map<String, dynamic>>> _fetchBambuLabFilaments() async {
    try {
      const String apiUrl = 'https://api.bambulab.com/v1/filaments';
      
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'ThreePrint-App/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        
        if (responseData is Map<String, dynamic> && responseData.containsKey('filaments')) {
          final List<dynamic> rawFilaments = responseData['filaments'];
          return rawFilaments.map((filament) => _normalizeFilamentData(filament)).toList();
        } else if (responseData is List) {
          final List<dynamic> rawFilaments = responseData;
          return rawFilaments.map((filament) => _normalizeFilamentData(filament)).toList();
        }
      }
    } catch (e) {
      print('Error fetching Bambu Lab filaments: $e');
    }
    
    return [];
  }

  /// Filter filaments based on search criteria
  static List<Map<String, dynamic>> _filterFilaments(
    List<Map<String, dynamic>> filaments, {
    String query = '',
    String? brand,
    String? material,
    String? color,
  }) {
    List<Map<String, dynamic>> filteredResults = filaments;

    if (query.isNotEmpty) {
      filteredResults = filteredResults.where((filament) {
        final searchText = query.toLowerCase();
        return filament['name'].toString().toLowerCase().contains(searchText) ||
               filament['material'].toString().toLowerCase().contains(searchText) ||
               filament['color'].toString().toLowerCase().contains(searchText) ||
               filament['brand'].toString().toLowerCase().contains(searchText);
      }).toList();
    }

    if (brand != null && brand.isNotEmpty) {
      filteredResults = filteredResults.where((filament) =>
          filament['brand'].toString().toLowerCase().contains(brand.toLowerCase())
      ).toList();
    }

    if (material != null && material.isNotEmpty) {
      filteredResults = filteredResults.where((filament) =>
          filament['material'].toString().toLowerCase() == material.toLowerCase()
      ).toList();
    }

    if (color != null && color.isNotEmpty) {
      filteredResults = filteredResults.where((filament) =>
          filament['color'].toString().toLowerCase().contains(color.toLowerCase())
      ).toList();
    }

    return filteredResults;
  }

  /// Normalize filament data from API to our expected format
  static Map<String, dynamic> _normalizeFilamentData(dynamic rawFilament) {
    final Map<String, dynamic> filament = rawFilament as Map<String, dynamic>;
    
    return {
      'id': filament['id'] ?? filament['sku'] ?? 'unknown_${DateTime.now().millisecondsSinceEpoch}',
      'brand': filament['brand'] ?? filament['manufacturer'] ?? 'Bambu Lab',
      'name': filament['name'] ?? filament['product_name'] ?? 'Unknown Filament',
      'material': filament['material'] ?? filament['type'] ?? 'PLA',
      'color': filament['color'] ?? filament['color_name'] ?? 'Unknown',
      'color_hex': filament['color_hex'] ?? filament['hex_color'] ?? '#808080',
      'diameter': _parseDouble(filament['diameter']) ?? 1.75,
      'weight': _parseDouble(filament['weight']) ?? 1000,
      'price': _parseDouble(filament['price']) ?? _parseDouble(filament['retail_price']) ?? 0.0,
      'temperature': {
        'nozzle': _parseInt(filament['nozzle_temp']) ?? 
                  _parseInt(filament['print_temp']) ?? 
                  _getDefaultNozzleTemp(filament['material'] ?? 'PLA'),
        'bed': _parseInt(filament['bed_temp']) ?? 
               _parseInt(filament['heated_bed_temp']) ?? 
               _getDefaultBedTemp(filament['material'] ?? 'PLA'),
      },
      'properties': {
        'strength': filament['strength'] ?? _getMaterialStrength(filament['material'] ?? 'PLA'),
        'flexibility': filament['flexibility'] ?? _getMaterialFlexibility(filament['material'] ?? 'PLA'),
        'ease_of_use': filament['ease_of_use'] ?? _getMaterialEaseOfUse(filament['material'] ?? 'PLA'),
        'supports_required': filament['supports_required'] ?? _getMaterialSupportsRequired(filament['material'] ?? 'PLA'),
      },
      'description': filament['description'] ?? filament['product_description'] ?? '',
      'in_stock': filament['in_stock'] ?? filament['available'] ?? true,
      'ams_compatible': filament['ams_compatible'] ?? _isAmsCompatible(filament['material'] ?? 'PLA'),
      'spool_weight': _parseDouble(filament['spool_weight']) ?? 200,
    };
  }

  /// Fallback mock data when API is not available
  static Future<List<Map<String, dynamic>>> _getMockFilaments({
    String query = '',
    String? brand,
    String? material,
    String? color,
  }) async {
    final List<Map<String, dynamic>> mockFilaments = [
      {
        'id': 'bambu_pla_white',
        'brand': 'Bambu Lab',
        'name': 'PLA Basic White',
        'material': 'PLA',
        'color': 'White',
        'color_hex': '#FFFFFF',
        'diameter': 1.75,
        'weight': 1000,
        'price': 24.99,
        'temperature': {'nozzle': 220, 'bed': 35},
        'properties': {
          'strength': 'Medium',
          'flexibility': 'Low',
          'ease_of_use': 'High',
          'supports_required': false,
        },
        'description': 'High-quality PLA filament perfect for beginners',
        'in_stock': true,
        'ams_compatible': true,
        'spool_weight': 200,
      },
      {
        'id': 'bambu_petg_clear',
        'brand': 'Bambu Lab',
        'name': 'PETG Basic Clear',
        'material': 'PETG',
        'color': 'Clear',
        'color_hex': '#F0F0F0',
        'diameter': 1.75,
        'weight': 1000,
        'price': 29.99,
        'temperature': {'nozzle': 250, 'bed': 70},
        'properties': {
          'strength': 'High',
          'flexibility': 'Medium',
          'ease_of_use': 'Medium',
          'supports_required': false,
        },
        'description': 'Transparent PETG for strong, clear prints',
        'in_stock': true,
        'ams_compatible': true,
        'spool_weight': 200,
      },
      {
        'id': 'bambu_abs_black',
        'brand': 'Bambu Lab',
        'name': 'ABS Black',
        'material': 'ABS',
        'color': 'Black',
        'color_hex': '#000000',
        'diameter': 1.75,
        'weight': 1000,
        'price': 27.99,
        'temperature': {'nozzle': 270, 'bed': 90},
        'properties': {
          'strength': 'Very High',
          'flexibility': 'Medium',
          'ease_of_use': 'Low',
          'supports_required': true,
        },
        'description': 'Industrial-grade ABS for functional parts',
        'in_stock': false,
        'ams_compatible': true,
        'spool_weight': 200,
      },
      {
        'id': 'bambu_tpu_red',
        'brand': 'Bambu Lab',
        'name': 'TPU 95A Red',
        'material': 'TPU',
        'color': 'Red',
        'color_hex': '#FF0000',
        'diameter': 1.75,
        'weight': 500,
        'price': 39.99,
        'temperature': {'nozzle': 220, 'bed': 35},
        'properties': {
          'strength': 'Medium',
          'flexibility': 'Very High',
          'ease_of_use': 'Low',
          'supports_required': false,
        },
        'description': 'Flexible TPU for phone cases and gaskets',
        'in_stock': true,
        'ams_compatible': false,
        'spool_weight': 200,
      },
      {
        'id': 'bambu_wood_pla',
        'brand': 'Bambu Lab',
        'name': 'PLA Wood',
        'material': 'PLA',
        'color': 'Wood',
        'color_hex': '#D2B48C',
        'diameter': 1.75,
        'weight': 1000,
        'price': 32.99,
        'temperature': {'nozzle': 215, 'bed': 35},
        'properties': {
          'strength': 'Medium',
          'flexibility': 'Low',
          'ease_of_use': 'Medium',
          'supports_required': false,
        },
        'description': 'Wood-filled PLA with natural wood appearance',
        'in_stock': true,
        'ams_compatible': true,
        'spool_weight': 200,
      },
    ];

    return _filterFilaments(mockFilaments, query: query, brand: brand, material: material, color: color);
  }

  /// Get filament details by ID
  static Future<Map<String, dynamic>?> getFilamentDetails(String filamentId) async {
    try {
      final filaments = await searchFilaments();
      return filaments.firstWhere(
        (filament) => filament['id'] == filamentId,
        orElse: () => {},
      );
    } catch (e) {
      print('Error getting filament details: $e');
      return null;
    }
  }

  /// Get available filament materials
  static Future<List<String>> getFilamentMaterials() async {
    try {
      final filaments = await searchFilaments();
      final materials = filaments
          .map((filament) => filament['material'].toString())
          .toSet()
          .toList();
      materials.sort();
      return materials.isNotEmpty ? materials : ['PLA', 'PETG', 'ABS', 'TPU'];
    } catch (e) {
      print('Error getting filament materials: $e');
      return ['PLA', 'PETG', 'ABS', 'TPU'];
    }
  }

  /// Get available filament brands
  static Future<List<String>> getFilamentBrands() async {
    try {
      final filaments = await searchFilaments();
      final brands = filaments
          .map((filament) => filament['brand'].toString())
          .toSet()
          .toList();
      brands.sort();
      return brands.isNotEmpty ? brands : ['Bambu Lab'];
    } catch (e) {
      print('Error getting filament brands: $e');
      return ['Bambu Lab'];
    }
  }

  /// Generate a sample 3MF file for testing
  static Future<String?> generateSample3MF() async {
    const sample3mfContent = '''<?xml version="1.0" encoding="UTF-8"?>
<model unit="millimeter" xml:lang="en-US" xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02">
  <metadata name="Title">Test Cube</metadata>
  <metadata name="Designer">ThreePrint App</metadata>
  <metadata name="Description">Sample test cube generated by ThreePrint</metadata>
  <resources>
    <object id="1" type="model">
      <mesh>
        <vertices>
          <vertex x="0" y="0" z="0"/>
          <vertex x="10" y="0" z="0"/>
          <vertex x="10" y="10" z="0"/>
          <vertex x="0" y="10" z="0"/>
          <vertex x="0" y="0" z="10"/>
          <vertex x="10" y="0" z="10"/>
          <vertex x="10" y="10" z="10"/>
          <vertex x="0" y="10" z="10"/>
        </vertices>
        <triangles>
          <triangle v1="0" v2="1" v3="2"/>
          <triangle v1="0" v2="2" v3="3"/>
          <triangle v1="4" v2="6" v3="5"/>
          <triangle v1="4" v2="7" v3="6"/>
          <triangle v1="0" v2="4" v3="5"/>
          <triangle v1="0" v2="5" v3="1"/>
          <triangle v1="2" v2="6" v3="7"/>
          <triangle v1="2" v2="7" v3="3"/>
          <triangle v1="0" v2="3" v3="7"/>
          <triangle v1="0" v2="7" v3="4"/>
          <triangle v1="1" v2="5" v3="6"/>
          <triangle v1="1" v2="6" v3="2"/>
        </triangles>
      </mesh>
    </object>
  </resources>
  <build>
    <item objectid="1"/>
  </build>
</model>''';
    
    return await saveTemporaryFile(
      content: sample3mfContent,
      fileName: 'test_cube',
      extension: '3mf',
    );
  }

  // Helper methods for parsing and normalizing data
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static int _getDefaultNozzleTemp(String material) {
    switch (material.toUpperCase()) {
      case 'PLA':
        return 220;
      case 'PETG':
        return 250;
      case 'ABS':
        return 270;
      case 'TPU':
        return 220;
      case 'WOOD':
      case 'PLA+':
        return 215;
      default:
        return 220;
    }
  }

  static int _getDefaultBedTemp(String material) {
    switch (material.toUpperCase()) {
      case 'PLA':
        return 35;
      case 'PETG':
        return 70;
      case 'ABS':
        return 90;
      case 'TPU':
        return 35;
      case 'WOOD':
      case 'PLA+':
        return 35;
      default:
        return 35;
    }
  }

  static String _getMaterialStrength(String material) {
    switch (material.toUpperCase()) {
      case 'PLA':
        return 'Medium';
      case 'PETG':
        return 'High';
      case 'ABS':
        return 'Very High';
      case 'TPU':
        return 'Medium';
      default:
        return 'Medium';
    }
  }

  static String _getMaterialFlexibility(String material) {
    switch (material.toUpperCase()) {
      case 'PLA':
      case 'ABS':
        return 'Low';
      case 'PETG':
        return 'Medium';
      case 'TPU':
        return 'Very High';
      default:
        return 'Low';
    }
  }

  static String _getMaterialEaseOfUse(String material) {
    switch (material.toUpperCase()) {
      case 'PLA':
        return 'High';
      case 'PETG':
      case 'TPU':
      case 'ABS':
        return 'Medium';
      default:
        return 'High';
    }
  }

  static bool _getMaterialSupportsRequired(String material) {
    switch (material.toUpperCase()) {
      case 'ABS':
        return true;
      default:
        return false;
    }
  }

  static bool _isAmsCompatible(String material) {
    switch (material.toUpperCase()) {
      case 'TPU':
        return false;
      default:
        return true;
    }
  }
}

/// Exception class for Bambu Lab integration errors
class BambuLabException implements Exception {
  final String message;
  final String? code;
  
  const BambuLabException(this.message, [this.code]);
  
  @override
  String toString() => 'BambuLabException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Enum for different Bambu Lab integration methods
enum BambuIntegrationMethod {
  bambuConnect,
  developerMode,
  localServer,
}

/// Configuration class for Bambu Lab settings
class BambuLabConfig {
  final BambuIntegrationMethod method;
  final String? printerIp;
  final String? accessCode;
  final String? localServerUrl;
  
  const BambuLabConfig({
    required this.method,
    this.printerIp,
    this.accessCode,
    this.localServerUrl,
  });
  
  factory BambuLabConfig.bambuConnect() {
    return const BambuLabConfig(method: BambuIntegrationMethod.bambuConnect);
  }
  
  factory BambuLabConfig.developerMode({
    required String printerIp,
    String? accessCode,
  }) {
    return BambuLabConfig(
      method: BambuIntegrationMethod.developerMode,
      printerIp: printerIp,
      accessCode: accessCode,
    );
  }
  
  factory BambuLabConfig.localServer({
    required String serverUrl,
  }) {
    return BambuLabConfig(
      method: BambuIntegrationMethod.localServer,
      localServerUrl: serverUrl,
    );
  }
}