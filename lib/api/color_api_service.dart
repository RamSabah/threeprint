import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class ColorApiService {
  static const String _baseUrl = 'https://www.thecolorapi.com';
  
  // Predefined color name to hex mappings for comprehensive color search (300+ colors)
  static const Map<String, String> _colorNameToHex = {
    // Basic Colors
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
    
    // Extended Reds
    'dark red': '8B0000',
    'light red': 'FFB6C1',
    'crimson': 'DC143C',
    'maroon': '800000',
    'indian red': 'CD5C5C',
    'fire brick': 'B22222',
    'light coral': 'F08080',
    'salmon': 'FA8072',
    'dark salmon': 'E9967A',
    'light salmon': 'FFA07A',
    'tomato': 'FF6347',
    'red orange': 'FF5349',
    'vermillion': 'E34234',
    'scarlet': 'FF2400',
    'ruby': 'E0115F',
    'cherry': 'D2001F',
    'rose': 'FF007F',
    'cerise': 'DE3163',
    'cardinal': 'C41E3A',
    'brick red': 'CB4154',
    'burgundy': '800020',
    'wine': '722F37',
    'mahogany': 'C04000',
    
    // Extended Blues
    'navy': '000080',
    'navy blue': '000080',
    'dark blue': '00008B',
    'medium blue': '0000CD',
    'light blue': 'ADD8E6',
    'powder blue': 'B0E0E6',
    'sky blue': '87CEEB',
    'light sky blue': '87CEFA',
    'deep sky blue': '00BFFF',
    'dodger blue': '1E90FF',
    'cornflower blue': '6495ED',
    'steel blue': '4682B4',
    'royal blue': '4169E1',
    'blue violet': '8A2BE2',
    'indigo': '4B0082',
    'midnight blue': '191970',
    'slate blue': '6A5ACD',
    'dark slate blue': '483D8B',
    'medium slate blue': '7B68EE',
    'periwinkle': 'CCCCFF',
    'cadet blue': '5F9EA0',
    'azure': 'F0FFFF',
    'alice blue': 'F0F8FF',
    'light steel blue': 'B0C4DE',
    'ice blue': 'B8D4E3',
    'baby blue': '89CFF0',
    'sapphire': '0F52BA',
    'cobalt': '0047AB',
    'prussian blue': '003153',
    'electric blue': '7DF9FF',
    'turquoise blue': '00FFEF',
    
    // Extended Greens
    'dark green': '006400',
    'forest green': '228B22',
    'lime green': '32CD32',
    'light green': '90EE90',
    'pale green': '98FB98',
    'spring green': '00FF7F',
    'medium spring green': '00FA9A',
    'sea green': '2E8B57',
    'medium sea green': '3CB371',
    'dark sea green': '8FBC8F',
    'olive green': '808000',
    'olive': '808000',
    'yellow green': '9ACD32',
    'lawn green': '7CFC00',
    'chartreuse': '7FFF00',
    'green yellow': 'ADFF2F',
    'dark olive green': '556B2F',
    'olive drab': '6B8E23',
    'light sea green': '20B2AA',
    'dark cyan': '008B8B',
    'teal': '008080',
    'aqua': '00FFFF',
    'cyan': '00FFFF',
    'light cyan': 'E0FFFF',
    'dark turquoise': '00CED1',
    'turquoise': '40E0D0',
    'medium turquoise': '48D1CC',
    'pale turquoise': 'AFEEEE',
    'mint cream': 'F5FFFA',
    'mint': '98FF98',
    'emerald': '50C878',
    'jade': '00A86B',
    'forest': '014421',
    'pine': '01796F',
    'sage': '9CAF88',
    'lime': '00FF00',
    'neon green': '39FF14',
    
    // Extended Yellows
    'light yellow': 'FFFFE0',
    'lemon chiffon': 'FFFACD',
    'light goldenrod yellow': 'FAFAD2',
    'papaya whip': 'FFEFD5',
    'moccasin': 'FFE4B5',
    'peach puff': 'FFDAB9',
    'pale goldenrod': 'EEE8AA',
    'khaki': 'F0E68C',
    'dark khaki': 'BDB76B',
    'gold': 'FFD700',
    'goldenrod': 'DAA520',
    'dark goldenrod': 'B8860B',
    'lemon': 'FFF700',
    'canary': 'FFFF99',
    'banana': 'FFE135',
    'mustard': 'FFDB58',
    'amber': 'FFBF00',
    'honey': 'FFB90F',
    'corn': 'FBEC5D',
    'wheat': 'F5DEB3',
    'cream': 'FFFDD0',
    'ivory': 'FFFFF0',
    'beige': 'F5F5DC',
    'champagne': 'F7E7CE',
    
    // Extended Oranges
    'dark orange': 'FF8C00',
    'light orange': 'FFE4B5',
    'deep orange': 'FF6600',
    'burnt orange': 'CC5500',
    'dark coral': 'CD5B45',
    'peach': 'FFCBA4',
    'apricot': 'FBCEB1',
    'papaya': 'FFEFD5',
    'tangerine': 'F28500',
    'mandarin': 'F37A48',
    'clementine': 'FF7F00',
    'persimmon': 'EC5800',
    'pumpkin': 'FF7518',
    'carrot': 'ED9121',
    'cadmium orange': 'FF6103',
    'safety orange': 'FF6700',
    
    // Extended Purples
    'dark violet': '9400D3',
    'dark orchid': '9932CC',
    'medium orchid': 'BA55D3',
    'dark magenta': '8B008B',
    'magenta': 'FF00FF',
    'fuchsia': 'FF00FF',
    'violet': 'EE82EE',
    'plum': 'DDA0DD',
    'thistle': 'D8BFD8',
    'lavender': 'E6E6FA',
    'medium purple': '9370DB',
    'medium violet red': 'C71585',
    'pale violet red': 'DB7093',
    'deep pink': 'FF1493',
    'hot pink': 'FF69B4',
    'light pink': 'FFB6C1',
    'antique white': 'FAEBD7',
    'lavender blush': 'FFF0F5',
    'misty rose': 'FFE4E1',
    'orchid': 'DA70D6',
    'amethyst': '9966CC',
    'grape': '6F2DA8',
    'eggplant': '614051',
    'mulberry': 'C54B8C',
    'mauve': 'E0B0FF',
    'lilac': 'C8A2C8',
    
    // Extended Pinks
    'rose gold': 'E8B4CB',
    'blush': 'DE5D83',
    'flamingo': 'FC8EAC',
    'bubblegum': 'FF69B4',
    'carnation': 'FFA6C9',
    'cotton candy': 'FFB7D5',
    'cherry blossom': 'FFB7C5',
    'baby pink': 'F4C2C2',
    'powder pink': 'FFB6C1',
    'dusty rose': 'DCAE96',
    'old rose': 'C08081',
    'tea rose': 'F88379',
    
    // Extended Browns
    'dark brown': '654321',
    'light brown': 'CD853F',
    'saddle brown': '8B4513',
    'sienna': 'A0522D',
    'dark chocolate': '3C1810',
    'peru': 'CD853F',
    'sandy brown': 'F4A460',
    'rosy brown': 'BC8F8F',
    'tan': 'D2B48C',
    'burlywood': 'DEB887',
    'navajo white': 'FFDEAD',
    'bisque': 'FFE4C4',
    'blanched almond': 'FFEBCD',
    'cornsilk': 'FFF8DC',
    'coffee': '6F4E37',
    'espresso': '362D1D',
    'mocha': '967117',
    'cocoa': 'D2691E',
    'cinnamon': 'D2691E',
    'bronze': 'CD7F32',
    'copper': 'B87333',
    'rust': 'B7410E',
    'chestnut': '954535',
    'auburn': 'A52A2A',
    'umber': '635147',
    'sepia': '704214',
    'taupe': '483C32',
    
    // Extended Grays
    'light gray': 'D3D3D3',
    'light grey': 'D3D3D3',
    'silver': 'C0C0C0',
    'dark gray': 'A9A9A9',
    'dark grey': 'A9A9A9',
    'dim gray': '696969',
    'dim grey': '696969',
    'light slate gray': '778899',
    'light slate grey': '778899',
    'slate gray': '708090',
    'slate grey': '708090',
    'dark slate gray': '2F4F4F',
    'dark slate grey': '2F4F4F',
    'charcoal': '36454F',
    'smoke': '848884',
    'ash': 'B2BEB5',
    'stone': '928E85',
    'pewter': '96A8A1',
    'iron': '464451',
    'steel': '71797E',
    'gunmetal': '2C3539',
    'platinum': 'E5E4E2',
    'gainsboro': 'DCDCDC',
    'white smoke': 'F5F5F5',
    'ghost white': 'F8F8FF',
    
    // Nature Colors
    'moss': '8A9A5B',
    'fern': '4F7942',
    'seafoam': '93E9BE',
    'ocean': '006994',
    'sky': '87CEEB',
    'cloud': 'F0F8FF',
    'sand': 'C2B280',
    'earth': '654321',
    'clay': 'B66325',
    'mud': '60460F',
    'granite': '676767',
    'marble': 'F8F8FF',
    'pearl': 'F0EAD6',
    'bone': 'F9F6EE',
    'shell': 'FFF5EE',
    'sunset': 'FAD5A5',
    'sunrise': 'FFCF48',
    'moonlight': 'F0F8FF',
    'starlight': 'FFFACD',
    
    // Metallic Colors
    'brass': 'B5A642',
    'chrome': 'AAA9AD',
    'titanium': '878681',
    'aluminum': 'A8A8A8',
    'zinc': '7A7A7A',
    'nickel': '727472',
    'tin': '7C7C72',
    'lead': '2C2C2C',
    'mercury': 'E5E5E5',
    
    // Gemstone Colors
    'diamond': 'B9F2FF',
    'topaz': 'FFC87C',
    'garnet': '733635',
    'opal': 'A8C3BC',
    'aquamarine': '7FFFD4',
    'citrine': 'E4D00A',
    'peridot': 'E6E200',
    'onyx': '353839',
    'obsidian': '3C4142',
    'quartz': 'F7F3E9',
    'crystal': 'A7D8DE',
    
    // Food Colors
    'strawberry': 'FC5A8D',
    'raspberry': 'E30B5C',
    'blueberry': '4F86F7',
    'pineapple': 'FFDB58',
    'mango': 'FFCC5C',
    'coconut': 'F8F8FF',
    'avocado': '568203',
    'vanilla': 'F3E5AB',
    'caramel': 'AF6F09',
    'ginger': 'B06500',
    'nutmeg': 'C49675',
    'paprika': 'CC2222',
    'saffron': 'F4C430',
    'curry': 'CC9900',
    'ketchup': 'D2691E',
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