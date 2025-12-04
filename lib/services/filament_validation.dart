class FilamentValidation {
  /// Validate filament type
  static String? validateFilamentType(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select a filament type';
    }
    return null;
  }

  /// Validate filament color
  static String? validateFilamentColor(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select or enter a color';
    }
    return null;
  }

  /// Validate filament count
  static String? validateFilamentCount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter the filament count';
    }
    
    final count = int.tryParse(value);
    if (count == null) {
      return 'Please enter a valid number';
    }
    
    if (count <= 0) {
      return 'Count must be greater than 0';
    }
    
    if (count > 10000) {
      return 'Count must be less than 10,000';
    }
    
    return null;
  }

  /// Validate filament brand
  static String? validateFilamentBrand(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a brand name';
    }
    
    if (value.trim().length < 2) {
      return 'Brand name must be at least 2 characters';
    }
    
    if (value.trim().length > 50) {
      return 'Brand name must be less than 50 characters';
    }
    
    return null;
  }

  /// Validate filament weight
  static String? validateWeight(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter the weight';
    }
    
    final weight = double.tryParse(value);
    if (weight == null) {
      return 'Please enter a valid weight';
    }
    
    if (weight <= 0) {
      return 'Weight must be greater than 0';
    }
    
    if (weight > 10000) {
      return 'Weight must be less than 10,000g';
    }
    
    return null;
  }

  /// Validate filament diameter
  static String? validateDiameter(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter the diameter';
    }
    
    final diameter = double.tryParse(value);
    if (diameter == null) {
      return 'Please enter a valid diameter';
    }
    
    if (diameter <= 0) {
      return 'Diameter must be greater than 0';
    }
    
    if (diameter > 10) {
      return 'Diameter must be less than 10mm';
    }
    
    return null;
  }

  /// Validate quantity
  static String? validateQuantity(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter the quantity';
    }
    
    final quantity = int.tryParse(value);
    if (quantity == null) {
      return 'Please enter a valid quantity';
    }
    
    if (quantity <= 0) {
      return 'Quantity must be greater than 0';
    }
    
    if (quantity > 1000) {
      return 'Quantity must be less than 1,000';
    }
    
    return null;
  }

  /// Validate empty spool weight (optional)
  static String? validateEmptySpoolWeight(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }
    
    final weight = double.tryParse(value);
    if (weight == null) {
      return 'Please enter a valid weight';
    }
    
    if (weight < 0) {
      return 'Weight cannot be negative';
    }
    
    if (weight > 5000) {
      return 'Empty spool weight must be less than 5,000g';
    }
    
    return null;
  }

  /// Validate cost (optional)
  static String? validateCost(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }
    
    final cost = double.tryParse(value);
    if (cost == null) {
      return 'Please enter a valid cost';
    }
    
    if (cost < 0) {
      return 'Cost cannot be negative';
    }
    
    if (cost > 10000) {
      return 'Cost must be less than 10,000';
    }
    
    return null;
  }

  /// Validate storage location (optional)
  static String? validateStorageLocation(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }
    
    if (value.trim().length > 100) {
      return 'Storage location must be less than 100 characters';
    }
    
    return null;
  }

  /// Validate notes (optional)
  static String? validateNotes(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }
    
    if (value.trim().length > 500) {
      return 'Notes must be less than 500 characters';
    }
    
    return null;
  }

  /// Validate hex color code
  static String? validateHexColor(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Hex color is optional
    }
    
    // Remove # if present
    String cleanHex = value.replaceAll('#', '');
    
    // Check if it's a valid hex color (3 or 6 characters)
    if (!RegExp(r'^[A-Fa-f0-9]{3}$|^[A-Fa-f0-9]{6}$').hasMatch(cleanHex)) {
      return 'Please enter a valid hex color (e.g., #FF0000 or #F00)';
    }
    
    return null;
  }

  /// Format hex color with # prefix
  static String formatHexColor(String hexColor) {
    String cleanHex = hexColor.replaceAll('#', '');
    return '#${cleanHex.toUpperCase()}';
  }

  /// Check if a color is a valid hex color
  static bool isValidHexColor(String color) {
    String cleanHex = color.replaceAll('#', '');
    return RegExp(r'^[A-Fa-f0-9]{3}$|^[A-Fa-f0-9]{6}$').hasMatch(cleanHex);
  }

  /// Get display name for filament
  static String getFilamentDisplayName({
    required String type,
    required String color,
    required int count,
  }) {
    return '$type - $color ($count units)';
  }
}