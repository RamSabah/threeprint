import 'package:flutter/material.dart';
import 'dart:async';
import '../api/color_api_service.dart';

class AddFilamentPage extends StatefulWidget {
  const AddFilamentPage({super.key});

  @override
  State<AddFilamentPage> createState() => _AddFilamentPageState();
}

class _AddFilamentPageState extends State<AddFilamentPage> {
  final _formKey = GlobalKey<FormState>();
  final _countController = TextEditingController();
  final _colorSearchController = TextEditingController();
  final _hexColorController = TextEditingController();
  
  String? _selectedFilamentType;
  String? _selectedColor;
  String? _customHexColor;
  List<String> _filteredColors = [];
  List<ColorResult> _apiColorResults = [];
  bool _showColorSearch = false;
  bool _showHexInput = false;
  bool _isSearchingApi = false;
  bool _showApiResults = false;
  Timer? _searchTimer;
  
  final List<String> _filamentTypes = ['PETG', 'PLA', 'Other'];
  final List<String> _allColors = [
    'Red',
    'Dark Red',
    'Light Red',
    'Crimson',
    'Maroon',
    'Blue',
    'Dark Blue', 
    'Light Blue',
    'Navy Blue',
    'Sky Blue',
    'Royal Blue',
    'Cyan',
    'Teal',
    'Green',
    'Dark Green',
    'Light Green',
    'Lime Green',
    'Forest Green',
    'Mint Green',
    'Olive Green',
    'Yellow',
    'Light Yellow',
    'Golden Yellow',
    'Lemon Yellow',
    'Orange',
    'Dark Orange',
    'Light Orange',
    'Coral',
    'Purple',
    'Dark Purple',
    'Light Purple',
    'Violet',
    'Lavender',
    'Magenta',
    'Pink',
    'Hot Pink',
    'Light Pink',
    'Rose',
    'Black',
    'Dark Gray',
    'Gray',
    'Light Gray',
    'Silver',
    'White',
    'Ivory',
    'Cream',
    'Beige',
    'Brown',
    'Dark Brown',
    'Light Brown',
    'Tan',
    'Bronze',
    'Gold',
    'Copper',
    'Clear/Transparent',
    'Glow in the Dark',
    'Metallic Silver',
    'Metallic Gold',
    'Wood Fill',
    'Carbon Fiber',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _filteredColors = _allColors;
  }

