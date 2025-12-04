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