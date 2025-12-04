import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SpoolmanSearchWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onFilamentSelected;

  const SpoolmanSearchWidget({
    super.key,
    required this.onFilamentSelected,
  });

  @override
  State<SpoolmanSearchWidget> createState() => _SpoolmanSearchWidgetState();
}

class _SpoolmanSearchWidgetState extends State<SpoolmanSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _filaments = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  // Configure this URL to point to your Spoolman instance
  // Common URLs:
  // - Local: http://localhost:7912/api/v1
  // - Network: http://YOUR_IP:7912/api/v1  
  // - Docker: http://spoolman:7912/api/v1
  static const String _baseUrl = 'http://localhost:7912/api/v1';
  
  // Remove /api/v1 for display purposes
  static String get baseUrl => _baseUrl.replaceAll('/api/v1', '');

  @override
  void initState() {
    super.initState();
    // Don't load filaments automatically on init
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchFilaments() async {
    final searchTerm = _searchController.text.trim();
    
    if (searchTerm.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a search term';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _filaments = [];
    });

    try {
      String url = '$_baseUrl/filament?name=$searchTerm';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout - Spoolman server may not be running');
        },
      );

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        List<dynamic> data;
        
        // Handle both array and object responses
        if (responseData is List) {
          data = responseData;
        } else if (responseData is Map && responseData.containsKey('data')) {
          data = responseData['data'] as List<dynamic>;
        } else {
          data = [];
        }
        
        setState(() {
          _filaments = data;
          _isLoading = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _errorMessage = 'Spoolman API not found. Make sure the server is running on $baseUrl';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load filaments (${response.statusCode}): ${response.reasonPhrase}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        if (e.toString().contains('timeout')) {
          _errorMessage = 'Connection timeout - Is Spoolman running on $_baseUrl?';
        } else if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
          _errorMessage = 'Cannot connect to Spoolman server.\n\nPlease check:\n• Server is running on $_baseUrl\n• Network connection is available';
        } else {
          _errorMessage = 'Error: $e';
        }
        _isLoading = false;
      });
    }
  }



  String _getFilamentDisplayName(Map<String, dynamic> filament) {
    final name = filament['name'] ?? 'Unknown';
    final vendor = filament['vendor'];
    final vendorName = vendor != null ? vendor['name'] : null;
    
    if (vendorName != null) {
      return '$vendorName - $name';
    }
    return name;
  }

  String _getFilamentSubtitle(Map<String, dynamic> filament) {
    final material = filament['material'] ?? '';
    final diameter = filament['diameter'] ?? '';
    final weight = filament['weight'] ?? '';
    
    List<String> parts = [];
    if (material.isNotEmpty) parts.add(material);
    if (diameter != '') parts.add('${diameter}mm');
    if (weight != '') parts.add('${weight}g');
    
    return parts.join(' • ');
  }

  Color _getFilamentColor(Map<String, dynamic> filament) {
    final colorHex = filament['color_hex'] as String?;
    if (colorHex != null && colorHex.isNotEmpty) {
      try {
        // Remove # if present and convert to Color
        String cleanHex = colorHex.replaceAll('#', '');
        if (cleanHex.length == 6) {
          return Color(int.parse('FF$cleanHex', radix: 16));
        }
      } catch (e) {
        // Fallback to default color if parsing fails
      }
    }
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Import from Spoolman',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Search for filaments in the Spoolman database',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Search Field
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search filaments...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _searchFilaments(),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isLoading ? null : _searchFilaments,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isLoading ? Colors.grey : Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                child: _isLoading 
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('Searching...'),
                        ],
                      )
                    : const Text('Search'),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Results
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Searching filaments...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _searchFilaments,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    const Text(
                      '💡 Troubleshooting Tips:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Make sure Spoolman is installed and running',
                      style: TextStyle(fontSize: 14),
                    ),
                    Text(
                      '2. Server should be accessible at: $baseUrl',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const Text(
                      '3. Check your network connection',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_filaments.isEmpty && _searchController.text.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Enter a search term to find filaments',
              style: TextStyle(color: Colors.grey, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'e.g., "PLA", "Hatchbox", "Black"',
              style: TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_filaments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No filaments found',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filaments.length,
      itemBuilder: (context, index) {
        final filament = _filaments[index] as Map<String, dynamic>;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getFilamentColor(filament),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
            ),
            title: Text(_getFilamentDisplayName(filament)),
            subtitle: Text(_getFilamentSubtitle(filament)),
            trailing: const Icon(Icons.add),
            onTap: () {
              widget.onFilamentSelected(filament);
              Navigator.of(context).pop();
            },
          ),
        );
      },
    );
  }
}

class SpoolmanSearchUtils {
  static void showSpoolmanSearch({
    required BuildContext context,
    required Function(Map<String, dynamic>) onFilamentSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SpoolmanSearchWidget(
        onFilamentSelected: onFilamentSelected,
      ),
    );
  }
}