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
  String? _selectedManufacturer;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isLoadingManufacturers = false;
  bool _hasMore = false;
  int _totalCount = 0;
  String _searchQuery = '';
  bool _showingAllManufacturers = false;
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
      setState(() {
        _manufacturers = manufacturers;
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
                if (_selectedManufacturer != null || _searchQuery.isNotEmpty || _showingAllManufacturers) ...[
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
                        if (_showingAllManufacturers && _selectedManufacturer == null && _searchQuery.isEmpty) ...[
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
                            ),
                            child: Icon(
                              Icons.apps,
                              size: 14,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Showing: All Manufacturers',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
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
                : _selectedManufacturer == null && _searchQuery.isEmpty && !_showingAllManufacturers
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
                            child: Text(
                              'Select a Manufacturer (${_manufacturers.length} available)',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
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
                              itemCount: _manufacturers.length + 1, // +1 for "All" option
                              padding: const EdgeInsets.all(16),
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  // "All" option
                                  return Card(
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2),
                                    ),
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _selectedManufacturer = null;
                                        });
                                        _performSearch(reset: true, showAll: true);
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: 50,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                                              ),
                                              child: Icon(
                                                Icons.apps,
                                                color: Theme.of(context).colorScheme.secondary,
                                                size: 28,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            const Text(
                                              'All Manufacturers',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                
                                final manufacturer = _manufacturers[index - 1];
                                final firstLetter = manufacturer.isNotEmpty ? manufacturer[0].toUpperCase() : '?';
                                final colorIndex = manufacturer.hashCode % Colors.primaries.length;
                                final manufacturerColor = Colors.primaries[colorIndex.abs()];
                                
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
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: manufacturerColor.withValues(alpha: 0.1),
                                              border: Border.all(color: manufacturerColor, width: 2),
                                            ),
                                            child: Center(
                                              child: Text(
                                                firstLetter,
                                                style: TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                  color: manufacturerColor,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            manufacturer,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
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
                          // Results count header
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
                              child: Text(
                                'Showing ${_searchResults.length}${_hasMore ? '+' : ''} of $_totalCount results',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
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
                              itemCount: _searchResults.length + (_hasMore ? 1 : 0),
                              padding: const EdgeInsets.all(8),
                              itemBuilder: (context, index) {
                                if (index >= _searchResults.length) {
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
                          final filament = _searchResults[index];
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