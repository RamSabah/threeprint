import 'package:flutter/material.dart';

class AddFilamentPage extends StatefulWidget {
  const AddFilamentPage({super.key});

  @override
  State<AddFilamentPage> createState() => _AddFilamentPageState();
}

class _AddFilamentPageState extends State<AddFilamentPage> {
  final _formKey = GlobalKey<FormState>();
  final _countController = TextEditingController();
  
  String? _selectedFilamentType;
  String? _selectedColor;
  
  final List<String> _filamentTypes = ['PETG', 'PLA', 'Other'];
  final List<String> _colors = [
    'Red',
    'Blue', 
    'Green',
    'Yellow',
    'Orange',
    'Purple',
    'Pink',
    'Black',
    'White',
    'Gray',
    'Brown',
    'Clear/Transparent',
    'Other'
  ];

  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
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
    setState(() {
      _selectedFilamentType = null;
      _selectedColor = null;
    });
    _countController.clear();
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
            
            // Color Dropdown
            const Text(
              'Color',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedColor,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.palette),
                hintText: 'Select color',
              ),
              items: _colors.map((String color) {
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
                      Text(color),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedColor = newValue;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a color';
                }
                return null;
              },
            ),
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
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'pink':
        return Colors.pink;
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.white;
      case 'gray':
        return Colors.grey;
      case 'brown':
        return Colors.brown;
      case 'clear/transparent':
        return Colors.transparent;
      default:
        return Colors.grey;
    }
  }
}