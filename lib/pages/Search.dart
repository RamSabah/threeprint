import 'package:flutter/material.dart';
import '../services/spoolman_service.dart';
import '../services/filament_service.dart';
import 'FilamentDetail.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final SpoolmanService _spoolmanService = SpoolmanService();
  final FilamentService _filamentService = FilamentService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  
  List<SpoolmanFilament> _searchResults = [];
  List<String> _manufacturers = [];
  Map<String, int> _manufacturerCounts = {}; // Store filament counts per manufacturer
  String? _selectedManufacturer;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isLoadingManufacturers = false;
  bool _hasMore = false;
  int _totalCount = 0;
  String _searchQuery = '';
  bool _showingAllManufacturers = false;
  bool _sortByBrightness = false;
  String _viewMode = 'manufacturers'; // 'manufacturers' or 'colors'
  String? _selectedColorFilter; // Filter by color family
  bool _showCardView = false; // Toggle between color-only and card view
  static const int _pageSize = 20;
  
  @override
  void initState() {
    super.initState();
    _loadManufacturers();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _scrollController.removeListener(_onScroll);
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    if (query != _searchQuery) {
      setState(() {
        _searchQuery = query;
      });
      _performSearch(reset: true);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.8) {
      if (_hasMore && !_isLoadingMore && !_isLoading) {
        _loadMoreResults();
      }
    }
  }

  Future<void> _loadManufacturers() async {
    setState(() {
      _isLoadingManufacturers = true;
    });

    try {
      final manufacturers = await _spoolmanService.getManufacturers();
      
      // Fetch count for each manufacturer
      Map<String, int> counts = {};
      for (String manufacturer in manufacturers) {
        try {
          final result = await _spoolmanService.searchFilaments(
            manufacturer: manufacturer,
            limit: 1,
            offset: 0,
          );
          counts[manufacturer] = result.totalCount;
        } catch (e) {
          counts[manufacturer] = 0;
        }
      }
      
      setState(() {
        _manufacturers = manufacturers;
        _manufacturerCounts = counts;
        _isLoadingManufacturers = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingManufacturers = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load manufacturers: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _performSearch({bool reset = false, bool showAll = false}) async {
    if (_searchQuery.isEmpty && _selectedManufacturer == null && !showAll) {
      setState(() {
        _searchResults = [];
        _hasMore = false;
        _totalCount = 0;
        _isLoading = false;
        _showingAllManufacturers = false;
      });
      return;
    }
    
    if (showAll) {
      setState(() {
        _showingAllManufacturers = true;
      });
    } else {
      setState(() {
        _showingAllManufacturers = false;
      });
    }

    if (reset) {
      setState(() {
        _isLoading = true;
        _searchResults = [];
        _hasMore = false;
        _totalCount = 0;
      });
    }

    try {
      // Use larger page size for "All Colors" view to fill tablet screens
      final pageSize = showAll ? 60 : _pageSize;
      
      final result = await _spoolmanService.searchFilaments(
        query: (_searchQuery.isNotEmpty && !showAll) ? _searchQuery : null,
        manufacturer: showAll ? null : _selectedManufacturer,
        limit: pageSize,
        offset: reset ? 0 : _searchResults.length,
      );

      setState(() {
        if (reset) {
          _searchResults = result.filaments;
        } else {
          _searchResults.addAll(result.filaments);
        }
        _hasMore = result.hasMore;
        _totalCount = result.totalCount;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        if (reset) {
          _searchResults = [];
          _hasMore = false;
          _totalCount = 0;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadMoreResults() async {
    if (_isLoadingMore || !_hasMore) return;
    
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final result = await _spoolmanService.searchFilaments(
        query: (_searchQuery.isNotEmpty && !_showingAllManufacturers) ? _searchQuery : null,
        manufacturer: _showingAllManufacturers ? null : _selectedManufacturer,
        limit: _pageSize,
        offset: _searchResults.length,
      );

      setState(() {
        _searchResults.addAll(result.filaments);
        _hasMore = result.hasMore;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load more results: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _selectedManufacturer = null;
      _searchResults = [];
      _searchQuery = '';
      _hasMore = false;
      _totalCount = 0;
      _showingAllManufacturers = false;
      _viewMode = 'manufacturers';
      _sortByBrightness = false;
      _selectedColorFilter = null;
    });
  }

  Color _getColorFromHex(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) {
      return Colors.grey;
    }
    try {
      // Remove # if present and ensure 6 characters
      String cleanHex = hexColor.replaceAll('#', '');
      if (cleanHex.length == 6) {
        return Color(int.parse('FF$cleanHex', radix: 16));
      }
      return Colors.grey;
    } catch (e) {
      return Colors.grey;
    }
  }

  String? _getColorFamily(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) return null;
    
    try {
      String cleanHex = hexColor.replaceAll('#', '');
      if (cleanHex.length != 6) return null;
      
      int r = int.parse(cleanHex.substring(0, 2), radix: 16);
      int g = int.parse(cleanHex.substring(2, 4), radix: 16);
      int b = int.parse(cleanHex.substring(4, 6), radix: 16);
      
      // Calculate max, min for saturation and value (brightness)
      int max = [r, g, b].reduce((a, b) => a > b ? a : b);
      int min = [r, g, b].reduce((a, b) => a < b ? a : b);
      int delta = max - min;
      
      // Check for grayscale (low saturation)
      double saturation = max == 0 ? 0 : delta / max;
      
      // Grayscale detection
      if (saturation < 0.2) {
        if (max > 220) return 'White';
        if (max < 60) return 'Black';
        return 'Gray';
      }
      
      // Brown detection (low brightness with balanced RGB)
      if (max < 140 && r > 50 && g > 30 && b > 20 && r > g && g >= b) {
        return 'Brown';
      }
      
      // Find dominant hue
      if (r >= g && r >= b) {
        // Red-ish colors
        if (g > b + 40 && g > 120) {
          return 'Yellow';
        } else if (g > b + 20 && r > 180) {
          return 'Orange';
        } else if (b > 100 && b > g - 30) {
          return 'Pink';
        } else {
          return 'Red';
        }
      } else if (g >= r && g >= b) {
        // Green-ish colors
        if (r > b + 40 && r > 120) {
          return 'Yellow';
        } else if (b > r + 40 && b > 120) {
          return 'Cyan';
        } else {
          return 'Green';
        }
      } else {
        // Blue-ish colors
        if (r > g + 30 && r > 100) {
          return 'Purple';
        } else if (g > r + 40 && g > 120) {
          return 'Cyan';
        } else {
          return 'Blue';
        }
      }
    } catch (e) {
      return null;
    }
  }

  String? _getColorFamilyForFilament(SpoolmanFilament filament) {
    // Check for gradient (multi-color)
    if (filament.colorHexes != null && filament.colorHexes!.length > 1) {
      return 'Gradient';
    }

    // Check name for special finishes
    String nameLower = filament.name.toLowerCase();
    if (nameLower.contains('silver') || nameLower.contains('metallic silver')) {
      return 'Silver';
    }
    if (nameLower.contains('gold') || nameLower.contains('metallic gold')) {
      return 'Gold';
    }
    if (nameLower.contains('skin') || nameLower.contains('flesh')) {
      return 'Skin';
    }

    // Use hex color for standard color families
    return _getColorFamily(filament.colorHex);
  }

  List<SpoolmanFilament> _getFilteredResults() {
    if (_selectedColorFilter == null || _selectedColorFilter == 'All') {
      return _searchResults;
    }
    
    return _searchResults.where((filament) {
      String? colorFamily = _getColorFamilyForFilament(filament);
      return colorFamily == _selectedColorFilter;
    }).toList();
  }

  Future<void> _applyColorFilter(String? filter) async {
    setState(() {
      _selectedColorFilter = filter;
    });

    // If a specific color is selected, load all results first
    if (filter != null && filter != 'All') {
      setState(() {
        _isLoading = true;
      });

      try {
        List<SpoolmanFilament> allResults = List.from(_searchResults);
        
        // Keep loading until we have all results
        while (_hasMore) {
          final result = await _spoolmanService.searchFilaments(
            query: (_searchQuery.isNotEmpty && !_showingAllManufacturers) ? _searchQuery : null,
            manufacturer: _showingAllManufacturers ? null : _selectedManufacturer,
            limit: _pageSize,
            offset: allResults.length,
          );
          
          allResults.addAll(result.filaments);
          
          if (!result.hasMore) {
            break;
          }
        }
        
        setState(() {
          _searchResults = allResults;
          _hasMore = false; // All results are loaded
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load all colors: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showColorFilterDialog() {
    final colors = [
      {'name': 'All'},
      {'name': 'Red', 'color': 0xFFE53935},
      {'name': 'Orange', 'color': 0xFFFF9800},
      {'name': 'Yellow', 'color': 0xFFFFEB3B},
      {'name': 'Green', 'color': 0xFF4CAF50},
      {'name': 'Cyan', 'color': 0xFF00BCD4},
      {'name': 'Blue', 'color': 0xFF2196F3},
      {'name': 'Purple', 'color': 0xFF9C27B0},
      {'name': 'Pink', 'color': 0xFFE91E63},
      {'name': 'Brown', 'color': 0xFF795548},
      {'name': 'White', 'color': 0xFFFFFFFF},
      {'name': 'Gray', 'color': 0xFF9E9E9E},
      {'name': 'Black', 'color': 0xFF212121},
      {'name': 'Silver', 'color': 0xFFC0C0C0},
      {'name': 'Gold', 'color': 0xFFFFD700},
      {'name': 'Skin', 'color': 0xFFFFDBAC},
      {'name': 'Gradient', 'isGradient': true},
    ];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Color Filter',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = constraints.maxWidth;
                    final crossAxisCount = screenWidth > 600 ? 4 : 3;
                    
                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 2.5,
                      ),
                      itemCount: colors.length,
                      itemBuilder: (context, index) {
                    final colorItem = colors[index];
                    final name = colorItem['name'] as String;
                    final isSelected = (_selectedColorFilter ?? 'All') == name;
                    
                    return InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _applyColorFilter(name == 'All' ? null : name);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue.shade50 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? Colors.blue : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (name != 'All')
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: colorItem['isGradient'] == true
                                      ? null
                                      : Color(colorItem['color'] as int),
                                  gradient: colorItem['isGradient'] == true
                                      ? const LinearGradient(
                                          colors: [Color(0xFFE53935), Color(0xFFFFEB3B), Color(0xFF2196F3)],
                                        )
                                      : null,
                                  borderRadius: BorderRadius.circular(4),
                                  border: name == 'White'
                                      ? Border.all(color: Colors.grey.shade400)
                                      : null,
                                ),
                              ),
                            if (name != 'All') const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
            ],
          ),
        ),
      ),
    );
  }

  double _getColorBrightness(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) {
      return 128; // Default mid-brightness for grey
    }
    try {
      String cleanHex = hexColor.replaceAll('#', '');
      if (cleanHex.length == 6) {
        int r = int.parse(cleanHex.substring(0, 2), radix: 16);
        int g = int.parse(cleanHex.substring(2, 4), radix: 16);
        int b = int.parse(cleanHex.substring(4, 6), radix: 16);
        // Calculate Euclidean distance from white (255, 255, 255)
        // Smaller distance = closer to white (lighter)
        double distanceFromWhite = ((255 - r) * (255 - r) + 
                                    (255 - g) * (255 - g) + 
                                    (255 - b) * (255 - b)).toDouble();
        return distanceFromWhite;
      }
      return 128;
    } catch (e) {
      return 128;
    }
  }

  void _toggleSortByBrightness() async {
    setState(() {
      _sortByBrightness = !_sortByBrightness;
    });
    
    if (_sortByBrightness) {
      // Load all results before sorting
      setState(() {
        _isLoading = true;
      });
      
      try {
        List<SpoolmanFilament> allResults = List.from(_searchResults);
        
        // Keep loading until we have all results
        while (_hasMore) {
          final result = await _spoolmanService.searchFilaments(
            query: (_searchQuery.isNotEmpty && !_showingAllManufacturers) ? _searchQuery : null,
            manufacturer: _showingAllManufacturers ? null : _selectedManufacturer,
            limit: _pageSize,
            offset: allResults.length,
          );
          
          allResults.addAll(result.filaments);
          
          if (!result.hasMore) {
            break;
          }
        }
        
        // Sort all results by brightness
        allResults.sort((a, b) {
          double distanceA = _getColorBrightness(a.colorHex);
          double distanceB = _getColorBrightness(b.colorHex);
          return distanceA.compareTo(distanceB);
        });
        
        setState(() {
          _searchResults = allResults;
          _hasMore = false; // All results are loaded
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load all results: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildColorIndicator(SpoolmanFilament filament) {
    if (filament.colorHexes != null && filament.colorHexes!.isNotEmpty) {
      // Multi-color filament
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: filament.colorHexes!
                .map((hex) => _getColorFromHex(hex))
                .toList(),
          ),
        ),
      );
    } else if (filament.colorHex != null) {
      // Single color filament
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: _getColorFromHex(filament.colorHex),
          border: Border.all(color: Colors.grey.shade300),
        ),
      );
    } else {
      // No color info
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade300,
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: const Icon(
          Icons.help_outline,
          color: Colors.grey,
          size: 20,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Search filaments by brand or name...',
                    prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.secondary),
                    suffixIcon: _searchQuery.isNotEmpty || _selectedManufacturer != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _clearSearch,
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ],
            ),
          ),
          // Results or Manufacturer Selection
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : (_selectedManufacturer == null && _searchQuery.isEmpty && !_showingAllManufacturers && _viewMode == 'manufacturers')
                    ? // Show manufacturer list when no search or manufacturer selected
                      Column(
                        children: [
                          // Manufacturer list header
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Dropdown button
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: DropdownButton<String>(
                                    value: _viewMode,
                                    underline: const SizedBox(),
                                    icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade700, size: 20),
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    onChanged: (String? newValue) {
                                      if (newValue != null) {
                                        setState(() {
                                          _viewMode = newValue;
                                          if (newValue == 'colors') {
                                            _selectedManufacturer = null;
                                            _performSearch(reset: true, showAll: true);
                                          }
                                        });
                                      }
                                    },
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'manufacturers',
                                        child: Text('Manufacturers'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'colors',
                                        child: Text('All Colors'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Manufacturer grid
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final screenWidth = constraints.maxWidth;
                                final crossAxisCount = screenWidth > 900 ? 4 : (screenWidth > 600 ? 3 : 2);
                                
                                return GridView.builder(
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    childAspectRatio: 1.5,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                                  itemCount: _manufacturers.length,
                                  padding: const EdgeInsets.all(16),
                                  itemBuilder: (context, index) {
                                final manufacturer = _manufacturers[index];
                                final filamentCount = _manufacturerCounts[manufacturer] ?? 0;
                                
                                return Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: Colors.grey.shade200, width: 1),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedManufacturer = manufacturer;
                                        _showingAllManufacturers = false;
                                      });
                                      _performSearch(reset: true);
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            manufacturer,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '$filamentCount filament${filamentCount != 1 ? 's' : ''}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Theme.of(context).colorScheme.secondary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          }),
                        ),
                        ],
                      )
                    : _searchResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty && _selectedManufacturer == null && !_showingAllManufacturers
                                  ? 'Start typing to search filaments'
                                  : 'No filaments found',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                            ),
                            if (_searchQuery.isNotEmpty || _selectedManufacturer != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Try different search terms or filters',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey.shade500,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      )
                        : Column(
                        children: [
                          // Results count header with dropdown
                          if (_searchResults.isNotEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                border: Border(
                                  bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Dropdowns row - make it scrollable
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        // View mode dropdown
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey.shade300),
                                          ),
                                          child: DropdownButton<String>(
                                            value: _viewMode,
                                            underline: const SizedBox(),
                                            icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade700, size: 20),
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            onChanged: (String? newValue) {
                                              if (newValue != null) {
                                                setState(() {
                                                  _viewMode = newValue;
                                                  if (newValue == 'manufacturers') {
                                                    // Reset to manufacturer view
                                                    _selectedManufacturer = null;
                                                    _searchResults = [];
                                                    _showingAllManufacturers = false;
                                                    _sortByBrightness = false;
                                                  } else if (newValue == 'colors') {
                                                    _selectedManufacturer = null;
                                                    _performSearch(reset: true, showAll: true);
                                                  }
                                                });
                                              }
                                            },
                                            items: const [
                                              DropdownMenuItem(
                                                value: 'manufacturers',
                                                child: Text('Manufacturers'),
                                              ),
                                              DropdownMenuItem(
                                                value: 'colors',
                                                child: Text('All Colors'),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Show selected manufacturer
                                        if (_selectedManufacturer != null && !_showingAllManufacturers)
                                          Container(
                                            constraints: const BoxConstraints(maxWidth: 200),
                                            child: Text(
                                              _selectedManufacturer!,
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.secondary,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      // Color filter button (only show when viewing all colors)
                                      if (_showingAllManufacturers)
                                        InkWell(
                                          onTap: _showColorFilterDialog,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.grey.shade300),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  _selectedColorFilter ?? 'All Colors',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade700,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Icon(Icons.arrow_drop_down, color: Colors.grey.shade700, size: 20),
                                              ],
                                            ),
                                          ),
                                        ),
                                      // Reset filter button (only show when a filter or sort is active)
                                      if (_showingAllManufacturers && (_selectedColorFilter != null || _sortByBrightness))
                                        Padding(
                                          padding: const EdgeInsets.only(left: 8),
                                          child: Material(
                                            color: Colors.red.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                            child: InkWell(
                                              onTap: () {
                                                setState(() {
                                                  _selectedColorFilter = null;
                                                  _sortByBrightness = false;
                                                  _viewMode = 'manufacturers';
                                                  _selectedManufacturer = null;
                                                  _searchResults = [];
                                                  _showingAllManufacturers = false;
                                                });
                                              },
                                              borderRadius: BorderRadius.circular(8),
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.clear,
                                                      size: 16,
                                                      color: Colors.red.shade700,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Reset',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w600,
                                                        color: Colors.red.shade700,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      const SizedBox(width: 12),
                                      // Card/Color view toggle button
                                      Material(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              _showCardView = !_showCardView;
                                            });
                                          },
                                          borderRadius: BorderRadius.circular(8),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  _showCardView ? Icons.view_list : Icons.grid_view,
                                                  size: 18,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Sort button
                                      Material(
                                        color: _sortByBrightness 
                                            ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                        child: InkWell(
                                          onTap: _toggleSortByBrightness,
                                          borderRadius: BorderRadius.circular(8),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  _sortByBrightness ? Icons.sort : Icons.sort_outlined,
                                                  size: 18,
                                                  color: _sortByBrightness 
                                                      ? Theme.of(context).colorScheme.secondary
                                                      : Colors.grey.shade600,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Sort',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: _sortByBrightness ? FontWeight.w600 : FontWeight.normal,
                                                    color: _sortByBrightness 
                                                        ? Theme.of(context).colorScheme.secondary
                                                        : Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  ),
                                ],
                              ),
                            ),
                          // Results list
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final screenWidth = constraints.maxWidth;
                                // Adjust columns based on view mode
                                final crossAxisCount = _showCardView 
                                    ? (screenWidth > 900 ? 4 : (screenWidth > 600 ? 3 : 2))
                                    : (screenWidth > 900 ? 6 : (screenWidth > 600 ? 5 : 4));
                                final childAspectRatio = _showCardView ? 1.05 : 1.0;
                                final spacing = _showCardView ? 12.0 : 4.0;
                                
                                return GridView.builder(
                                  controller: _scrollController,
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    childAspectRatio: childAspectRatio,
                                    crossAxisSpacing: spacing,
                                    mainAxisSpacing: spacing,
                                  ),
                                  itemCount: _getFilteredResults().length + (_hasMore && _selectedColorFilter == null ? 1 : 0),
                                  padding: EdgeInsets.all(_showCardView ? 16 : 8),
                                  itemBuilder: (context, index) {
                                final filteredResults = _getFilteredResults();
                                if (index >= filteredResults.length) {
                                  // Loading indicator at the bottom
                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    child: Center(
                                      child: _isLoadingMore
                                          ? const CircularProgressIndicator()
                                          : const SizedBox.shrink(),
                                    ),
                                  );
                                }
                          final filament = filteredResults[index];
                          return InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => FilamentDetail(
                                    filament: filament,
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: _showCardView 
                                ? _buildFilamentCard(filament)
                                : Padding(
                                    padding: const EdgeInsets.all(2),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        // Color indicator only
                                        _buildColorIndicator(filament),
                                      ],
                                    ),
                                  ),
                          );
                        },
                      );
                    }),
                  ),
                  ],
                ),
              ),
            ],
          ),
        );
  }
  
  Widget _buildFilamentCard(SpoolmanFilament filament) {
    Color cardColor = Colors.grey;
    try {
      if (filament.colorHex != null && filament.colorHex!.isNotEmpty) {
        String hexColor = filament.colorHex!.replaceFirst('#', '');
        if (hexColor.length == 6) {
          cardColor = Color(int.parse('FF$hexColor', radix: 16));
        }
      }
    } catch (e) {
      cardColor = Colors.grey;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Color header
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                ),
              ),
          // Info section
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Brand and material
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        filament.manufacturer ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${filament.material ?? 'N/A'}, ${filament.name ?? ''}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  // Specs rows
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (filament.diameter != null) ...[
                            Icon(Icons.straighten, size: 10, color: Colors.grey[600]),
                            const SizedBox(width: 2),
                            Text(
                              '${filament.diameter}mm',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (filament.weight != null) ...[
                            Icon(Icons.scale, size: 10, color: Colors.grey[600]),
                            const SizedBox(width: 2),
                            Text(
                              '${filament.weight}g',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      // Temperature row
                      Row(
                        children: [
                          if (filament.extruderTemp != null) ...[
                            Icon(Icons.thermostat, size: 10, color: Colors.grey[600]),
                            const SizedBox(width: 2),
                            Text(
                              '${filament.extruderTemp}°C',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (filament.bedTemp != null) ...[
                            Icon(Icons.layers, size: 10, color: Colors.grey[600]),
                            const SizedBox(width: 2),
                            Text(
                              '${filament.bedTemp}°C',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          ],
        ),
        // Plus icon button in bottom right corner
        Positioned(
          bottom: 4,
          right: 4,
          child: FutureBuilder<bool>(
            future: _filamentService.isSpoolmanFilamentSaved(filament.id.toString()),
            builder: (context, snapshot) {
              final isSaved = snapshot.data ?? false;
              return Material(
                color: isSaved ? Colors.green : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: isSaved ? null : () => _saveFilamentToLibrary(filament),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.add,
                      size: 18,
                      color: isSaved ? Colors.white : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
    );
  }

  Future<void> _saveFilamentToLibrary(SpoolmanFilament filament) async {
    // Check if already saved
    final isSaved = await _filamentService.isSpoolmanFilamentSaved(filament.id.toString());
    if (isSaved) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Filament already in your library!'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    try {
      await _filamentService.saveSpoolmanFilament(
        spoolmanId: filament.id.toString(),
        displayName: filament.displayName,
        manufacturer: filament.manufacturer,
        productName: filament.name,
        material: filament.material,
        diameter: filament.diameter,
        weight: filament.weight,
        density: filament.density,
        spoolWeight: filament.spoolWeight,
        spoolType: filament.spoolType,
        colorHex: filament.colorHex,
        colorHexes: filament.colorHexes,
        extruderTemp: filament.extruderTemp,
        extruderTempRange: filament.extruderTempRange,
        bedTemp: filament.bedTemp,
        bedTempRange: filament.bedTempRange,
        finish: filament.finish,
        pattern: filament.pattern,
        isTranslucent: filament.translucent,
        isGlowInDark: filament.glow,
        quantity: 1,
        notes: 'Saved from Spoolman search',
      );

      if (mounted) {
        setState(() {}); // Refresh to update the icon color
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Filament saved to your library!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save filament: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}