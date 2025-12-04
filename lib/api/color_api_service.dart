import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class ColorApiService {
  static const String _baseUrl = 'https://www.thecolorapi.com';
  
  // Predefined color name to hex mappings for common colors
  static const Map<String, String> _colorNameToHex = {
    'red': 'FF0000',
    'blue': '0000FF',
    'green': '00FF00',
    'yellow': 'FFFF00',
    'orange': 'FFA500',
    'purple': '800080',
    'pink': 'FFC0CB',
    'brown': 'A52A2A',
    'black': '000000',
    'white': 'FFFFFF',
    'gray': '808080',
    'grey': '808080',
    'navy': '000080',
    'teal': '008080',
    'lime': '00FF00',
    'cyan': '00FFFF',
    'magenta': 'FF00FF',
    'maroon': '800000',
    'olive': '808000',
    'silver': 'C0C0C0',
    'gold': 'FFD700',
    'coral': 'FF7F50',
    'salmon': 'FA8072',
    'crimson': 'DC143C',
    'indigo': '4B0082',
    'violet': 'EE82EE',
    'turquoise': '40E0D0',
    'khaki': 'F0E68C',
    'plum': 'DDA0DD',
  };
  
  /// Search for colors by name
  static Future<List<ColorResult>> searchColors(String query) async {
    if (query.isEmpty || query.length < 2) return [];
    
    try {
      List<ColorResult> results = [];
      
      // Search through predefined colors first
      final lowerQuery = query.toLowerCase();
      for (String colorName in _colorNameToHex.keys) {
        if (colorName.contains(lowerQuery) || lowerQuery.contains(colorName)) {
          final hex = _colorNameToHex[colorName]!;
          final apiResult = await getColorByHex(hex);
          if (apiResult != null) {
            results.add(apiResult);
          }
        }
      }
      
      // If no results, try direct hex conversion if it looks like a hex
      if (results.isEmpty && RegExp(r'^[A-Fa-f0-9]{3,6}$').hasMatch(query)) {
        final apiResult = await getColorByHex(query);
        if (apiResult != null) {
          results.add(apiResult);
        }
      }
      
      return results.take(10).toList(); // Limit to 10 results
    } catch (e) {
      print('Error searching colors: $e');
      return [];
    }
  }
  
  /// Get color information by name (deprecated - use getColorByHex instead)
  static Future<ColorResult?> getColorByName(String colorName) async {
    // The Color API doesn't support name queries directly
    // Try to find a matching hex from our predefined list
    final hex = _colorNameToHex[colorName.toLowerCase()];
    if (hex != null) {
      return getColorByHex(hex);
    }
    return null;
  }
  
  /// Get color information by HEX code
  static Future<ColorResult?> getColorByHex(String hexCode) async {
    try {
      // Remove # if present
      String cleanHex = hexCode.replaceAll('#', '');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/id?hex=$cleanHex'),
        headers: {'Accept': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ColorResult.fromJson(data);
      }
    } catch (e) {
      print('Error getting color by hex: $e');
    }
    return null;
  }
  
  /// Generate color name variations for better search results
  static List<String> _generateColorVariations(String query) {
    final variations = <String>[];
    final lowerQuery = query.toLowerCase();
    
    // Common color prefixes and suffixes
    final prefixes = ['light', 'dark', 'bright', 'pale', 'deep'];
    final suffixes = ['red', 'blue', 'green', 'yellow', 'purple', 'orange', 'pink', 'brown', 'gray', 'grey'];
    
    // Add variations with prefixes
    for (String prefix in prefixes) {
      if (!lowerQuery.contains(prefix)) {
        variations.add('$prefix $query');
      }
    }
    
    // Add base colors if query contains modifiers
    for (String prefix in prefixes) {
      if (lowerQuery.startsWith(prefix)) {
        variations.add(query.substring(prefix.length).trim());
        break;
      }
    }
    
    // Add similar color names based on common mappings
    final colorMappings = {
      'red': ['crimson', 'scarlet', 'maroon', 'cherry'],
      'blue': ['navy', 'azure', 'cyan', 'teal'],
      'green': ['lime', 'forest', 'olive', 'mint'],
      'yellow': ['gold', 'amber', 'lemon'],
      'purple': ['violet', 'magenta', 'lavender'],
      'orange': ['coral', 'peach', 'tangerine'],
      'pink': ['rose', 'salmon', 'fuchsia'],
      'brown': ['tan', 'beige', 'coffee'],
      'gray': ['silver', 'charcoal'],
      'grey': ['silver', 'charcoal'],
    };
    
    for (String baseColor in colorMappings.keys) {
      if (lowerQuery.contains(baseColor)) {
        variations.addAll(colorMappings[baseColor]!);
      }
    }
    
    return variations.take(5).toList(); // Limit variations to avoid too many API calls
  }
}

class ColorResult {
  final String hex;
  final String name;
  final Color color;
  final Map<String, dynamic> rgb;
  final Map<String, dynamic> hsl;
  
  ColorResult({
    required this.hex,
    required this.name,
    required this.color,
    required this.rgb,
    required this.hsl,
  });
  
  factory ColorResult.fromJson(Map<String, dynamic> json) {
    // Safely extract hex value
    String hexValue = '#000000';
    if (json['hex'] != null && json['hex'] is Map && json['hex']['value'] != null) {
      hexValue = json['hex']['value'];
    }
    
    // Safely extract color name
    String colorName = 'Unknown';
    if (json['name'] != null && json['name'] is Map && json['name']['value'] != null) {
      colorName = json['name']['value'];
    }
    
    // Safely extract RGB and HSL values
    final rgbValues = json['rgb'] ?? {};
    final hslValues = json['hsl'] ?? {};
    
    // Convert hex to Flutter Color
    final hexColor = hexValue.replaceAll('#', '');
    int colorValue;
    try {
      colorValue = int.parse('FF$hexColor', radix: 16);
    } catch (e) {
      colorValue = 0xFF000000; // Default to black if parsing fails
    }
    
    return ColorResult(
      hex: hexValue,
      name: colorName,
      color: Color(colorValue),
      rgb: rgbValues,
      hsl: hslValues,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'hex': hex,
      'name': name,
      'rgb': rgb,
      'hsl': hsl,
    };
  }
  
  @override
  String toString() {
    return 'ColorResult(name: $name, hex: $hex)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ColorResult && other.hex.toLowerCase() == hex.toLowerCase();
  }
  
  @override
  int get hashCode => hex.toLowerCase().hashCode;
}