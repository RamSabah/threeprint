import 'package:flutter/material.dart';
import '../services/filament_service.dart';
import '../services/filament_validation.dart';
import '../widgets/ColorPicker.dart';
import '../models/filament.dart';

class AddFilamentPage extends StatefulWidget {
  final Filament? filamentToEdit;
  
  const AddFilamentPage({super.key, this.filamentToEdit});

  @override
  State<AddFilamentPage> createState() => _AddFilamentPageState();
}

class _AddFilamentPageState extends State<AddFilamentPage> {
  final _formKey = GlobalKey<FormState>();
  final _countController = TextEditingController();
  final _brandController = TextEditingController();
  final _productNameController = TextEditingController();
  final _weightController = TextEditingController(text: '1000');
  final _diameterController = TextEditingController(text: '1.75');
  final _quantityController = TextEditingController(text: '1');
  final _emptySpoolWeightController = TextEditingController();
  final _costController = TextEditingController();
  final _storageLocationController = TextEditingController();
  final _notesController = TextEditingController();
  final _notesFocusNode = FocusNode();
  
  // New fields
  final _densityController = TextEditingController(text: '1.24');
  final _spoolWeightController = TextEditingController();
  final _spoolTypeController = TextEditingController();
  final _extruderTempController = TextEditingController();
  final _extruderTempMinController = TextEditingController();
  final _extruderTempMaxController = TextEditingController();
  final _bedTempController = TextEditingController();
  final _bedTempMinController = TextEditingController();
  final _bedTempMaxController = TextEditingController();
  final _finishController = TextEditingController();
  final _patternController = TextEditingController();
  
  String? _selectedFilamentType;
  String? _selectedSpoolType;
  Color _selectedColor = Colors.red;
  String _selectedColorName = 'Red';
  bool _isSaving = false;
  bool _isNotesFocused = false;
  bool _isTranslucent = false;
  bool _isGlowInDark = false;
  final FilamentService _filamentService = FilamentService();
  
  final List<String> _filamentTypes = ['PLA', 'PLA+', 'ABS', 'PETG', 'TPU', 'WOOD', 'ASA', 'PC', 'Other'];
  final List<String> _spoolTypes = ['PLASTIC', 'CARDBOARD', 'METAL', 'OTHER'];

  @override
  void initState() {
    super.initState();
    _notesFocusNode.addListener(() {
      setState(() {
        _isNotesFocused = _notesFocusNode.hasFocus;
      });
    });
    
    // Initialize form with existing filament data if editing
    if (widget.filamentToEdit != null) {
      _initializeFormForEditing();
    }
  }
  
  void _initializeFormForEditing() {
    final filament = widget.filamentToEdit!;
    
    // Set filament type, but add to list if it doesn't exist
    if (!_filamentTypes.contains(filament.type)) {
      _filamentTypes.insert(_filamentTypes.length - 1, filament.type); // Insert before 'Other'
    }
    _selectedFilamentType = filament.type;
    _countController.text = filament.count.toString();
    _brandController.text = filament.brand;
    _productNameController.text = filament.productName ?? '';
    _weightController.text = filament.weight.toString();
    _diameterController.text = filament.diameter.toString();
    _quantityController.text = filament.quantity.toString();
    _emptySpoolWeightController.text = filament.emptySpoolWeight?.toString() ?? '';
    _costController.text = filament.cost?.toString() ?? '';
    _storageLocationController.text = filament.storageLocation ?? '';
    _notesController.text = filament.notes ?? '';
    
    // Initialize new fields
    _densityController.text = filament.density?.toString() ?? '';
    _spoolTypeController.text = filament.spoolType ?? '';
    _extruderTempController.text = filament.extruderTemp?.toString() ?? '';
    if (filament.extruderTempRange != null && filament.extruderTempRange!.length == 2) {
      _extruderTempMinController.text = filament.extruderTempRange![0].toString();
      _extruderTempMaxController.text = filament.extruderTempRange![1].toString();
    }
    _bedTempController.text = filament.bedTemp?.toString() ?? '';
    if (filament.bedTempRange != null && filament.bedTempRange!.length == 2) {
      _bedTempMinController.text = filament.bedTempRange![0].toString();
      _bedTempMaxController.text = filament.bedTempRange![1].toString();
    }
    _finishController.text = filament.finish ?? '';
    _patternController.text = filament.pattern ?? '';
    _isTranslucent = filament.isTranslucent ?? false;
    _isGlowInDark = filament.isGlowInDark ?? false;
    
    // Initialize color from hex string
    try {
      if (filament.color.isNotEmpty) {
        String cleanHex = filament.color.replaceAll('#', '');
        if (cleanHex.length == 6) {
          _selectedColor = Color(int.parse('FF$cleanHex', radix: 16));
          _selectedColorName = ColorPickerUtils.getColorName(_selectedColor);
        }
      }
    } catch (e) {
      // Keep default color if parsing fails
    }
  }