  @override
  void dispose() {
    _countController.dispose();
    _colorSearchController.dispose();
    _hexColorController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  void _filterColors(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredColors = _allColors;
        _apiColorResults.clear();
        _showApiResults = false;
      } else {
        // Filter local colors
        _filteredColors = _allColors
            .where((color) => color.toLowerCase().contains(query.toLowerCase()))
            .toList();
        
        // Search API for colors
        _searchApiColors(query);
      }
    });
  }

  void _searchApiColors(String query) {
    if (query.length < 2) {
      setState(() {
        _apiColorResults.clear();
        _showApiResults = false;
        _isSearchingApi = false;
      });
      return;
    }
    
    // Cancel previous timer
    _searchTimer?.cancel();
    
    // Start new timer for debouncing (wait 800ms before making API call)
    _searchTimer = Timer(const Duration(milliseconds: 800), () async {
      await _performApiSearch();
    });
  }
  
  void _clearSearchState() {
    _searchTimer?.cancel();
    setState(() {
      _colorSearchController.clear();
      _apiColorResults.clear();
      _showApiResults = false;
      _isSearchingApi = false;
      _showColorSearch = false;
    });
  }
  
  Color _getDisplayColorForSelected() {
    if (_customHexColor != null) {
      return _getColorFromHex(_customHexColor!);
    } else if (_selectedColor != null) {
      return _getColorFromName(_selectedColor!);
    }
    return Colors.grey;
  }

  Future<void> _performApiSearch() async {
    final query = _colorSearchController.text.trim();
    if (query.isEmpty) return;
    
    // Cancel any existing search
    _searchTimer?.cancel();
    
    setState(() {
      _isSearchingApi = true;
      _showApiResults = false;
      _apiColorResults.clear(); // Clear previous results
    });

    try {
      final results = await ColorApiService.searchColors(query);
      if (mounted) {
        setState(() {
          _apiColorResults = results;
          _showApiResults = results.isNotEmpty;
          _isSearchingApi = false;
        });
        
        if (results.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No colors found. Try searching for common colors like "blue", "red", or hex codes.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearchingApi = false;
          _showApiResults = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching colors: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _setColorFromHex(String hexValue) {
    if (hexValue.isNotEmpty) {
      // Validate hex format
      if (RegExp(r'^#?([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$').hasMatch(hexValue)) {
        setState(() {
          _customHexColor = hexValue.startsWith('#') ? hexValue : '#$hexValue';
          _selectedColor = 'Custom ($hexValue)';
        });
      }
    }
  }

  void _saveFilament() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implement save functionality (e.g., save to Firebase/local storage)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Filament saved: $_selectedFilamentType, $_selectedColor, ${_countController.text} units',
          ),
          backgroundColor: Colors.green,
        ),
      );
      
      // Clear form after saving
      _resetForm();
    }
  }

  void _resetForm() {
    // Cancel any ongoing search
    _searchTimer?.cancel();
    
    setState(() {
      _selectedFilamentType = null;
      _selectedColor = null;
      _customHexColor = null;
      _showColorSearch = false;
      _showHexInput = false;
      _filteredColors = _allColors;
      _apiColorResults.clear();
      _showApiResults = false;
      _isSearchingApi = false;
    });
    _countController.clear();
    _colorSearchController.clear();
    _hexColorController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  Image.asset(
                    'lib/assets/icons/Filament_Roll.png',
                    width: 80,
                    height: 80,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Add New Filament',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Track your filament inventory',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Filament Type Dropdown
            const Text(
              'Filament Type',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedFilamentType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
                hintText: 'Select filament type',
              ),
              items: _filamentTypes.map((String type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedFilamentType = newValue;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a filament type';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            
            // Color Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Color',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _showColorSearch = !_showColorSearch;
                          if (_showColorSearch) _showHexInput = false;
                        });
                      },
                      icon: Icon(
                        Icons.search,
                        color: _showColorSearch ? Colors.green : Colors.grey,
                      ),
                      tooltip: 'Search colors',
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _showHexInput = !_showHexInput;
                          if (_showHexInput) _showColorSearch = false;
                        });
                      },
                      icon: Icon(
                        Icons.color_lens,
                        color: _showHexInput ? Colors.green : Colors.grey,
                      ),
                      tooltip: 'Custom HEX color',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Color Search Field
            if (_showColorSearch) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _colorSearchController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search colors (e.g., blue, red, FF0000)...',
                      ),
                      onChanged: _filterColors,
                      onSubmitted: (value) => _performApiSearch(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSearchingApi ? null : _performApiSearch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: _isSearchingApi 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Search'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // API Search Results - More visible list
              if (_showApiResults && _apiColorResults.isNotEmpty) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue.shade300, width: 2),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.blue.shade50,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.palette, 
                              size: 20, 
                              color: Colors.blue.shade700
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Color Search Results (${_apiColorResults.length})',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _apiColorResults.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          color: Colors.grey.shade300,
                        ),
                        itemBuilder: (context, index) {
                          final colorResult = _apiColorResults[index];
                          return ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: colorResult.color,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey.shade400,
                                  width: 2,
                                ),
                              ),
                            ),
                            title: Text(
                              colorResult.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              'HEX: ${colorResult.hex}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () {
                              // Cancel any ongoing search
                              _searchTimer?.cancel();
                              
                              setState(() {
                                // Add the API color to our local colors if not already present
                                if (!_allColors.contains(colorResult.name)) {
                                  _allColors.add(colorResult.name);
                                }
                                if (!_filteredColors.contains(colorResult.name)) {
                                  _filteredColors.add(colorResult.name);
                                }
                                
                                _selectedColor = colorResult.name;
                                _customHexColor = colorResult.hex;
                                _colorSearchController.clear(); // Clear search field
                                _showApiResults = false;
                                _apiColorResults.clear();
                                _isSearchingApi = false;
                                _showColorSearch = false; // Hide search UI
                              });
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Selected: ${colorResult.name}'),
                                  backgroundColor: Colors.green,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: TextButton(
                          onPressed: () {
                            _searchTimer?.cancel();
                            setState(() {
                              _showApiResults = false;
                              _apiColorResults.clear();
                              _isSearchingApi = false;
                            });
                          },
                          child: const Text('Close Results'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
            
            // HEX Color Input
            if (_showHexInput) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _hexColorController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.tag),
                        hintText: 'Enter HEX color (e.g., FF5733)',
                      ),
                      onChanged: (value) {
                        if (value.length >= 6) {
                          _setColorFromHex(value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _customHexColor != null 
                          ? _getColorFromHex(_customHexColor!) 
                          : Colors.grey.shade300,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            
            // Color Dropdown
            DropdownButtonFormField<String>(
              value: _filteredColors.contains(_selectedColor) ? _selectedColor : null,
              isExpanded: true,
              menuMaxHeight: 500,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.palette),
                hintText: _selectedColor != null && !_filteredColors.contains(_selectedColor) 
                  ? 'Selected: $_selectedColor (from API)'
                  : 'Select color',
              ),
              items: _filteredColors.map((String color) {
                return DropdownMenuItem<String>(
                  value: color,
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: _getColorFromName(color),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          color,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedColor = newValue;
                  _customHexColor = null; // Clear custom hex when selecting predefined color
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a color';
                }
                return null;
              },
            ),
            
            // Show selected API color if it's not in dropdown
            if (_selectedColor != null && !_filteredColors.contains(_selectedColor!)) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _getDisplayColorForSelected(),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected: $_selectedColor',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          if (_customHexColor != null)
                            Text(
                              'HEX: $_customHexColor',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedColor = null;
                          _customHexColor = null;
                        });
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            
            // Count Input
            const Text(
              'Count',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _countController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.format_list_numbered),
                hintText: 'Enter quantity',
                suffixText: 'units',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the count';
                }
                final count = int.tryParse(value);
                if (count == null || count <= 0) {
                  return 'Please enter a valid positive number';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveFilament,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save),
                    SizedBox(width: 8),
                    Text('Save Filament', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Reset Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _resetForm,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Reset Form', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorFromName(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'dark red':
        return Colors.red.shade800;
      case 'light red':
        return Colors.red.shade300;
      case 'crimson':
        return const Color(0xFFDC143C);
      case 'maroon':
        return const Color(0xFF800000);
      case 'blue':
        return Colors.blue;
      case 'dark blue':
        return Colors.blue.shade800;
      case 'light blue':
        return Colors.blue.shade300;
      case 'navy blue':
        return const Color(0xFF000080);
      case 'sky blue':
        return const Color(0xFF87CEEB);
      case 'royal blue':
        return const Color(0xFF4169E1);
      case 'cyan':
        return Colors.cyan;
      case 'teal':
        return Colors.teal;
      case 'green':
        return Colors.green;
      case 'dark green':
        return Colors.green.shade800;
      case 'light green':
        return Colors.green.shade300;
      case 'lime green':
        return const Color(0xFF32CD32);
      case 'forest green':
        return const Color(0xFF228B22);
      case 'mint green':
        return const Color(0xFF98FB98);
      case 'olive green':
        return const Color(0xFF808000);
      case 'yellow':
        return Colors.yellow;
      case 'light yellow':
        return Colors.yellow.shade300;
      case 'golden yellow':
        return const Color(0xFFFFD700);
      case 'lemon yellow':
        return const Color(0xFFFFFACD);
      case 'orange':
        return Colors.orange;
      case 'dark orange':
        return Colors.orange.shade800;
      case 'light orange':
        return Colors.orange.shade300;
      case 'coral':
        return const Color(0xFFFF7F50);
      case 'purple':
        return Colors.purple;
      case 'dark purple':
        return Colors.purple.shade800;
      case 'light purple':
        return Colors.purple.shade300;
      case 'violet':
        return const Color(0xFF8A2BE2);
      case 'lavender':
        return const Color(0xFFE6E6FA);
      case 'magenta':
        return Colors.pink.shade600;
      case 'pink':
        return Colors.pink;
      case 'hot pink':
        return const Color(0xFFFF69B4);
      case 'light pink':
        return Colors.pink.shade200;
      case 'rose':
        return const Color(0xFFFF007F);
      case 'black':
        return Colors.black;
      case 'dark gray':
        return Colors.grey.shade800;
      case 'gray':
        return Colors.grey;
      case 'light gray':
        return Colors.grey.shade400;
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'white':
        return Colors.white;
      case 'ivory':
        return const Color(0xFFFFFFF0);
      case 'cream':
        return const Color(0xFFFFFDD0);
      case 'beige':
        return const Color(0xFFF5F5DC);
      case 'brown':
        return Colors.brown;
      case 'dark brown':
        return Colors.brown.shade800;
      case 'light brown':
        return Colors.brown.shade300;
      case 'tan':
        return const Color(0xFFD2B48C);
      case 'bronze':
        return const Color(0xFFCD7F32);
      case 'gold':
        return const Color(0xFFFFD700);
      case 'copper':
        return const Color(0xFFB87333);
      case 'clear/transparent':
        return Colors.transparent;
      case 'glow in the dark':
        return const Color(0xFF39FF14);
      case 'metallic silver':
        return const Color(0xFFAAA9AD);
      case 'metallic gold':
        return const Color(0xFFD4AF37);
      case 'wood fill':
        return const Color(0xFF8B4513);
      case 'carbon fiber':
        return const Color(0xFF36454F);
      default:
        return Colors.grey;
    }
  }

  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      return Color(int.parse('FF$hexColor', radix: 16));
    } else if (hexColor.length == 3) {
      // Convert 3-digit hex to 6-digit
      String r = hexColor[0];
      String g = hexColor[1];
      String b = hexColor[2];
      return Color(int.parse('FF$r$r$g$g$b$b', radix: 16));
    }
    return Colors.grey;
  }
}