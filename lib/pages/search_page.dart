import 'package:flutter/material.dart';
import '../services/spoolman_service.dart';
import 'filament_detail_page.dart';

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

  Future<void> _performSearch({bool reset = false}) async {
    if (_searchQuery.isEmpty && _selectedManufacturer == null) {
      setState(() {
        _searchResults = [];
        _hasMore = false;
        _totalCount = 0;
        _isLoading = false;
      });
      return;
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
        query: _searchQuery.isNotEmpty ? _searchQuery : null,
        manufacturer: _selectedManufacturer,
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
        query: _searchQuery.isNotEmpty ? _searchQuery : null,
        manufacturer: _selectedManufacturer,
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
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
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
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _getColorFromHex(filament.colorHex),
          border: Border.all(color: Colors.grey.shade300),
        ),
      );
    } else {
      // No color info
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
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
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty || _selectedManufacturer != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _clearSearch,
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                ),
                const SizedBox(height: 12),
                // Manufacturer Filter
                Container(
                  width: double.infinity,
                  child: _isLoadingManufacturers
                      ? const Center(
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : DropdownButtonFormField<String>(
                          initialValue: _selectedManufacturer,
                          hint: const Text('Filter by manufacturer'),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface,
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('All Manufacturers'),
                            ),
                            ..._manufacturers.map((manufacturer) {
                              return DropdownMenuItem<String>(
                                value: manufacturer,
                                child: Text(manufacturer),
                              );
                            }),
                          ],
                          onChanged: (String? value) {
                            setState(() {
                              _selectedManufacturer = value;
                            });
                            _performSearch(reset: true);
                          },
                        ),
                ),
              ],
            ),
          ),
          // Results
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
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
                              _searchQuery.isEmpty && _selectedManufacturer == null
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
                            SizedBox(
                              width: double.infinity,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Text(
                                'Showing ${_searchResults.length}${_hasMore ? '+' : ''} of $_totalCount results',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          // Results list
                          Expanded(
                            child: ListView.builder(
                              controller: _scrollController,
                              itemCount: _searchResults.length + (_hasMore ? 1 : 0),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: _buildColorIndicator(filament),
                              title: Text(
                                filament.displayName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${filament.material} • ${filament.diameter}mm',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (filament.extruderTemp != null || filament.bedTemp != null)
                                    Text(
                                      'Extruder: ${filament.extruderTemp ?? '?'}°C • Bed: ${filament.bedTemp ?? '?'}°C',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${filament.weight.toInt()}g',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  if (filament.translucent || filament.glow) ...[
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (filament.translucent)
                                          Icon(
                                            Icons.visibility,
                                            size: 16,
                                            color: Colors.blue.shade400,
                                          ),
                                        if (filament.glow)
                                          Icon(
                                            Icons.flash_on,
                                            size: 16,
                                            color: Colors.green.shade400,
                                          ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => FilamentDetailPage(
                                      filament: filament,
                                    ),
                                  ),
                                );
                              },
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