  @override
  void dispose() {
    _countController.dispose();
    _brandController.dispose();
    _productNameController.dispose();
    _weightController.dispose();
    _diameterController.dispose();
    _quantityController.dispose();
    _emptySpoolWeightController.dispose();
    _costController.dispose();
    _storageLocationController.dispose();
    _notesController.dispose();
    _notesFocusNode.dispose();
    _densityController.dispose();
    _spoolWeightController.dispose();
    _spoolTypeController.dispose();
    _extruderTempController.dispose();
    _extruderTempMinController.dispose();
    _extruderTempMaxController.dispose();
    _bedTempController.dispose();
    _bedTempMinController.dispose();
    _bedTempMaxController.dispose();
    _finishController.dispose();
    _patternController.dispose();
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
        
        if (widget.filamentToEdit != null) {
          // Update existing filament
          final originalFilament = widget.filamentToEdit!;
          await _filamentService.updateFilament(
            filamentId: originalFilament.id,
            type: _selectedFilamentType!,
            color: finalColor,
            count: int.parse(_countController.text),
            brand: _brandController.text,
            productName: _productNameController.text.isNotEmpty 
                ? _productNameController.text.trim() 
                : null,
            clearProductName: originalFilament.productName != null && _productNameController.text.isEmpty,
            weight: double.parse(_weightController.text),
            diameter: double.parse(_diameterController.text),
            quantity: int.parse(_quantityController.text),
            emptySpoolWeight: _emptySpoolWeightController.text.isNotEmpty 
                ? double.tryParse(_emptySpoolWeightController.text) 
                : null,
            clearEmptySpoolWeight: originalFilament.emptySpoolWeight != null && _emptySpoolWeightController.text.isEmpty,
            cost: _costController.text.isNotEmpty 
                ? double.tryParse(_costController.text) 
                : null,
            clearCost: originalFilament.cost != null && _costController.text.isEmpty,
            storageLocation: _storageLocationController.text.isNotEmpty 
                ? _storageLocationController.text.trim() 
                : null,
            clearStorageLocation: originalFilament.storageLocation != null && _storageLocationController.text.isEmpty,
            notes: _notesController.text.isNotEmpty 
                ? _notesController.text.trim() 
                : null,
            clearNotes: originalFilament.notes != null && _notesController.text.isEmpty,
            density: _densityController.text.isNotEmpty 
                ? double.tryParse(_densityController.text) 
                : null,
            clearDensity: originalFilament.density != null && _densityController.text.isEmpty,
            spoolType: _spoolTypeController.text.isNotEmpty 
                ? _spoolTypeController.text.trim() 
                : null,
            clearSpoolType: originalFilament.spoolType != null && _spoolTypeController.text.isEmpty,
            extruderTemp: _extruderTempController.text.isNotEmpty 
                ? int.tryParse(_extruderTempController.text) 
                : null,
            clearExtruderTemp: originalFilament.extruderTemp != null && _extruderTempController.text.isEmpty,
            extruderTempRange: (_extruderTempMinController.text.isNotEmpty && _extruderTempMaxController.text.isNotEmpty)
                ? [int.parse(_extruderTempMinController.text), int.parse(_extruderTempMaxController.text)]
                : null,
            clearExtruderTempRange: originalFilament.extruderTempRange != null && _extruderTempMinController.text.isEmpty && _extruderTempMaxController.text.isEmpty,
            bedTemp: _bedTempController.text.isNotEmpty 
                ? int.tryParse(_bedTempController.text) 
                : null,
            clearBedTemp: originalFilament.bedTemp != null && _bedTempController.text.isEmpty,
            bedTempRange: (_bedTempMinController.text.isNotEmpty && _bedTempMaxController.text.isNotEmpty)
                ? [int.parse(_bedTempMinController.text), int.parse(_bedTempMaxController.text)]
                : null,
            clearBedTempRange: originalFilament.bedTempRange != null && _bedTempMinController.text.isEmpty && _bedTempMaxController.text.isEmpty,
            finish: _finishController.text.isNotEmpty 
                ? _finishController.text.trim() 
                : null,
            clearFinish: originalFilament.finish != null && _finishController.text.isEmpty,
            pattern: _patternController.text.isNotEmpty 
                ? _patternController.text.trim() 
                : null,
            clearPattern: originalFilament.pattern != null && _patternController.text.isEmpty,
            isTranslucent: _isTranslucent,
            isGlowInDark: _isGlowInDark,
          );
          
          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Filament updated successfully: ${_brandController.text} $_selectedFilamentType',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
            
            // Go back after updating
            Navigator.of(context).pop(true);
          }
        } else {
          // Save new filament
          await _filamentService.saveFilament(
            type: _selectedFilamentType!,
            color: finalColor,
            count: int.parse(_countController.text),
            brand: _brandController.text,
            productName: _productNameController.text.isNotEmpty 
                ? _productNameController.text.trim() 
                : null,
            weight: double.parse(_weightController.text),
            diameter: double.parse(_diameterController.text),
            quantity: int.parse(_quantityController.text),
            emptySpoolWeight: _emptySpoolWeightController.text.isNotEmpty 
                ? double.tryParse(_emptySpoolWeightController.text) 
                : null,
            cost: _costController.text.isNotEmpty 
                ? double.tryParse(_costController.text) 
                : null,
            storageLocation: _storageLocationController.text.isNotEmpty 
                ? _storageLocationController.text.trim() 
                : null,
            notes: _notesController.text.isNotEmpty 
                ? _notesController.text.trim() 
                : null,
            density: _densityController.text.isNotEmpty 
                ? double.tryParse(_densityController.text) 
                : null,
            spoolType: _spoolTypeController.text.isNotEmpty 
                ? _spoolTypeController.text.trim() 
                : null,
            extruderTemp: _extruderTempController.text.isNotEmpty 
                ? int.tryParse(_extruderTempController.text) 
                : null,
            extruderTempRange: (_extruderTempMinController.text.isNotEmpty && _extruderTempMaxController.text.isNotEmpty)
                ? [int.parse(_extruderTempMinController.text), int.parse(_extruderTempMaxController.text)]
                : null,
            bedTemp: _bedTempController.text.isNotEmpty 
                ? int.tryParse(_bedTempController.text) 
                : null,
            bedTempRange: (_bedTempMinController.text.isNotEmpty && _bedTempMaxController.text.isNotEmpty)
                ? [int.parse(_bedTempMinController.text), int.parse(_bedTempMaxController.text)]
                : null,
            finish: _finishController.text.isNotEmpty 
                ? _finishController.text.trim() 
                : null,
            pattern: _patternController.text.isNotEmpty 
                ? _patternController.text.trim() 
                : null,
            isTranslucent: _isTranslucent,
            isGlowInDark: _isGlowInDark,
          );

          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Filament saved successfully: ${_brandController.text} $_selectedFilamentType, $_selectedColorName, ${_countController.text} units',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
            
            // Clear form after saving
            _resetForm();
          }
        }
      } catch (e) {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.filamentToEdit != null 
                  ? 'Failed to update filament: ${e.toString()}'
                  : 'Failed to save filament: ${e.toString()}',
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
      _selectedSpoolType = null;
      _selectedColor = Colors.red;
      _selectedColorName = 'Red';
      _isTranslucent = false;
      _isGlowInDark = false;
    });
    _countController.clear();
    _brandController.clear();
    _productNameController.clear();
    _weightController.text = '1000';
    _diameterController.text = '1.75';
    _quantityController.text = '1';
    _densityController.text = '1.24';
    _emptySpoolWeightController.clear();
    _spoolWeightController.clear();
    _costController.clear();
    _storageLocationController.clear();
    _notesController.clear();
    _extruderTempController.clear();
    _extruderTempMinController.clear();
    _extruderTempMaxController.clear();
    _bedTempController.clear();
    _bedTempMinController.clear();
    _bedTempMaxController.clear();
    _finishController.clear();
    _patternController.clear();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final isTablet = screenWidth > 600;
          final maxWidth = isTablet ? 800.0 : double.infinity;
          final horizontalPadding = isTablet ? 32.0 : 16.0;
          
          return GestureDetector(
            onTap: () {
              // Hide keyboard when tapping outside input fields
              FocusScope.of(context).unfocus();
            },
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(horizontalPadding),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
              // Header
              Stack(
                children: [
                  // Cancel button (top-right)
                  if (widget.filamentToEdit != null)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        onPressed: () {
                          // Unfocus any text fields before closing
                          FocusScope.of(context).unfocus();
                          // Close the page
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                          padding: const EdgeInsets.all(8),
                        ),
                        tooltip: 'Cancel',
                      ),
                    ),
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          widget.filamentToEdit != null ? 'Edit Filament' : 'Add New Filament',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          widget.filamentToEdit != null 
                              ? 'Update your filament details'
                              : 'Track your filament inventory',
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // BASIC INFORMATION CARD
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.info_outline,
                              color: Theme.of(context).colorScheme.secondary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Basic Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Filament Type Dropdown
                      Text(
                        'Filament Type',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedFilamentType,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surfaceContainerHighest : Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade200, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2),
                          ),
                          prefixIcon: Icon(Icons.category, color: Theme.of(context).colorScheme.secondary),
                          hintText: 'Select filament type',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                      const SizedBox(height: 16),
                      
                      // Brand Input Field
                      Text(
                        'Brand',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _brandController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surfaceContainerHighest : Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade200, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2),
                          ),
                          prefixIcon: Icon(Icons.business, color: Theme.of(context).colorScheme.secondary),
                          hintText: 'Enter brand name (e.g., Hatchbox, eSUN)',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        validator: FilamentValidation.validateFilamentBrand,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),
                      
                      // Product Name Input Field
                      Text(
                        'Product Name (Optional)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _productNameController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surfaceContainerHighest : Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade200, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2),
                          ),
                          prefixIcon: Icon(Icons.label, color: Theme.of(context).colorScheme.secondary),
                          hintText: 'Enter product name (e.g., Dark Grey, Silk Gold)',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // COLOR CARD
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.palette,
                              color: Theme.of(context).colorScheme.secondary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Color',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Color Picker
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Theme.of(context).colorScheme.surfaceContainerHighest 
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Selected Color',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).brightness == Brightness.dark 
                                          ? Colors.grey.shade400 
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedColorName,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    ColorPickerUtils.colorToHex(_selectedColor),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).brightness == Brightness.dark 
                                          ? Colors.grey.shade400 
                                          : Colors.grey.shade600,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: _openColorPicker,
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: _selectedColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Theme.of(context).brightness == Brightness.dark 
                                        ? Colors.grey.shade700 
                                        : Colors.grey.shade300,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.palette,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // INVENTORY CARD
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.inventory_2,
                              color: Theme.of(context).colorScheme.secondary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Inventory',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Count Input
                      Text(
                        'Count',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _countController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surfaceContainerHighest : Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade200, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2),
                          ),
                          prefixIcon: Icon(Icons.numbers, color: Theme.of(context).colorScheme.secondary),
                          hintText: 'Enter number of filament units',
                          suffixText: 'units',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        validator: FilamentValidation.validateFilamentCount,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // SPECIFICATIONS CARD
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.settings,
                              color: Theme.of(context).colorScheme.secondary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Specifications',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const SizedBox(height: 20),
              
              // Weight, Diameter, Quantity Row
              Row(
                children: [
                  // Weight Field
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Weight (g)',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _weightController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surfaceContainerHighest : Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade200, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2),
                            ),
                            hintText: '1000',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          ),
                          validator: FilamentValidation.validateWeight,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Diameter Field
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Diameter (mm)',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _diameterController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surfaceContainerHighest : Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade200, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2),
                            ),
                            hintText: '1.75',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          ),
                          validator: FilamentValidation.validateDiameter,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Quantity Field
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quantity',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surfaceContainerHighest : Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade200, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2),
                            ),
                            hintText: '1',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          ),
                          validator: FilamentValidation.validateQuantity,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Additional Specifications Row (Density, Spool Weight, Spool Type)
              Row(
                children: [
                  // Density Field
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Density (g/cm³)',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _densityController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surfaceContainerHighest : Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade200, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2),
                            ),
                            hintText: '1.24',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Spool Weight Field
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Spool Weight (g)',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _spoolWeightController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surfaceContainerHighest : Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade200, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2),
                            ),
                            hintText: '340',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Spool Type
              Text(
                'Spool Type',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedSpoolType,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surfaceContainerHighest : Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade200, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2),
                  ),
                  prefixIcon: Icon(Icons.album, color: Theme.of(context).colorScheme.secondary),
                  hintText: 'Select spool type',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                items: _spoolTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedSpoolType = newValue;
                  });
                },
              ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // TEMPERATURE SETTINGS CARD
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.thermostat,
                              color: Theme.of(context).colorScheme.secondary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Temperature Settings',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      Row(
                        children: [
                          // Extruder Temperature
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Extruder Temp (°C)',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _extruderTempController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surfaceContainerHighest : Colors.grey.shade50,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade200, width: 1),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2),
                                    ),
                                    hintText: '200',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Or Temperature Range',
                                  style: TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _extruderTempMinController,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surfaceContainerHighest : Colors.grey.shade50,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide.none,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade200, width: 1),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2),
                                          ),
                                          hintText: 'Min',
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        ),
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 8),
                                      child: Text('-', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    ),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _extruderTempMaxController,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surfaceContainerHighest : Colors.grey.shade50,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide.none,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade200, width: 1),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2),
                                          ),
                                          hintText: 'Max',
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(width: 12),
                          
                          // Bed Temperature
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bed Temp (°C)',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _bedTempController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surfaceContainerHighest : Colors.grey.shade50,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade200, width: 1),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2),
                                    ),
                                    hintText: '60',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Or Temperature Range',
                                  style: TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _bedTempMinController,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surfaceContainerHighest : Colors.grey.shade50,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide.none,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade200, width: 1),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2),
                                          ),
                                          hintText: 'Min',
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        ),
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 8),
                                      child: Text('-', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    ),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _bedTempMaxController,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surfaceContainerHighest : Colors.grey.shade50,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide.none,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade200, width: 1),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2),
                                          ),
                                          hintText: 'Max',
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // SPECIAL PROPERTIES CARD
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade200, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.star_outline,
                              color: Theme.of(context).colorScheme.secondary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Special Properties',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      Row(
                        children: [
                          // Finish
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Finish',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _finishController,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surfaceContainerHighest : Colors.grey.shade50,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade200, width: 1),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2),
                                    ),
                                    hintText: 'Matte, Glossy, etc.',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(width: 12),
                          
                          // Pattern
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pattern',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _patternController,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surfaceContainerHighest : Colors.grey.shade50,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade200, width: 1),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2),
                                    ),
                                    hintText: 'Solid, Marble, etc.',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Translucent Toggle
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surfaceContainerHighest : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade200, width: 1),
                        ),
                        child: SwitchListTile(
                          title: Row(
                            children: [
                              Icon(Icons.visibility, size: 20, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Text(
                                'Translucent',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                            ],
                          ),
                          value: _isTranslucent,
                          activeColor: Theme.of(context).colorScheme.secondary,
                          onChanged: (bool value) {
                            setState(() {
                              _isTranslucent = value;
                            });
                          },
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Glow in Dark Toggle
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surfaceContainerHighest : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade200, width: 1),
                        ),
                        child: SwitchListTile(
                          title: Row(
                            children: [
                              Icon(Icons.light_mode, size: 20, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Text(
                                'Glow in Dark',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                            ],
                          ),
                          value: _isGlowInDark,
                          activeColor: Theme.of(context).colorScheme.secondary,
                          onChanged: (bool value) {
                            setState(() {
                              _isGlowInDark = value;
                            });
                          },
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // OPTIONAL DETAILS CARD
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.more_horiz,
                              color: Theme.of(context).colorScheme.secondary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Optional Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const SizedBox(height: 20),
              
              // Empty Spool Weight
              Text(
                'Empty Spool Weight (g)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87),
              ),
              const SizedBox(height: 4),
              Text(
                'Optional: Weight of empty spool',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emptySpoolWeightController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surfaceContainerHighest : Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade200, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2),
                  ),
                  hintText: '200',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                validator: FilamentValidation.validateEmptySpoolWeight,
              ),
              
              const SizedBox(height: 16),
              
              // Cost
              Text(
                'Cost',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _costController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surfaceContainerHighest : Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade200, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2),
                  ),
                  prefixIcon: Icon(Icons.attach_money, color: Theme.of(context).colorScheme.secondary),
                  hintText: '25.99',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                validator: FilamentValidation.validateCost,
              ),
              
              const SizedBox(height: 16),
              
              // Storage Location
              Text(
                'Storage Location',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _storageLocationController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surfaceContainerHighest : Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade200, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2),
                  ),
                  prefixIcon: Icon(Icons.location_on, color: Theme.of(context).colorScheme.secondary),
                  hintText: 'Shelf A, Drawer 2, etc.',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                validator: FilamentValidation.validateStorageLocation,
                textCapitalization: TextCapitalization.words,
              ),
              
              const SizedBox(height: 20),
              
              // Notes
              Text(
                'Notes',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                focusNode: _notesFocusNode,
                maxLines: 3,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surfaceContainerHighest : Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade200, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2),
                  ),
                  hintText: 'Any additional notes about this filament...',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  suffixIcon: _isNotesFocused 
                    ? IconButton(
                        icon: const Icon(Icons.close, color: Colors.black54, size: 20),
                        onPressed: () {
                          // Dismiss keyboard by removing focus
                          _notesFocusNode.unfocus();
                        },
                      )
                    : null,
                ),
                validator: FilamentValidation.validateNotes,
                textCapitalization: TextCapitalization.sentences,
              ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () {
                        if (widget.filamentToEdit != null) {
                          // If editing, cancel and go back
                          FocusScope.of(context).unfocus();
                          Navigator.of(context).pop();
                        } else {
                          // If adding new, clear all fields
                          _resetForm();
                          FocusScope.of(context).unfocus();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('All fields cleared'),
                              duration: const Duration(seconds: 2),
                              backgroundColor: Colors.grey.shade700,
                            ),
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey.shade400, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(widget.filamentToEdit != null ? Icons.close : Icons.clear_all),
                          const SizedBox(width: 8),
                          Text(
                            widget.filamentToEdit != null ? 'Cancel' : 'Clear Fields',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveFilament,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
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
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.save),
                                const SizedBox(width: 8),
                                Text(
                                  widget.filamentToEdit != null ? 'Update Filament' : 'Save Filament',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),

                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}