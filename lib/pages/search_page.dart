import 'package:flutter/material.dart';
import '../widgets/bambu_lab_integration_widget.dart';
import '../widgets/bambu_filament_search_widget.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  @override
  void dispose() {
    super.dispose();
  }

  void _showFilamentDetailsDialog(Map<String, dynamic> filament) {
    final color = _getColorFromHex(filament['color_hex'] ?? '#808080');
    final isInStock = filament['in_stock'] ?? false;
    final isAmsCompatible = filament['ams_compatible'] ?? false;
    final temperature = filament['temperature'] ?? {};
    final properties = filament['properties'] ?? {};

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        titlePadding: EdgeInsets.zero,
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        title: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      filament['name'] ?? 'Unknown',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${filament['brand']} • ${filament['material']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isInStock)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Out of Stock',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Description
              if (filament['description'] != null) ...[
                Text(
                  filament['description'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Specifications
              const Text(
                'Specifications',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildSpecRow('Diameter', '${filament['diameter']}mm'),
              _buildSpecRow('Weight', '${filament['weight']}g'),
              _buildSpecRow('Color', filament['color'] ?? 'Unknown'),
              if (temperature['nozzle'] != null)
                _buildSpecRow('Nozzle Temp', '${temperature['nozzle']}°C'),
              if (temperature['bed'] != null)
                _buildSpecRow('Bed Temp', '${temperature['bed']}°C'),
              
              const SizedBox(height: 16),

              // Properties
              if (properties.isNotEmpty) ...[
                const Text(
                  'Properties',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (properties['strength'] != null)
                  _buildSpecRow('Strength', properties['strength']),
                if (properties['flexibility'] != null)
                  _buildSpecRow('Flexibility', properties['flexibility']),
                if (properties['ease_of_use'] != null)
                  _buildSpecRow('Ease of Use', properties['ease_of_use']),
                const SizedBox(height: 16),
              ],

              // Features
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (isAmsCompatible)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, 
                               size: 16, 
                               color: Colors.green.shade700),
                          const SizedBox(width: 4),
                          Text(
                            'AMS Compatible',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (properties['supports_required'] == false)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.support, 
                               size: 16, 
                               color: Colors.blue.shade700),
                          const SizedBox(width: 4),
                          Text(
                            'No Supports',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Price
              Row(
                children: [
                  const Text(
                    'Price: ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '\$${filament['price']?.toStringAsFixed(2) ?? '0.00'}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: isInStock ? () {
              Navigator.pop(context);
              _addFilamentToInventory(filament);
            } : null,
            icon: const Icon(Icons.add_shopping_cart),
            label: Text(isInStock ? 'Add to Inventory' : 'Out of Stock'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isInStock ? Colors.orange : Colors.grey,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorFromHex(String hexColor) {
    try {
      String cleanHex = hexColor.replaceAll('#', '');
      if (cleanHex.length == 6) {
        return Color(int.parse('FF$cleanHex', radix: 16));
      }
    } catch (e) {
      // Fallback color
    }
    return Colors.grey;
  }

  void _addFilamentToInventory(Map<String, dynamic> filament) {
    // Here you would typically save to your database or local storage
    // For now, we'll just show a success message
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text('${filament['name']} added to inventory!'),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            // TODO: Navigate to inventory or filament details
          },
        ),
      ),
    );

    // Optional: Show additional confirmation dialog for purchase
    if (filament['price'] != null) {
      Future.delayed(const Duration(seconds: 1), () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Purchase Confirmation'),
            content: Text(
              'Would you like to purchase ${filament['name']} for \$${filament['price']?.toStringAsFixed(2)}?'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Later'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Redirecting to Bambu Lab store...'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Buy Now'),
              ),
            ],
          ),
        );
      });
    }
  }

  void _showFilamentCalculatorDialog() {
    final TextEditingController lengthController = TextEditingController();
    final TextEditingController diameterController = TextEditingController(text: '1.75');
    final TextEditingController densityController = TextEditingController(text: '1.24');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filament Calculator'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Calculate filament weight and cost for your prints',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: lengthController,
                decoration: const InputDecoration(
                  labelText: 'Print Length (mm)',
                  border: OutlineInputBorder(),
                  helperText: 'Estimated from slicer',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: diameterController,
                decoration: const InputDecoration(
                  labelText: 'Filament Diameter (mm)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: densityController,
                decoration: const InputDecoration(
                  labelText: 'Filament Density (g/cm³)',
                  border: OutlineInputBorder(),
                  helperText: 'PLA: 1.24, PETG: 1.27, ABS: 1.04',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement calculation logic
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Calculator feature coming soon!'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text('Calculate'),
          ),
        ],
      ),
    );
  }

  void _showFilamentGuideDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filament Guide'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGuideSection('PLA', Colors.green.shade600, [
                'Easy to print, low temperature',
                'Best for beginners',
                'Nozzle: 200-220°C, Bed: 20-60°C',
                'Good for decorative prints'
              ]),
              const SizedBox(height: 16),
              _buildGuideSection('PETG', Colors.blue.shade600, [
                'Strong and chemical resistant',
                'Crystal clear when printed well',
                'Nozzle: 230-250°C, Bed: 70-90°C',
                'Great for functional parts'
              ]),
              const SizedBox(height: 16),
              _buildGuideSection('ABS', Colors.red.shade600, [
                'Very strong, heat resistant',
                'Requires heated bed',
                'Nozzle: 250-270°C, Bed: 90-110°C',
                'Prone to warping'
              ]),
              const SizedBox(height: 16),
              _buildGuideSection('TPU', Colors.purple.shade600, [
                'Flexible, rubber-like',
                'Slow printing required',
                'Nozzle: 220-250°C, Bed: 20-50°C',
                'Perfect for phone cases'
              ]),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideSection(String material, Color color, List<String> points) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            material,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          ...points.map((point) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 4,
                  margin: const EdgeInsets.only(top: 6, right: 8),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: Text(
                    point,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Center(
            child: Column(
              children: [
                Icon(Icons.polymer, size: 80, color: Colors.orange),
                SizedBox(height: 16),
                Text(
                  'Filament Search',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Discover Bambu Lab filaments for your projects',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Bambu Lab Filament Search
          const Text(
            'Bambu Lab Filaments',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          BambuFilamentSearchWidget(
            onFilamentSelected: (filament) {
              _showFilamentDetailsDialog(filament);
            },
          ),
          
          const SizedBox(height: 32),
          
          // Printer Integration Section
          const Text(
            'Send to Printer',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Bambu Lab Integration Widget
          const BambuLabIntegrationWidget(),
          
          const SizedBox(height: 32),
          
          // Quick Actions Section
          const Text(
            'Filament Management',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: Card(
                  child: InkWell(
                    onTap: () {
                      // Navigate to inventory page
                      Navigator.of(context).pushNamed('/inventory');
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.inventory_2, size: 32, color: Colors.blue),
                          SizedBox(height: 8),
                          Text(
                            'My Inventory',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'View your filaments',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  child: InkWell(
                    onTap: () {
                      // Show filament calculator or tips
                      _showFilamentCalculatorDialog();
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.calculate, size: 32, color: Colors.green),
                          SizedBox(height: 8),
                          Text(
                            'Calculator',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Usage & costs',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Additional filament resources
          Card(
            child: ListTile(
              leading: const Icon(Icons.library_books, color: Colors.purple),
              title: const Text('Filament Guide'),
              subtitle: const Text('Material properties and print settings'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                _showFilamentGuideDialog();
              },
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.store, color: Colors.orange),
              title: const Text('Bambu Lab Store'),
              subtitle: const Text('Browse and purchase filaments'),
              trailing: const Icon(Icons.launch, size: 16),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Opening Bambu Lab store...'),
                    backgroundColor: Colors.orange,
                  ),
                );
                // TODO: Launch URL to Bambu Lab store
              },
            ),
          ),
        ],
      ),
    );
  }
}