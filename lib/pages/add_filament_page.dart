import 'package:flutter/material.dart';
import '../services/filament_service.dart';
import '../services/filament_validation.dart';
import '../widgets/color_picker_widget.dart';

class AddFilamentPage extends StatefulWidget {
  const AddFilamentPage({super.key});

  @override
  State<AddFilamentPage> createState() => _AddFilamentPageState();
}

class _AddFilamentPageState extends State<AddFilamentPage> {
  final _formKey = GlobalKey<FormState>();
  final _countController = TextEditingController();
  
  String? _selectedFilamentType;
  Color _selectedColor = Colors.red;
  String _selectedColorName = 'Red';
  bool _isSaving = false;
  final FilamentService _filamentService = FilamentService();
  
  final List<String> _filamentTypes = ['PETG', 'PLA', 'Other'];

  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
  }

  Future<void> _openColorPicker() async {
    final Color? pickedColor = await ColorPickerUtils.showColorPicker(
      context: context,
      initialColor: _selectedColor,
      title: 'Select Filament Color',
    );
    
    if (pickedColor != null) {
      setState(() {
        _selectedColor = pickedColor;
        _selectedColorName = ColorPickerUtils.getColorName(pickedColor);
      });
    }
  }

  Future<void> _saveFilament() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      try {
        // Get the final color value
        final String finalColor = ColorPickerUtils.colorToHex(_selectedColor);
        
        // Save to Firestore
        final filamentId = await _filamentService.saveFilament(
          type: _selectedFilamentType!,
          color: finalColor,
          count: int.parse(_countController.text),
        );

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Filament saved successfully: $_selectedFilamentType, $_selectedColorName, ${_countController.text} units',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          
          // Clear form after saving
          _resetForm();
        }
      } catch (e) {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to save filament: ${e.toString()}',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  void _resetForm() {
    setState(() {
      _selectedFilamentType = null;
      _selectedColor = Colors.red;
      _selectedColorName = 'Red';
    });
    _countController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
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
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.inventory_2,
                          size: 80,
                          color: Colors.grey,
                        );
                      },
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
                validator: FilamentValidation.validateFilamentType,
              ),
              const SizedBox(height: 20),
              
              // Color Section with Color Picker
              const Text(
                'Color',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selected Color',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedColorName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                ColorPickerUtils.colorToHex(_selectedColor),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: _selectedColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey.shade400,
                                  width: 2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: _openColorPicker,
                              icon: const Icon(Icons.palette, size: 18),
                              label: const Text('Pick Color'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
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
                  prefixIcon: Icon(Icons.numbers),
                  hintText: 'Enter number of filament units',
                  suffixText: 'units',
                ),
                validator: FilamentValidation.validateFilamentCount,
              ),
              
              const SizedBox(height: 32),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : _resetForm,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.refresh),
                          SizedBox(width: 8),
                          Text('Reset', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveFilament,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: _isSaving
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('Saving...', style: TextStyle(fontSize: 16)),
                              ],
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save),
                                SizedBox(width: 8),
                                Text('Save Filament', style: TextStyle(fontSize: 16)),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Use the color picker to select the exact color of your filament\\n'
                      '• The color will be saved with both the name and HEX value\\n'
                      '• All filaments are linked to your account for secure storage\\n'
                      '• You can track inventory across multiple devices',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade600,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}