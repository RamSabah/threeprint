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
  
  List<SpoolmanFilament> _searchResults = [];
  List<String> _manufacturers = [];
  String? _selectedManufacturer;
  bool _isLoading = false;
  bool _isLoadingManufacturers = false;
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _loadManufacturers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    if (query != _searchQuery) {
      setState(() {
        _searchQuery = query;
      });
      _performSearch();
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

  Future<void> _performSearch() async {
    if (_searchQuery.isEmpty && _selectedManufacturer == null) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _spoolmanService.searchFilaments(
        query: _searchQuery.isNotEmpty ? _searchQuery : null,
        manufacturer: _selectedManufacturer,
        limit: 100,
      );

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _searchResults = [];
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

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _selectedManufacturer = null;
      _searchResults = [];
      _searchQuery = '';
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
                  color: Colors.black.withOpacity(0.1),
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
                    fillColor: Theme.of(context).colorScheme.background,
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
                          value: _selectedManufacturer,
                          hint: const Text('Filter by manufacturer'),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.background,
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
                            _performSearch();
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
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
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
    );
  }
}