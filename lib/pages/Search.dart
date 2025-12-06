import 'package:flutter/material.dart';
import '../services/spoolman_service.dart';
import 'FilamentDetail.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final SpoolmanService _spoolmanService = SpoolmanService();
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
      final result = await _spoolmanService.searchFilaments(
        query: (_searchQuery.isNotEmpty && !showAll) ? _searchQuery : null,
        manufacturer: showAll ? null : _selectedManufacturer,
        limit: _pageSize,
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
                // Show selected manufacturer or search status
                if (_selectedManufacturer != null || _searchQuery.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        if (_selectedManufacturer != null) ...[
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.primaries[(_selectedManufacturer?.hashCode ?? 0) % Colors.primaries.length].withValues(alpha: 0.2),
                            ),
                            child: Center(
                              child: Text(
                                _selectedManufacturer![0].toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.primaries[(_selectedManufacturer?.hashCode ?? 0) % Colors.primaries.length],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Showing: $_selectedManufacturer',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                        if (_searchQuery.isNotEmpty && _selectedManufacturer != null)
                          const Text(' • '),
                        if (_searchQuery.isNotEmpty)
                          Expanded(
                            child: Text(
                              'Search: "$_searchQuery"',
                              style: const TextStyle(fontStyle: FontStyle.italic),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: _clearSearch,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ],
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
                            child: GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
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
                            ),
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
                                  // Dropdowns row
                                  Row(
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
                                      // Color filter dropdown (only show when viewing all colors)
                                      if (_showingAllManufacturers)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey.shade300),
                                          ),
                                          child: DropdownButton<String>(
                                            value: _selectedColorFilter ?? 'All',
                                            underline: const SizedBox(),
                                            icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade700, size: 20),
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            onChanged: (String? newValue) {
                                              _applyColorFilter(newValue == 'All' ? null : newValue);
                                            },
                                            items: [
                                              const DropdownMenuItem(value: 'All', child: Text('All Colors')),
                                              DropdownMenuItem(
                                                value: 'Red',
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 20,
                                                      height: 20,
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFE53935),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    const Text('Red'),
                                                  ],
                                                ),
                                              ),
                                              DropdownMenuItem(
                                                value: 'Orange',
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 20,
                                                      height: 20,
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFFF9800),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    const Text('Orange'),
                                                  ],
                                                ),
                                              ),
                                              DropdownMenuItem(
                                                value: 'Yellow',
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 20,
                                                      height: 20,
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFFFEB3B),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    const Text('Yellow'),
                                                  ],
                                                ),
                                              ),
                                              DropdownMenuItem(
                                                value: 'Green',
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 20,
                                                      height: 20,
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFF4CAF50),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    const Text('Green'),
                                                  ],
                                                ),
                                              ),
                                              DropdownMenuItem(
                                                value: 'Cyan',
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 20,
                                                      height: 20,
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFF00BCD4),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    const Text('Cyan'),
                                                  ],
                                                ),
                                              ),
                                              DropdownMenuItem(
                                                value: 'Blue',
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 20,
                                                      height: 20,
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFF2196F3),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    const Text('Blue'),
                                                  ],
                                                ),
                                              ),
                                              DropdownMenuItem(
                                                value: 'Purple',
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 20,
                                                      height: 20,
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFF9C27B0),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    const Text('Purple'),
                                                  ],
                                                ),
                                              ),
                                              DropdownMenuItem(
                                                value: 'Pink',
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 20,
                                                      height: 20,
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFE91E63),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    const Text('Pink'),
                                                  ],
                                                ),
                                              ),
                                              DropdownMenuItem(
                                                value: 'Brown',
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 20,
                                                      height: 20,
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFF795548),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    const Text('Brown'),
                                                  ],
                                                ),
                                              ),
                                              DropdownMenuItem(
                                                value: 'White',
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 20,
                                                      height: 20,
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFFFFFFF),
                                                        borderRadius: BorderRadius.circular(4),
                                                        border: Border.all(color: Colors.grey.shade400),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    const Text('White'),
                                                  ],
                                                ),
                                              ),
                                              DropdownMenuItem(
                                                value: 'Gray',
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 20,
                                                      height: 20,
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFF9E9E9E),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    const Text('Gray'),
                                                  ],
                                                ),
                                              ),
                                              DropdownMenuItem(
                                                value: 'Black',
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 20,
                                                      height: 20,
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFF212121),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    const Text('Black'),
                                                  ],
                                                ),
                                              ),
                                              DropdownMenuItem(
                                                value: 'Silver',
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 20,
                                                      height: 20,
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFC0C0C0),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    const Text('Silver'),
                                                  ],
                                                ),
                                              ),
                                              DropdownMenuItem(
                                                value: 'Gold',
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 20,
                                                      height: 20,
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFFFD700),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    const Text('Gold'),
                                                  ],
                                                ),
                                              ),
                                              DropdownMenuItem(
                                                value: 'Skin',
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 20,
                                                      height: 20,
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFFFDBAC),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    const Text('Skin'),
                                                  ],
                                                ),
                                              ),
                                              DropdownMenuItem(
                                                value: 'Gradient',
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 20,
                                                      height: 20,
                                                      decoration: BoxDecoration(
                                                        gradient: const LinearGradient(
                                                          colors: [
                                                            Color(0xFFE53935),
                                                            Color(0xFFFFEB3B),
                                                            Color(0xFF2196F3),
                                                          ],
                                                        ),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    const Text('Gradient'),
                                                  ],
                                                ),
                                              ),
                                            ],
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
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Sort button row
                                  Row(
                                    children: [
                                      const Spacer(),
                                      // Sort button
                                      Material(
                                        color: _sortByBrightness 
                                            ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                        child: InkWell(
                                          onTap: _toggleSortByBrightness,
                                          borderRadius: BorderRadius.circular(8),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                                ],
                              ),
                            ),
                          // Results list
                          Expanded(
                            child: GridView.builder(
                              controller: _scrollController,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                childAspectRatio: 1.0,
                                crossAxisSpacing: 4,
                                mainAxisSpacing: 4,
                              ),
                              itemCount: _getFilteredResults().length + (_hasMore && _selectedColorFilter == null ? 1 : 0),
                              padding: const EdgeInsets.all(8),
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
                            child: Padding(
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
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
  }
}